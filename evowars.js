// ==UserScript==
// @name         EvoWars.io ESP (CezDev - Threat Awareness v11.4)
// @version      11.4.0
// @description  Facing Warning, Continuous Aim Override, Absolute Lock, Enemy Rings
// @author       DDatiOS (Optimized by CezDev)
// @match        *://evowars.io/*
// @icon         https://www.google.com/s2/favicons?domain=evowars.io
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const config = {
        // --- CẤU HÌNH MÀU SẮC & GIAO DIỆN ---
        TRACER: "rgba(255, 255, 255, 0.2)", 
        WARNING_TRACER: "rgba(255, 0, 0, 0.4)", 
        FACING_WARNING_TRACER: "rgba(255, 0, 0, 0.9)", // Dây cảnh báo đỏ rực khi bị ngắm
        
        ENEMY_RING_NORMAL: "rgba(255, 255, 255, 0.5)", 
        ENEMY_RING_DANGER: "rgba(255, 0, 0, 0.6)",     
        MY_RING_COLOR: "rgba(255, 165, 0, 0.6)",       

        TARGET_COLOR: "#00ff00", 
        IN_RANGE_COLOR: "#ff0000", 
        FONT: "#ffffff",
        FONT_DANGER: "#ff4444",
        FONT_WARNING: "#ff0000",
        
        SHOW_TRACER: true,
        SHOW_NAMES: true,
        SHOW_SCORES: true,
        SHOW_ATTACK_RING: true,          
        SHOW_FACING_WARNING: true,       // Bật/tắt tính năng cảnh báo hướng nhìn
        FACING_CONE: Math.PI / 4,        // Góc cảnh báo (45 độ mỗi bên)
        
        // --- PHÍM TẮT ---
        AIM_KEY: "Shift",        
        TOGGLE_KEY: "v",         

        // --- CẤU HÌNH TẦM ĐÁNH ---
        ATTACK_RANGE_MULTIPLIER: 2.2,    
        ATTACK_RANGE_BUFFER: 60,         

        // --- CẤU HÌNH AUTO ATTACK ---
        AUTO_ATTACK: true,               
        ATTACK_COOLDOWN: 300,            
        ATTACK_LOCK_DURATION: 200, 
    };

    const state = {
        rt: null,
        pType: null,
        gameCanvas: null,
        nameIndex: 18, 
        scoreIndex: 27, 
        isAiming: false,
        isActive: true,
        lastAttackTime: 0,
        attackLockEnd: 0, 
        lockedTarget: null 
    };

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d', { alpha: true });

    const setupDOM = () => {
        document.body.appendChild(canvas);
        canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:9999;';
        
        const resize = () => {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        };
        window.addEventListener('resize', resize);
        resize();

        const blockRealMouse = (e) => {
            if (state.isActive && Date.now() < state.attackLockEnd && e.isTrusted) {
                e.stopPropagation();
                e.stopImmediatePropagation();
            }
        };

        window.addEventListener('mousemove', blockRealMouse, true);
        window.addEventListener('pointermove', blockRealMouse, true);
        window.addEventListener('mousedown', blockRealMouse, true);
        window.addEventListener('pointerdown', blockRealMouse, true);

        window.addEventListener('keydown', (e) => {
            if (document.activeElement && document.activeElement.tagName === 'INPUT') return;
            
            if (e.key === config.AIM_KEY && !state.isAiming) {
                state.isAiming = true;
                if (state.gameCanvas) {
                    state.gameCanvas.dispatchEvent(new MouseEvent('mousedown', {
                        button: 2, bubbles: true, cancelable: true
                    }));
                }
            }
            if (e.key.toLowerCase() === config.TOGGLE_KEY) state.isActive = !state.isActive;
        });
        
        window.addEventListener('keyup', (e) => {
            if (e.key === config.AIM_KEY) {
                state.isAiming = false;
                if (state.gameCanvas) {
                    state.gameCanvas.dispatchEvent(new MouseEvent('mouseup', {
                        button: 2, bubbles: true, cancelable: true
                    }));
                }
            }
        });

        window.addEventListener('contextmenu', (e) => {
            if (state.isActive) e.preventDefault();
        });
    };

    const simulateAttack = (x, y) => {
        if (!state.gameCanvas) return;
        const opts = { clientX: x, clientY: y, button: 0, bubbles: true, cancelable: true, view: window };
        
        state.gameCanvas.dispatchEvent(new PointerEvent('pointerdown', opts));
        state.gameCanvas.dispatchEvent(new MouseEvent('mousedown', opts));
        
        setTimeout(() => {
            if (state.gameCanvas) {
                state.gameCanvas.dispatchEvent(new PointerEvent('pointerup', opts));
                state.gameCanvas.dispatchEvent(new MouseEvent('mouseup', opts));
            }
        }, 60); 
    };

    const render = () => {
        if (!state.isActive || !state.rt?.running_layout || !state.pType) {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            return;
        }

        const now = Date.now();
        const scrollX = state.rt.running_layout.scrollX;
        const scrollY = state.rt.running_layout.scrollY;
        let self = null;
        let min_d = Infinity;

        for (const p of state.pType.instances) {
            const d = (p.x - scrollX) ** 2 + (p.y - scrollY) ** 2;
            if (d < min_d) {
                min_d = d;
                self = p;
            }
        }

        if (!self || (self.x === 0 && self.y === 0)) {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            return;
        }
        
        const selfScore = Math.floor(self.instance_vars[state.scoreIndex] || 0);

        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        const rect = state.gameCanvas.getBoundingClientRect();
        const viewX = rect.left + rect.width / 2;
        const viewY = rect.top + rect.height / 2;
        const scale = self.layer.getScale();

        ctx.lineWidth = 1;
        
        const tracersNormal = new Path2D();
        const tracersDanger = new Path2D();
        const tracersFacing = new Path2D(); // Dây tia laser đỏ khi bị ngắm

        let bestTarget = null;
        let minTargetDist = Infinity;

        const selfAttackRadius = (self.width / 2) * config.ATTACK_RANGE_MULTIPLIER + config.ATTACK_RANGE_BUFFER;

        if (config.SHOW_ATTACK_RING) {
            ctx.beginPath();
            ctx.arc(viewX, viewY, selfAttackRadius * scale, 0, 2 * Math.PI);
            ctx.strokeStyle = config.MY_RING_COLOR; 
            ctx.lineWidth = 2;
            ctx.setLineDash([5, 5]);
            ctx.stroke();
            ctx.setLineDash([]);
        }

        for (const p of state.pType.instances) {
            if (p.uid === self.uid) continue;
            
            const pScore = Math.floor(p.instance_vars[state.scoreIndex] || 0);
            const isDanger = pScore > selfScore; 
            
            const dx = self.x - p.x;
            const dy = self.y - p.y;
            const worldDist = Math.sqrt(dx*dx + dy*dy);

            const pX = viewX + (p.x - scrollX) * scale;
            const pY = viewY + (p.y - scrollY) * scale;

            const enemyAttackRadius = (p.width / 2) * config.ATTACK_RANGE_MULTIPLIER + config.ATTACK_RANGE_BUFFER;

            // TÍNH TOÁN HƯỚNG NHÌN CỦA ĐỊCH
            let isFacingMe = false;
            if (config.SHOW_FACING_WARNING) {
                // Tính góc từ địch đến mình
                const angleToMe = Math.atan2(self.y - p.y, self.x - p.x);
                // Lấy góc quay hiện tại của địch (p.angle)
                let angleDiff = p.angle - angleToMe;
                // Chuẩn hóa góc về mốc -PI đến PI
                angleDiff = Math.atan2(Math.sin(angleDiff), Math.cos(angleDiff));
                
                // Nếu độ lệch góc nằm trong hình nón 90 độ (45 độ mỗi bên)
                if (Math.abs(angleDiff) < config.FACING_CONE) {
                    isFacingMe = true;
                }
            }

            if (config.SHOW_ATTACK_RING) {
                ctx.beginPath();
                ctx.arc(pX, pY, enemyAttackRadius * scale, 0, 2 * Math.PI);
                ctx.strokeStyle = isDanger ? config.ENEMY_RING_DANGER : config.ENEMY_RING_NORMAL;
                ctx.lineWidth = isDanger ? 2 : 1.5;
                ctx.setLineDash([4, 4]);
                ctx.stroke();
                ctx.setLineDash([]);
            }

            if (config.SHOW_TRACER) {
                if (isFacingMe && isDanger) {
                    tracersFacing.moveTo(viewX, viewY);
                    tracersFacing.lineTo(pX, pY);
                } else {
                    const targetTracer = isDanger ? tracersDanger : tracersNormal;
                    targetTracer.moveTo(viewX, viewY);
                    targetTracer.lineTo(pX, pY);
                }
            }
            
            const name = p.instance_vars[state.nameIndex] || ''; 
            let text = `${config.SHOW_NAMES ? name : ''} ${config.SHOW_SCORES ? '[' + pScore + ']' : ''}`.trim();
            
            // THÊM CHỮ CẢNH BÁO NẾU ĐỊCH ĐANG CHỮA VŨ KHÍ VÀO BẠN
            if (isFacingMe) {
                ctx.font = "bold 14px Arial";
                ctx.textAlign = 'center';
                // Chỉ nháy cảnh báo nguy hiểm nếu địch to hơn, nếu địch nhỏ hơn thì hiện cảnh báo nhẹ hơn
                ctx.fillStyle = isDanger ? config.FONT_WARNING : config.FONT_DANGER;
                ctx.fillText("⚠️ NGẮM BẠN ⚠️", pX, pY - (enemyAttackRadius * scale) - 25);
            }

            if (text) {
                ctx.font = isDanger ? "bold 13px Arial" : "bold 12px Arial";
                ctx.textAlign = 'center';
                ctx.fillStyle = isDanger ? config.FONT_DANGER : config.FONT;
                ctx.fillText(text, pX, pY - (enemyAttackRadius * scale) - 8);
            }

            if (worldDist < minTargetDist) {
                minTargetDist = worldDist;
                bestTarget = { x: pX, y: pY, pWidth: p.width, worldDist: worldDist }; 
            }
        }

        if (config.SHOW_TRACER) {
            ctx.lineWidth = 1;
            ctx.strokeStyle = config.TRACER; ctx.stroke(tracersNormal);
            ctx.strokeStyle = config.WARNING_TRACER; ctx.stroke(tracersDanger);
            
            // Vẽ dây laser đỏ rực và dày hơn nếu đang bị kẻ địch to ngắm trúng
            ctx.lineWidth = 3;
            ctx.strokeStyle = config.FACING_WARNING_TRACER; 
            ctx.stroke(tracersFacing);
        }

        // --- HỆ THỐNG GHI ĐÈ LIÊN TỤC KHI ĐANG VUNG KIẾM ---
        if (now < state.attackLockEnd && state.lockedTarget) {
            const opts = { clientX: state.lockedTarget.x, clientY: state.lockedTarget.y, bubbles: true, cancelable: true };
            state.gameCanvas.dispatchEvent(new PointerEvent('pointermove', opts));
            state.gameCanvas.dispatchEvent(new MouseEvent('mousemove', opts));
        }

        if (bestTarget) {
            const isInRange = bestTarget.worldDist < (selfAttackRadius + (bestTarget.pWidth / 2));
            
            ctx.beginPath();
            ctx.strokeStyle = isInRange ? config.IN_RANGE_COLOR : config.TARGET_COLOR;
            ctx.lineWidth = isInRange ? 4 : 2; 
            const size = isInRange ? 20 : 15;
            
            ctx.moveTo(bestTarget.x - size, bestTarget.y); ctx.lineTo(bestTarget.x + size, bestTarget.y);
            ctx.moveTo(bestTarget.x, bestTarget.y - size); ctx.lineTo(bestTarget.x, bestTarget.y + size);
            ctx.stroke();

            if (isInRange) {
                ctx.font = "bold 16px Arial";
                ctx.fillStyle = config.IN_RANGE_COLOR;
                ctx.fillText("⚔️ AUTO SNAP & STRIKE ⚔️", bestTarget.x, bestTarget.y - 30);

                if (config.AUTO_ATTACK) {
                    if (now - state.lastAttackTime > config.ATTACK_COOLDOWN) {
                        state.lockedTarget = { x: bestTarget.x, y: bestTarget.y };
                        state.attackLockEnd = now + config.ATTACK_LOCK_DURATION;
                        
                        const opts = { clientX: bestTarget.x, clientY: bestTarget.y, bubbles: true, cancelable: true };
                        state.gameCanvas.dispatchEvent(new PointerEvent('pointermove', opts));
                        state.gameCanvas.dispatchEvent(new MouseEvent('mousemove', opts));
                        
                        simulateAttack(bestTarget.x, bestTarget.y);
                        state.lastAttackTime = now;
                    }
                }
            } else {
                if (state.isAiming && now > state.attackLockEnd) {
                    const opts = { clientX: bestTarget.x, clientY: bestTarget.y, bubbles: true, cancelable: true };
                    state.gameCanvas.dispatchEvent(new PointerEvent('pointermove', opts));
                    state.gameCanvas.dispatchEvent(new MouseEvent('mousemove', opts));
                }
            }
        }
    };

    const mainLoop = () => {
        try { render(); } catch (err) {}
        requestAnimationFrame(mainLoop);
    };

    const init = setInterval(() => {
        if (window.cr_getC2Runtime && (state.rt = window.cr_getC2Runtime())) {
            clearInterval(init);
            state.gameCanvas = state.rt.canvas;

            for (const type of state.rt.types_by_index) {
                if (type?.instvar_sids?.length === 72) {
                    state.pType = type;
                    break;
                }
            }
            if (state.pType) {
                console.log("%c[EvoWars ESP] V11.4 THREAT AWARENESS ACTIVE", "color: #00ff00; font-weight: bold;");
                setupDOM();
                mainLoop();
            }
        }
    }, 1000);
})();

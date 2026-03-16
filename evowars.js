// ==UserScript==
// @name         EvoWars.io ESP (CezDev - Strike Signal + Auto Sprint)
// @version      9.0.0
// @description  Vector Evade, Attack Range Indicator, Auto Sprint, ESP
// @author       DDatiOS (Optimized by CezDev)
// @match        *://evowars.io/*
// @icon         https://www.google.com/s2/favicons?domain=evowars.io
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const config = {
        CIRCLE_SIZE_FACTOR: 1.7,
        
        CIRCLE_FILL: "rgba(255, 255, 255, 0.15)", 
        CIRCLE_BORDER: "rgba(255, 255, 255, 0.8)", 
        TRACER: "rgba(255, 255, 255, 0.5)", 
        
        WARNING_FILL: "rgba(255, 0, 0, 0.25)", 
        WARNING_BORDER: "rgba(255, 0, 0, 0.9)", 
        WARNING_TRACER: "rgba(255, 0, 0, 0.7)", 
        
        TARGET_COLOR: "#00ff00", // Đang ngắm (Xanh)
        IN_RANGE_COLOR: "#ff0000", // ĐÃ VÀO TẦM CHÉM (ĐỎ)
        EVADE_COLOR: "#ff00ff",  
        FONT: "#ffffff",
        FONT_DANGER: "#ff4444",
        
        SHOW_CIRCLE: true,
        SHOW_TRACER: true,
        SHOW_NAMES: true,
        SHOW_SCORES: true,
        
        AIM_KEY: "Shift",        
        TOGGLE_KEY: "v",         
        
        // --- CẤU HÌNH AUTO EVADE ---
        AUTO_EVADE: true,        
        EVADE_MULTIPLIER: 1.5,   
        EVADE_BUFFER: 400,       

        // --- CẤU HÌNH TẦM ĐÁNH (MỚI) ---
        SHOW_ATTACK_RING: true,          // Hiển thị vòng tròn tầm đánh của bạn
        ATTACK_RANGE_MULTIPLIER: 2.2,    // Hệ số nhân chiều dài vũ khí (Tinh chỉnh theo cảm giác)
        ATTACK_RANGE_BUFFER: 60,         // Khoảng bù trừ (Pixel)
    };

    const state = {
        rt: null,
        pType: null,
        gameCanvas: null,
        nameIndex: 18, 
        scoreIndex: 27, 
        isAiming: false,
        isActive: true
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

        window.addEventListener('keydown', (e) => {
            if (document.activeElement && document.activeElement.tagName === 'INPUT') return;
            
            if (e.key === config.AIM_KEY && !state.isAiming) {
                state.isAiming = true;
                if (state.gameCanvas) {
                    state.gameCanvas.dispatchEvent(new MouseEvent('mousedown', {
                        button: 2, 
                        bubbles: true,
                        cancelable: true
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
                        button: 2,
                        bubbles: true,
                        cancelable: true
                    }));
                }
            }
        });

        window.addEventListener('contextmenu', (e) => {
            if (state.isActive) e.preventDefault();
        });
    };

    const render = () => {
        if (!state.isActive || !state.rt?.running_layout || !state.pType) {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            return;
        }

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
        const circlesNormal = new Path2D();
        const circlesDanger = new Path2D();

        let bestTarget = null;
        let minTargetDist = Infinity;
        
        let forceX = 0;
        let forceY = 0;
        let dangerCount = 0;

        // Tính toán Tầm đánh của bản thân (World Coordinates)
        const selfAttackRadius = (self.width / 2) * config.ATTACK_RANGE_MULTIPLIER + config.ATTACK_RANGE_BUFFER;

        // Vẽ Vòng tròn Tầm đánh (Attack Ring) nếu được bật
        if (config.SHOW_ATTACK_RING) {
            ctx.beginPath();
            ctx.arc(viewX, viewY, selfAttackRadius * scale, 0, 2 * Math.PI);
            ctx.strokeStyle = "rgba(255, 165, 0, 0.3)"; // Cam mờ
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
            const radius = (p.width / 2) * scale * config.CIRCLE_SIZE_FACTOR;

            if (config.SHOW_TRACER) {
                const targetTracer = isDanger ? tracersDanger : tracersNormal;
                targetTracer.moveTo(viewX, viewY);
                targetTracer.lineTo(pX, pY);
            }

            if (config.SHOW_CIRCLE) {
                const targetCircle = isDanger ? circlesDanger : circlesNormal;
                targetCircle.moveTo(pX + radius, pY);
                targetCircle.arc(pX, pY, radius, 0, 2 * Math.PI);
            }
            
            const name = p.instance_vars[state.nameIndex] || ''; 
            let text = `${config.SHOW_NAMES ? name : ''} ${config.SHOW_SCORES ? '[' + pScore + ']' : ''}`.trim();
            if (text) {
                ctx.font = isDanger ? "bold 13px Arial" : "bold 12px Arial";
                ctx.textAlign = 'center';
                ctx.fillStyle = isDanger ? config.FONT_DANGER : config.FONT;
                ctx.fillText(text, pX, pY - radius - 8);
            }

            if (isDanger) {
                const threatRadius = (p.width / 2) * config.EVADE_MULTIPLIER + config.EVADE_BUFFER;
                if (worldDist < threatRadius) {
                    dangerCount++;
                    const strength = 1 - (worldDist / threatRadius);
                    if (worldDist > 0) {
                        forceX += (dx / worldDist) * strength;
                        forceY += (dy / worldDist) * strength;
                    }
                }
            } else {
                if (worldDist < minTargetDist) {
                    minTargetDist = worldDist;
                    bestTarget = { x: pX, y: pY, pWidth: p.width, worldDist: worldDist }; 
                }
            }
        }

        if (config.SHOW_TRACER) {
            ctx.strokeStyle = config.TRACER; ctx.stroke(tracersNormal);
            ctx.strokeStyle = config.WARNING_TRACER; ctx.stroke(tracersDanger);
        }
        if (config.SHOW_CIRCLE) {
            ctx.fillStyle = config.CIRCLE_FILL; ctx.fill(circlesNormal);
            ctx.strokeStyle = config.CIRCLE_BORDER; ctx.stroke(circlesNormal);
            ctx.fillStyle = config.WARNING_FILL; ctx.fill(circlesDanger);
            ctx.strokeStyle = config.WARNING_BORDER; ctx.stroke(circlesDanger);
        }

        if (config.AUTO_EVADE && dangerCount > 0) {
            let escapeAngle = Math.atan2(forceY, forceX);
            if (forceX === 0 && forceY === 0) escapeAngle = Math.random() * Math.PI * 2; 

            const escapeX = viewX + Math.cos(escapeAngle) * 500;
            const escapeY = viewY + Math.sin(escapeAngle) * 500;

            state.gameCanvas.dispatchEvent(new MouseEvent('mousemove', {
                clientX: escapeX,
                clientY: escapeY,
                bubbles: true,
                cancelable: true
            }));

            ctx.beginPath();
            ctx.strokeStyle = config.EVADE_COLOR;
            ctx.lineWidth = 3;
            ctx.setLineDash([10, 5]); 
            ctx.moveTo(viewX, viewY);
            ctx.lineTo(escapeX, escapeY);
            ctx.stroke();
            ctx.setLineDash([]); 

            ctx.font = "bold 16px Arial";
            ctx.fillStyle = config.EVADE_COLOR;
            ctx.fillText(`⚠ EVADING ${dangerCount} THREATS ⚠`, viewX, viewY - 40);

        } else if (bestTarget) {
            // Kiểm tra xem địch đã lọt vào vùng vung kiếm chưa (Khoảng cách < Bán kính đánh + Nửa thân hình địch)
            const isInRange = bestTarget.worldDist < (selfAttackRadius + (bestTarget.pWidth / 2));
            
            // Vẽ hồng tâm
            ctx.beginPath();
            ctx.strokeStyle = isInRange ? config.IN_RANGE_COLOR : config.TARGET_COLOR;
            ctx.lineWidth = isInRange ? 4 : 2; // Làm đậm hồng tâm nếu vào tầm
            const size = isInRange ? 20 : 15;
            
            ctx.moveTo(bestTarget.x - size, bestTarget.y); ctx.lineTo(bestTarget.x + size, bestTarget.y);
            ctx.moveTo(bestTarget.x, bestTarget.y - size); ctx.lineTo(bestTarget.x, bestTarget.y + size);
            ctx.stroke();

            // Hiện chữ báo hiệu CHÉM
            if (isInRange) {
                ctx.font = "bold 16px Arial";
                ctx.fillStyle = config.IN_RANGE_COLOR;
                ctx.fillText("⚔️ CHÉM ⚔️", bestTarget.x, bestTarget.y - 30);
            }

            if (state.isAiming) {
                state.gameCanvas.dispatchEvent(new MouseEvent('mousemove', {
                    clientX: bestTarget.x,
                    clientY: bestTarget.y,
                    bubbles: true,
                    cancelable: true
                }));
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
                console.log("%c[EvoWars ESP] V9.0 STRIKE SIGNAL ACTIVE", "color: #00ff00; font-weight: bold;");
                setupDOM();
                mainLoop();
            }
        }
    }, 1000);
})();

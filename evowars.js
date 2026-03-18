// ==UserScript==
// @name         EvoWars.io ESP (CezDev - Pure ESP Vision v12.0)
// @version      12.0.0
// @description  Manual Combat, Visual Rings, Smart Tracers, No Auto-Interference
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
        FACING_SAFE_TRACER: "rgba(255, 255, 255, 1)", 
        FACING_DANGER_TRACER: "rgba(255, 0, 0, 1)",   
        
        ENEMY_RING_NORMAL: "rgba(255, 255, 255, 0.5)", 
        ENEMY_RING_DANGER: "rgba(255, 0, 0, 0.6)",     
        MY_RING_COLOR: "rgba(255, 165, 0, 0.6)",       

        TARGET_COLOR: "#00ff00", 
        IN_RANGE_COLOR: "#ff0000", 
        FONT: "#ffffff",
        FONT_DANGER: "#ff4444",
        FONT_WARNING: "#ff3333",
        
        SHOW_TRACER: true,
        SHOW_NAMES: true,
        SHOW_SCORES: true,
        SHOW_ATTACK_RING: true,          
        SHOW_FACING_WARNING: true,       
        FACING_CONE: Math.PI / 4,        
        
        // --- PHÍM TẮT ---
        TOGGLE_KEY: "v", // Bật/tắt giao diện ESP

        // --- CẤU HÌNH TẦM ĐÁNH (Chỉ dùng để hiển thị vòng) ---
        ATTACK_RANGE_MULTIPLIER: 2.0,    
        ATTACK_RANGE_BUFFER: 40,         
    };

    const state = {
        rt: null,
        pType: null,
        gameCanvas: null,
        nameIndex: 18, 
        scoreIndex: 27, 
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
            if (e.key.toLowerCase() === config.TOGGLE_KEY) state.isActive = !state.isActive;
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

            let isFacingMe = false;
            if (config.SHOW_FACING_WARNING) {
                const angleToMe = Math.atan2(self.y - p.y, self.x - p.x);
                let angleDiff = p.angle - angleToMe;
                angleDiff = Math.atan2(Math.sin(angleDiff), Math.cos(angleDiff));
                if (Math.abs(angleDiff) < config.FACING_CONE) isFacingMe = true;
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
                ctx.beginPath();
                ctx.moveTo(viewX, viewY);
                ctx.lineTo(pX, pY);
                
                if (isFacingMe) {
                    ctx.lineWidth = 3; 
                    ctx.strokeStyle = isDanger ? config.FACING_DANGER_TRACER : config.FACING_SAFE_TRACER;
                } else {
                    ctx.lineWidth = 1; 
                    ctx.strokeStyle = isDanger ? config.WARNING_TRACER : config.TRACER;
                }
                ctx.stroke();
            }
            
            ctx.shadowColor = "black";
            ctx.shadowBlur = 3;
            ctx.textAlign = 'center';

            if (isFacingMe) {
                ctx.font = "900 15px Arial"; 
                ctx.fillStyle = isDanger ? config.FONT_WARNING : "#ffffff";
                ctx.fillText("⚠️ ĐANG NGẮM ⚠️", pX, pY - (enemyAttackRadius * scale) - 25);
            }

            const name = p.instance_vars[state.nameIndex] || ''; 
            let text = `${config.SHOW_NAMES ? name : ''} ${config.SHOW_SCORES ? '[' + pScore + ']' : ''}`.trim();
            if (text) {
                ctx.font = isDanger ? "bold 13px Arial" : "bold 12px Arial";
                ctx.fillStyle = isDanger ? config.FONT_DANGER : config.FONT;
                ctx.fillText(text, pX, pY - (enemyAttackRadius * scale) - 8);
            }

            ctx.shadowBlur = 0; 

            if (worldDist < minTargetDist) {
                minTargetDist = worldDist;
                bestTarget = { 
                    x: pX, y: pY, worldDist: worldDist, 
                    attackRadius: enemyAttackRadius, pScore: pScore 
                }; 
            }
        }

        // CHỈ HIỂN THỊ CẢNH BÁO TẦM ĐÁNH (KHÔNG CAN THIỆP CHUỘT)
        if (bestTarget) {
            const triggerDistance = (selfAttackRadius + bestTarget.attackRadius);
            const isInRange = bestTarget.worldDist <= triggerDistance;
            const isDangerTarget = bestTarget.pScore > selfScore; 
            
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
                ctx.shadowColor = "black"; ctx.shadowBlur = 4;
                
                if (isDangerTarget) {
                    ctx.fillText("❌ RÚT LUI ❌", bestTarget.x, bestTarget.y - 30);
                } else {
                    ctx.fillText("⚠️ TRONG TẦM ĐÁNH ⚠️", bestTarget.x, bestTarget.y - 30);
                }
                ctx.shadowBlur = 0;
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
                console.log("%c[EvoWars ESP] V12.0 PURE ESP ACTIVE", "color: #00ff00; font-weight: bold;");
                setupDOM();
                mainLoop();
            }
        }
    }, 1000);
})();

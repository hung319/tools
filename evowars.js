// ==UserScript==
// @name         EvoWars.io ESP (CezDev Vector Evade & Aim)
// @version      6.0.0
// @description  Advanced ESP, Repulsion Vector Evade, Magnetic Aim
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
        
        TARGET_COLOR: "#00ff00", 
        EVADE_COLOR: "#ff00ff",  
        FONT: "#ffffff",
        FONT_DANGER: "#ff4444",
        
        // --- TÍNH NĂNG & PHÍM TẮT ---
        SHOW_CIRCLE: true,
        SHOW_TRACER: true,
        SHOW_NAMES: true,
        SHOW_SCORES: true,
        
        AIM_KEY: "Shift",        
        TOGGLE_KEY: "v",         
        
        // --- CẤU HÌNH AUTO EVADE (MỚI) ---
        AUTO_EVADE: true,        
        EVADE_MULTIPLIER: 1.5,   // Nhân số theo thân hình địch
        EVADE_BUFFER: 400,       // Khoảng bù trừ (Chống lại tầm chém của vũ khí dài)
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
            if (e.key === config.AIM_KEY) state.isAiming = true;
            if (e.key.toLowerCase() === config.TOGGLE_KEY) state.isActive = !state.isActive;
        });
        
        window.addEventListener('keyup', (e) => {
            if (e.key === config.AIM_KEY) state.isAiming = false;
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
        
        // Biến phục vụ Thuật toán Repulsion (Tổng hợp lực đẩy)
        let forceX = 0;
        let forceY = 0;
        let dangerCount = 0;

        for (const p of state.pType.instances) {
            if (p.uid === self.uid) continue;
            
            const pScore = Math.floor(p.instance_vars[state.scoreIndex] || 0);
            const isDanger = pScore > selfScore; 
            
            // Tính khoảng cách World thực tế (Chuẩn xác hơn Screen)
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

            // --- THUẬT TOÁN LỰC ĐẨY (AUTO EVADE) ---
            if (isDanger) {
                // Vùng nguy hiểm = Bán kính thân hình địch + Khoảng bù trừ lưỡi kiếm
                const threatRadius = (p.width / 2) * config.EVADE_MULTIPLIER + config.EVADE_BUFFER;
                
                if (worldDist < threatRadius) {
                    dangerCount++;
                    // Lực đẩy mạnh hơn nếu địch ở gần, yếu hơn nếu địch ở rìa vùng nguy hiểm
                    const strength = 1 - (worldDist / threatRadius);
                    
                    if (worldDist > 0) {
                        forceX += (dx / worldDist) * strength;
                        forceY += (dy / worldDist) * strength;
                    }
                }
            } else {
                // --- THUẬT TOÁN TÌM CON MỒI (AIM ASSIST) ---
                if (worldDist < minTargetDist) {
                    minTargetDist = worldDist;
                    bestTarget = { x: pX, y: pY }; 
                }
            }
        }

        // Render Đồ họa
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

        // --- XỬ LÝ ĐIỀU KHIỂN CHUỘT ---
        if (config.AUTO_EVADE && dangerCount > 0) {
            // TÍNH TOÁN GÓC CHẠY TRỐN TỔNG HỢP (Chạy khỏi tất cả mục tiêu cùng lúc)
            let escapeAngle = Math.atan2(forceY, forceX);
            // Fallback nếu đang ở chính giữa 2 lực cân bằng tuyệt đối
            if (forceX === 0 && forceY === 0) escapeAngle = Math.random() * Math.PI * 2; 

            // Phóng con trỏ chuột ra xa 500 pixel để game nhận diện đây là lệnh "chạy max tốc độ"
            const escapeX = viewX + Math.cos(escapeAngle) * 500;
            const escapeY = viewY + Math.sin(escapeAngle) * 500;

            state.gameCanvas.dispatchEvent(new MouseEvent('mousemove', {
                clientX: escapeX,
                clientY: escapeY,
                bubbles: true,
                cancelable: true
            }));

            // Vẽ chỉ báo đường thoát màu tím
            ctx.beginPath();
            ctx.strokeStyle = config.EVADE_COLOR;
            ctx.lineWidth = 3;
            ctx.setLineDash([10, 5]); // Kẻ đứt nét cho đường chạy trốn
            ctx.moveTo(viewX, viewY);
            ctx.lineTo(escapeX, escapeY);
            ctx.stroke();
            ctx.setLineDash([]); // Reset nét vẽ

            ctx.font = "bold 16px Arial";
            ctx.fillStyle = config.EVADE_COLOR;
            ctx.fillText(`⚠ EVADING ${dangerCount} THREATS ⚠`, viewX, viewY - 40);

        } else if (bestTarget) {
            // Vẽ hồng tâm nhắm bắn
            ctx.beginPath();
            ctx.strokeStyle = config.TARGET_COLOR;
            ctx.lineWidth = 2;
            const size = 15;
            ctx.moveTo(bestTarget.x - size, bestTarget.y); ctx.lineTo(bestTarget.x + size, bestTarget.y);
            ctx.moveTo(bestTarget.x, bestTarget.y - size); ctx.lineTo(bestTarget.x, bestTarget.y + size);
            ctx.stroke();

            // Chỉ override chuột ngắm bắn khi GIỮ phím Shift (tránh giật chuột khi đang đi dạo)
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
                console.log("%c[EvoWars ESP] VECTOR EVADE & AIM ACTIVE", "color: #00ff00; font-weight: bold;");
                setupDOM();
                mainLoop();
            }
        }
    }, 1000);
})();

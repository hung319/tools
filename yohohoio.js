// ==UserScript==
// @name         YoHoHo.io Precision Hybrid (CezDev)
// @namespace    http://tampermonkey.net/
// @version      1.8
// @description  Sửa lỗi double click, gồng lại ngay lập tức sau khi thả chuột.
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = {
        autoCharge: true,
        spamEnabled: true
    };

    let isUserHolding = false;
    let chargeTimer = null;

    // --- 1. UI Quản lý ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed', top: '15px', left: '15px', padding: '12px',
        backgroundColor: 'rgba(10, 10, 10, 0.9)', color: '#00ff00',
        fontFamily: 'monospace', zIndex: '10000', borderRadius: '6px',
        border: '1px solid #00ff00', pointerEvents: 'none', fontSize: '12px'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        ui.innerHTML = `
            <b style="color:#fbff00">CEZDEV PRO V1.8</b><br>
            [T] CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}<br>
            [G] SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}
        `;
        ui.style.borderColor = config.autoCharge ? '#00ff00' : '#ff4444';
    };
    updateUI();

    // --- 2. Logic Events ---
    const canvas = document.querySelector('canvas') || document.body;
    const sendEvent = (type) => {
        canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, button: 0 }));
    };

    // Vòng lặp xử lý chính (Interval)
    setInterval(() => {
        if (!config.autoCharge && !config.spamEnabled) return;

        if (isUserHolding && config.spamEnabled) {
            // Chế độ SPAM
            sendEvent('mouseup');
            setTimeout(() => { if(isUserHolding) sendEvent('mousedown'); }, 5);
        } else if (config.autoCharge && !isUserHolding) {
            // Chế độ GỒNG (Chỉ chạy khi người dùng KHÔNG chạm vào chuột)
            sendEvent('mousedown');
        }
    }, 50);

    // --- 3. Listeners ---
    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            // Ngắt gồng ngay lập tức để thực hiện đòn đánh hoặc bắt đầu spam
            sendEvent('mouseup'); 
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            // Đảm bảo sau khi nhả chuột, script "ép" lệnh gồng lại ngay lập tức (không đợi interval)
            if (config.autoCharge) {
                setTimeout(() => {
                    if (!isUserHolding) sendEvent('mousedown');
                }, 10); 
            }
        }
    }, true);

    window.addEventListener('keydown', (e) => {
        const key = e.key.toLowerCase();
        if (key === 't') { config.autoCharge = !config.autoCharge; if(!config.autoCharge) sendEvent('mouseup'); updateUI(); }
        if (key === 'g') { config.spamEnabled = !config.spamEnabled; updateUI(); }
    });

    console.log("CezDev: Precision Hybrid v1.8 Loaded.");
})();

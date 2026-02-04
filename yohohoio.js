// ==UserScript==
// @name         CEZ COMBAT PRO
// @namespace    http://tampermonkey.net/
// @version      2.5
// @description  Hệ thống hỗ trợ chiến đấu YoHoHo: Auto-Charge & Turbo-Spam.
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = { autoCharge: true, turboSpam: true };
    let isUserHolding = false;
    let lastAction = 0;

    // --- 1. UI: CEZ COMBAT PRO (Góc dưới trái) ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed', bottom: '20px', left: '20px', padding: '12px',
        backgroundColor: 'rgba(15, 15, 15, 0.9)', color: '#00ff00',
        fontFamily: 'Segoe UI, Tahoma, sans-serif', zIndex: '10000', borderRadius: '8px',
        border: '2px solid #00ff00', pointerEvents: 'none', fontSize: '12px',
        boxShadow: '0 0 15px rgba(0, 255, 0, 0.2)', letterSpacing: '0.5px'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        ui.innerHTML = `
            <div style="font-weight: bold; color: #fbff00; border-bottom: 1px solid #444; margin-bottom: 6px; padding-bottom: 4px;">CEZ COMBAT PRO</div>
            <div style="display: flex; justify-content: space-between; gap: 15px;">
                <span>[T] AUTO-CHARGE:</span> 
                <span style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">${config.autoCharge ? 'ON' : 'OFF'}</span>
            </div>
            <div style="display: flex; justify-content: space-between; gap: 15px;">
                <span>[G] TURBO-SPAM:</span> 
                <span style="color: ${config.turboSpam ? '#00ffff' : '#ff4444'}">${config.turboSpam ? 'ON' : 'OFF'}</span>
            </div>
        `;
    };
    updateUI();

    // --- 2. Core Logic ---
    const canvas = document.querySelector('canvas') || document.body;
    const send = (type) => canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, button: 0 }));

    // Vòng lặp đồng bộ hiệu năng cao (45ms)
    setInterval(() => {
        const now = Date.now();

        if (isUserHolding && config.turboSpam) {
            // Chế độ Turbo Spam: Nhịp độ cao, ổn định lực chém
            send('mouseup');
            send('mousedown');
        } else if (config.autoCharge && !isUserHolding) {
            // Chế độ Auto-Charge: Chỉ kích hoạt sau 180ms để tránh Double Click
            if (now - lastAction > 180) {
                send('mousedown');
            }
        }
    }, 45);

    // --- 3. Event Listeners ---
    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            lastAction = Date.now();
            send('mouseup'); // Nhả phát gồng cũ để bung đòn hoặc bắt đầu spam
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            lastAction = Date.now();
        }
    }, true);

    window.addEventListener('keydown', (e) => {
        const key = e.key.toLowerCase();
        if (key === 't') {
            config.autoCharge = !config.autoCharge;
            if (!config.autoCharge) send('mouseup');
            updateUI();
        }
        if (key === 'g') {
            config.turboSpam = !config.turboSpam;
            updateUI();
        }
    });

    // Khởi động trễ khi load web để game ổn định
    setTimeout(() => { if (config.autoCharge) send('mousedown'); }, 2500);

})();

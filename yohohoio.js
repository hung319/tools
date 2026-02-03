// ==UserScript==
// @name         YoHoHo.io Infinite Hold (CezDev)
// @namespace    http://tampermonkey.net/
// @version      2.1
// @description  Giữ nguyên Zero-Conflict, tăng cường khả năng tự động Hold liên tục.
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = { autoCharge: true, spamEnabled: true };
    let isUserHolding = false;
    let isLocked = false; 
    let spamInterval = null;

    // --- 1. UI (Góc dưới trái) ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed', bottom: '20px', left: '20px', padding: '12px',
        backgroundColor: 'rgba(0, 0, 0, 0.9)', color: '#00ff00',
        fontFamily: 'Consolas, monospace', zIndex: '10000', borderRadius: '8px',
        border: '1px solid #00ff00', pointerEvents: 'none', fontSize: '13px'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        ui.innerHTML = `
            <b style="color:#fbff00">CEZDEV INFINITE HOLD</b><br>
            <span style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">[T] AUTO-CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}</span><br>
            <span style="color: ${config.spamEnabled ? '#00ffff' : '#ff4444'}">[G] HOLD-TO-SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}</span>
        `;
    };
    updateUI();

    // --- 2. Core Actions ---
    const canvas = document.querySelector('canvas') || document.body;
    const send = (type) => {
        canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, button: 0 }));
    };

    // Vòng lặp Watchdog (0.5s một lần) - Đảm bảo nhân vật luôn gồng
    setInterval(() => {
        if (config.autoCharge && !isUserHolding && !isLocked) {
            send('mousedown');
        }
    }, 500);

    const startSpam = () => {
        if (spamInterval) return;
        spamInterval = setInterval(() => {
            if (isUserHolding && config.spamEnabled) {
                send('mouseup');
                setTimeout(() => { if (isUserHolding) send('mousedown'); }, 10);
            }
        }, 60);
    };

    const stopSpam = () => {
        clearInterval(spamInterval);
        spamInterval = null;
    };

    // --- 3. Event Listeners ---
    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            isLocked = true; // Khóa ngay khi người dùng chạm vào
            if (config.spamEnabled) startSpam();
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            stopSpam();
            
            // Chống double click: Khóa trong 200ms
            setTimeout(() => {
                isLocked = false;
                if (config.autoCharge && !isUserHolding) {
                    send('mousedown');
                }
            }, 200); 
        }
    }, true);

    window.addEventListener('keydown', (e) => {
        const key = e.key.toLowerCase();
        if (key === 't') {
            config.autoCharge = !config.autoCharge;
            config.autoCharge ? send('mousedown') : send('mouseup');
            updateUI();
        }
        if (key === 'g') {
            config.spamEnabled = !config.spamEnabled;
            updateUI();
        }
    });

    setTimeout(() => { if (config.autoCharge) send('mousedown'); }, 2000);
})();

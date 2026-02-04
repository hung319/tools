// ==UserScript==
// @name         YoHoHo.io Turbo Double-Spam (CezDev)
// @namespace    http://tampermonkey.net/
// @version      2.3
// @description  Tính năng Double-Click trong lúc Spam. T: Auto-Charge | G: Hold-to-Spam.
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
            <b style="color:#fbff00">CEZDEV TURBO V2.3</b><br>
            <span style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">[T] AUTO-CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}</span><br>
            <span style="color: ${config.spamEnabled ? '#00ffff' : '#ff4444'}">[G] DOUBLE-SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}</span>
        `;
    };
    updateUI();

    // --- 2. Core Actions ---
    const send = (type) => {
        const canvas = document.querySelector('canvas') || document.body;
        canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, button: 0 }));
    };

    // Vòng lặp Spam với kỹ thuật Double-Click
    const startSpam = () => {
        if (spamInterval) return;
        spamInterval = setInterval(() => {
            if (isUserHolding && config.spamEnabled) {
                // Nhát chém 1
                send('mouseup');
                setTimeout(() => { 
                    if (isUserHolding) {
                        send('mousedown');
                        // Nhát chém 2 (Double click ngay lập tức)
                        setTimeout(() => {
                            if (isUserHolding) {
                                send('mouseup');
                                setTimeout(() => { if (isUserHolding) send('mousedown'); }, 5);
                            }
                        }, 10); 
                    }
                }, 5);
            }
        }, 70); // Tăng nhịp gốc lên 70ms để tránh lag do Double-Click quá nhanh
    };

    const stopSpam = () => {
        clearInterval(spamInterval);
        spamInterval = null;
    };

    // --- 3. Event Listeners ---
    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            isLocked = true;
            if (config.spamEnabled) {
                send('mouseup'); // Nhả phát gồng để bắt đầu chuỗi Turbo
                startSpam();
            }
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            stopSpam();
            setTimeout(() => {
                isLocked = false;
                if (config.autoCharge && !isUserHolding) send('mousedown');
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

    // Watchdog duy trì gồng (Fix lỗi web không ổn định)
    setInterval(() => {
        if (config.autoCharge && !isUserHolding && !isLocked) {
            send('mousedown');
        }
    }, 500);

    // Khởi động
    setTimeout(() => { if (config.autoCharge) send('mousedown'); }, 2000);

})();

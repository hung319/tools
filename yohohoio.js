// ==UserScript==
// @name         YoHoHo.io Zero-Conflict (CezDev)
// @namespace    http://tampermonkey.net/
// @version      2.0
// @description  Loại bỏ hoàn toàn double click bằng cách ngừng can thiệp khi người dùng thao tác.
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = { autoCharge: true, spamEnabled: true };
    let isUserHolding = false;
    let spamInterval = null;
    let globalLock = false; // Khóa toàn bộ script

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
            <b style="color:#fbff00">CEZDEV ZERO-CONFLICT</b><br>
            <span style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">[T] AUTO-CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}</span><br>
            <span style="color: ${config.spamEnabled ? '#00ffff' : '#ff4444'}">[G] HOLD-TO-SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}</span>
        `;
    };
    updateUI();

    // --- 2. Core Actions ---
    const canvas = document.querySelector('canvas') || document.body;
    const send = (type) => {
        if (!globalLock || type === 'mouseup') { // Cho phép nhả chuột ngay cả khi lock
            canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, button: 0 }));
        }
    };

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
            globalLock = true; // NGỪNG TOÀN BỘ AUTO KHI NGƯỜI DÙNG NHẤN CHUỘT
            
            if (config.spamEnabled) {
                startSpam();
            }
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            stopSpam();
            
            // SAU KHI THẢ CHUỘT: Đợi game xử lý xong đòn đánh thật (250ms)
            // Trong 250ms này, script không được phép tự ý nhấn mousedown (chống double click)
            setTimeout(() => {
                globalLock = false; 
                if (config.autoCharge && !isUserHolding) {
                    send('mousedown');
                }
            }, 250); 
        }
    }, true);

    // Watchdog cực chậm để đảm bảo luôn gồng khi không chơi
    setInterval(() => {
        if (config.autoCharge && !isUserHolding && !globalLock) {
            send('mousedown');
        }
    }, 2000);

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

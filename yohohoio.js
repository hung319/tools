// ==UserScript==
// @name         YoHoHo.io Combat Master (Auto-Charge & Spam)
// @namespace    http://tampermonkey.net/
// @version      1.3
// @description  T để Bật/Tắt. Giữ chuột để Spam chém, thả ra tự động Tích lực.
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let isEnabled = true;
    let isUserHolding = false; 
    let mainLoop = null;

    // --- 1. UI Indicator ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed', top: '10px', left: '10px', padding: '10px',
        backgroundColor: 'rgba(0, 0, 0, 0.8)', color: '#00ff00',
        fontFamily: 'monospace', zIndex: '10000', borderRadius: '5px',
        border: '1px solid #00ff00', pointerEvents: 'none'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        ui.innerText = `[CezDev] STATUS: ${isEnabled ? 'ACTIVE' : 'OFF'} | KEY: T`;
        ui.style.color = isEnabled ? '#00ff00' : '#ff4444';
        ui.style.borderColor = isEnabled ? '#00ff00' : '#ff4444';
    };
    updateUI();

    // --- 2. Core Logic ---
    const sendEvent = (type) => {
        const target = document.querySelector('canvas') || document.body;
        target.dispatchEvent(new MouseEvent(type, { bubbles: true, button: 0 }));
    };

    const runCombatLogic = () => {
        if (!isEnabled) return;

        if (isUserHolding) {
            // Chế độ SPAM: Click liên tục khi người dùng giữ chuột
            sendEvent('mouseup');
            setTimeout(() => sendEvent('mousedown'), 10);
        } else {
            // Chế độ IDLE: Luôn giữ tích lực
            sendEvent('mousedown');
        }
    };

    // Vòng lặp chính (Interval nhanh để spam mượt)
    mainLoop = setInterval(runCombatLogic, 60);

    // --- 3. Listeners ---
    window.addEventListener('keydown', (e) => {
        if (e.key.toLowerCase() === 't') {
            isEnabled = !isEnabled;
            if (!isEnabled) sendEvent('mouseup');
            updateUI();
        }
    });

    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            // Ép game nhả tích lực cũ để bắt đầu chu kỳ spam/đánh đòn mạnh
            sendEvent('mouseup'); 
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
        }
    }, true);

    console.log("CezDev: Combat Master v1.3 loaded.");
})();

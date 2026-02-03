// ==UserScript==
// @name         YoHoHo.io Perfect Logic (Bottom-Left UI)
// @namespace    http://tampermonkey.net/
// @version      1.9.1
// @description  Chuyển Menu xuống góc dưới bên trái. T: Auto-Charge | G: Hold-to-Spam.
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = { autoCharge: true, spamEnabled: true };
    let isUserHolding = false;
    let spamInterval = null;

    // --- 1. UI - Đã chuyển xuống Bottom-Left ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed',
        bottom: '20px', // Cách đáy 20px
        left: '20px',   // Cách lề trái 20px
        padding: '12px',
        backgroundColor: 'rgba(0, 0, 0, 0.85)',
        color: '#00ff00',
        fontFamily: 'Consolas, monospace',
        zIndex: '10000',
        borderRadius: '8px',
        border: '1px solid #00ff00',
        pointerEvents: 'none',
        boxShadow: '0 0 10px rgba(0, 255, 0, 0.3)',
        fontSize: '13px',
        lineHeight: '1.6'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        ui.innerHTML = `
            <b style="color:#fbff00; font-size: 14px;">CEZDEV COMMANDER</b><br>
            <span style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">[T] AUTO-CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}</span><br>
            <span style="color: ${config.spamEnabled ? '#00ffff' : '#ff4444'}">[G] HOLD-TO-SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}</span>
        `;
        ui.style.borderColor = config.autoCharge ? '#00ff00' : '#ff4444';
    };
    updateUI();

    // --- 2. Core Actions ---
    const canvas = document.querySelector('canvas') || document.body;
    const send = (type) => canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, button: 0 }));

    const startSpam = () => {
        if (spamInterval) return;
        spamInterval = setInterval(() => {
            if (isUserHolding && config.spamEnabled) {
                send('mouseup');
                setTimeout(() => { if (isUserHolding) send('mousedown'); }, 5);
            }
        }, 50);
    };

    const stopSpam = () => {
        clearInterval(spamInterval);
        spamInterval = null;
    };

    // --- 3. Event Listeners ---
    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            if (config.spamEnabled) startSpam();
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            stopSpam();
            
            if (config.autoCharge) {
                setTimeout(() => {
                    if (!isUserHolding) send('mousedown');
                }, 30);
            }
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

    // Khởi tạo trạng thái ban đầu
    setTimeout(() => { if (config.autoCharge) send('mousedown'); }, 2000);

})();

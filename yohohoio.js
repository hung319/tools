// ==UserScript==
// @name         YoHoHo.io Dual Control (CezDev)
// @namespace    http://tampermonkey.net/
// @version      1.7
// @description  T: Toggle Auto-Charge | G: Toggle Hold-to-Spam Click
// @author       CezDev
// @match        https://yohoho.io/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = {
        autoCharge: true,  // Tự động gồng (mặc định ON)
        spamEnabled: true, // Cho phép giữ chuột để spam (mặc định ON)
    };

    let isUserHolding = false;

    // --- 1. Giao diện quản lý ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed', top: '15px', left: '15px', padding: '12px',
        backgroundColor: 'rgba(15, 15, 15, 0.9)', color: '#fff',
        fontFamily: 'Consolas, monospace', zIndex: '10000', borderRadius: '6px',
        border: '1px solid #444', pointerEvents: 'none', minWidth: '180px'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        ui.innerHTML = `
            <div style="color:#00ff00; font-weight:bold; margin-bottom:5px;">CEZDEV CONTROL</div>
            <div style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">[T] AUTO-CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}</div>
            <div style="color: ${config.spamEnabled ? '#00ffff' : '#ff4444'}">[G] HOLD-TO-SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}</div>
            <div style="font-size:10px; margin-top:5px; color:#aaa;">Status: ${isUserHolding && config.spamEnabled ? 'SPAMMING' : 'IDLE'}</div>
        `;
    };
    updateUI();

    // --- 2. Logic điều khiển ---
    const canvas = document.querySelector('canvas') || document.body;
    const sendEvent = (type) => {
        canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, button: 0 }));
    };

    // Vòng lặp xử lý chính
    setInterval(() => {
        // Ưu tiên 1: Đang giữ chuột và đã bật tính năng Spam
        if (isUserHolding && config.spamEnabled) {
            sendEvent('mouseup');
            setTimeout(() => { if(isUserHolding) sendEvent('mousedown'); }, 10);
        } 
        // Ưu tiên 2: Không giữ chuột và đang bật Auto-Charge
        else if (config.autoCharge && !isUserHolding) {
            sendEvent('mousedown');
        }
    }, 45);

    // --- 3. Sự kiện Bàn phím & Chuột ---
    window.addEventListener('keydown', (e) => {
        const key = e.key.toLowerCase();
        if (key === 't') {
            config.autoCharge = !config.autoCharge;
            if (!config.autoCharge) sendEvent('mouseup');
            updateUI();
        }
        if (key === 'g') {
            config.spamEnabled = !config.spamEnabled;
            updateUI();
        }
    });

    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            // Nếu có bất kỳ chức năng nào bật, cần nhả mousedown ảo cũ ra để game nhận click mới
            if (config.autoCharge || config.spamEnabled) sendEvent('mouseup');
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            updateUI();
        }
    }, true);

    console.log("CezDev Dual Control v1.7: Ready.");
})();

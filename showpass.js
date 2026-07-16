// ==UserScript==
// @name         Universal - Compact Password Copy Button
// @namespace    http://tampermonkey.net/
// @version      4.0
// @description  Hiện nút copy siêu nhỏ gọn (chỉ chứa icon) cho mọi ô password trên tất cả trang web
// @author       Gemini
// @match        *://*/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function() {
    'use strict';

    function addCopyButtonToInput(input) {
        // Tránh xử lý trùng lặp
        if (input.dataset.universalCopyAdded === 'true') return;
        input.dataset.universalCopyAdded = 'true';

        // Thiết lập thuộc tính cha relative để định vị nút
        const parent = input.parentElement;
        if (parent) {
            parent.style.position = 'relative';
        }

        // Tạo nút Copy dạng Icon siêu nhỏ
        const copyBtn = document.createElement('button');
        copyBtn.innerText = '📋';
        copyBtn.type = 'button';
        copyBtn.title = 'Copy password'; // Hiện chữ gợi ý khi rê chuột vào
        
        // CSS rút gọn, biến nút thành một biểu tượng nhỏ tinh tế ở góc phải
        Object.assign(copyBtn.style, {
            position: 'absolute',
            right: '6px',
            top: '50%',
            transform: 'translateY(-50%)',
            zIndex: '9999',
            border: 'none',
            background: 'transparent',
            cursor: 'pointer',
            fontSize: '14px',
            padding: '2px',
            lineHeight: '1',
            opacity: '0.7',
            transition: 'opacity 0.2s, transform 0.1s'
        });

        // Hiệu ứng di chuột vào thì sáng lên
        copyBtn.addEventListener('mouseenter', () => copyBtn.style.opacity = '1');
        copyBtn.addEventListener('mouseleave', () => copyBtn.style.opacity = '0.7');

        // Sự kiện xử lý Copy
        copyBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const valueToCopy = input.value;
            if (!valueToCopy) return;

            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(valueToCopy).then(() => {
                    showSuccess(copyBtn);
                }).catch(() => {
                    fallbackCopy(input, copyBtn);
                });
            } else {
                fallbackCopy(input, copyBtn);
            }
        });

        // Chèn nút vào bên phải ô input
        input.after(copyBtn);

        // Chừa khoảng trống nhỏ bên phải ô để chữ không bị đè lên icon
        const currentPadding = parseInt(window.getComputedStyle(input).paddingRight) || 0;
        if (currentPadding < 30) {
            input.style.paddingRight = '30px';
        }
    }

    // Hiển thị trạng thái copy thành công bằng cách đổi icon
    function showSuccess(btn) {
        btn.innerText = '✅';
        btn.style.transform = 'translateY(-50%) scale(1.2)';
        setTimeout(() => {
            btn.innerText = '📋';
            btn.style.transform = 'translateY(-50%) scale(1)';
        }, 1500);
    }

    // Phương án dự phòng cho điện thoại / trình duyệt cũ
    function fallbackCopy(input, btn) {
        try {
            input.select();
            input.setSelectionRange(0, 99999);
            document.execCommand('copy');
            showSuccess(btn);
        } catch (err) {
            // Thất bại thầm lặng để không quấy rầy trải nghiệm người dùng
        }
    }

    // Quét tất cả các ô password
    function scanInputs() {
        const selector = 'input[type="password"], .PasswordInput-input-FEU3F, .TextInput-input-svfXu, .Input-input-KWeec';
        const inputs = document.querySelectorAll(selector);
        
        inputs.forEach(input => {
            addCopyButtonToInput(input);
        });
    }

    // Quét liên tục mỗi 0.5 giây để luôn hoạt động kể cả khi trang web tải động
    setInterval(scanInputs, 500);
})();

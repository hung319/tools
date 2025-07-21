// js/regex-tool.js

document.addEventListener('DOMContentLoaded', () => {
    // Phần tử của Tester
    const patternInput = document.getElementById('regex-pattern');
    const testStringTextarea = document.getElementById('test-string');
    const resultsDiv = document.getElementById('regex-results');
    const errorDiv = document.getElementById('regex-error');

    // Phần tử của Builder
    const presetSelector = document.getElementById('builder-preset');
    const generateBtn = document.getElementById('generate-regex-btn');

    const PRESET_PATTERNS = {
        email: '/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/g',
        url: '/https?:\\/\\/(?:www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b(?:[-a-zA-Z0-9()@:%_\\+.~#?&//=]*)/g',
        phone_vn: '/(0|\\+84|84)?(3[2-9]|5[689]|7[06-9]|8[1-689]|9[0-46-9])([0-9]{7})\\b/g',
        ipv4: '/((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/g'
    };

    const updateHighlighting = () => {
        const pattern = patternInput.value;
        const testString = testStringTextarea.value;

        resultsDiv.innerHTML = '';
        errorDiv.textContent = '';

        if (!pattern || !testString) {
            resultsDiv.textContent = testString;
            return;
        }

        let regex;
        try {
            const match = pattern.match(new RegExp('^/(.*?)/([gimyusv]*)$'));
            if (match) {
                regex = new RegExp(match[1], match[2] || '');
            } else {
                regex = new RegExp(pattern, 'g');
            }
        } catch (e) {
            errorDiv.textContent = e.message;
            resultsDiv.textContent = testString;
            return;
        }

        // Dùng textContent để chèn text gốc, tránh lỗi XSS
        resultsDiv.textContent = testString;
        // Sau đó mới dùng innerHTML để thay thế các match bằng thẻ span
        // Kỹ thuật này an toàn hơn là gán trực tiếp innerHTML từ chuỗi đầu vào
        const highlightedHTML = resultsDiv.innerHTML.replace(regex, (match) => `<span class="match">${match}</span>`);
        resultsDiv.innerHTML = highlightedHTML;
    };
    
    const generateRegex = () => {
        const selectedPreset = presetSelector.value;
        if (PRESET_PATTERNS[selectedPreset]) {
            patternInput.value = PRESET_PATTERNS[selectedPreset];
            // Kích hoạt việc cập nhật highlight ngay sau khi tạo regex
            updateHighlighting();
        }
    };

    // --- Gắn sự kiện ---
    patternInput.addEventListener('input', updateHighlighting);
    testStringTextarea.addEventListener('input', updateHighlighting);
    generateBtn.addEventListener('click', generateRegex);

    // Chạy lần đầu
    updateHighlighting();
});
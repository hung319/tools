// js/regex-tool.js

document.addEventListener('DOMContentLoaded', () => {
    // --- Các phần tử DOM ---
    const dataInput = document.getElementById('data-input');
    const analyzeBtn = document.getElementById('analyze-btn');
    const analyzeStatus = document.getElementById('analyze-status');
    const patternInput = document.getElementById('regex-pattern');
    const testStringTextarea = document.getElementById('test-string');
    const resultsDiv = document.getElementById('regex-results');
    const errorDiv = document.getElementById('regex-error');

    /**
     * THƯ VIỆN NHẬN DẠNG MẪU (ĐÃ NÂNG CẤP)
     * - testRegex: Dùng để kiểm tra nghiêm ngặt xem CẢ DÒNG có khớp không (độ chính xác cao).
     * - displayRegex: Regex được hiển thị cho người dùng, thường có cờ /g để tìm tất cả.
     */
    const PATTERN_LIBRARY = [
        { name: 'Email', testRegex: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/, displayRegex: '/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/g' },
        { name: 'URL (http/https)', testRegex: /^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/, displayRegex: '/https?:\\/\\/(?:www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b(?:[-a-zA-Z0-9()@:%_\\+.~#?&//=]*)/g' },
        { name: 'Số điện thoại VN', testRegex: /^(0|\+84|84)?(3[2-9]|5[689]|7[06-9]|8[1-689]|9[0-46-9])([0-9]{7})$/, displayRegex: '/(0|\\+84|84)?(3[2-9]|5[689]|7[06-9]|8[1-689]|9[0-46-9])([0-9]{7})\\b/g' },
        { name: 'Địa chỉ IPv4', testRegex: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/, displayRegex: '/((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/g' },
        { name: 'Chỉ gồm số', testRegex: /^[0-9]+$/, displayRegex: '/[0-9]+/g' },
        { name: 'Chỉ gồm chữ (không dấu)', testRegex: /^[a-zA-Z]+$/, displayRegex: '/[a-zA-Z]+/g' },
        { name: 'Chữ và số (không dấu)', testRegex: /^[a-zA-Z0-9]+$/, displayRegex: '/[a-zA-Z0-9]+/g' }
    ];

    const analyzeAndGenerateRegex = () => {
        const inputText = dataInput.value.trim();
        analyzeStatus.textContent = ''; // Xóa thông báo cũ
        if (!inputText) {
            analyzeStatus.textContent = 'Vui lòng nhập dữ liệu mẫu để phân tích.';
            analyzeStatus.style.color = 'var(--text-color)';
            return;
        }

        testStringTextarea.value = inputText;
        
        const lines = inputText.split('\n').map(line => line.trim()).filter(line => line !== '');
        if (lines.length === 0) {
            analyzeStatus.textContent = 'Dữ liệu mẫu rỗng.';
            analyzeStatus.style.color = 'var(--text-color)';
            return;
        }

        let bestMatch = { name: 'Không tìm thấy', score: 0, displayRegex: '' };

        PATTERN_LIBRARY.forEach(pattern => {
            let matches = 0;
            lines.forEach(line => {
                if (pattern.testRegex.test(line)) {
                    matches++;
                }
            });

            const score = matches / lines.length;
            if (score > bestMatch.score) {
                bestMatch = { name: pattern.name, score: score, displayRegex: pattern.displayRegex };
            }
        });

        if (bestMatch.score >= 0.8) { // Yêu cầu độ chính xác từ 80% trở lên
            patternInput.value = bestMatch.displayRegex;
            analyzeStatus.textContent = `✅ Đã nhận dạng mẫu: ${bestMatch.name} (Độ chính xác: ${Math.round(bestMatch.score * 100)}%)`;
            analyzeStatus.style.color = 'var(--success-color)';
        } else {
            patternInput.value = '';
            analyzeStatus.textContent = '❌ Không nhận dạng được mẫu chung. Hãy thử với dữ liệu rõ ràng và đồng nhất hơn.';
            analyzeStatus.style.color = 'var(--error-color)';
        }
        
        updateHighlighting();
    };

    const updateHighlighting = () => {
        const pattern = patternInput.value;
        const testString = testStringTextarea.value;

        resultsDiv.innerHTML = '';
        errorDiv.textContent = '';

        if (!testString) return;
        if (!pattern) {
            resultsDiv.textContent = testString;
            return;
        }

        let regex;
        try {
            const match = pattern.match(new RegExp('^/(.*?)/([gimyusv]*)$'));
            if (match) {
                // Đảm bảo cờ 'g' luôn có để tìm tất cả kết quả
                const flags = match[2] ? (match[2].includes('g') ? match[2] : match[2] + 'g') : 'g';
                regex = new RegExp(match[1], flags);
            } else {
                regex = new RegExp(pattern, 'g');
            }
        } catch (e) {
            errorDiv.textContent = e.message;
            resultsDiv.textContent = testString;
            return;
        }
        
        // Kỹ thuật highlight an toàn
        resultsDiv.textContent = testString;
        const highlightedHTML = resultsDiv.innerHTML.replace(regex, (match) => `<span class="match">${match}</span>`);
        resultsDiv.innerHTML = highlightedHTML;
    };
    
    // --- Gắn sự kiện ---
    analyzeBtn.addEventListener('click', analyzeAndGenerateRegex);
    patternInput.addEventListener('input', updateHighlighting);
    testStringTextarea.addEventListener('input', updateHighlighting);

    analyzeStatus.textContent = 'Sẵn sàng phân tích dữ liệu.';
    analyzeStatus.style.color = 'var(--text-color)';
});
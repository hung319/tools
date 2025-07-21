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

    // --- Thư viện các mẫu Regex phổ biến để nhận dạng ---
    const PATTERN_LIBRARY = [
        { name: 'Email', regex: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g },
        { name: 'URL (http/https)', regex: /https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*)/g },
        { name: 'Số điện thoại VN', regex: /(0|\+84|84)?(3[2-9]|5[689]|7[06-9]|8[1-689]|9[0-46-9])([0-9]{7})\b/g },
        { name: 'Địa chỉ IPv4', regex: /((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/g },
        { name: 'Chỉ gồm số', regex: /^[0-9]+$/g },
        { name: 'Chỉ gồm chữ', regex: /^[a-zA-Z]+$/g },
        { name: 'Chữ và số', regex: /^[a-zA-Z0-9]+$/g }
    ];

    /**
     * Phân tích dữ liệu đầu vào và tìm mẫu Regex phù hợp nhất
     */
    const analyzeAndGenerateRegex = () => {
        const inputText = dataInput.value.trim();
        if (!inputText) {
            analyzeStatus.textContent = 'Vui lòng nhập dữ liệu mẫu.';
            return;
        }

        // Tự động sao chép dữ liệu vào ô kiểm tra
        testStringTextarea.value = inputText;
        
        const lines = inputText.split('\n').filter(line => line.trim() !== '');
        if (lines.length === 0) {
            analyzeStatus.textContent = 'Dữ liệu mẫu rỗng.';
            return;
        }

        let bestMatch = { name: 'Không tìm thấy', score: 0, regex: null };

        PATTERN_LIBRARY.forEach(pattern => {
            let matches = 0;
            lines.forEach(line => {
                // Reset lại lastIndex của regex global
                pattern.regex.lastIndex = 0; 
                if (line.trim().match(pattern.regex)) {
                    matches++;
                }
            });

            const score = matches / lines.length;
            if (score > bestMatch.score) {
                bestMatch = { name: pattern.name, score: score, regex: pattern.regex };
            }
        });

        if (bestMatch.score > 0.8) { // Yêu cầu độ chính xác trên 80%
            patternInput.value = bestMatch.regex.toString();
            analyzeStatus.textContent = `✅ Đã nhận dạng mẫu: ${bestMatch.name}`;
            analyzeStatus.style.color = 'var(--success-color)';
        } else {
            patternInput.value = '';
            analyzeStatus.textContent = '❌ Không nhận dạng được mẫu chung. Hãy thử với dữ liệu rõ ràng hơn.';
            analyzeStatus.style.color = 'var(--error-color)';
        }
        
        // Cập nhật kết quả highlight
        updateHighlighting();
    };


    /**
     * Cập nhật phần highlight kết quả
     */
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
                regex = new RegExp(match[1], match[2] || 'g'); // Thêm 'g' mặc định nếu không có
            } else {
                regex = new RegExp(pattern, 'g');
            }
        } catch (e) {
            errorDiv.textContent = e.message;
            resultsDiv.textContent = testString;
            return;
        }
        
        const highlightedHTML = testString.replace(regex, (match) => `<span class="match">${match}</span>`);
        resultsDiv.innerHTML = highlightedHTML;
    };
    
    // --- Gắn sự kiện ---
    analyzeBtn.addEventListener('click', analyzeAndGenerateRegex);
    patternInput.addEventListener('input', updateHighlighting);
    testStringTextarea.addEventListener('input', updateHighlighting);

    // Xóa nội dung mặc định
    analyzeStatus.textContent = '';
});
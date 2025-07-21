// js/regex-tool.js

document.addEventListener('DOMContentLoaded', () => {
    const patternInput = document.getElementById('regex-pattern');
    const testStringTextarea = document.getElementById('test-string');
    const resultsDiv = document.getElementById('regex-results');
    const errorDiv = document.getElementById('regex-error');

    const updateHighlighting = () => {
        const pattern = patternInput.value;
        const testString = testStringTextarea.value;

        // Xóa kết quả và lỗi cũ
        resultsDiv.innerHTML = '';
        errorDiv.textContent = '';

        if (!pattern || !testString) {
            resultsDiv.textContent = testString; // Hiển thị lại text gốc nếu không có pattern
            return;
        }

        let regex;
        try {
            // Tách pattern và flags (ví dụ: /abc/gi)
            const match = pattern.match(new RegExp('^/(.*?)/([gimyusv]*)$'));
            if (match) {
                regex = new RegExp(match[1], match[2]);
            } else {
                // Nếu người dùng không nhập theo dạng /.../, coi như không có flag
                regex = new RegExp(pattern, 'g');
            }
        } catch (e) {
            errorDiv.textContent = e.message;
            resultsDiv.textContent = testString; // Hiển thị text gốc khi có lỗi
            return;
        }

        // Sử dụng replace với function để highlight mà không làm mất text gốc
        const highlightedHTML = testString.replace(regex, (match) => {
            // Tạo một thẻ span an toàn, tránh XSS
            const span = document.createElement('span');
            span.className = 'match';
            span.textContent = match;
            return span.outerHTML;
        });
        
        resultsDiv.innerHTML = highlightedHTML;
    };

    // Lắng nghe sự kiện input trên cả hai ô
    patternInput.addEventListener('input', updateHighlighting);
    testStringTextarea.addEventListener('input', updateHighlighting);

    // Chạy lần đầu để hiển thị text
    updateHighlighting();
});
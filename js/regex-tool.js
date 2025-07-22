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
                 // Đảm bảo cờ 'g' luôn có để tìm tất cả kết quả
                const flags = match[2] ? (match[2].includes('g') ? match[2] : match[2] + 'g') : 'g';
                regex = new RegExp(match[1], flags);
            } else {
                // Nếu người dùng không nhập theo dạng /.../, coi như không có flag và thêm 'g'
                regex = new RegExp(pattern, 'g');
            }
        } catch (e) {
            errorDiv.textContent = e.message;
            resultsDiv.textContent = testString; // Hiển thị text gốc khi có lỗi
            return;
        }
        
        // Kỹ thuật highlight an toàn
        resultsDiv.textContent = testString;
        const highlightedHTML = resultsDiv.innerHTML.replace(regex, (match) => `<span class="match">${match}</span>`);
        resultsDiv.innerHTML = highlightedHTML;
    };

    // Lắng nghe sự kiện input trên cả hai ô để cập nhật real-time
    patternInput.addEventListener('input', updateHighlighting);
    testStringTextarea.addEventListener('input', updateHighlighting);

    // Chạy lần đầu để hiển thị text
    updateHighlighting();
});
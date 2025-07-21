// js/rdusername.js

document.addEventListener('DOMContentLoaded', () => {
    // --- Lấy các phần tử DOM ---
    const generateBtn = document.getElementById('generate-btn');
    const usernameDisplay = document.getElementById('username-display');
    const copyMessage = document.getElementById('copy-message');

    // --- Hằng số để tạo tên ---
    const consonants = 'bcdfghjklmnpqrstvwxyz';
    const vowels = 'aeiou';

    /**
     * Cải tiến logic:
     * - Tạo username dễ đọc hơn bằng cách xen kẽ phụ âm và nguyên âm.
     * - Đảm bảo tính ngẫu nhiên về việc bắt đầu bằng nguyên âm hay phụ âm.
     */
    const generateUsername = () => {
        let username = '';
        // Ngẫu nhiên quyết định ký tự đầu tiên là nguyên âm hay phụ âm
        let isNextVowel = Math.random() > 0.5;

        for (let i = 0; i < 8; i++) {
            if (isNextVowel) {
                username += vowels[Math.floor(Math.random() * vowels.length)];
            } else {
                username += consonants[Math.floor(Math.random() * consonants.length)];
            }
            isNextVowel = !isNextVowel; // Luân phiên
        }

        usernameDisplay.innerText = username;
        copyMessage.style.display = 'none'; // Ẩn thông báo khi tạo tên mới
    };

    /**
     * Cải tiến logic sao chép:
     * - Sử dụng API Clipboard hiện đại (navigator.clipboard.writeText).
     * - Cung cấp phản hồi trực quan cho người dùng.
     */
    const copyToClipboard = async () => {
        const username = usernameDisplay.innerText;
        if (!username || username === "Bấm nút để tạo") return;

        try {
            await navigator.clipboard.writeText(username);
            // Hiển thị thông báo thành công
            copyMessage.style.display = 'block';
            setTimeout(() => {
                copyMessage.style.display = 'none';
            }, 2000);
        } catch (err) {
            console.error('Không thể sao chép: ', err);
            // Có thể thêm thông báo lỗi cho người dùng ở đây
            copyMessage.innerText = "Lỗi khi sao chép!";
            copyMessage.style.color = "#ff5252"; // Màu đỏ
            copyMessage.style.display = 'block';
            setTimeout(() => {
                copyMessage.style.display = 'none';
                copyMessage.innerText = "Đã sao chép vào clipboard!"; // Reset lại
                copyMessage.style.color = "var(--success-color)";
            }, 2000);
        }
    };

    // --- Gắn sự kiện ---
    generateBtn.addEventListener('click', generateUsername);
    usernameDisplay.addEventListener('click', copyToClipboard);

    // --- Chạy lần đầu khi tải trang ---
    generateUsername();
});
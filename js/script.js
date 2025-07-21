document.addEventListener('DOMContentLoaded', () => {
    // Lấy các phần tử cần thiết từ DOM
    const hamburgerBtn = document.getElementById('hamburger-btn');
    const navMenu = document.getElementById('nav-menu');

    // Kiểm tra xem các phần tử có tồn tại không
    if (hamburgerBtn && navMenu) {
        // Thêm sự kiện 'click' cho nút hamburger
        hamburgerBtn.addEventListener('click', () => {
            // Thêm/xóa lớp 'show' trên menu để hiện/ẩn nó
            navMenu.classList.toggle('show');
        });
    }
});
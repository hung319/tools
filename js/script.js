document.addEventListener('DOMContentLoaded', () => {
    const hamburgerBtn = document.getElementById('hamburger-btn');
    const navMenu = document.getElementById('nav-menu');

    if (hamburgerBtn && navMenu) {
        hamburgerBtn.addEventListener('click', () => {
            // Toggle lớp 'show' để hiện/ẩn menu
            navMenu.classList.toggle('show');
            
            // Toggle lớp 'active' để tạo hiệu ứng X cho nút
            hamburgerBtn.classList.toggle('active');
        });
    }
});
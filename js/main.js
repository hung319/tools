// js/main.js

function initializeMenu() {
    const menuBtn = document.getElementById('menu-btn');
    const navMenu = document.getElementById('nav-menu');

    // Nếu không tìm thấy các element thì không làm gì cả
    if (!menuBtn || !navMenu) {
        console.error("Menu button or navigation panel not found!");
        return;
    }

    menuBtn.addEventListener('click', () => {
        menuBtn.classList.toggle('active');
        navMenu.classList.toggle('active');
    });
}

// Chờ cho component được chèn vào rồi mới chạy logic
// Sử dụng setTimeout nhỏ để đảm bảo DOM đã cập nhật
document.addEventListener('DOMContentLoaded', () => {
    // Đảm bảo hàm này chạy sau khi component đã được attach
    setTimeout(initializeMenu, 0); 
});
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
document.addEventListener('DOMContentLoaded', () => {
    // Initialize menu after a slight delay to ensure components are loaded
    initializeMenu();
});
// js/main.js

function initializeMenu() {
    const menuBtn = document.getElementById('menu-btn');
    const navMenu = document.getElementById('nav-menu');

    if (!menuBtn || !navMenu) {
        return;
    }

    menuBtn.addEventListener('click', () => {
        menuBtn.classList.toggle('active');
        navMenu.classList.toggle('active');
    });

    navMenu.addEventListener('click', (e) => {
        if (e.target === navMenu || e.target.closest('a')) {
            menuBtn.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && navMenu.classList.contains('active')) {
            menuBtn.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });
}

document.addEventListener('DOMContentLoaded', () => {
    initializeMenu();
});
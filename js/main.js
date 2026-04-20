// js/main.js

function initializeMenu() {
    const menuBtn = document.getElementById('menu-btn');
    const navMenu = document.getElementById('nav-menu');

    if (!menuBtn || !navMenu) {
        return;
    }

    const toggleScroll = (disable) => {
        document.body.style.overflow = disable ? 'hidden' : '';
        document.body.style.position = disable ? 'fixed' : '';
        document.body.style.width = disable ? '100%' : '';
    };

    menuBtn.addEventListener('click', () => {
        const isOpening = !menuBtn.classList.contains('active');
        menuBtn.classList.toggle('active');
        navMenu.classList.toggle('active');
        toggleScroll(isOpening);
    });

    navMenu.addEventListener('click', (e) => {
        if (e.target === navMenu || e.target.tagName === 'A') {
            menuBtn.classList.remove('active');
            navMenu.classList.remove('active');
            toggleScroll(false);
        }
    });
}

document.addEventListener('DOMContentLoaded', () => {
    initializeMenu();
});
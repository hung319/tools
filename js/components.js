// js/components.js

class SharedUI {
    constructor() {
        this.headerHTML = `
            <header class="shared-header">
                <button id="menu-btn" class="hamburger-menu" aria-label="Mở menu">
                    <div class="hamburger-box"><div class="hamburger-inner"></div></div>
                </button>
                <nav id="nav-menu" class="nav-panel">
                    <div class="nav-header"><h3>MENU</h3></div>
                    <ul>
                        <li><a href="/index.html"><span class="nav-icon">▶</span> Trang Chủ</a></li>
                        <li><a href="/tools/rdusername.html"><span class="nav-icon">▶</span> Tạo Username</a></li>
                        <li><a href="/tools/rdname.html"><span class="nav-icon">▶</span> Tạo Tên Ngẫu Nhiên</a></li>
                        <li><a href="/tools/regex-tool.html"><span class="nav-icon">▶</span> Regex Tester</a></li>
                        <li><a href="/tools/sfw-img-download.html"><span class="nav-icon">▶</span> Tải Ảnh SFW</a></li>
                        <li class="menu-link-nsfw"><a href="/tools/nsfw-img-download.html"><span class="nav-icon">▶</span> Tải Ảnh NSFW</a></li>
                    </ul>
                </nav>
            </header>
        `;
    }
    attachHeader() {
        document.body.insertAdjacentHTML('afterbegin', this.headerHTML);
    }
}
document.addEventListener('DOMContentLoaded', () => {
    const ui = new SharedUI();
    ui.attachHeader();
});
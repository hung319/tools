// js/components.js

class SharedUI {
    constructor() {
        this.headerHTML = `
            <header class="shared-header">
                <button id="menu-btn" class="hamburger-menu" aria-label="Open menu">
                    <div class="hamburger-box"><div class="hamburger-inner"></div></div>
                </button>
                <nav id="nav-menu" class="nav-panel">
                    <div class="nav-header"><h3>MENU</h3></div>
                    <ul>
                        <li><a href="/index.html"><span class="nav-icon">🏠</span> Home</a></li>
                     <li><a href="/tools/rdusername.html"><span class="nav-icon">👤</span> User Gen</a></li>
                     <li><a href="/tools/rdpassword.html"><span class="nav-icon">🔒</span> Pass Gen</a></li>
                     <li><a href="/tools/rdkey.html"><span class="nav-icon">🔑</span> Key Gen</a></li>
                     <li><a href="/tools/hash-text.html"><span class="nav-icon">#️⃣</span> Hash Gen</a></li>
                     <li><a href="/tools/formatters.html"><span class="nav-icon">🧹</span> Formatters</a></li>
                     <li><a href="/tools/cron-gen.html"><span class="nav-icon">⏰</span> Cron Gen</a></li>
                     <li><a href="/tools/converters.html"><span class="nav-icon">🔄</span> Converters</a></li>
                     <li><a href="/tools/url-parser.html"><span class="nav-icon">🔗</span> URL Parser</a></li>
                     <li><a href="/tools/device-info.html"><span class="nav-icon">📱</span> Device Info</a></li>
                     <li><a href="/tools/network-utils.html"><span class="nav-icon">🌐</span> Net Utils</a></li>
                     <li><a href="/tools/basic-auth.html"><span class="nav-icon">🛡️</span> Auth Gen</a></li>
                     <li><a href="/tools/jwt-parser.html"><span class="nav-icon">🎫</span> JWT Parser</a></li>
                     <li><a href="/tools/ua-parser.html"><span class="nav-icon">🕵️</span> UA Parser</a></li>
                     <li><a href="/tools/http-status.html"><span class="nav-icon">🚥</span> HTTP Status</a></li>
                     <li><a href="/tools/rdname.html"><span class="nav-icon">🏷️</span> Name Gen</a></li>
                     <li><a href="/tools/regex-tool.html"><span class="nav-icon">🧩</span> Regex Tester</a></li>
                     <li><a href="/tools/rdport.html"><span class="nav-icon">🔌</span> Port Gen</a></li>
                     <li><a href="/tools/sfw-img-download.html"><span class="nav-icon">🖼️</span> SFW DL</a></li>
                     <li class="menu-link-nsfw"><a href="/tools/nsfw-img-download.html"><span class="nav-icon">🔞</span> NSFW DL</a></li>
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
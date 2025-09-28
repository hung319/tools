// ==UserScript==
// @name         Auto Inject Eruda
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Tự động chèn Eruda console vào mọi trang web
// @author       Yuu Onii-chan
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Tạo script tải Eruda
    var script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/eruda';
    document.body.appendChild(script);

    // Khi tải xong thì init Eruda
    script.onload = function () {
        eruda.init();
        // Có thể mở console ngay
        eruda.show();
    };
})();

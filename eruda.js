// ==UserScript==
// @name         Auto Load Eruda (Hidden)
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Tải Eruda vào trang nhưng không tự động hiển thị
// @author       Yuu Onii-chan
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Chèn script Eruda
    var script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/eruda';
    document.body.appendChild(script);

    // Khi tải xong thì khởi tạo nhưng KHÔNG hiển thị
    script.onload = function () {
        eruda.init(); // khởi tạo
        // không gọi eruda.show() để nó ẩn
        // Anh có thể tự mở bằng cách gõ eruda.show() trong console sau
    };
})();

// ==UserScript==
// @name         Full Proxy Redirect (with Auth-Compatible Format)
// @namespace    http://tampermonkey.net/
// @version      2.1
// @description  Chuyển hướng toàn bộ request (HTML, fetch, XHR...) qua proxy có định dạng tương thích server
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const proxyBase = "";
    const apiKey = "";
    const currentUrl = location.href;

    // Tránh vòng lặp khi đã vào proxy rồi
    if (currentUrl.startsWith(proxyBase)) return;

    // Hàm tạo URL đúng định dạng proxy server cần
    const toProxyURL = (url) => `${proxyBase}${encodeURIComponent(url)}?key=${apiKey}`;

    // Nếu là trang HTML chính, chuyển hướng toàn trang
    const isHtml = /text\/html/.test(document.contentType || "");
    if (isHtml) {
        const newUrl = toProxyURL(currentUrl);
        location.replace(newUrl);
        return;
    }

    // Patch fetch()
    const originalFetch = window.fetch;
    window.fetch = function(input, init = {}) {
        const url = typeof input === "string" ? input : input.url;
        return originalFetch(toProxyURL(url), init);
    };

    // Patch XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url, ...rest) {
        const proxyUrl = toProxyURL(url);
        return originalOpen.call(this, method, proxyUrl, ...rest);
    };
})();

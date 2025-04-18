// ==UserScript==
// @name         Facebook Proxy Redirect Only
// @namespace    http://tampermonkey.net/
// @version      2.2
// @description  Chuyển hướng request của Facebook (HTML, fetch, XHR...) qua proxy có API key
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    const proxyBase = "";
    const apiKey = "";
    const currentUrl = location.href;

    // Kiểm tra xem URL có thuộc các tên miền Facebook không
    const isFacebookDomain = (url) => {
        return /(?:facebook\.com|fbcdn\.net|messenger\.com)/i.test(url);
    };

    // Nếu không phải Facebook, bỏ qua toàn bộ script
    if (!isFacebookDomain(currentUrl)) return;

    // Tránh vòng lặp khi đã vào proxy rồi
    if (currentUrl.startsWith(proxyBase)) return;

    const toProxyURL = (url) => `${proxyBase}${encodeURIComponent(url)}?key=${apiKey}`;

    // Nếu là HTML chính, chuyển hướng sang proxy
    const isHtml = /text\/html/.test(document.contentType || "");
    if (isHtml) {
        location.replace(toProxyURL(currentUrl));
        return;
    }

    // Patch fetch
    const originalFetch = window.fetch;
    window.fetch = function (input, init = {}) {
        const url = typeof input === "string" ? input : input.url;
        if (isFacebookDomain(url) && !url.startsWith(proxyBase)) {
            input = toProxyURL(url);
        }
        return originalFetch(input, init);
    };

    // Patch XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url, ...rest) {
        if (isFacebookDomain(url) && !url.startsWith(proxyBase)) {
            url = toProxyURL(url);
        }
        return originalOpen.call(this, method, url, ...rest);
    };
})();

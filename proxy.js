// ==UserScript==
// @name         Full Proxy Wrapper with API Key
// @namespace    http://tampermonkey.net/
// @version      1.3
// @description  Tải mọi nội dung trang (HTML, text, API...) qua proxy nhưng giữ nguyên URL
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(async function () {
    'use strict';

    const proxy = "";
    const apiKey = "";
    const targetUrl = location.href;

    if (targetUrl.startsWith(proxy)) return;

    try {
        const proxyUrl = `${proxy}${encodeURIComponent(targetUrl)}?key=${apiKey}`;
        const response = await fetch(proxyUrl);

        if (!response.ok) throw new Error(`Proxy lỗi: ${response.statusText}`);

        const contentType = response.headers.get("content-type") || "";

        if (contentType.includes("text/html")) {
            const html = await response.text();
            document.open();
            document.write(html);
            document.close();
        } else if (contentType.includes("application/json") || contentType.includes("text/plain")) {
            const text = await response.text();
            document.documentElement.innerHTML = `<pre style="white-space: pre-wrap; word-break: break-all;">${text}</pre>`;
        } else {
            document.body.innerHTML = `<h2>Loại nội dung không hỗ trợ: ${contentType}</h2>`;
        }
    } catch (e) {
        document.body.innerHTML = `<h1 style="color:red;">Lỗi proxy: ${e.message}</h1>`;
    }
})();

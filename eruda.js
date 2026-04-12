// ==UserScript==
// @name         eruda load
// @namespace    http://tampermonkey.net/
// @version      0.3
// @description  Console for mobile browsers
// @author       kairusds
// @include      http://*
// @include      https://*
// @require      https://unpkg.com/eruda@latest/eruda.js
// @run-at       document-body
// @grant        none
// ==/UserScript==

(() => {
	eruda.init();
})();

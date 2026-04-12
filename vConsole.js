// ==UserScript==
// @name         eruda load
// @namespace    http://tampermonkey.net/
// @version      0.3
// @description  Console for mobile browsers
// @author       kairusds
// @include      http://*
// @include      https://*
// @require      https://unpkg.com/vconsole@latest/dist/vconsole.min.js
// @run-at       document-body
// @grant        none
// ==/UserScript==

(() => {
	var vConsole = new window.VConsole();
})();

// ==UserScript==
// @name         eruda load
// @namespace    http://tampermonkey.net/
// @version      0.3
// @description  Console for mobile browsers
// @author       kairusds
// @include      http://*
// @include      https://*
// @require      https://cdnjs.cloudflare.com/ajax/libs/eruda/3.2.2/eruda.min.js
// @run-at       document-body
// @grant        none
// ==/UserScript==

(() => {
	eruda.init();
})();

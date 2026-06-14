// ==UserScript==
// @name         replace-fonts
// @namespace    http://tampermonkey.net/
// @version      20240131
// @description  Replace all fonts by preferred ones.
// @author       Rafael David Tinoco
// @match        http*://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

; (function () {
    'use strict'

    // Don't change fonts for these domains.
    var domainExceptionList = [
        'docs.google.com',
        'netflix.com',
        'youtube.com',
        // ... add more domains as needed
    ]

    // Fonts to be changed to Open Sans.
    var fontsToOpenSans = [
        'Calibri',
        'Cambria',
        'Candara',
        'Constantia',
        'Corbel',
        'Georgia',
        'Segoe UI',
        'Trebuchet MS',
        'Verdana',
        'sans',
        'sans-serif',
        'serif',
        'Avenir',
        'Avenir Next',
        'Comic Sans MS',
        'Comic Sans',
        'Lucida Grande',
        'Lucida Sans',
        'Roboto'
    ].map(font => font.toLowerCase());

    // Fonts to be changed to Cousine (fixed-width).
    var fontsToCousine = [
        'Monospace',
        'Noto Mono',
        'Consolas',
        'Courier New',
        'Courier',
        'Monaco',
        'Menlo',
        'Fira Mono',
        'Liberation Mono',
        'Roboto Mono'
    ].map(font => font.toLowerCase());

    // Fonts to be changed to Liberation Sans (more condensed sans).
    var fontsToLiberationSans = [
        'Arial',
        'Times New Roman',
        'Arial Narrow',
        'Tahoma',
        'Helvetica',
        'Helvetica Neue',
        'San Francisco',
        'Fira Sans',
        'Noto Sans'
    ].map(font => font.toLowerCase());

    function adjustElementStyles(node) {
        let currentDomain = window.location.hostname

        // Nothing to do for these domains.
        if (domainExceptionList.some(domain => currentDomain.includes(domain))) {
            return
        }

        let fontFamily = window
            .getComputedStyle(node)
            .fontFamily.replace(/["']/g, '')
            .toLowerCase();

        fontFamily.split(',').some(font => {
            font = font.trim();
            if (fontsToOpenSans.includes(font)) {
                node.style.fontFamily = '"Open Sans", sans-serif';
                return true;
            } else if (fontsToCousine.includes(font)) {
                node.style.fontFamily = 'Cousine, monospace';
                return true;
            } else if (fontsToLiberationSans.includes(font)) {
                node.style.fontFamily = '"Liberation Sans", sans-serif';
                return true;
            }
            return false;
        });
    }

    function observeDOMChanges() {
        const observer = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        adjustElementStyles(node)
                        node.querySelectorAll('*').forEach(adjustElementStyles)
                    }
                })
            })
        })
        observer.observe(document, { childList: true, subtree: true })
    }

    window.addEventListener('load', () => {
        document.querySelectorAll('*').forEach(adjustElementStyles)
        observeDOMChanges()
    })

    document.addEventListener('DOMContentLoaded', () => {
        document.querySelectorAll('*').forEach(adjustElementStyles)
    })
})()

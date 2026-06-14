// ==UserScript==
// @name         google-chrome-dark-mode-exceptions
// @namespace    http://tampermonkey.net/
// @version      20240131
// @description  Google Chrome Dark Mode Exceptions
// @author       Rafael David Tinoco
// @match        *://*/*
// @grant        GM_addStyle
// @run-at       document-start
// ==/UserScript==

// To be used after chrome://flags => #enable-force-dark is enabled.

; (function () {
    'use strict'

    let defaultMode = 'dark' // or "light"

    // Do not apply chrome's default dark mode to site
    const excludedDomains = [
        'github.com',
        'docs.google.com',
        'drive.google.com',
        'docusign',
    ]

    function isExcluded() {
        const currentDomain = window.location.hostname
        return excludedDomains.find(domain => currentDomain.includes(domain))
    }

    const lightCSS = `
        :root {
            color-scheme: light only !important;
        }
    `

    const darkCSS = `
        :root {
            color-scheme: darkonly !important;
        }
    `

    if (defaultMode === 'dark') {
        if (isExcluded()) {
            GM_addStyle(lightCSS)
        }
    } else if (defaultMode === 'light') {
        if (isExcluded()) {
            GM_addStyle(darkCSS)
        }
    }
})()

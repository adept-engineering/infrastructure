(function () {
  'use strict';

  var BRAND = {
    company_name: 'Adept Engineering Solutions',
    login_caption: 'Secure virtual workspaces for teams',
    html_title: 'Adept Engineering Solutions',
    login_splash_background: '/branding/login-splash.svg',
  };

  var brandingInjected = false;
  var attempts = 0;
  var maxAttempts = 60;

  try {
    localStorage.setItem('login_caption', BRAND.login_caption);
    localStorage.setItem('login_splash_background', BRAND.login_splash_background);
    localStorage.setItem('login_logo', 'img/logo.svg');
    localStorage.setItem('header_logo', 'img/headerlogo.svg');
    localStorage.setItem('favicon_logo', 'img/favicon.png');
  } catch (e) { /* private mode / blocked storage */ }

  function hidePoweredBy() {
    document.querySelectorAll('.logo-bottom-txt p, .smaller-text p').forEach(function (node) {
      if (/powered by kasm/i.test(node.textContent || '')) {
        node.style.display = 'none';
      }
    });
  }

  function injectBrandingBlock(wrap) {
    if (wrap.getAttribute('data-adept-branded') === '1') {
      return true;
    }
    wrap.setAttribute('data-adept-branded', '1');
    wrap.innerHTML = '';

    var company = document.createElement('div');
    company.className = 'adept-company-name';
    company.textContent = BRAND.company_name;

    var tagline = document.createElement('div');
    tagline.className = 'adept-tagline';
    tagline.textContent = BRAND.login_caption;

    wrap.appendChild(company);
    wrap.appendChild(tagline);
    return true;
  }

  function injectBranding() {
    document.title = BRAND.html_title;
    hidePoweredBy();

    var wraps = document.querySelectorAll('.logo-bottom-txt');
    if (!wraps.length) {
      return false;
    }

    wraps.forEach(injectBrandingBlock);
    brandingInjected = true;
    return true;
  }

  function tick() {
    attempts += 1;
    if (injectBranding()) {
      return;
    }
    if (attempts < maxAttempts) {
      setTimeout(tick, 250);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', tick);
  } else {
    tick();
  }
  window.addEventListener('load', tick);
})();

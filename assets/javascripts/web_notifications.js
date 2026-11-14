// Header bell, drop-down panel and desktop pop-ups for redmine_web_notifications.
(function () {
  'use strict';

  var cfg = window.RedmineWebNotifications;
  if (!cfg) return;

  // Shared by all tabs of this site, so a notification pops up only once.
  var LAST_SEEN_KEY = 'redmine-web-notifications:last-seen-id';
  var baseTitle = document.title;
  var bell, badge, panel, timer;

  function storageGet(key) {
    try { return window.localStorage.getItem(key); } catch (e) { return null; }
  }

  function storageSet(key, value) {
    try { window.localStorage.setItem(key, value); } catch (e) { /* private mode */ }
  }

  function csrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }

  function request(method, url, onSuccess) {
    var headers = { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' };
    if (method !== 'GET') headers['X-CSRF-Token'] = csrfToken();
    fetch(url, { method: method, credentials: 'same-origin', headers: headers })
      .then(function (res) {
        // Logged out or session expired: stop asking until the next page load.
        if (res.status === 401 || res.status === 403) { stopPolling(); return null; }
        return res.ok ? res.json() : null;
      })
      .then(function (data) { if (data) onSuccess(data); })
      .catch(function () { /* offline; try again next round */ });
  }

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function setUnread(count) {
    badge.textContent = count > 99 ? '99+' : String(count);
    badge.hidden = count <= 0;
    bell.classList.toggle('has-unread', count > 0);
    bell.setAttribute('aria-label', cfg.text.title + (count > 0 ? ' (' + count + ')' : ''));
    document.title = (count > 0 ? '(' + count + ') ' : '') + baseTitle;
  }

  // --- bell -------------------------------------------------------------------------------

  var BELL_SVG =
    '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false">' +
    '<path fill="currentColor" d="M12 22a2.5 2.5 0 0 0 2.45-2h-4.9A2.5 2.5 0 0 0 12 22zm7-6V11a7 7 0 0 0-5.5-6.84V3.5' +
    'a1.5 1.5 0 0 0-3 0v.66A7 7 0 0 0 5 11v5l-2 2v1h18v-1l-2-2z"/></svg>';

  // Redmine 7 turned the account links into an avatar drop-down (#account.dropdown inside
  // .profile-menu). The bell then sits next to the avatar, outside the drop-down. Redmine 6 and
  // older keep it as the first item of the #account list.
  function redmine7Account() {
    return document.querySelector('#top-menu .profile-menu > #account.dropdown');
  }

  // Below Redmine's mobile breakpoint the whole #top-menu is hidden, so on Redmine 7 the bell
  // moves into #header next to the menu toggle button, and back when the window gets wider.
  function placeBell(item, account) {
    var toggle = document.querySelector('#header > .js-flyout-menu-toggle-button');
    var mobile = !!toggle && window.getComputedStyle(toggle).display !== 'none';
    if (mobile) {
      if (item.previousElementSibling !== toggle) toggle.parentNode.insertBefore(item, toggle.nextSibling);
    } else if (item.nextElementSibling !== account) {
      account.parentNode.insertBefore(item, account);
    }
    item.classList.toggle('web-notifications-menu--mobile', mobile);
  }

  function buildBell() {
    var account = redmine7Account();
    var menu = account ? null : (document.querySelector('#account ul') || document.querySelector('#top-menu ul'));
    if (!account && !menu) return false;

    var item = el(account ? 'div' : 'li', 'web-notifications-menu');
    bell = el('a', 'web-notifications-bell');
    bell.href = cfg.urls.index;
    bell.setAttribute('role', 'button');
    bell.setAttribute('aria-haspopup', 'true');
    bell.setAttribute('aria-expanded', 'false');
    bell.innerHTML = BELL_SVG;
    badge = el('span', 'web-notifications-badge');
    bell.appendChild(badge);

    panel = el('div', 'web-notifications-panel');
    panel.hidden = true;

    item.appendChild(bell);
    item.appendChild(panel);
    if (account) {
      item.classList.add('web-notifications-menu--header');
      placeBell(item, account);
      var placing = null;
      window.addEventListener('resize', function () {
        if (placing) return;
        placing = window.requestAnimationFrame(function () {
          placing = null;
          var wasMobile = item.classList.contains('web-notifications-menu--mobile');
          placeBell(item, account);
          if (wasMobile !== item.classList.contains('web-notifications-menu--mobile')) closePanel();
        });
      });
    } else {
      menu.insertBefore(item, menu.firstChild);
    }

    bell.addEventListener('click', function (event) {
      event.preventDefault();
      panel.hidden ? openPanel() : closePanel();
    });
    // Capture phase: Redmine 7's account drop-down and the mobile menu toggle stop the click from
    // bubbling, and opening either of them should still close the panel.
    document.addEventListener('click', function (event) {
      if (!panel.hidden && !item.contains(event.target)) closePanel();
    }, true);
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && !panel.hidden) { closePanel(); bell.focus(); }
    });
    return true;
  }

  // --- panel ------------------------------------------------------------------------------

  function openPanel() {
    panel.hidden = false;
    bell.setAttribute('aria-expanded', 'true');
    renderPanel(null);
    request('GET', cfg.urls.recent, function (data) {
      setUnread(data.unread);
      renderPanel(data.items);
    });
  }

  function closePanel() {
    panel.hidden = true;
    bell.setAttribute('aria-expanded', 'false');
  }

  function renderPanel(items) {
    panel.textContent = '';

    var header = el('div', 'web-notifications-panel-header');
    header.appendChild(el('strong', null, cfg.text.title));
    var markAll = el('button', 'web-notifications-mark-all', cfg.text.markAllRead);
    markAll.type = 'button';
    markAll.addEventListener('click', function () {
      request('POST', cfg.urls.readAll, function (data) {
        setUnread(data.unread);
        panel.querySelectorAll('.unread').forEach(function (n) { n.classList.remove('unread'); });
      });
    });
    header.appendChild(markAll);
    panel.appendChild(header);

    var list = el('ul', 'web-notifications-items');
    if (items === null) {
      list.appendChild(el('li', 'web-notifications-loading', '…'));
    } else if (items.length === 0) {
      list.appendChild(el('li', 'web-notifications-empty', cfg.text.empty));
    } else {
      items.forEach(function (n) { list.appendChild(renderItem(n)); });
    }
    panel.appendChild(list);

    var footer = el('div', 'web-notifications-panel-footer');
    var viewAll = el('a', null, cfg.text.viewAll);
    viewAll.href = cfg.urls.index;
    footer.appendChild(viewAll);
    footer.appendChild(desktopControl());
    panel.appendChild(footer);
  }

  function renderItem(n) {
    var li = el('li', n.unread ? 'unread' : null);
    var link = el('a');
    link.href = n.url;
    var meta = el('span', 'web-notifications-meta');
    meta.appendChild(el('span', 'web-notifications-kind', n.kind));
    [n.project, n.actor, n.ago].forEach(function (part) {
      if (part) meta.appendChild(el('span', null, part));
    });
    link.appendChild(meta);
    link.appendChild(el('span', 'web-notifications-title', n.title));
    if (n.summary) link.appendChild(el('span', 'web-notifications-summary', n.summary));
    li.appendChild(link);
    return li;
  }

  function desktopControl() {
    if (!('Notification' in window)) return el('span');
    if (Notification.permission === 'denied') {
      return el('span', 'web-notifications-desktop-denied', cfg.text.desktopDenied);
    }
    if (Notification.permission === 'granted') return el('span');

    var button = el('button', 'web-notifications-enable-desktop', cfg.text.enableDesktop);
    button.type = 'button';
    button.addEventListener('click', function () {
      var answer = Notification.requestPermission(function () { renderPanelFooterAgain(); });
      if (answer && answer.then) answer.then(renderPanelFooterAgain);
    });
    return button;
  }

  function renderPanelFooterAgain() {
    var footer = panel.querySelector('.web-notifications-panel-footer');
    if (footer && footer.lastChild) footer.replaceChild(desktopControl(), footer.lastChild);
  }

  // --- polling and desktop pop-ups -------------------------------------------------------

  function lastSeenId() {
    return parseInt(storageGet(LAST_SEEN_KEY), 10) || 0;
  }

  function poll() {
    var since = lastSeenId();
    request('GET', cfg.urls.poll + '?since=' + since, function (data) {
      setUnread(data.unread);
      if (data.latest_id > lastSeenId()) storageSet(LAST_SEEN_KEY, String(data.latest_id));
      (data.fresh || []).forEach(popUp);
    });
  }

  function popUp(n) {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;
    // The badge is enough while the user is looking at this tab.
    if (document.visibilityState === 'visible' && document.hasFocus()) return;
    try {
      var body = [n.project, n.actor].filter(Boolean).join(' · ');
      if (n.summary) body += (body ? '\n' : '') + n.summary;
      // The tag makes a second tab's copy replace the first instead of stacking.
      var popup = new Notification(n.kind + ': ' + n.title, { body: body, tag: 'redmine-web-notification-' + n.id });
      popup.onclick = function () {
        window.focus();
        window.location.href = n.url;
        popup.close();
      };
    } catch (e) { /* some mobile browsers only allow service-worker notifications */ }
  }

  function startPolling() {
    stopPolling();
    timer = window.setInterval(poll, cfg.interval * 1000);
  }

  function stopPolling() {
    if (timer) window.clearInterval(timer);
    timer = null;
  }

  function init() {
    if (!buildBell()) return;
    setUnread(cfg.unread);
    // Whatever exists when the page loads is already counted on the badge; pop up only newer ones.
    if (cfg.latestId > lastSeenId()) storageSet(LAST_SEEN_KEY, String(cfg.latestId));
    startPolling();
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') poll();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

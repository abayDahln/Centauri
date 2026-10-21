/// Jembatan JS Centauri yang di-inject LANGSUNG ke dokumen konten (tanpa
/// iframe). Berjalan di dokumen yang dirender AI sendiri, sehingga seleksi,
/// overlay, navigasi antar-halaman, dan baca/tulis gaya selalu sinkron dengan
/// HTML yang terlihat.
///
/// Kontrak:
///  - id stabil `data-centauri-id` di-stamp di Dart; JS tidak generate id
///    (kecuali node baru via MCP yang memakai prefix `m`).
///  - JS hanya melaporkan metadata via event, dan menulis inline style.
///  - HTML di DOM tetap source of truth.
library;

/// Id atribut untuk elemen `<script>` bridge, agar bisa dibuang saat
/// mengekspor/menyinkronkan HTML (supaya bridge tidak bocor ke hasil simpan).
const String _bridgeScriptId = 'centauri-bridge';

/// Nama fungsi/objek global yang di-inject. Dipakai Dart untuk memanggil JS.
const String canvasBridgeScript = r'''
(function () {
  if (window.__centauriReady) return; // idempoten: jangan dobel listener
  window.__centauriReady = true;

  var overlay = null;
  var hoverBox = null;
  var selectBox = null;
  var selectedId = null;
  // Mode interaksi (default) membiarkan input, tombol, dan hover bekerja
  // seperti halaman biasa. Mode seleksi menangkap klik untuk memilih elemen.
  var mode = 'interact';
  var actionsBox = null;
  var actionsId = null;

  function sendToHost(payload) {
    try {
      var json = JSON.stringify(payload);
      if (window.centauriBridge && window.centauriBridge.postMessage) {
        window.centauriBridge.postMessage(json);
        return;
      }
      if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
        window.chrome.webview.postMessage(json);
        return;
      }
    } catch (e) { /* host bridge belum siap */ }
  }

  // Laporkan error JS apa pun ke Dart (hardening).
  window.onerror = function (message, source, line) {
    sendToHost({ type: 'error', message: String(message) +
      (line ? (' @' + line) : '') });
    return false;
  };
  window.addEventListener('unhandledrejection', function (e) {
    try {
      sendToHost({ type: 'error', message: 'Unhandled: ' +
        (e.reason && e.reason.message ? e.reason.message : String(e.reason)) });
    } catch (err) {}
  });

  function ensureOverlay() {
    if (overlay && overlay.ownerDocument === document &&
        overlay.parentNode === document.body) {
      return;
    }
    overlay = document.createElement('div');
    overlay.setAttribute('data-centauri-overlay', '1');
    overlay.style.cssText = 'position:absolute;inset:0;pointer-events:none;z-index:2147483647';

    hoverBox = document.createElement('div');
    hoverBox.style.cssText = 'position:absolute;border:1px solid rgba(78,161,255,0.9);' +
      'background:rgba(78,161,255,0.12);pointer-events:none;display:none;box-sizing:border-box';
    selectBox = document.createElement('div');
    selectBox.style.cssText = 'position:absolute;border:1.5px solid rgb(0,120,212);' +
      'background:rgba(0,120,212,0.10);pointer-events:none;display:none;box-sizing:border-box';

    overlay.appendChild(hoverBox);
    overlay.appendChild(selectBox);
    document.body.appendChild(overlay);
  }

  function rectOf(id) {
    var el = id ? document.querySelector('[data-centauri-id="' + id + '"]') : null;
    if (!el) return null;
    var r = el.getBoundingClientRect();
    return { x: r.left, y: r.top, w: r.width, h: r.height };
  }

  function placeBox(box, rect) {
    if (!box) return;
    if (!rect || rect.w <= 0 || rect.h <= 0) { box.style.display = 'none'; return; }
    var sx = window.scrollX || 0;
    var sy = window.scrollY || 0;
    box.style.display = 'block';
    box.style.left = (rect.x + sx) + 'px';
    box.style.top = (rect.y + sy) + 'px';
    box.style.width = rect.w + 'px';
    box.style.height = rect.h + 'px';
  }

  function idFromEvent(e) {
    var el = e.target;
    while (el && el.getAttribute) {
      var id = el.getAttribute('data-centauri-id');
      if (id) return id;
      el = el.parentElement;
    }
    return null;
  }

  // Pastikan dokumen punya <meta name="viewport"> agar fluid di semua ukuran.
  function ensureViewportMeta() {
    try {
      var head = document.head || document.documentElement;
      if (!head) return;
      if (document.querySelector('meta[name="viewport"]')) return;
      var meta = document.createElement('meta');
      meta.setAttribute('name', 'viewport');
      meta.setAttribute('content', 'width=device-width, initial-scale=1');
      head.appendChild(meta);
    } catch (e) { /* abaikan */ }
  }

  // Scrollbar bawaan WebView2 mengikuti tema Windows dan bisa tampil hitam di
  // halaman terang. Warna netral ini jadi cadangan; disisipkan paling awal di
  // <head> supaya CSS halaman (yang tahu paletnya sendiri) tetap menang.
  function ensureScrollbarDefaults() {
    try {
      if (document.getElementById('centauri-scrollbar')) return;
      var head = document.head || document.documentElement;
      if (!head) return;
      var style = document.createElement('style');
      style.id = 'centauri-scrollbar';
      style.textContent =
        'html{scrollbar-width:thin;' +
        'scrollbar-color:rgba(120,120,120,.45) transparent;}' +
        '::-webkit-scrollbar{width:10px;height:10px;}' +
        '::-webkit-scrollbar-track{background:transparent;}' +
        '::-webkit-scrollbar-thumb{background:rgba(120,120,120,.45);' +
        'border-radius:999px;}' +
        '::-webkit-scrollbar-thumb:hover{background:rgba(120,120,120,.65);}';
      head.insertBefore(style, head.firstChild);
    } catch (e) { /* abaikan */ }
  }

  // Cari target halaman pada handler inline, mis.
  // `onclick="location.href='cart.html'"` atau `window.location='cart.html'`.
  function inlineNavTarget(el) {
    var node = el;
    while (node && node.getAttribute) {
      var attr = node.getAttribute('onclick');
      if (attr) {
        var m = attr.match(/['"]([^'"]*\.html[^'"]*)['"]/i);
        if (m) return m[1];
      }
      if (node === document.body) break;
      node = node.parentElement;
    }
    return null;
  }

  // Navigasi yang dipicu JS (location.assign/replace, window.open) diteruskan
  // ke host tanpa membuat WebView memuat URL yang tidak ada. `location.href`
  // ditangani host lewat pemantauan URL.
  function patchNavigationApis() {
    try {
      var proto = Location.prototype;
      ['assign', 'replace'].forEach(function (name) {
        if (typeof proto[name] !== 'function') return;
        proto[name] = function (url) {
          sendToHost({ type: 'navigate', href: String(url) });
        };
      });
    } catch (e) { /* abaikan */ }
    try {
      window.open = function (url) {
        if (url) sendToHost({ type: 'navigate', href: String(url) });
        return null;
      };
    } catch (e) { /* abaikan */ }
  }

  function attachPicker() {
    if (!document.body) return;
    ensureViewportMeta();
    ensureScrollbarDefaults();
    applySharpnessDefaults();
    ensureOverlay();
    ensureImageFallback();
    patchNavigationApis();

    document.addEventListener('mouseover', function (e) {
      if (mode !== 'select') return;
      var id = idFromEvent(e);
      if (!id) return;
      placeBox(hoverBox, rectOf(id));
      sendToHost({ type: 'hover', id: id });
    }, true);

    document.addEventListener('mouseout', function () {
      if (hoverBox) hoverBox.style.display = 'none';
      sendToHost({ type: 'hover', id: null });
    }, true);

    document.addEventListener('click', function (e) {
      // Mode seleksi: klik memilih elemen untuk memberi konteks ke AI.
      // Link tidak dinavigasi agar elemen <a> pun bisa ikut diedit.
      if (mode === 'select') {
        var pickedId = idFromEvent(e);
        if (!pickedId) return;
        e.preventDefault();
        e.stopPropagation();
        selectedId = pickedId;
        placeBox(selectBox, rectOf(pickedId));
        showActions(pickedId);
        sendToHost({ type: 'select', id: pickedId, label: labelOf(pickedId) });
        setTimeout(function () { centauriInspect(pickedId); }, 30);
        return;
      }
      // Mode interaksi: klik diteruskan ke halaman apa adanya. Link
      // antar-halaman di-intercept agar host yang mengganti halaman;
      // anchor (#...) dibiarkan agar browser menggulir seperti biasa.
      // Handler inline yang memanggil `location.href='x.html'` juga
      // diarahkan ke host supaya WebView tidak memuat URL yang tidak ada.
      var inlineHref = inlineNavTarget(e.target);
      if (inlineHref) {
        e.preventDefault();
        e.stopPropagation();
        sendToHost({ type: 'navigate', href: inlineHref });
        return;
      }
      var a = e.target && e.target.closest ? e.target.closest('a[href]') : null;
      if (a) {
        var href = a.getAttribute('href') || '';
        if (href && href.charAt(0) !== '#' &&
            href.indexOf('javascript:') !== 0) {
          e.preventDefault();
          e.stopPropagation();
          sendToHost({ type: 'navigate', href: href });
        }
      }
    }, true);

    document.addEventListener('scroll', function () {
      hideActions();
      refreshSelection();
    }, true);

    refreshSelection();
    sendToHost({ type: 'ready' });
  }

  function refreshSelection() {
    if (selectedId) placeBox(selectBox, rectOf(selectedId));
  }

  // Default ketajaman render: font anti-alias + teks legible.
  function applySharpnessDefaults() {
    try {
      var style = document.getElementById('centauri-sharp');
      if (!style) {
        style = document.createElement('style');
        style.id = 'centauri-sharp';
        (document.head || document.documentElement).appendChild(style);
      }
      style.textContent =
        'body{-webkit-font-smoothing:antialiased;' +
        '-moz-osx-font-smoothing:grayscale;' +
        'text-rendering:optimizeLegibility;}' +
        'img{image-rendering:auto;}';
    } catch (e) { /* abaikan */ }
  }

  // Jaring pengaman gambar: bila sebuah <img> gagal dimuat, beri latar gradien
  // lembut agar UI tidak menampilkan kotak rusak. `src` TIDAK dihapus.
  function ensureImageFallback() {
    try {
      if (document.getElementById('centauri-img-fix')) return;
      var style = document.createElement('style');
      style.id = 'centauri-img-fix';
      style.textContent =
        'img.centauri-fallback{background:linear-gradient(135deg,#6366F1,#8B5CF6,' +
        '#EC4899)!important;object-fit:cover!important;color:transparent;}';
      (document.head || document.documentElement).appendChild(style);

      var imgs = document.querySelectorAll('img');
      for (var i = 0; i < imgs.length; i++) {
        (function (img) {
          if (img.dataset.centauriImg) return;
          img.dataset.centauriImg = '1';
          if (img.complete && img.naturalWidth === 0) {
            img.classList.add('centauri-fallback');
            return;
          }
          img.addEventListener('error', function () {
            img.classList.add('centauri-fallback');
          });
        })(imgs[i]);
      }
    } catch (e) { /* abaikan */ }
  }

  // Label ringkas untuk mention di prompt, mis. `button · Masukkan Keranjang`.
  function labelOf(id) {
    var el = id ? document.querySelector('[data-centauri-id="' + id + '"]') : null;
    if (!el) return '';
    var tag = (el.tagName || '').toLowerCase();
    var text = '';
    try { text = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim(); }
    catch (e) { text = ''; }
    if (text.length > 28) text = text.slice(0, 28) + '…';
    return text ? (tag + ' · ' + text) : tag;
  }

  // Menu aksi kecil di dekat elemen terpilih (mode seleksi).
  function makeAction(text, color, onClick) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.textContent = text;
    btn.style.cssText = 'all:unset;cursor:pointer;padding:8px 10px;' +
      'border-radius:7px;display:block;width:100%;box-sizing:border-box;' +
      'color:' + color + ';font:500 12px Inter,system-ui,sans-serif;';
    btn.addEventListener('mouseenter', function () {
      btn.style.background = '#27272A';
    });
    btn.addEventListener('mouseleave', function () {
      btn.style.background = 'transparent';
    });
    btn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      onClick();
    }, true);
    return btn;
  }

  function ensureActions() {
    if (actionsBox && actionsBox.ownerDocument === document &&
        actionsBox.parentNode) return;
    actionsBox = document.createElement('div');
    actionsBox.setAttribute('data-centauri-actions', '1');
    actionsBox.style.cssText = 'position:absolute;display:none;pointer-events:auto;' +
      'flex-direction:column;background:#18181B;border:1px solid #3F3F46;' +
      'border-radius:10px;box-shadow:0 12px 30px rgba(0,0,0,0.45);' +
      'padding:4px;min-width:150px;z-index:2147483647;';
    actionsBox.appendChild(makeAction('Edit dengan AI', '#FAFAFA', function () {
      sendToHost({ type: 'editWithAi', id: actionsId, label: labelOf(actionsId) });
      hideActions();
    }));
    actionsBox.appendChild(makeAction('Hapus komponen', '#F87171', function () {
      sendToHost({ type: 'deleteNode', id: actionsId });
      hideActions();
    }));
    (overlay || document.body).appendChild(actionsBox);
  }

  function showActions(id) {
    ensureActions();
    var rect = rectOf(id);
    if (!rect || rect.w <= 0 || rect.h <= 0) { hideActions(); return; }
    actionsId = id;
    var sx = window.scrollX || 0;
    var sy = window.scrollY || 0;
    actionsBox.style.display = 'flex';
    var w = actionsBox.offsetWidth || 150;
    var h = actionsBox.offsetHeight || 76;
    var left = Math.max(sx + 4, Math.min(rect.x + sx,
      sx + (window.innerWidth || 0) - w - 8));
    var top = rect.y + sy - h - 8;
    if (top < sy + 4) top = rect.y + sy + rect.h + 8;
    actionsBox.style.left = left + 'px';
    actionsBox.style.top = top + 'px';
  }

  function hideActions() {
    actionsId = null;
    if (actionsBox) actionsBox.style.display = 'none';
  }

  // Dipanggil dari Dart saat memilih / hover node.
  function centauriSelect(id) {
    selectedId = id;
    if (!id) {
      if (selectBox) selectBox.style.display = 'none';
      hideActions();
      return;
    }
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    if (el && el.scrollIntoView) {
      el.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    }
    placeBox(selectBox, rectOf(id));
    setTimeout(function () { centauriInspect(id); }, 30);
  }

  function centauriHover(id) {
    if (!id) { if (hoverBox) hoverBox.style.display = 'none'; return; }
    placeBox(hoverBox, rectOf(id));
  }

  function centauriSetMode(next) {
    mode = next === 'select' ? 'select' : 'interact';
    if (mode !== 'select') {
      selectedId = null;
      if (hoverBox) hoverBox.style.display = 'none';
      if (selectBox) selectBox.style.display = 'none';
      hideActions();
    }
  }

  var __centauriWatchedProps = ['display', 'position', 'left', 'top',
    'width', 'height', 'margin', 'marginTop', 'marginRight', 'marginBottom',
    'marginLeft', 'padding', 'paddingTop', 'paddingRight', 'paddingBottom',
    'paddingLeft', 'color', 'backgroundColor', 'fontSize', 'fontWeight',
    'fontFamily', 'lineHeight', 'textAlign', 'border', 'borderWidth',
    'borderStyle', 'borderColor', 'borderRadius', 'boxShadow', 'opacity',
    'transform', 'gap', 'flexDirection', 'justifyContent', 'alignItems'];

  function centauriInspect(id) {
    if (!id) return null;
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return null;
    var r = el.getBoundingClientRect();
    var cs = window.getComputedStyle ? window.getComputedStyle(el) : null;
    var styles = {};
    if (cs) {
      for (var i = 0; i < __centauriWatchedProps.length; i++) {
        var k = __centauriWatchedProps[i];
        try { styles[k] = cs[k] || ''; } catch (e) { styles[k] = ''; }
      }
      try { styles['tag'] = el.tagName ? el.tagName.toLowerCase() : ''; }
      catch (e) {}
    }
    try {
      for (var j = 0; j < __centauriWatchedProps.length; j++) {
        var kk = __centauriWatchedProps[j];
        var inline = el.style[kk];
        if (inline !== undefined && inline !== null && inline !== '') {
          styles[kk] = inline;
        }
      }
      styles['cssText'] = el.style.cssText || '';
    } catch (e) {}
    var payload = { type: 'geometry', id: id,
      tag: el.tagName ? el.tagName.toLowerCase() : '',
      rect: { x: r.left, y: r.top, w: r.width, h: r.height },
      styles: styles };
    sendToHost(payload);
    placeBox(selectBox, { x: r.left, y: r.top, w: r.width, h: r.height });
    return payload;
  }

  // Satu-satunya jalur tulis: set inline style, bukan scene graph.
  function centauriApplyStyle(id, patch) {
    if (!id || !patch) return false;
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return false;
    for (var k in patch) {
      try { el.style[k] = patch[k]; } catch (e) {}
    }
    placeBox(selectBox, rectOf(id));
    return true;
  }

  function centauriMoveResize(id, box) {
    if (!id || !box) return false;
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return false;
    try {
      var cs = window.getComputedStyle ? window.getComputedStyle(el) : null;
      var pos = cs ? cs.position : '';
      if (pos === 'static') el.style.position = 'relative';
      if (box.dx) {
        var cur = parseFloat(el.style.left) || 0;
        el.style.left = (cur + box.dx) + 'px';
      }
      if (box.dy) {
        var cur2 = parseFloat(el.style.top) || 0;
        el.style.top = (cur2 + box.dy) + 'px';
      }
      if (box.w !== undefined && box.w !== null) el.style.width = box.w + 'px';
      if (box.h !== undefined && box.h !== null) el.style.height = box.h + 'px';
    } catch (e) { return false; }
    placeBox(selectBox, rectOf(id));
    setTimeout(function () { centauriInspect(id); }, 60);
    return true;
  }

  // Ukuran dokumen (dipakai ekspor SVG tanpa viewport fixed).
  function centauriGetSize() {
    try {
      var w = Math.max(document.body ? document.body.scrollWidth : 0,
        document.documentElement ? document.documentElement.scrollWidth : 0);
      var h = Math.max(document.body ? document.body.scrollHeight : 0,
        document.documentElement ? document.documentElement.scrollHeight : 0);
      sendToHost({ type: 'size', width: w, height: h });
    } catch (e) {}
  }

  // Mutasi DOM untuk MCP bridge (external agent).
  function __centauriQuery(id) {
    if (!id) return null;
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    return el ? el : null;
  }

  function __centauriSync() {
    placeBox(selectBox, selectedId ? rectOf(selectedId) : null);
    return true;
  }

  function centauriAddNode(parentId, html, position) {
    if (!document.body || !html) return false;
    try {
      var parent = parentId
        ? document.querySelector('[data-centauri-id="' + parentId + '"]')
        : document.body;
      if (!parent) return false;
      var stamp = 'm' + Date.now().toString(36);
      var tpl = document.createElement('template');
      tpl.innerHTML = html.trim();
      var nodes = tpl.content.childNodes;
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].nodeType === 1) {
          nodes[i].setAttribute('data-centauri-id', stamp + '_' + i);
        }
      }
      var pos = position || 'beforeend';
      parent.insertAdjacentHTML(pos, tpl.innerHTML);
      __centauriSync();
      var added = parent.querySelector('[data-centauri-id^="' + stamp + '"]');
      if (added && added.scrollIntoView) {
        added.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      }
      return true;
    } catch (e) { return false; }
  }

  function centauriSetText(id, text) {
    var el = __centauriQuery(id);
    if (!el) return false;
    try {
      el.textContent = text;
      __centauriSync();
      return true;
    } catch (e) { return false; }
  }

  function centauriDeleteNode(id) {
    var el = __centauriQuery(id);
    if (!el) return false;
    try {
      if (selectedId === id) {
        selectedId = null;
        if (selectBox) selectBox.style.display = 'none';
        sendToHost({ type: 'select', id: null });
      }
      el.remove();
      __centauriSync();
      return true;
    } catch (e) { return false; }
  }

  // Buang elemen internal (overlay + style/script bridge) sebelum HTML dikirim.
  function __centauriCleanClone() {
    var clone = document.documentElement.cloneNode(true);
    var junk = clone.querySelectorAll('[data-centauri-overlay]');
    for (var i = 0; i < junk.length; i++) {
      if (junk[i].parentNode) junk[i].parentNode.removeChild(junk[i]);
    }
    var extras = ['#centauri-img-fix', '#centauri-sharp', '#centauri-bridge'];
    for (var j = 0; j < extras.length; j++) {
      var node = clone.querySelector(extras[j]);
      if (node && node.parentNode) node.parentNode.removeChild(node);
    }
    return clone;
  }

  function centauriGetHtml() {
    if (!document.documentElement) return null;
    try {
      var clone = __centauriCleanClone();
      var html = '<!DOCTYPE html>\n' + clone.outerHTML;
      sendToHost({ type: 'html', html: html });
      return html;
    } catch (e) {
      sendToHost({ type: 'error', message: 'getHtml: ' + e });
      return null;
    }
  }

  function centauriGetOuterHtml(id) {
    var el = __centauriQuery(id);
    if (!el) {
      sendToHost({ type: 'outerHtmlError', id: id });
      return null;
    }
    try {
      var payload = { type: 'outerHtml', id: id,
        tag: el.tagName ? el.tagName.toLowerCase() : '',
        html: el.outerHTML };
      sendToHost(payload);
      return payload.html;
    } catch (e) {
      sendToHost({ type: 'outerHtmlError', id: id });
      return null;
    }
  }

  // Ekspor PNG dokumen via SVG foreignObject → canvas.
  function centauriExportPng(pixelRatio) {
    if (!document.documentElement) {
      sendToHost({ type: 'pngError', message: 'Dokumen belum siap.' });
      return;
    }
    try {
      var scale = pixelRatio || 2;
      if (scale < 1) scale = 1;
      if (scale > 3) scale = 3;
      var w = Math.max(document.body ? document.body.scrollWidth : 0,
        document.documentElement.scrollWidth || 0);
      var h = Math.max(document.body ? document.body.scrollHeight : 0,
        document.documentElement.scrollHeight || 0);
      if (!w || !h) {
        sendToHost({ type: 'pngError', message: 'Ukuran dokumen nol.' });
        return;
      }
      var maxPixels = 4096 * 4096;
      while (w * scale * h * scale > maxPixels && scale > 1) scale -= 0.25;

      var serializer = new XMLSerializer();
      var clone = __centauriCleanClone();

      var blobUrl = null;
      var guard = function (fn) {
        return function () {
          var args = arguments;
          try { return fn.apply(null, args); }
          catch (e) {
            if (blobUrl) URL.revokeObjectURL(blobUrl);
            sendToHost({ type: 'pngError',
              message: 'Ekspor PNG gagal: ' + (e && e.message ? e.message : e) });
          }
        };
      };

      var rasterize = guard(function () {
        var xhtml = serializer.serializeToString(clone);
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + w +
          '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">' +
          '<foreignObject width="100%" height="100%">' + xhtml +
          '</foreignObject></svg>';
        var blob = new Blob([svg], { type: 'image/svg+xml;charset=utf-8' });
        blobUrl = URL.createObjectURL(blob);
        var img = new Image();
        img.onload = guard(function () {
          var canvas = document.createElement('canvas');
          canvas.width = Math.round(w * scale);
          canvas.height = Math.round(h * scale);
          var ctx = canvas.getContext('2d');
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
          URL.revokeObjectURL(blobUrl);
          blobUrl = null;
          var dataUrl = canvas.toDataURL('image/png');
          sendToHost({ type: 'png', dataUrl: dataUrl });
        });
        img.onerror = guard(function () {
          sendToHost({ type: 'pngError', message: 'Gagal memuat SVG dokumen.' });
        });
        img.src = blobUrl;
      });

      var urls = {};
      var nodes = clone.querySelectorAll('img, [style]');
      for (var j = 0; j < nodes.length; j++) {
        var el = nodes[j];
        var candidates = [];
        var src = el.getAttribute && el.getAttribute('src');
        if (src && /^https?:/i.test(src)) candidates.push(src);
        var st = el.getAttribute && el.getAttribute('style');
        if (st) {
          var re = /url\(["']?(https?:[^"')]+)["']?\)/gi;
          var m;
          while ((m = re.exec(st)) !== null) candidates.push(m[1]);
        }
        for (var k = 0; k < candidates.length; k++) urls[candidates[k]] = true;
      }
      var externalUrls = Object.keys(urls);
      if (!externalUrls.length) { rasterize(); return; }

      var swapImage = function (url, dataUrl) {
        var sel = url.replace(/"/g, '\\"');
        var els = clone.querySelectorAll('img[src="' + sel + '"]');
        for (var q = 0; q < els.length; q++) els[q].setAttribute('src', dataUrl);
        var styled = clone.querySelectorAll('[style*="' + sel + '"]');
        for (var r = 0; r < styled.length; r++) {
          styled[r].setAttribute(
            'style', styled[r].getAttribute('style').split(url).join(dataUrl));
        }
      };

      var pending = externalUrls.length;
      var finishOne = function () {
        if (--pending === 0) rasterize();
      };
      externalUrls.forEach(function (url) {
        fetch(url, { mode: 'cors' })
          .then(function (resp) {
            if (!resp.ok) throw new Error('HTTP ' + resp.status);
            return resp.blob();
          })
          .then(function (blob) {
            return new Promise(function (resolve) {
              var reader = new FileReader();
              reader.onloadend = function () { resolve(reader.result); };
              reader.readAsDataURL(blob);
            });
          })
          .then(guard(function (dataUrl) {
            if (dataUrl) swapImage(url, dataUrl);
          }))
          .catch(function () { /* biarkan apa adanya */ })
          .then(finishOne, finishOne);
      });
    } catch (e) {
      sendToHost({ type: 'pngError',
        message: 'Ekspor PNG gagal: ' + (e && e.message ? e.message : e) });
    }
  }

  // Ekspor struktur halaman ke payload Figma (dipakai plugin companion dan
  // ekspor SVG yang bisa ditempel langsung di board Figma).
  // Menghasilkan tree node dengan bbox + computed style + teks per baris
  // (beserta baseline) + gambar + SVG inline, supaya hasil rekonstruksi
  // punya teks, gambar, dan frame yang bisa diedit.
  var __figmaStyleKeys = ['backgroundColor', 'color', 'fontSize', 'fontWeight',
    'fontFamily', 'lineHeight', 'letterSpacing', 'textAlign', 'borderRadius',
    'borderWidth', 'borderStyle', 'borderColor', 'opacity', 'display',
    'flexDirection', 'justifyContent', 'alignItems', 'gap', 'paddingTop',
    'paddingRight', 'paddingBottom', 'paddingLeft', 'boxShadow', 'overflow',
    'textTransform', 'visibility', 'position', 'zIndex', 'fontStyle',
    'textDecorationLine', 'objectFit', 'backgroundImage', 'whiteSpace'];

  function __figmaStyles(win, el) {
    var cs = win.getComputedStyle ? win.getComputedStyle(el) : null;
    var out = {};
    if (!cs) return out;
    for (var i = 0; i < __figmaStyleKeys.length; i++) {
      var k = __figmaStyleKeys[i];
      try { out[k] = cs[k] || ''; } catch (e) { out[k] = ''; }
    }
    return out;
  }

  function __figmaLabel(el, tag) {
    if (el.id) return tag + '#' + el.id;
    // Pada elemen SVG, `className` bukan string (SVGAnimatedString).
    var cls = el.getAttribute ? (el.getAttribute('class') || '').trim() : '';
    if (cls) return tag + '.' + cls.split(/\s+/)[0];
    return tag;
  }

  // Elemen yang secara visual tersembunyi (label sr-only, ikon terpotong,
  // teks yang digeser keluar layar) tidak ikut diekspor: kalau ikut, teksnya
  // akan menimpa elemen lain di Figma.
  function __figmaIsHidden(win, el, r) {
    var cs = win.getComputedStyle ? win.getComputedStyle(el) : null;
    if (!cs) return false;
    if (cs.display === 'none' || cs.visibility === 'hidden') return true;
    if (parseFloat(cs.opacity || '1') <= 0.001) return true;
    if (cs.clipPath && cs.clipPath !== 'none') return true;
    if (cs.clip && cs.clip !== 'auto') return true;
    if (parseFloat(cs.textIndent || '0') <= -100) return true;
    // Pola sr-only: 1x1 px + clip.
    if (r && r.width <= 1.01 && r.height <= 1.01) return true;
    return false;
  }

  // Metrik font (ascent/descent) dari canvas supaya posisi baseline teks
  // di SVG bisa pas dengan tampilan di browser.
  var __figmaCtx = null;
  function __figmaFontMetrics(win, el) {
    var cs = win.getComputedStyle ? win.getComputedStyle(el) : null;
    var size = cs ? (parseFloat(cs.fontSize) || 16) : 16;
    try {
      if (!__figmaCtx) {
        __figmaCtx = win.document.createElement('canvas').getContext('2d');
      }
      if (__figmaCtx) {
        __figmaCtx.font = (cs.fontStyle || 'normal') + ' ' +
          (cs.fontWeight || '400') + ' ' + size + 'px ' +
          (cs.fontFamily || 'sans-serif');
        var m = __figmaCtx.measureText('Hxg');
        var asc = m.fontBoundingBoxAscent || (size * 0.8);
        var desc = m.fontBoundingBoxDescent || (size * 0.2);
        if (asc > 0) return { asc: asc, desc: desc, size: size };
      }
    } catch (e) { /* pakai perkiraan */ }
    return { asc: size * 0.8, desc: size * 0.2, size: size };
  }

  // Terapkan `text-transform` CSS (isi DOM belum ikut berubah).
  function __figmaTransformText(text, transform) {
    if (!text || !transform) return text;
    var t = String(transform).toLowerCase();
    if (t === 'uppercase') return text.toUpperCase();
    if (t === 'lowercase') return text.toLowerCase();
    if (t === 'capitalize') {
      return text.replace(/(^|\s)(\S)/g, function (m, sp, ch) {
        return sp + ch.toUpperCase();
      });
    }
    return text;
  }

  // Teks langsung di dalam elemen, dipecah per baris visual beserta kotak
  // dan baseline-nya.
  function __figmaTextLines(win, el, sx, sy) {
    var lines = [];
    var kids = el.childNodes || [];
    var metrics = __figmaFontMetrics(win, el);
    var cs = win.getComputedStyle ? win.getComputedStyle(el) : null;
    var transform = cs ? (cs.textTransform || 'none') : 'none';
    for (var i = 0; i < kids.length; i++) {
      var node = kids[i];
      if (node.nodeType !== 3) continue;
      var raw = node.data || '';
      if (!raw.replace(/\s+/g, '')) continue;
      var range = el.ownerDocument.createRange();
      range.selectNodeContents(node);
      var rects = range.getClientRects();
      if (rects.length <= 1) {
        var r0 = rects.length ? rects[0] : el.getBoundingClientRect();
        var t0 = __figmaTransformText(raw.replace(/\s+/g, ' ').trim(), transform);
        if (t0) {
          lines.push({
            text: t0,
            x: r0.left + sx, y: r0.top + sy, w: r0.width, h: r0.height,
            baseline: r0.top + sy + (r0.height - (metrics.asc + metrics.desc)) / 2 + metrics.asc
          });
        }
        continue;
      }
      // Multi baris: pecah per karakter agar isi tiap baris akurat.
      var current = null;
      for (var c = 0; c < raw.length; c++) {
        var ch = raw.charAt(c);
        if (ch === '\n' || ch === '\r') {
          if (current) { lines.push(current); current = null; }
          continue;
        }
        var cr = el.ownerDocument.createRange();
        cr.setStart(node, c);
        cr.setEnd(node, c + 1);
        var cRects = cr.getClientRects();
        var rect = cRects.length ? cRects[0] : null;
        if (!rect || (rect.width === 0 && rect.height === 0)) {
          if (current && /\s/.test(ch)) current.text += ' ';
          continue;
        }
        if (!current || Math.abs(rect.top - current.y) > 1) {
          if (current) lines.push(current);
          current = {
            text: ch, x: rect.left + sx, y: rect.top + sy,
            w: rect.width, h: rect.height
          };
        } else {
          current.text += ch;
          var right = rect.left + rect.width;
          if (right - sx - current.x > current.w) {
            current.w = right - sx - current.x;
          }
        }
      }
      if (current) {
        current.baseline = current.y +
          (current.h - (metrics.asc + metrics.desc)) / 2 + metrics.asc;
        lines.push(current);
      }
      // Baseline untuk baris yang sudah terlanjurdidorong.
      for (var k = 0; k < lines.length; k++) {
        if (lines[k].baseline === undefined) {
          lines[k].baseline = lines[k].y +
            (lines[k].h - (metrics.asc + metrics.desc)) / 2 + metrics.asc;
        }
        lines[k].text = __figmaTransformText(lines[k].text, transform);
      }
    }
    return lines;
  }

  function __figmaImage(el) {
    var tag = el.tagName ? el.tagName.toLowerCase() : '';
    if (tag !== 'img') return null;
    var src = el.currentSrc || el.getAttribute('src') || '';
    if (!src) return null;
    return { src: src, fit: el.getAttribute('object-fit') || '' };
  }

  // Placeholder atau nilai pada input/textarea → text layer (di Figma
  // placeholder tidak ikut karena bukan text node).
  function __figmaFieldText(win, el, r) {
    var tag = el.tagName ? el.tagName.toLowerCase() : '';
    if (tag !== 'input' && tag !== 'textarea') return null;
    var value = '';
    try { value = el.value || ''; } catch (e) { value = ''; }
    if (!value) value = el.getAttribute('placeholder') || '';
    if (!value) return null;
    var cs = win.getComputedStyle ? win.getComputedStyle(el) : null;
    if (!cs) return null;
    var pcs = null;
    try { pcs = win.getComputedStyle(el, '::placeholder'); } catch (e) { pcs = null; }
    var size = parseFloat(cs.fontSize) || 14;
    var padLeft = parseFloat(cs.paddingLeft) || 0;
    var padTop = parseFloat(cs.paddingTop) || 0;
    var lh = parseFloat(cs.lineHeight);
    if (!lh || isNaN(lh)) lh = size * 1.2;
    var metrics = __figmaFontMetrics(win, el);
    return {
      text: value,
      x: r.left + padLeft,
      baseline: r.top + padTop + (lh - size) / 2 + metrics.asc,
      color: (pcs && pcs.color) || cs.color || '',
      fontSize: size,
      fontWeight: cs.fontWeight || '400',
      fontFamily: cs.fontFamily || ''
    };
  }

  // Warna terhitung dari sebuah elemen, ditulis sebagai atribut inline
  // supaya tidak bergantung CSS halaman (yang tidak ikut tersalin).
  function __figmaNormColor(value) {
    if (!value) return null;
    var m = /rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)(?:[,\s/]+([\d.]+))?\s*\)/
      .exec(value);
    if (!m) return { color: value, alpha: 1 };
    var ch = function (x) {
      var n = Math.round(parseFloat(x));
      return n < 0 ? 0 : (n > 255 ? 255 : n);
    };
    var hex = function (n) {
      var s = n.toString(16);
      return s.length < 2 ? '0' + s : s;
    };
    var alpha = m[4] === undefined ? 1 : parseFloat(m[4]);
    return {
      color: '#' + hex(ch(m[1])) + hex(ch(m[2])) + hex(ch(m[3])),
      alpha: isNaN(alpha) ? 1 : alpha
    };
  }

  function __figmaPaint(win, el) {
    if (!el || !el.nodeType) return null;
    var cs = win.getComputedStyle ? win.getComputedStyle(el) : null;
    if (!cs) return null;
    var ink = __figmaNormColor(cs.color || '');
    var inkHex = ink ? ink.color : '#000000';
    var inkAlpha = ink ? ink.alpha : 1;
    var out = {};
    var fill = __figmaNormColor(cs.fill);
    if (fill) {
      if (fill.color === 'currentcolor') {
        fill = { color: inkHex, alpha: inkAlpha };
      }
      out['fill'] = fill.color;
      if (fill.alpha < 1) out['fill-opacity'] = fill.alpha;
    }
    var stroke = __figmaNormColor(cs.stroke);
    if (stroke) {
      if (stroke.color === 'currentcolor') {
        stroke = { color: inkHex, alpha: inkAlpha };
      }
      out['stroke'] = stroke.color;
      if (stroke.alpha < 1) out['stroke-opacity'] = stroke.alpha;
    }
    var props = ['stroke-width', 'stroke-linecap', 'stroke-linejoin',
      'fill-rule', 'stroke-dasharray', 'opacity'];
    for (var i = 0; i < props.length; i++) {
      var v = cs[props[i]];
      if (!v || v === 'auto' || v === 'normal') continue;
      if (props[i] === 'stroke-dasharray' && v === 'none') continue;
      out[props[i]] = v;
    }
    return out;
  }

  function __figmaApplyPaint(paint, dst) {
    if (!paint || !dst) return;
    for (var key in paint) {
      if (!Object.prototype.hasOwnProperty.call(paint, key)) continue;
      try { dst.setAttribute(key, String(paint[key])); } catch (e) { /* abaikan */ }
    }
  }

  // Ikon sering memakai `<use href="#id">` ke simbol sprite di dokumen lain.
  // Isi simbolnya disalin langsung (lengkap dengan warnanya) supaya SVG
  // ekspor mandiri — Figma tidak mendukung referensi `<use>`.
  //
  // Warna diambil dari elemen `<use>` asli di dokumen (clone tidak punya
  // gaya terhitung karena tidak menempel ke DOM).
  function __figmaExpandUse(doc, win, root, srcRoot) {
    var uses = root.querySelectorAll('use');
    var srcUses = srcRoot ? srcRoot.querySelectorAll('use') : null;
    for (var i = 0; i < uses.length; i++) {
      var use = uses[i];
      var srcUse = (srcUses && srcUses[i]) ? srcUses[i] : use;
      var href = use.getAttribute('href') || use.getAttribute('xlink:href') || '';
      if (href.charAt(0) !== '#') continue;
      var target = doc.getElementById(href.substring(1));
      if (!target) continue;
      // Warna diambil dari elemen <use> (mewarisi gaya ikon di halaman),
      // bukan dari isi simbol yang tidak pernah dirender.
      var base = __figmaPaint(win, srcUse) || {};
      var clone = target.cloneNode(true);
      var group = doc.createElementNS('http://www.w3.org/2000/svg', 'g');
      var ux = parseFloat(use.getAttribute('x') || '0') || 0;
      var uy = parseFloat(use.getAttribute('y') || '0') || 0;
      if (ux || uy) {
        group.setAttribute('transform', 'translate(' + ux + ' ' + uy + ')');
      }
      // Salin dulu ke array: `children` itu live collection, jadi kalau
      // dipindah satu per satu, elemen berikutnya ikut hilang.
      var cloneKids = Array.prototype.slice.call(clone.children || []);
      for (var c = 0; c < cloneKids.length; c++) {
        var child = cloneKids[c];
        var paint = {};
        for (var k in base) {
          if (Object.prototype.hasOwnProperty.call(base, k)) paint[k] = base[k];
        }
        var own = ['fill', 'stroke', 'stroke-width', 'opacity', 'fill-opacity',
          'stroke-opacity', 'stroke-linecap', 'stroke-linejoin'];
        for (var o = 0; o < own.length; o++) {
          if (child.hasAttribute(own[o])) {
            paint[own[o]] = child.getAttribute(own[o]);
          }
        }
        __figmaApplyPaint(paint, child);
        group.appendChild(child);
      }
      if (use.parentNode) use.parentNode.replaceChild(group, use);
    }
  }

  // Warna bentuk di dalam SVG inline ikut ditulis ulang supaya tidak
  // bergantung CSS halaman.
  function __figmaPaintTree(win, src, dst) {
    if (!src || !dst) return;
    var srcKids = src.children || [];
    var dstKids = dst.children || [];
    for (var i = 0; i < dstKids.length; i++) {
      var tag = (dstKids[i].tagName || '').toLowerCase();
      if (tag === 'path' || tag === 'circle' || tag === 'ellipse' ||
          tag === 'rect' || tag === 'line' || tag === 'polygon' ||
          tag === 'polyline' || tag === 'text') {
        __figmaApplyPaint(__figmaPaint(win, srcKids[i]), dstKids[i]);
      }
      __figmaPaintTree(win, srcKids[i], dstKids[i]);
    }
  }

  function __figmaSvgMarkup(win, el) {
    try {
      var r = el.getBoundingClientRect();
      var clone = el.cloneNode(true);
      // Warna bentuk dulu (dari elemen asli yang benar-benar dirender),
      // baru `<use>`-expand: isi simbol mewarisi gaya elemen `<use>`.
      __figmaPaintTree(win, el, clone);
      __figmaExpandUse(el.ownerDocument, win, clone, el);

      // SVG inline dijadikan <g> + transform, bukan <svg> bersarang.
      // Figma mengimpor <svg> di dalam <svg> sebagai frame terpisah dengan
      // viewBox sendiri, sehingga ikon jadi terpotong dan bergeser.
      var doc = el.ownerDocument;
      var group = doc.createElementNS('http://www.w3.org/2000/svg', 'g');
      var cls = el.getAttribute('class') || '';
      if (cls) group.setAttribute('data-name', cls.split(/\s+/)[0]);
      var parts = (clone.getAttribute('viewBox') || '')
        .split(/[\s,]+/)
        .map(function (n) { return parseFloat(n); });
      if (parts.length === 4 && parts[2] > 0 && parts[3] > 0 &&
          r.width > 0.5 && r.height > 0.5) {
        var sx = r.width / parts[2];
        var sy = r.height / parts[3];
        var stretch = (clone.getAttribute('preserveAspectRatio') || '')
          .indexOf('none') === 0;
        var scale = stretch ? sx : Math.min(sx, sy);
        var tx = (r.width - parts[2] * scale) / 2;
        var ty = (r.height - parts[3] * scale) / 2;
        group.setAttribute(
          'transform',
          'translate(' + tx.toFixed(3) + ' ' + ty.toFixed(3) + ')' +
          ' scale(' + scale.toFixed(5) + ')' +
          ' translate(' + (-parts[0]).toFixed(3) + ' ' + (-parts[1]).toFixed(3) + ')'
        );
      }
      while (clone.firstChild) group.appendChild(clone.firstChild);
      return group.outerHTML || '';
    } catch (e) {
      return el.outerHTML || '';
    }
  }

  // Matriks transform sederhana (scale/translate/matrix) untuk menghitung
  // kotak pseudo-element setelah transform.
  function __figmaMatrix(transform) {
    if (!transform || transform === 'none') return null;
    var m = transform.match(/^matrix\(([^)]+)\)$/);
    if (m) {
      var v = m[1].split(',').map(function (n) { return parseFloat(n) || 0; });
      if (v.length >= 6) {
        return { a: v[0], b: v[1], c: v[2], d: v[3], e: v[4], f: v[5] };
      }
      return null;
    }
    var s = transform.match(/^scale\(([^)]+)\)$/);
    if (s) {
      var p = s[1].split(',').map(function (n) { return parseFloat(n) || 1; });
      return { a: p[0], b: 0, c: 0, d: p.length > 1 ? p[1] : p[0], e: 0, f: 0 };
    }
    return null;
  }

  // Pseudo-element dekoratif (`::before`/`::after` dengan konten kosong dan
  // border/background) → bentuk sederhana supaya dekorasi tidak hilang.
  function __figmaPseudoBox(win, el, which) {
    var cs = null;
    try { cs = win.getComputedStyle(el, which); } catch (e) { cs = null; }
    if (!cs) return null;
    var content = cs.content;
    if (!content || content === 'none') return null;
    if (content !== '""' && content !== "''") return null;
    if (cs.position !== 'absolute' && cs.position !== 'fixed') return null;
    var parent = el;
    var pcs = win.getComputedStyle(parent);
    var pr = parent.getBoundingClientRect();
    var borderLeft = parseFloat(pcs.borderLeftWidth) || 0;
    var borderTop = parseFloat(pcs.borderTopWidth) || 0;
    var left = parseFloat(cs.left);
    var top = parseFloat(cs.top);
    var width = parseFloat(cs.width);
    var height = parseFloat(cs.height);
    if (isNaN(left)) left = 0;
    if (isNaN(top)) top = 0;
    if (isNaN(width) || width <= 0) return null;
    if (isNaN(height) || height <= 0) return null;
    var x = pr.left + borderLeft + left;
    var y = pr.top + borderTop + top;
    var matrix = __figmaMatrix(cs.transform);
    if (matrix) {
      var cx = x + width / 2;
      var cy = y + height / 2;
      var pts = [[x, y], [x + width, y], [x, y + height], [x + width, y + height]];
      var mapped = pts.map(function (p) {
        return {
          x: cx + matrix.a * (p[0] - cx) + matrix.c * (p[1] - cy) + matrix.e,
          y: cy + matrix.b * (p[0] - cx) + matrix.d * (p[1] - cy) + matrix.f
        };
      });
      var xs = mapped.map(function (p) { return p.x; });
      var ys = mapped.map(function (p) { return p.y; });
      var minX = Math.min.apply(null, xs);
      var minY = Math.min.apply(null, ys);
      var maxX = Math.max.apply(null, xs);
      var maxY = Math.max.apply(null, ys);
      x = minX; y = minY; width = maxX - minX; height = maxY - minY;
    }
    return {
      x: x, y: y, w: width, h: height,
      fill: cs.backgroundColor || '',
      stroke: cs.borderTopColor || '',
      strokeWidth: parseFloat(cs.borderTopWidth) || 0,
      radius: cs.borderRadius || '0px'
    };
  }

  function __figmaNode(win, el, depth) {
    var tag = el.tagName ? el.tagName.toLowerCase() : 'element';
    var r = el.getBoundingClientRect();
    if (__figmaIsHidden(win, el, r)) return null;
    var sx = win.scrollX || 0;
    var sy = win.scrollY || 0;
    var children = [];
    var kids = el.children || [];
    for (var i = 0; i < kids.length; i++) {
      var child = kids[i];
      var ct = child.tagName ? child.tagName.toLowerCase() : '';
      if (ct === 'script' || ct === 'style' || ct === 'meta' ||
          ct === 'link' || ct === 'noscript' || ct === 'template') continue;
      // `<use>` sudah di-expand jadi path di dalam markup SVG induknya,
      // jadi tidak perlu layer sendiri (kosong) di Figma.
      if (ct === 'use') continue;
      if (child.getAttribute && child.getAttribute('data-centauri-overlay')) continue;
      var node = __figmaNode(win, child, depth + 1);
      if (node) children.push(node);
    }
    var text = '';
    var nodes = el.childNodes || [];
    for (var j = 0; j < nodes.length; j++) {
      if (nodes[j].nodeType === 3) {
        var t = nodes[j].data.replace(/\s+/g, ' ').trim();
        if (t) text += (text ? ' ' : '') + t;
      }
    }
    var pseudos = [];
    var before = __figmaPseudoBox(win, el, '::before');
    if (before) pseudos.push(before);
    var after = __figmaPseudoBox(win, el, '::after');
    if (after) pseudos.push(after);
    return {
      id: (el.getAttribute && el.getAttribute('data-centauri-id')) || '',
      tag: tag,
      name: __figmaLabel(el, tag),
      rect: { x: r.left + sx, y: r.top + sy, w: r.width, h: r.height },
      styles: __figmaStyles(win, el),
      text: text,
      textLines: __figmaTextLines(win, el, sx, sy),
      field: __figmaFieldText(win, el, r),
      image: __figmaImage(el),
      svg: tag === 'svg' ? __figmaSvgMarkup(win, el) : '',
      pseudos: pseudos,
      children: children
    };
  }

  // Kumpulkan payload dari sebuah dokumen (dokumen utama atau iframe).
  function __figmaCollect(win, doc) {
    var w = Math.max(doc.body ? (doc.body.scrollWidth || 0) : 0,
      doc.documentElement ? (doc.documentElement.scrollWidth || 0) : 0);
    var h = Math.max(doc.body ? (doc.body.scrollHeight || 0) : 0,
      doc.documentElement ? (doc.documentElement.scrollHeight || 0) : 0);
    var nodes = [];
    var kids = doc.body ? (doc.body.children || []) : [];
    for (var i = 0; i < kids.length; i++) {
      var el = kids[i];
      var t = el.tagName ? el.tagName.toLowerCase() : '';
      if (t === 'script' || t === 'style' || t === 'meta' ||
          t === 'link' || t === 'noscript') continue;
      if (el.getAttribute && el.getAttribute('data-centauri-overlay')) continue;
      var node = __figmaNode(win, el, 0);
      if (node) nodes.push(node);
    }
    var bodyBg = '';
    try {
      bodyBg = win.getComputedStyle(doc.body).backgroundColor || '';
    } catch (e) { bodyBg = ''; }
    var pageMeta = doc.querySelector('meta[name="centauri-page"]');
    return {
      app: 'centauri',
      format: 'centauri-figma',
      version: 1,
      page: {
        name: doc.title || '',
        slug: pageMeta ? (pageMeta.getAttribute('content') || '') : '',
        width: w,
        height: h,
        background: bodyBg
      },
      nodes: nodes
    };
  }

  // Render ulang halaman di iframe dengan lebar tertentu, supaya hasil ekspor
  // memakai layout desktop dan bukan ukuran pratinjau saat ini.
  function __figmaRenderAtWidth(width, height, done) {
    var html = '';
    try { html = document.documentElement.outerHTML; } catch (e) { html = ''; }
    // Bridge tidak ikut supaya tidak berjalan dua kali di iframe.
    html = html.replace(/<script id="centauri-bridge">[\s\S]*?<\/script>/g, '');
    var iframe = document.createElement('iframe');
    iframe.setAttribute('aria-hidden', 'true');
    iframe.setAttribute('tabindex', '-1');
    iframe.style.cssText = 'position:fixed;left:-20000px;top:0;width:' +
      width + 'px;height:' + (height || 1200) + 'px;border:0;visibility:hidden;';
    var finished = false;
    var cleanup = function () {
      if (finished) return;
      finished = true;
      try {
        if (iframe.parentNode) iframe.parentNode.removeChild(iframe);
      } catch (e) { /* abaikan */ }
    };
    var collect = function () {
      var idoc = iframe.contentDocument;
      var iwin = iframe.contentWindow;
      if (!idoc || !idoc.body || !idoc.body.children.length) return false;
      var payload = null;
      try { payload = __figmaCollect(iwin, idoc); } catch (e) { payload = null; }
      cleanup();
      done(payload);
      return true;
    };
    // `load` bisa terpicu untuk about:blank lebih dulu, jadi tunggu sampai
    // dokumen benar-benar berisi konten.
    var started = Date.now();
    var wait = function () {
      if (finished) return;
      var idoc = iframe.contentDocument;
      var iwin = iframe.contentWindow;
      if (idoc && idoc.body && idoc.body.children.length) {
        var ready = null;
        try {
          ready = (iwin.document.fonts && iwin.document.fonts.ready) ?
            iwin.document.fonts.ready : null;
        } catch (e) { ready = null; }
        if (ready && ready.then) {
          var guard = setTimeout(function () { collect(); }, 3000);
          ready.then(function () {
            clearTimeout(guard);
            setTimeout(function () { collect(); }, 150);
          }, function () { clearTimeout(guard); collect(); });
        } else {
          setTimeout(function () { collect(); }, 400);
        }
        return;
      }
      if (Date.now() - started > 8000) { cleanup(); done(null); return; }
      setTimeout(wait, 60);
    };
    try {
      document.body.appendChild(iframe);
      iframe.srcdoc = html;
      setTimeout(wait, 60);
    } catch (e) {
      cleanup();
      done(null);
    }
  }

  // Kirim payload ke host; gambar eksternal diubah jadi data URL supaya SVG
  // hasil ekspor mandiri (bisa ditempel di Figma tanpa akses jaringan).
  function __figmaSendPayload(payload) {
    var nodes = payload.nodes || [];
    var urls = {};
    var collect = function (node) {
      if (node.image && node.image.src && /^https?:/i.test(node.image.src)) {
        urls[node.image.src] = true;
      }
      var bg = node.styles ? (node.styles.backgroundImage || '') : '';
      var m = /url\(["']?([^"')]+)["']?\)/i.exec(bg || '');
      if (m && /^https?:/i.test(m[1])) urls[m[1]] = true;
      var kids2 = node.children || [];
      for (var c = 0; c < kids2.length; c++) collect(kids2[c]);
    };
    for (var u = 0; u < nodes.length; u++) collect(nodes[u]);

    var send = function (map) {
      if (map) {
        var apply = function (node) {
          if (node.image && map[node.image.src]) {
            node.image.src = map[node.image.src];
          }
          var kids3 = node.children || [];
          for (var c = 0; c < kids3.length; c++) apply(kids3[c]);
        };
        for (var a = 0; a < nodes.length; a++) apply(nodes[a]);
      }
      sendToHost({ type: 'figma', payload: payload });
    };

    var list = Object.keys(urls);
    if (!list.length) { send(null); return; }
    var map = {};
    var pending = list.length;
    var done = function () { if (--pending === 0) send(map); };
    list.forEach(function (url) {
      fetch(url, { mode: 'cors' })
        .then(function (resp) {
          if (!resp.ok) throw new Error('HTTP ' + resp.status);
          return resp.blob();
        })
        .then(function (blob) {
          return new Promise(function (resolve) {
            var reader = new FileReader();
            reader.onloadend = function () { resolve(reader.result); };
            reader.readAsDataURL(blob);
          });
        })
        .then(function (dataUrl) { if (dataUrl) map[url] = dataUrl; })
        .catch(function () { /* biarkan URL aslinya */ })
        .then(done, done);
    });
  }

  // Ekspor ke Figma. `width` = 0 → pakai ukuran pratinjau saat ini;
  // > 0 → render ulang halaman di iframe sebesar itu (layout desktop).
  function centauriExportFigma(width, height) {
    if (!document.body) {
      sendToHost({ type: 'figmaError', message: 'Dokumen belum siap.' });
      return;
    }
    var target = parseInt(width || '0', 10) || 0;
    if (target <= 0) {
      try {
        __figmaSendPayload(__figmaCollect(window, document));
      } catch (e) {
        sendToHost({ type: 'figmaError',
          message: 'Ekspor Figma gagal: ' + (e && e.message ? e.message : e) });
      }
      return;
    }
    __figmaRenderAtWidth(target, parseInt(height || '0', 10) || 0, function (payload) {
      if (!payload) {
        sendToHost({ type: 'figmaError',
          message: 'Render ulang pada lebar ' + target + 'px gagal.' });
        return;
      }
      try {
        __figmaSendPayload(payload);
      } catch (e) {
        sendToHost({ type: 'figmaError',
          message: 'Ekspor Figma gagal: ' + (e && e.message ? e.message : e) });
      }
    });
  }

  window.centauriSelect = centauriSelect;
  window.centauriHover = centauriHover;
  window.centauriInspect = centauriInspect;
  window.centauriApplyStyle = centauriApplyStyle;
  window.centauriMoveResize = centauriMoveResize;
  window.centauriGetSize = centauriGetSize;
  window.centauriAddNode = centauriAddNode;
  window.centauriSetText = centauriSetText;
  window.centauriDeleteNode = centauriDeleteNode;
  window.centauriGetHtml = centauriGetHtml;
  window.centauriGetOuterHtml = centauriGetOuterHtml;
  window.centauriExportPng = centauriExportPng;
  window.centauriExportFigma = centauriExportFigma;

  function boot() {
    if (document.body) {
      attachPicker();
    } else if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', attachPicker);
    } else {
      setTimeout(boot, 20);
    }
  }
  boot();
})();
''';

/// Menyuntikkan [canvasBridgeScript] ke dalam [html] sebagai `<script>`
/// tepat sebelum `</body>` (fallback: sebelum `</html>`, terakhir: append).
///
/// Script diberi id [_bridgeScriptId] agar bisa dibuang saat ekspor/sinkron.
String injectBridge(String html) {
  // Idempoten: dokumen yang sudah membawa bridge (mis. hasil render ulang)
  // dikembalikan apa adanya supaya listener tidak terpasang dua kali.
  if (html.contains('<script id="$_bridgeScriptId">')) return html;

  final injection =
      '<script id="$_bridgeScriptId">\n$canvasBridgeScript\n</script>\n';

  final lower = html.toLowerCase();
  final bodyClose = lower.lastIndexOf('</body>');
  if (bodyClose >= 0) {
    return '${html.substring(0, bodyClose)}$injection${html.substring(bodyClose)}';
  }
  final htmlClose = lower.lastIndexOf('</html>');
  if (htmlClose >= 0) {
    return '${html.substring(0, htmlClose)}$injection${html.substring(htmlClose)}';
  }
  return '$html\n$injection';
}

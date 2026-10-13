/// Jembatan JS Centauri yang di-inject LANGSUNG ke dokumen konten (tanpa
/// iframe). Berjalan di dokumen yang dirender AI sendiri, sehingga seleksi,
/// overlay, dan baca/tulis gaya selalu sinkron dengan HTML yang terlihat.
///
/// Alasan arsitektur: WebView2 memuat dokumen via `NavigateToString`
/// (origin `about:blank`). Memuat iframe `srcdoc` di dalamnya rapuh —
/// frame tampil kosong dan bridge mati tanpa error. Dengan meng-inject bridge
/// ke dokumen konten, `document` adalah dokumen konten itu sendiri.
///
/// Kontrak (anti-menyimpang, lihat docs/feature_map.md §7):
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

  var designWidth = 0;
  var overlay = null;
  var hoverBox = null;
  var selectBox = null;
  var selectedId = null;

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

  // Laporkan error JS apa pun ke Dart (hardening): agar kegagalan render
  // terlihat sebagai pesan, bukan frame putih tanpa penjelasan.
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

  function attachPicker() {
    if (!document.body) return;
    hideFrameScrollbars();
    ensureOverlay();
    ensureImageFallback();
    scheduleContentSizeReports();

    document.addEventListener('mouseover', function (e) {
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
      var id = idFromEvent(e);
      if (!id) return;
      e.preventDefault();
      e.stopPropagation();
      selectedId = id;
      placeBox(selectBox, rectOf(id));
      sendToHost({ type: 'select', id: id });
      setTimeout(function () { centauriInspect(id); }, 30);
    }, true);

    document.addEventListener('scroll', function () {
      refreshSelection();
    }, true);

    refreshSelection();
    // Beri tahu Dart bahwa dokumen siap (frame bisa dianggap ter-render).
    sendToHost({ type: 'ready' });
  }

  function refreshSelection() {
    if (selectedId) placeBox(selectBox, rectOf(selectedId));
  }

  // Ukur tinggi konten dokumen lalu laporkan ke Dart agar frame bisa
  // menyesuaikan tinggi (konten utuh, tanpa scrollbar).
  function reportContentSize() {
    try {
      var height = Math.max(
        document.body ? document.body.scrollHeight : 0,
        document.documentElement ? document.documentElement.scrollHeight : 0
      );
      if (height > 0) sendToHost({ type: 'resize', height: height });
    } catch (e) { /* abaikan */ }
  }

  // Laporkan tinggi konten beberapa kali (gambar/font memuat asinkron dapat
  // mengubah tinggi dokumen setelah load pertama).
  function scheduleContentSizeReports() {
    reportContentSize();
    var delays = [150, 400, 900, 1600];
    for (var i = 0; i < delays.length; i++) {
      setTimeout(function () { reportContentSize(); }, delays[i]);
    }
    try {
      var imgs = document.querySelectorAll('img');
      for (var j = 0; j < imgs.length; j++) {
        imgs[j].addEventListener('load', function () { reportContentSize(); });
      }
    } catch (e) { /* abaikan */ }
  }

  // Sembunyikan scrollbar dokumen yang dirender agar UI tampil bersih.
  function hideFrameScrollbars() {
    try {
      var style = document.getElementById('centauri-scroll-fix');
      if (!style) {
        style = document.createElement('style');
        style.id = 'centauri-scroll-fix';
        (document.head || document.documentElement).appendChild(style);
      }
      style.textContent =
        'html{overflow:hidden;}body{overflow:hidden;}' +
        '::-webkit-scrollbar{width:0;height:0;display:none;}' +
        '*{scrollbar-width:none;-ms-overflow-style:none;}';
    } catch (e) { /* abaikan */ }
  }

  // Jaring pengaman gambar: bila sebuah <img> gagal dimuat, ganti dengan
  // gradien lembut agar UI tidak menampilkan kotak rusak/kosong.
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
          img.addEventListener('error', function () {
            img.classList.add('centauri-fallback');
            img.removeAttribute('src');
          });
        })(imgs[i]);
      }
    } catch (e) { /* abaikan */ }
  }

  // Dipanggil dari Dart saat tree memilih / hover node.
  function centauriSelect(id) {
    selectedId = id;
    if (!id) { if (selectBox) selectBox.style.display = 'none'; return; }
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

  // Fase 1+2 — JS bridge metadata (HTML tetap source of truth).
  // Daftar props dibaca via getComputedStyle untuk inspector (Fase 2).
  // Selalu sertakan juga inline style bila computed kosong.
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
    // Inline style menang: lebih akurat untuk apa yang akan diedit inspector
    // (computed bisa normalisasi warna/font menjadi bentuk lain).
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
    // Jaga box seleksi tetap sinkron setelah inspect dari layers panel.
    placeBox(selectBox, { x: r.left, y: r.top, w: r.width, h: r.height });
    return payload;
  }

  // Satu-satunya jalur tulis Fase 1: set inline style, bukan scene graph.
  function centauriApplyStyle(id, patch) {
    if (!id || !patch) return false;
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return false;
    for (var k in patch) {
      try { el.style[k] = patch[k]; } catch (e) {}
    }
    placeBox(selectBox, rectOf(id));
    reportContentSize();
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
      // Move sebagai DELTA (aman untuk flow layout): left/top adalah offset
      // dari posisi normal, jadi tambah, jangan set absolut.
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
    reportContentSize();
    // Konfirmasi balik agar overlay native akurat.
    setTimeout(function () { centauriInspect(id); }, 60);
    return true;
  }

  // Lebar CSS desain (mis. 390px). Lebar ini FIXED dan tidak boleh berubah
  // saat board di-zoom: zoom hanya memperbesar/memperkecil tampilan, bukan
  // meng-reflow layout. Pada Windows, skala board ditangani oleh zoomFactor
  // WebView2, jadi dokumen selalu 100%. Pada mobile (tanpa zoomFactor native)
  // skala diterapkan lewat transform CSS di setZoom.
  function setViewport(width) {
    designWidth = width || 0;
    if (window.__centauriNativeZoom) return; // native zoom mengurus skala
    var el = document.documentElement;
    el.style.width = (width ? width + 'px' : '100%');
    el.style.maxWidth = (width ? width + 'px' : '100%');
  }

  function setZoom(factor) {
    if (window.__centauriNativeZoom) return; // native zoom mengurus skala
    // Fallback (mobile): skala via transform dari kiri atas.
    var el = document.documentElement;
    var f = factor || 1;
    el.style.transformOrigin = 'top left';
    el.style.transform = (f !== 1) ? 'scale(' + f + ')' : 'none';
  }

  // Ditandai host Windows yang memakai zoomFactor native WebView2.
  function centauriSetNativeZoom(enabled) {
    window.__centauriNativeZoom = !!enabled;
  }

  // Fase 4 — mutasi DOM untuk MCP bridge (external agent).
  // Semua tulis tetap inline di DOM; Dart sinkron ulang via centauriGetHtml.
  function __centauriQuery(id) {
    if (!id) return null;
    var el = document.querySelector('[data-centauri-id="' + id + '"]');
    return el ? el : null;
  }

  function __centauriSync() {
    placeBox(selectBox, selectedId ? rectOf(selectedId) : null);
    reportContentSize();
    return true;
  }

  function centauriAddNode(parentId, html, position) {
    if (!document.body || !html) return false;
    try {
      var parent = parentId
        ? document.querySelector('[data-centauri-id="' + parentId + '"]')
        : document.body;
      if (!parent) return false;
      // Stamp id unik sisi-JS untuk node baru (prefix m agar tak bentrok
      // dengan counter Dart n*); Dart me-rebuild tree dari HTML hasil.
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

  // Buang elemen internal (overlay seleksi + script bridge) sebelum HTML
  // dikirim/diekspor, agar tidak bocor ke hasil simpan.
  function __centauriCleanClone() {
    var clone = document.documentElement.cloneNode(true);
    var junk = clone.querySelectorAll('[data-centauri-overlay]');
    for (var i = 0; i < junk.length; i++) {
      if (junk[i].parentNode) junk[i].parentNode.removeChild(junk[i]);
    }
    var extras = ['#centauri-scroll-fix', '#centauri-img-fix', '#centauri-bridge'];
    for (var j = 0; j < extras.length; j++) {
      var node = clone.querySelector(extras[j]);
      if (node && node.parentNode) node.parentNode.removeChild(node);
    }
    return clone;
  }

  // Kirim HTML dokumen penuh (untuk sinkronisasi Dart pasca-mutasi).
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

  // Fase 3 — ekspor PNG dokumen via SVG foreignObject → canvas.
  // Gambar eksternal di-inline ke data URL dulu (fetch → blob) supaya canvas
  // tidak di-taint oleh sumber cross-origin (toDataURL SecurityError).
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
      // Batasi piksel agar tidak OOM pada dokumen sangat panjang.
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

      // Kumpulkan URL gambar eksternal (img src + background inline style).
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
          .catch(function () {
            // Gambar gagal di-inline (server tanpa CORS): biarkan apa adanya;
            // rasterize tetap dicoba dan pngError dilaporkan bila tainted.
          })
          .then(finishOne, finishOne);
      });
    } catch (e) {
      sendToHost({ type: 'pngError',
        message: 'Ekspor PNG gagal: ' + (e && e.message ? e.message : e) });
    }
  }

  // Ekspos API ke Dart (window.centauriXxx).
  window.centauriSelect = centauriSelect;
  window.centauriHover = centauriHover;
  window.centauriInspect = centauriInspect;
  window.centauriApplyStyle = centauriApplyStyle;
  window.centauriMoveResize = centauriMoveResize;
  window.centauriSetNativeZoom = centauriSetNativeZoom;
  window.centauriAddNode = centauriAddNode;
  window.centauriSetText = centauriSetText;
  window.centauriDeleteNode = centauriDeleteNode;
  window.centauriGetHtml = centauriGetHtml;
  window.centauriGetOuterHtml = centauriGetOuterHtml;
  window.centauriExportPng = centauriExportPng;
  window.setViewport = setViewport;
  window.setZoom = setZoom;
  window.clearCanvas = function () { /* tidak dipakai: Dart memuat HTML baru */ };
  window.renderCanvas = function () { /* tidak dipakai: Dart memuat HTML baru */ };

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
/// [nativeZoom] menandai shell bahwa skala ditangani zoomFactor native
/// (Windows), sehingga setViewport/setZoom tidak menerapkan transform CSS.
///
/// Script diberi id [_bridgeScriptId] agar bisa dibuang saat ekspor/sinkron.
String injectBridge(String html, {required bool nativeZoom}) {
  final buffer = StringBuffer()
    ..write('<script id="')
    ..write(_bridgeScriptId)
    ..write('">\n')
    ..write('window.__centauriNativeZoom = ')
    ..write(nativeZoom ? 'true' : 'false')
    ..write(';\n')
    ..write(canvasBridgeScript)
    ..write('\n</script>\n');
  final injection = buffer.toString();

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
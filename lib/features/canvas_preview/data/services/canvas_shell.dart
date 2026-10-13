/// Shell HTML statis yang dimuat satu kali ke WebView. Render canvas
/// dilakukan via `renderCanvas(html)` (iframe srcdoc) dan `setViewport(width)`
/// sehingga update UI tidak perlu reload halaman penuh (FR-03).
///
/// Shell juga menjadi jembatan seleksi antara layers tree (Dart) dan elemen
/// di dalam canvas:
///  - picker di-inject ke dokumen iframe setiap kali selesai load,
///  - hover/klik elemen dikirim ke Dart via `window.centauriSend`,
///  - Dart memanggil `window.centauriSelect(id)` / `window.centauriHover(id)`.
const String canvasShellHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Centauri Canvas</title>
<style>
  html, body {
    margin: 0;
    padding: 0;
    height: 100%;
    width: 100%;
    background: #FFFFFF;
    /* Tanpa scrollbar di shell: frame mengisi penuh area. */
    overflow: hidden;
  }
  #stage {
    height: 100%;
    transition: max-width 300ms cubic-bezier(0.16, 1, 0.3, 1);
  }
  #frame {
    width: 100%;
    height: 100%;
    border: 0;
    display: block;
    background: #FFFFFF;
    /* Sembunyikan scrollbar di dalam dokumen yang dirender. */
    overflow: hidden;
  }
  /* Sembunyikan scrollbar webkit di dalam frame. */
  ::-webkit-scrollbar { width: 0; height: 0; }
</style>
</head>
<body>
<div id="stage"><iframe id="frame" title="Centauri Canvas"></iframe></div>
<script>
  var frame = document.getElementById('frame');
  var stage = document.getElementById('stage');
  var designWidth = 0;
  var overlay = null;
  var hoverBox = null;
  var selectBox = null;
  var selectedId = null;

  function sendToHost(payload) {
    var json = JSON.stringify(payload);
    try {
      if (window.centauriBridge && window.centauriBridge.postMessage) {
        window.centauriBridge.postMessage(json);
        return;
      }
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(json);
        return;
      }
    } catch (e) { /* host bridge belum siap */ }
  }

  function frameDoc() {
    try { return frame.contentDocument || frame.contentWindow.document; }
    catch (e) { return null; }
  }

  function ensureOverlay(doc) {
    if (overlay && overlay.ownerDocument === doc) return;
    overlay = doc.createElement('div');
    overlay.setAttribute('data-centauri-overlay', '1');
    overlay.style.cssText = 'position:absolute;inset:0;pointer-events:none;z-index:2147483647';

    hoverBox = doc.createElement('div');
    hoverBox.style.cssText = 'position:absolute;border:1px solid rgba(78,161,255,0.9);' +
      'background:rgba(78,161,255,0.12);pointer-events:none;display:none;box-sizing:border-box';
    selectBox = doc.createElement('div');
    selectBox.style.cssText = 'position:absolute;border:1.5px solid rgb(0,120,212);' +
      'background:rgba(0,120,212,0.10);pointer-events:none;display:none;box-sizing:border-box';

    overlay.appendChild(hoverBox);
    overlay.appendChild(selectBox);
    doc.body.appendChild(overlay);
  }

  function rectOf(doc, id) {
    var el = doc && id ? doc.querySelector('[data-centauri-id="' + id + '"]') : null;
    if (!el) return null;
    var r = el.getBoundingClientRect();
    return { x: r.left, y: r.top, w: r.width, h: r.height };
  }

  function placeBox(box, rect, doc) {
    if (!box) return;
    if (!rect || rect.w <= 0 || rect.h <= 0) { box.style.display = 'none'; return; }
    var sx = (doc.defaultView && doc.defaultView.scrollX) || 0;
    var sy = (doc.defaultView && doc.defaultView.scrollY) || 0;
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
    var doc = frameDoc();
    if (!doc || !doc.body) return;
    hideFrameScrollbars(doc);
    ensureOverlay(doc);
    ensureImageFallback(doc);
    scheduleContentSizeReports(doc);

    doc.addEventListener('mouseover', function (e) {
      var id = idFromEvent(e);
      if (!id) return;
      placeBox(hoverBox, rectOf(doc, id), doc);
      sendToHost({ type: 'hover', id: id });
    }, true);

    doc.addEventListener('mouseout', function () {
      if (hoverBox) hoverBox.style.display = 'none';
      sendToHost({ type: 'hover', id: null });
    }, true);

    doc.addEventListener('click', function (e) {
      var id = idFromEvent(e);
      if (!id) return;
      e.preventDefault();
      e.stopPropagation();
      selectedId = id;
      placeBox(selectBox, rectOf(doc, id), doc);
      sendToHost({ type: 'select', id: id });
      setTimeout(function () { centauriInspect(id); }, 30);
    }, true);

    doc.addEventListener('scroll', function () {
      refreshSelection();
    }, true);

    refreshSelection();
  }

  function refreshSelection() {
    var doc = frameDoc();
    if (!doc) return;
    if (selectedId) placeBox(selectBox, rectOf(doc, selectedId), doc);
  }

  // Ukur tinggi konten dokumen lalu laporkan ke Dart agar frame bisa
  // menyesuaikan tinggi (konten utuh, tanpa scrollbar).
  function reportContentSize(doc) {
    try {
      var height = Math.max(
        doc.body.scrollHeight,
        doc.documentElement ? doc.documentElement.scrollHeight : 0
      );
      if (height > 0) sendToHost({ type: 'resize', height: height });
    } catch (e) { /* abaikan */ }
  }

  // Laporkan tinggi konten beberapa kali (gambar/font memuat asinkron dapat
  // mengubah tinggi dokumen setelah load pertama).
  function scheduleContentSizeReports(doc) {
    reportContentSize(doc);
    var delays = [150, 400, 900, 1600];
    for (var i = 0; i < delays.length; i++) {
      setTimeout(function () { reportContentSize(doc); }, delays[i]);
    }
    try {
      var imgs = doc.querySelectorAll('img');
      for (var j = 0; j < imgs.length; j++) {
        imgs[j].addEventListener('load', function () { reportContentSize(doc); });
      }
    } catch (e) { /* abaikan */ }
  }

  // Sembunyikan scrollbar dokumen yang dirender agar UI tampil bersih.
  function hideFrameScrollbars(doc) {
    try {
      var style = doc.getElementById('centauri-scroll-fix');
      if (!style) {
        style = doc.createElement('style');
        style.id = 'centauri-scroll-fix';
        doc.head.appendChild(style);
      }
      style.textContent =
        'html{overflow:hidden;}body{overflow:hidden;}' +
        '::-webkit-scrollbar{width:0;height:0;display:none;}' +
        '*{scrollbar-width:none;-ms-overflow-style:none;}';
    } catch (e) { /* abaikan */ }
  }

  // Jaring pengaman gambar: bila sebuah <img> gagal dimuat, ganti dengan
  // gradien lembut agar UI tidak menampilkan kotak rusak/kosong.
  function ensureImageFallback(doc) {
    try {
      if (doc.getElementById('centauri-img-fix')) return;
      var style = doc.createElement('style');
      style.id = 'centauri-img-fix';
      style.textContent =
        'img.centauri-fallback{background:linear-gradient(135deg,#6366F1,#8B5CF6,' +
        '#EC4899)!important;object-fit:cover!important;color:transparent;}';
      doc.head.appendChild(style);

      function attach(img) {
        if (img.dataset.centauriImg) return;
        img.dataset.centauriImg = '1';
        img.addEventListener('error', function () {
          img.classList.add('centauri-fallback');
          img.removeAttribute('src');
        });
      }
      var imgs = doc.querySelectorAll('img');
      for (var i = 0; i < imgs.length; i++) attach(imgs[i]);
    } catch (e) { /* abaikan */ }
  }

  function renderCanvas(html) {
    frame.srcdoc = html;
  }

  // Dipanggil dari Dart saat tree memilih / hover node.
  function centauriSelect(id) {
    var doc = frameDoc();
    if (!doc) return;
    selectedId = id;
    if (!id) { if (selectBox) selectBox.style.display = 'none'; return; }
    var el = doc.querySelector('[data-centauri-id="' + id + '"]');
    if (el && el.scrollIntoView) {
      el.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    }
    placeBox(selectBox, rectOf(doc, id), doc);
    setTimeout(function () { centauriInspect(id); }, 30);
  }

  function centauriHover(id) {
    var doc = frameDoc();
    if (!doc) return;
    if (!id) { if (hoverBox) hoverBox.style.display = 'none'; return; }
    placeBox(hoverBox, rectOf(doc, id), doc);
  }

  // Fase 1+2 — JS bridge metadata (HTML tetap source of truth).
  // id stabil dari Dart via data-centauri-id; JS tidak boleh generate id.
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
    var doc = frameDoc();
    if (!doc || !id) return null;
    var el = doc.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return null;
    var r = el.getBoundingClientRect();
    var cs = doc.defaultView ? doc.defaultView.getComputedStyle(el) : null;
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
      for (var i = 0; i < __centauriWatchedProps.length; i++) {
        var k = __centauriWatchedProps[i];
        var inline = el.style[k];
        if (inline !== undefined && inline !== null && inline !== '') {
          styles[k] = inline;
        }
      }
      // Sediakan juga cssText mentah untuk debugging.
      styles['cssText'] = el.style.cssText || '';
    } catch (e) {}
    var payload = { type: 'geometry', id: id,
      tag: el.tagName ? el.tagName.toLowerCase() : '',
      rect: { x: r.left, y: r.top, w: r.width, h: r.height },
      styles: styles };
    sendToHost(payload);
    // Jaga box seleksi tetap sinkron setelah inspect dari layers panel.
    placeBox(selectBox, { x: r.left, y: r.top, w: r.width, h: r.height }, doc);
    return payload;
  }

  // Satu-satunya jalur tulis Fase 1: set inline style, bukan scene graph.
  function centauriApplyStyle(id, patch) {
    var doc = frameDoc();
    if (!doc || !id || !patch) return false;
    var el = doc.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return false;
    for (var k in patch) {
      try { el.style[k] = patch[k]; } catch (e) {}
    }
    placeBox(selectBox, rectOf(doc, id), doc);
    reportContentSize(doc);
    return true;
  }

  function centauriMoveResize(id, box) {
    var doc = frameDoc();
    if (!doc || !id || !box) return false;
    var el = doc.querySelector('[data-centauri-id="' + id + '"]');
    if (!el) return false;
    try {
      var cs = doc.defaultView ? doc.defaultView.getComputedStyle(el) : null;
      var pos = cs ? cs.position : '';
      if (pos === 'static') el.style.position = 'relative';
      // Move sebagai DELTA (aman untuk flow layout): left/top adalah offset
      // dari posisi normal, jadi tambah, jangan set absolut.
      if (box.dx) {
        var cur = parseFloat(el.style.left) || 0;
        el.style.left = (cur + box.dx) + 'px';
      }
      if (box.dy) {
        var cur = parseFloat(el.style.top) || 0;
        el.style.top = (cur + box.dy) + 'px';
      }
      if (box.w !== undefined && box.w !== null) el.style.width = box.w + 'px';
      if (box.h !== undefined && box.h !== null) el.style.height = box.h + 'px';
    } catch (e) { return false; }
    placeBox(selectBox, rectOf(doc, id), doc);
    reportContentSize(doc);
    // Konfirmasi balik agar overlay native akurat.
    setTimeout(function () { centauriInspect(id); }, 60);
    return true;
  }

  // Lebar CSS desain (mis. 390px). Lebar ini FIXED dan tidak boleh berubah
  // saat board di-zoom: zoom hanya memperbesar/memperkecil tampilan, bukan
  // meng-reflow layout. Pada Windows, skala board ditangani oleh
  // zoomFactor WebView2, jadi shell selalu 100%. Pada mobile (tanpa zoomFactor
  // native) skala diterapkan lewat transform CSS di setZoom.
  function setViewport(width) {
    designWidth = width || 0;
    if (window.__centauriNativeZoom) {
      stage.style.width = '100%';
      stage.style.maxWidth = '100%';
    } else {
      // Jangan cap dengan max-width:100% — widget Flutter memang lebih kecil
      // dari lebar desain saat zoom-out (size*scale), dan transform scale()
      // yang akan mengecilkannya agar pas. Capping justru mengubah lebar CSS
      // (mis. 1280 -> 192) sehingga layout reflow dan terlihat "berubah".
      stage.style.width = (width ? width + 'px' : '100%');
      stage.style.maxWidth = (width ? width + 'px' : '100%');
    }
  }

  function setZoom(factor) {
    if (window.__centauriNativeZoom) {
      // Native zoom mengurus semuanya; shell tetap netral.
      stage.style.transform = 'none';
      return;
    }
    // Fallback (mobile): skala via transform dari kiri atas.
    var f = factor || 1;
    stage.style.transform = (f !== 1) ? 'scale(' + f + ')' : 'none';
    stage.style.transformOrigin = 'top left';
  }

  // Ditandai oleh host Windows yang memakai zoomFactor native WebView2.
  function centauriSetNativeZoom(enabled) {
    window.__centauriNativeZoom = !!enabled;
  }

  // Fase 4 — mutasi DOM untuk MCP bridge (external agent).
  // Semua tulis tetap inline di DOM; Dart sinkron ulang via centauriGetHtml.
  function __centauriQuery(id) {
    var doc = frameDoc();
    if (!doc || !id) return null;
    var el = doc.querySelector('[data-centauri-id="' + id + '"]');
    return el ? { doc: doc, el: el } : null;
  }

  function __centauriSync(reason) {
    var doc = frameDoc();
    if (!doc) return false;
    placeBox(selectBox, selectedId ? rectOf(doc, selectedId) : null, doc);
    reportContentSize(doc);
    return true;
  }

  function centauriAddNode(parentId, html, position) {
    var doc = frameDoc();
    if (!doc || !doc.body || !html) return false;
    try {
      var parent = parentId
        ? doc.querySelector('[data-centauri-id="' + parentId + '"]')
        : doc.body;
      if (!parent) return false;
      // Stamp id unik sisi-JS untuk node baru (prefix m agar tak bentrok
      // dengan counter Dart n*); Dart me-rebuild tree dari HTML hasil.
      var stamp = 'm' + Date.now().toString(36);
      var tpl = doc.createElement('template');
      tpl.innerHTML = html.trim();
      var added = null;
      var nodes = tpl.content.childNodes;
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].nodeType === 1) {
          nodes[i].setAttribute('data-centauri-id', stamp + '_' + i);
          if (!added) added = nodes[i];
        }
      }
      var pos = position || 'beforeend';
      parent.insertAdjacentHTML(pos, tpl.innerHTML);
      __centauriSync('add');
      if (added && added.scrollIntoView) {
        added.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      }
      return true;
    } catch (e) { return false; }
  }

  function centauriSetText(id, text) {
    var found = __centauriQuery(id);
    if (!found) return false;
    try {
      found.el.textContent = text;
      __centauriSync('text');
      return true;
    } catch (e) { return false; }
  }

  function centauriDeleteNode(id) {
    var found = __centauriQuery(id);
    if (!found) return false;
    try {
      if (selectedId === id) {
        selectedId = null;
        if (selectBox) selectBox.style.display = 'none';
        sendToHost({ type: 'select', id: null });
      }
      found.el.remove();
      __centauriSync('delete');
      return true;
    } catch (e) { return false; }
  }

  // Kirim HTML dokumen penuh (untuk sinkronisasi Dart pasca-mutasi).
  function centauriGetHtml() {
    var doc = frameDoc();
    if (!doc || !doc.documentElement) return null;
    try {
      var html = '<!DOCTYPE html>\n' + doc.documentElement.outerHTML;
      sendToHost({ type: 'html', html: html });
      return html;
    } catch (e) { return null; }
  }

  function centauriGetOuterHtml(id) {
    var found = __centauriQuery(id);
    if (!found) {
      sendToHost({ type: 'outerHtmlError', id: id });
      return null;
    }
    try {
      var payload = { type: 'outerHtml', id: id,
        tag: found.el.tagName ? found.el.tagName.toLowerCase() : '',
        html: found.el.outerHTML };
      sendToHost(payload);
      return payload.html;
    } catch (e) {
      sendToHost({ type: 'outerHtmlError', id: id });
      return null;
    }
  }

  // Fase 3 — ekspor PNG frame via SVG foreignObject → canvas.
  // Dijalankan di konteks shell agar bisa akses dokumen iframe.
  // Gambar eksternal (http) dapat menodai canvas (CORS) → kirim pngError.
  function centauriExportPng(pixelRatio) {
    var doc = frameDoc();
    if (!doc || !doc.documentElement) {
      sendToHost({ type: 'pngError', message: 'Dokumen frame belum siap.' });
      return;
    }
    try {
      var scale = pixelRatio || 2;
      if (scale < 1) scale = 1;
      if (scale > 3) scale = 3;
      var w = Math.max(doc.body ? doc.body.scrollWidth : 0,
        doc.documentElement.scrollWidth || 0);
      var h = Math.max(doc.body ? doc.body.scrollHeight : 0,
        doc.documentElement.scrollHeight || 0);
      if (!w || !h) {
        sendToHost({ type: 'pngError', message: 'Ukuran dokumen nol.' });
        return;
      }
      // Batasi piksel agar tidak OOM pada dokumen sangat panjang.
      var maxPixels = 4096 * 4096;
      while (w * scale * h * scale > maxPixels && scale > 1) scale -= 0.25;

      var serializer = new XMLSerializer();
      var clone = doc.documentElement.cloneNode(true);
      // Buang overlay seleksi internal agar tidak ikut tercetak.
      var overlays = clone.querySelectorAll('[data-centauri-overlay]');
      for (var i = 0; i < overlays.length; i++) {
        if (overlays[i].parentNode) overlays[i].parentNode.removeChild(overlays[i]);
      }
      var xhtml = serializer.serializeToString(clone);
      var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + w +
        '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">' +
        '<foreignObject width="100%" height="100%">' + xhtml +
        '</foreignObject></svg>';
      var blob = new Blob([svg], { type: 'image/svg+xml;charset=utf-8' });
      var url = URL.createObjectURL(blob);
      var img = new Image();
      img.onload = function () {
        try {
          var canvas = document.createElement('canvas');
          canvas.width = Math.round(w * scale);
          canvas.height = Math.round(h * scale);
          var ctx = canvas.getContext('2d');
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
          URL.revokeObjectURL(url);
          var dataUrl = canvas.toDataURL('image/png');
          sendToHost({ type: 'png', dataUrl: dataUrl });
        } catch (e) {
          URL.revokeObjectURL(url);
          sendToHost({ type: 'pngError',
            message: 'Gagal merender PNG (kemungkinan gambar eksternal memblokir ekspor).' });
        }
      };
      img.onerror = function () {
        URL.revokeObjectURL(url);
        sendToHost({ type: 'pngError', message: 'Gagal memuat SVG frame.' });
      };
      img.src = url;
    } catch (e) {
      sendToHost({ type: 'pngError',
        message: 'Ekspor PNG gagal: ' + (e && e.message ? e.message : e) });
    }
  }

  function clearCanvas() {
    selectedId = null;
    frame.srcdoc = '<!DOCTYPE html><html><body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:#FFFFFF;color:#9AA0A6;font-family:Inter,system-ui,sans-serif;font-size:13px">Frame kosong</body></html>';
  }

  frame.addEventListener('load', attachPicker);
</script>
</body>
</html>
''';

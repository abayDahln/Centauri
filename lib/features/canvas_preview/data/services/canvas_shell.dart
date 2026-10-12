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
  }

  function centauriHover(id) {
    var doc = frameDoc();
    if (!doc) return;
    if (!id) { if (hoverBox) hoverBox.style.display = 'none'; return; }
    placeBox(hoverBox, rectOf(doc, id), doc);
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

  function clearCanvas() {
    selectedId = null;
    frame.srcdoc = '<!DOCTYPE html><html><body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:#FFFFFF;color:#9AA0A6;font-family:Inter,system-ui,sans-serif;font-size:13px">Frame kosong</body></html>';
  }

  frame.addEventListener('load', attachPicker);
</script>
</body>
</html>
''';

/// Shell HTML statis yang dimuat satu kali ke WebView. Render canvas
/// dilakukan via `renderCanvas(html)` (iframe srcdoc) dan `setViewport(width)`
/// sehingga update UI tidak perlu reload halaman penuh (FR-03).
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
    background: #0F0F11;
    overflow: auto;
  }
  #stage {
    margin: 0 auto;
    height: 100%;
    transition: max-width 300ms cubic-bezier(0.16, 1, 0.3, 1);
  }
  #frame {
    width: 100%;
    height: 100%;
    border: 0;
    display: block;
    background: #FFFFFF;
  }
</style>
</head>
<body>
<div id="stage"><iframe id="frame" title="Centauri Canvas"></iframe></div>
<script>
  var frame = document.getElementById('frame');
  var stage = document.getElementById('stage');
  function renderCanvas(html) {
    frame.srcdoc = html;
  }
  function setViewport(width) {
    stage.style.maxWidth = width ? width + 'px' : '100%';
  }
  function clearCanvas() {
    frame.srcdoc = '<!DOCTYPE html><html><body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:#0F0F11;color:#52525B;font-family:Inter,sans-serif;font-size:14px">Canvas kosong</body></html>';
  }
</script>
</body>
</html>
''';

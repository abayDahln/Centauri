// Centauri Design Import — Figma plugin.
//
// Membaca payload JSON yang diekspor Centauri (menu Ekspor → "Figma (payload
// plugin)") lalu merekonstruksi frame/layer yang bisa diedit di Figma.
//
// Payload (skema `centauri-figma` v1):
//   {
//     app: "centauri", format: "centauri-figma", version: 1,
//     page: { name, slug, width, height },
//     nodes: [ { id, tag, name, rect:{x,y,w,h}, styles:{...}, text, children:[...] } ]
//   }
//
// Rekonstruksi:
//   - Satu root FRAME seukuran halaman.
//   - Tiap node → FRAME dengan posisi absolut (relatif parent), fill, radius,
//     stroke, dan opacity dari computed style.
//   - Node tanpa elemen anak tapi punya teks → TEXT layer di dalamnya.

figma.showUI(__html__, { width: 420, height: 460 });

var FONT = { family: 'Inter', style: 'Regular' };

function parseColor(value) {
  if (!value || typeof value !== 'string') return null;
  var m = value.match(/rgba?\(([^)]+)\)/i);
  if (!m) return null;
  var parts = m[1].split(',').map(function (p) { return parseFloat(p); });
  if (parts.length < 3) return null;
  var a = parts.length >= 4 ? parts[3] : 1;
  if (a <= 0.001) return null; // transparan → jangan beri fill
  return {
    color: {
      r: clamp01(parts[0] / 255),
      g: clamp01(parts[1] / 255),
      b: clamp01(parts[2] / 255)
    },
    opacity: clamp01(a)
  };
}

function clamp01(n) {
  if (isNaN(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

function px(value) {
  if (value === null || value === undefined) return 0;
  var n = parseFloat(String(value));
  return isNaN(n) ? 0 : n;
}

function num(value, fallback) {
  var n = px(value);
  return n === 0 && value !== 0 && value !== '0' ? fallback : n;
}

function makeSolid(rgb) {
  return [{ type: 'SOLID', color: rgb }];
}

async function buildText(parent, node, parentOrigin) {
  var rect = node.rect || {};
  var styles = node.styles || {};
  var text = await figma.createText();
  text.fontName = FONT;
  text.characters = node.text || '';
  var size = px(styles.fontSize);
  text.fontSize = size > 0 ? size : 14;
  var fill = parseColor(styles.color);
  if (fill) text.fills = makeSolid(fill.color);
  text.x = px(rect.x) - parentOrigin.x + px(styles.paddingLeft);
  text.y = px(rect.y) - parentOrigin.y + px(styles.paddingTop);
  text.textAutoResize = 'NONE';
  text.resize(Math.max(1, px(rect.w)), Math.max(1, px(rect.h)));
  parent.appendChild(text);
}

async function buildNode(node, parent, parentOrigin) {
  var rect = node.rect || {};
  var styles = node.styles || {};
  var origin = { x: px(rect.x), y: px(rect.y) };

  var frame = figma.createFrame();
  frame.name = node.name || node.tag || 'layer';
  frame.resize(Math.max(1, px(rect.w)), Math.max(1, px(rect.h)));
  frame.x = origin.x - parentOrigin.x;
  frame.y = origin.y - parentOrigin.y;
  frame.clipsContent = false;

  // Fill
  var bg = parseColor(styles.backgroundColor);
  frame.fills = bg ? makeSolid(bg.color) : [];
  if (bg && bg.opacity < 1) frame.opacity = bg.opacity;

  // Radius
  var radius = px(styles.borderRadius);
  if (radius > 0) frame.cornerRadius = radius;

  // Stroke
  var borderWidth = px(styles.borderWidth);
  var borderColor = parseColor(styles.borderColor);
  if (borderWidth > 0 && borderColor) {
    frame.strokes = makeSolid(borderColor.color);
    frame.strokeWeight = borderWidth;
  }

  var opacity = px(styles.opacity);
  if (opacity > 0 && opacity < 1) frame.opacity = opacity;

  parent.appendChild(frame);

  var children = node.children || [];
  var hasText = node.text && String(node.text).trim().length > 0;

  if (children.length === 0 && hasText) {
    await buildText(frame, node, origin);
  } else {
    for (var i = 0; i < children.length; i++) {
      await buildNode(children[i], frame, origin);
    }
    // Teks yang hidup berdampingan dengan anak elemen (mis. label + ikon).
    if (hasText) await buildText(frame, node, origin);
  }

  return frame;
}

async function buildFromPayload(payload) {
  if (!payload || payload.format !== 'centauri-figma') {
    throw new Error('Payload bukan format centauri-figma.');
  }
  var nodes = payload.nodes;
  if (!Array.isArray(nodes) || nodes.length === 0) {
    throw new Error('Payload tidak punya node untuk dibangun.');
  }

  await figma.loadFontAsync(FONT);

  var page = payload.page || {};
  var width = num(page.width, 1440) || 1440;
  var height = num(page.height, 2000) || 2000;

  var root = figma.createFrame();
  root.name = (page.name && String(page.name)) || 'Centauri Page';
  root.resize(width, height);
  root.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  root.clipsContent = false;
  root.x = 0;
  root.y = 0;

  var origin = { x: 0, y: 0 };
  for (var i = 0; i < nodes.length; i++) {
    await buildNode(nodes[i], root, origin);
  }

  figma.currentPage.selection = [root];
  figma.viewport.scrollAndZoomIntoView([root]);

  var total = countNodes(nodes);
  return { frameId: root.id, count: total, name: root.name };
}

function countNodes(nodes) {
  var total = 0;
  for (var i = 0; i < nodes.length; i++) {
    var n = nodes[i];
    total += 1;
    if (n && Array.isArray(n.children)) total += countNodes(n.children);
  }
  return total;
}

figma.ui.onmessage = async function (msg) {
  if (!msg || msg.type !== 'build') return;
  try {
    var parsed = typeof msg.payload === 'string'
      ? JSON.parse(msg.payload)
      : msg.payload;
    var result = await buildFromPayload(parsed);
    figma.ui.postMessage({
      type: 'done',
      count: result.count,
      name: result.name
    });
    figma.notify('Centauri: ' + result.count + ' layer dibuat.');
  } catch (e) {
    figma.ui.postMessage({
      type: 'error',
      message: (e && e.message) ? e.message : String(e)
    });
  }
};

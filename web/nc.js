// NebenCheck page scripts: the statement-import bridge and splash removal.
// Kept in an external file (not inline in index.html) so the site's
// Content-Security-Policy can enforce script-src 'self' without
// 'unsafe-inline'.
'use strict';

if (window.pdfjsLib) {
  window.pdfjsLib.GlobalWorkerOptions.workerSrc = 'vendor/pdfjs/pdf.worker.min.js';
}

// Self-hosted Tesseract paths: worker JS, wasm cores, and language data.
// Must be ABSOLUTE URLs: tesseract runs in a blob: worker, where relative
// URLs cannot be resolved (importScripts throws on them).
function ncAbs(p) { return new URL(p, document.baseURI).href; }
var NC_TESS_OPTS = {
  workerPath: ncAbs('vendor/tesseract/worker.min.js'),
  corePath: ncAbs('vendor/tesseract/core'),
  langPath: ncAbs('vendor/tessdata'),
};

function ncBuffer(file) {
  return new Promise(function (resolve, reject) {
    var r = new FileReader();
    r.onload = function () { resolve(r.result); };
    r.onerror = function () { reject(r.error); };
    r.readAsArrayBuffer(file);
  });
}
function ncText(file) {
  return new Promise(function (resolve) {
    var r = new FileReader();
    r.onload = function () { resolve(String(r.result || '')); };
    r.onerror = function () { resolve(''); };
    r.readAsText(file);
  });
}

// File -> plain text. The photo option (cameraOnly) accepts only images
// (OCR); the document option accepts only Word/PDF/text (embedded text,
// much more accurate than OCR). A file of the wrong kind for the chosen
// option is rejected. Returns "__WRONGTYPE__" when the kind doesn't match.
async function ncExtract(file, cameraOnly) {
  var name = (file.name || '').toLowerCase();
  var type = file.type || '';
  var isImage = type.indexOf('image/') === 0 ||
    /\.(jpe?g|png|gif|bmp|webp|heic|heif|tiff?)$/.test(name);
  var isPdf = type === 'application/pdf' || name.endsWith('.pdf');
  var isDocx = name.endsWith('.docx');
  var isDoc = name.endsWith('.doc');
  var isTxt = type === 'text/plain' || name.endsWith('.txt');
  try {
    if (cameraOnly) {
      if (!isImage) return '__WRONGTYPE__';
      if (typeof Tesseract === 'undefined') return '';
      var ocr = await Tesseract.recognize(file, 'deu', NC_TESS_OPTS);
      return (ocr && ocr.data && ocr.data.text) || '';
    }
    // Document option: no images allowed.
    if (isImage) return '__WRONGTYPE__';
    if (isDocx && typeof mammoth !== 'undefined') {
      var buf = await ncBuffer(file);
      var res = await mammoth.extractRawText({ arrayBuffer: buf });
      return (res && res.value) || '';
    }
    if (isPdf && window.pdfjsLib) {
      var buf2 = await ncBuffer(file);
      var pdf = await window.pdfjsLib.getDocument({
        data: buf2,
        isEvalSupported: false, // don't let a crafted PDF run eval
        disableAutoFetch: true,
        disableRange: true,
      }).promise;
      var out = '';
      for (var i = 1; i <= pdf.numPages; i++) {
        var page = await pdf.getPage(i);
        var tc = await page.getTextContent();
        out += tc.items.map(function (it) { return it.str; }).join(' ') + '\n';
      }
      return out;
    }
    if (isTxt || isDoc) return await ncText(file);
    return '__WRONGTYPE__';
  } catch (e) {
    return '';
  }
}

// Opens a picker and resolves with the extracted text ("" on cancel/fail).
// cameraOnly=true prefers the device camera and only accepts images.
window.ncPickAndExtract = function (cameraOnly) {
  return new Promise(function (resolve) {
    var input = document.createElement('input');
    input.type = 'file';
    if (cameraOnly) {
      input.accept = 'image/*';
      input.setAttribute('capture', 'environment');
    } else {
      input.accept = '.docx,.doc,.pdf,.txt';
    }
    // Mobile browsers (iOS Safari especially) only open the picker for an
    // input that is in the DOM AND within the viewport — an off-screen or
    // display:none input is silently ignored. So keep it on-screen but
    // effectively invisible: a 1px, fully transparent box in the corner.
    input.style.position = 'fixed';
    input.style.left = '0';
    input.style.top = '0';
    input.style.width = '1px';
    input.style.height = '1px';
    input.style.opacity = '0';
    input.style.border = '0';
    input.style.padding = '0';
    input.setAttribute('aria-hidden', 'true');
    input.setAttribute('tabindex', '-1');
    var done = false;
    function finish(text) {
      if (done) return;
      done = true;
      try { input.remove(); } catch (e) {}
      resolve(text);
    }
    input.onchange = function () {
      var file = input.files && input.files[0];
      if (!file) { finish(''); return; }
      ncExtract(file, cameraOnly).then(function (t) { finish(t || ''); }).catch(function () { finish(''); });
    };
    input.oncancel = function () { finish(''); };
    document.body.appendChild(input);
    input.click();
  });
};

// Remove the HTML splash once Flutter paints its first frame.
window.addEventListener('flutter-first-frame', function () {
  var s = document.getElementById('nc-splash');
  if (s) s.remove();
});

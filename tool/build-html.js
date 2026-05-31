#!/usr/bin/env node
/**
 * build-html.js
 * public/_sections/ 의 섹션 파일들을 조립해 public/index.html 을 생성합니다.
 *
 * 실행: node tool/build-html.js
 */

const fs = require("fs");
const path = require("path");

const SECTIONS_DIR = path.resolve(__dirname, "../public/_sections");
const OUTPUT = path.resolve(__dirname, "../public/index.html");

/** 섹션 파일을 UTF-8 로 읽어 반환 */
function read(file) {
  return fs.readFileSync(path.join(SECTIONS_DIR, file), "utf-8");
}

/** 조립 순서 — 변경 시 index.html 렌더링 순서가 바뀝니다 */
const BODY_SECTIONS = [
  "nav.html",
  "section-hero.html",
  "section-feature-01.html",
  "section-feature-02.html",
  "section-feature-03.html",
  "section-cta.html",
  "footer.html",
  "modal-download.html",
  "scripts.html",
];

const head = read("head.html");
const body = BODY_SECTIONS.map(read).join("\n");

const GENERATED_COMMENT =
  `<!-- ⚠️  이 파일은 자동 생성됩니다. 직접 수정하지 마세요.\n` +
  `     섹션 수정 → public/_sections/*.html 편집\n` +
  `     반영      → node tool/build-html.js\n` +
  `-->\n`;

const html =
  `<!doctype html>\n` +
  GENERATED_COMMENT +
  `<html lang="ko">\n` +
  `  <head>\n` +
  head +
  `  </head>\n` +
  `  <body class="font-sans">\n` +
  body +
  `  </body>\n` +
  `</html>\n`;

fs.writeFileSync(OUTPUT, html, "utf-8");
console.log("✅ public/index.html 생성 완료");

// Web/index.html から、描画に使っているシェーダ（GLSL）の文字列を取り出して JSON で出す
const fs = require('fs');
const html = fs.readFileSync(process.argv[2] || 'Web/index.html', 'utf8');
const a = html.indexOf('const VS = ');
const f = html.indexOf('const FS_F = ', a);
const z = html.indexOf('`;', f);
if (a < 0 || f < 0 || z < 0) { console.error('shader block not found'); process.exit(1); }
const src = html.slice(a, z + 2);
const out = new Function(src + '\nreturn { FS_H, FS_V, FS_F };')();
process.stdout.write(JSON.stringify(out));

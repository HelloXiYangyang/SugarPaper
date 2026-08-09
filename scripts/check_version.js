/*
 * 版本一致性校验：node scripts/check_version.js
 * 校验 web / app / updates / README 四处版本号必须一致，防止再次失同步。
 * 任一不一致则退出码非 0（可接入 CI）。
 */
'use strict';

const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const read = (p) => fs.readFileSync(path.join(root, p), 'utf8');

function extract(re, src) {
  const m = re.exec(src);
  return m ? m[1] : null;
}

const checks = [
  ['web/js/store.js', extract(/APP_VERSION\s*=\s*'([\d.]+)'/, read('web/js/store.js'))],
  ['web/sw.js', extract(/CACHE_NAME\s*=\s*'[^']*v([\d.]+)'/, read('web/sw.js'))],
  ['app/lib/data/store.dart', extract(/appVersion\s*=\s*'([\d.]+)'/, read('app/lib/data/store.dart'))],
  ['app/pubspec.yaml', extract(/version:\s*([\d.]+)\+/, read('app/pubspec.yaml'))],
  ['updates/latest.json', extract(/"version":\s*"([\d.]+)"/, read('updates/latest.json'))]
];

const readme = read('README.md');
const readmeV = extract(/当前版本：v([\d.]+)/, readme);
checks.push(['README.md', readmeV]);

const versions = checks.map(([, v]) => v);
const expected = versions[0];
let ok = expected != null;
let failed = [];

for (const [file, v] of checks) {
  if (v !== expected) {
    ok = false;
    failed.push(`${file}: ${v} != ${expected}`);
  }
}

if (ok) {
  console.log('OK: 全部版本一致 = v' + expected);
} else {
  console.error('FAIL: 版本不一致\n  ' + failed.join('\n  '));
}
process.exit(ok ? 0 : 1);

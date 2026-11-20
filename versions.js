// Prints the installed versions and what @expo/metro-config publishes for `./babel-core`.
const fs = require('fs');
const path = require('path');

const dir = (pkg) => path.dirname(require.resolve(`${pkg}/package.json`));
const version = (pkg) => require(`${pkg}/package.json`).version;
const metroConfig = dir('@expo/metro-config');
const firstLine = (file) => {
  const full = path.join(metroConfig, file);
  return fs.existsSync(full) ? fs.readFileSync(full, 'utf8').split(/\r?\n/)[0] : '(missing)';
};

console.log(
  ['expo', '@expo/metro-config', '@babel/core', '@types/babel__core', 'typescript']
    .map((pkg) => `${pkg} ${version(pkg)}`)
    .join(', '),
);
console.log(`  build/babel-core.js, line 1:   ${firstLine('build/babel-core.js')}`);
console.log(`  build/babel-core.d.ts, line 1: ${firstLine('build/babel-core.d.ts')}`);
console.log(
  `  build/ts-declarations/babel-core.d.ts: ${fs.existsSync(path.join(metroConfig, 'build/ts-declarations/babel-core.d.ts')) ? 'present' : 'missing'}`,
);
const runtime = typeof require('@babel/core').loadPartialConfigSync;
console.log(`  typeof require('@babel/core').loadPartialConfigSync: ${runtime}`);
process.exitCode = runtime === 'function' ? 0 : 1;

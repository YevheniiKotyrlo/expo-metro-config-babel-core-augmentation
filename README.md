# @expo/metro-config's published babel-core.d.ts drops its own augmentation

`@expo/metro-config` publishes `build/babel-core.d.ts`, which re-exports `loadPartialConfigSync` from `@babel/core`.
`@types/babel__core` 7.20.5 declares no `loadPartialConfigSync`, so the package carries its own declaration in `build/ts-declarations/babel-core.d.ts`.
`build/babel-core.js` starts with `/// <reference path="./ts-declarations/babel-core.d.ts" />`; `build/babel-core.d.ts` does not, so an app never loads that declaration.

This is SDK 58's `blank-typescript` template with `@types/babel__core` 7.20.5 and `transformer.ts`, which imports `ExpoBabelCaller` from `@expo/metro-config/babel-transformer`.
`tsconfig.transformer.json` type-checks it with `skipLibCheck: false`; `tsconfig.control.json` adds `build/ts-declarations/babel-core.d.ts` to the same program.

```sh
./repro.sh
```

It installs the app with npm, prints the versions and the first line of each published `babel-core` file, runs `npx expo-doctor@latest`, then `npx tsc -p tsconfig.transformer.json` and `npx tsc -p tsconfig.control.json`, and ends with one `SUMMARY` line.
It exits 1 while `transformer.ts` fails with TS2724 on `loadPartialConfigSync` alone and the control type-checks; 0 once `transformer.ts` type-checks; and 2 when a step fails or the result is neither.

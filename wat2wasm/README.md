- `wat2wasm.js` is from https://github.com/emilbayes/wat2wasm/index.js
- `libwabt.js` is from https://github.com/WebAssembly/wabt/blob/master/demo/libwabt.js

The `wat2wasm` package seems to be the only way of compiling a `.wat` file into a `.wasm` file without building a large C++ project (wabt) from source.
Unfortunately, the `libwabt.js` script in the `wat2wasm` package hasn't been updated in 10 months, so it's using an outdated assembler.
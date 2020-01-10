# WebAssembly

Project Repository:
https://github.com/zerovolts/wasm-explorations

A stack-based language

Primarily a binary format (`.wasm`)
`41 03 41 06 6A` // 3 + 6

There also exists a human-readable text format (`.wat`)

```wasm
i32.const 3     ;; [3]
i32.const 6     ;; [3, 6]
i32.add         ;; [9]
```

There are only 4 data types in the language (i32, i64, f32, f64), along with separate instructions for each variant.

```wasm
i32.const 42
f32.const 3.1415
```

Text format has an optional s-expression syntax for instructions, similar to Lisp dialects.

```clojure
(fn arg1 arg2 arg3)
```

```wasm
(i32.add
    (i32.const 3)
    (i32.const 6))
```

Function locals

```wasm
(func $f (param $x i32) (result i32)
    (local $y i32)
    (local.set $y (local.get $x))
    (local.get $y)
)
```

Memory is allocated in 64K blocks

```wasm
(memory 1)

;; store value 255 into memory location 0
(i32.store8
    (i32.const 0)
    (i32.const 255))

;; load value at memory location 0
(i32.load8_u
    (i32.const 0))
```

Loops are actually more like labels that you can jump back to

```wasm
;; infinite loop
(loop $inf_loop
    ;; do stuff
    (br $inf_loop))

;; not actually a loop at all
(loop $not_a_loop
    ;; do stuff)
```

# Conway's Game of Life

- 2D grid of cells that are either dead or alive (0 or 1)
- Each step is a pure function from the previous grid state
- For each cell, count the number of live neighbors and act accordingly:

<2 -> dies by underpopulation
4+ -> dies by overpopulation
2-3 & alive -> stay alive
3 & dead -> become alive by reproduction

;; imports from js
(import "dimensions" "width" (global $width i32))
(import "dimensions" "height" (global $height i32))

;; (65,536 * 1) bytes of memory
(memory (export "memory") 1)

;; buffer indices expected by utility functions
(global $mainbuffer i32 (i32.const 0))
(global $backbuffer i32 (i32.const 1))

;; generate the next frame and encode it into linear memory
(export "stepSimulation" (func $stepSimulation))
(func $stepSimulation
    (local $x i32)
    (local $y i32)

    (local.set $x (i32.const 0))
    (local.set $y (i32.const 0))

    (loop $loopY
        (loop $loopX
            (call $setGridByte
                (local.get $x)
                (local.get $y)
                (global.get $backbuffer)
                (call $stepCell
                    (local.get $x)
                    (local.get $y)))

            ;; continue looping while x > 255
            (br_if $loopX
                (i32.lt_u
                    ;; x++
                    (local.tee $x (i32.add (local.get $x) (i32.const 1)))
                    (global.get $height))))
        ;; reset x for next iteration
        (local.set $x (i32.const 0))
        ;; continue looping while y > 255
        (br_if $loopY
            (i32.lt_u
                ;; y++
                (local.tee $y (i32.add (local.get $y) (i32.const 1)))
                (global.get $width))))
                (call $swapBackBuffer))

(func $stepCell (param $x i32) (param $y i32) (result i32)
    (local $liveNeighbors i32)
    (local.set $liveNeighbors (call $getLiveNeighbors (local.get $x) (local.get $y)))
    ;; < 2 - dies by underpopulation
    ;; > 3 - dies by overpopulation
    ;; 2-3 - lives on
    ;; 3 - becomes live by reproduction
    (if
        (i32.eq (local.get $liveNeighbors) (i32.const 3))
        (then (return (i32.const 1))))
    (if
        (i32.eq (local.get $liveNeighbors) (i32.const 2))
        (then (return (call $getCell (local.get $x) (local.get $y)))))
    (return (i32.const 0))
)

(func $getLiveNeighbors (param $x i32) (param $y i32) (result i32)
    (call $getCell
        (i32.sub (local.get $x) (i32.const 1))
        (i32.sub (local.get $y) (i32.const 1)))
    (call $getCell
        (local.get $x)
        (i32.sub (local.get $y) (i32.const 1)))
    (call $getCell
        (i32.add (local.get $x) (i32.const 1))
        (i32.sub (local.get $y) (i32.const 1)))
    (call $getCell
        (i32.add (local.get $x) (i32.const 1))
        (local.get $y))
    (call $getCell
        (i32.add (local.get $x) (i32.const 1))
        (i32.add (local.get $y) (i32.const 1)))
    (call $getCell
        (local.get $x)
        (i32.add (local.get $y) (i32.const 1)))
    (call $getCell
        (i32.sub (local.get $x) (i32.const 1))
        (i32.add (local.get $y) (i32.const 1)))
    (call $getCell
        (i32.sub (local.get $x) (i32.const 1))
        (local.get $y))
    i32.add
    i32.add
    i32.add
    i32.add
    i32.add
    i32.add
    i32.add
)

(func $getCell (param $x i32) (param $y i32) (result i32)
    (if (result i32)
        (i32.and
            (call $inRange (i32.const 0) (global.get $width) (local.get $x))
            (call $inRange (i32.const 0) (global.get $height) (local.get $y)))
        (then (call $getGridByte (local.get $x) (local.get $y) (global.get $mainbuffer)))
        (else (i32.const 0))))

(func $inRange (param $min i32) (param $max i32) (param $value i32) (result i32)
    (i32.and
        (i32.ge_s (local.get $value) (local.get $min))
        (i32.lt_s (local.get $value) (local.get $max))))

;; ---- UTILITY FUNCTIONS ---- ;;

;; copy the entire content of the $backbuffer into the $mainbuffer.
(func $swapBackBuffer 
    (local $x i32)
    (local $y i32)

    (local.set $x (i32.const 0))
    (local.set $y (i32.const 0))

    (loop $loopY
        (loop $loopX
            ;; copy the backbuffer pixel at this coordinate into the main buffer
            (call $setGridByte
                (local.get $x)
                (local.get $y)
                (global.get $mainbuffer)
                (call $getGridByte
                    (local.get $x)
                    (local.get $y)
                    (global.get $backbuffer)))

            ;; continue looping while x > 255
            (br_if $loopX
                (i32.lt_u
                    ;; x++
                    (local.tee $x (i32.add (local.get $x) (i32.const 1)))
                    (global.get $height))))
        ;; reset x for next iteration
        (local.set $x (i32.const 0))
        ;; continue looping while y > 255
        (br_if $loopY
            (i32.lt_u
                ;; y++
                (local.tee $y (i32.add (local.get $y) (i32.const 1)))
                (global.get $width)))))

;; retrieves the byte stored at grid coordinate ($x, $y) in $buffer.
(func $getGridByte (param $x i32) (param $y i32) (param $buffer i32) (result i32)
    (i32.load8_u
        (call $coordToIndex
            (local.get $x)
            (local.get $y)
            (local.get $buffer))))

;; stores the given byte at grid coordinate ($x, $y) in $buffer.
(func $setGridByte (param $x i32) (param $y i32) (param $buffer i32) (param $byte i32)
    (i32.store8
        (call $coordToIndex
            (local.get $x)
            (local.get $y)
            (local.get $buffer))
        (local.get $byte)))

;; convert a 2d coordinate to an index into linear memory
;; (3, 4) -> 3 + (4 * width)
;; an offset of a multiple of (width * height) is added to allow selection of
;; various buffers
(func $coordToIndex (param $x i32) (param $y i32) (param $buffer i32) (result i32)
    (i32.add
        ;; calculate buffer offset
        (i32.mul
            (local.get $buffer)
            ;; buffer size
            (i32.mul
                (global.get $width)
                (global.get $height)))
        ;; calculate index from $x and $y
        (i32.add
            (local.get $x)
            (i32.mul
                (local.get $y)
                (global.get $width)))))

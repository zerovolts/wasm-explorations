(import "Math" "sqrt" (func $sqrt (param f32) (result f32)))

;; (65,536 * 4) bytes of memory
(memory (export "memory") 64)

(global $width i32 (i32.const 1024))
(global $height i32 (i32.const 1024))
(global $max_iter i32 (i32.const 32))

;; calculate all pixel data and encode it into linear memory
(func $render (result)
    (local $x i32)
    (local $y i32)
    (local $cx f32)
    (local $cy f32)
    (local $m i32)

    (local.set $x (i32.const 0))
    (local.set $y (i32.const 0))

    (loop $loopY
        (loop $loopX
            ;; convert pixel coordinates to graph coordinates
            (local.set $cx
                (call $camera (local.get $x)))
            (local.set $cy
                (call $camera (local.get $y)))
            ;; calculate the mandelbrot value of this point
            (local.set $m
                (i32.sub
                    (i32.const 255)
                    (call $denormalizeByte
                        (call $mandelbrot
                            (local.get $cx)
                            (local.get $cy)
                            (global.get $max_iter)))))
            ;; color this pixel based on the mandelbrot value
            (call $setPixel
                (local.get $x)
                (local.get $y)
                (call $color
                    (local.get $m)
                    (local.get $m)
                    (local.get $m)))
            ;; continue looping while x > 255
            (br_if $loopX
                (i32.lt_u
                    ;; x++
                    (local.tee $x (call $inc (local.get $x)))
                    (global.get $height))))
        ;; reset x for next iteration
        (local.set $x (i32.const 0))
        ;; continue looping while y > 255
        (br_if $loopY
            (i32.lt_u
                ;; y++
                (local.tee $y (call $inc (local.get $y)))
                (global.get $width)))))

(func $camera (param $xy i32) (result f32)
    (f32.mul
        (f32.sub
            (call $normalize (local.get $xy))
            (f32.const 0.5))
        (f32.const 4)))

;; set the given pixel position to an rgba color (encoded as an i32)
(func $setPixel (param $x i32) (param $y i32) (param $color i32)
    (i32.store
        (i32.mul
            (i32.const 4)
            (call $coordToIndex
                (local.get $x)
                (local.get $y)))
        (local.get $color)))

;; convert a 2d coordinate to an index into linear memory
(func $coordToIndex (param $x i32) (param $y i32) (result i32)
    (i32.add
        (local.get $x)
        (i32.mul
            (local.get $y)
            (global.get $width))))

;; 0..255 -> 0.0..1.0
(func $normalize (param $byte i32) (result f32)
    (f32.div
        (f32.convert_i32_u (local.get $byte))
        (f32.convert_i32_u (global.get $width))))

;; 0..255 -> 0.0..1.0
(func $normalizeByte (param $byte i32) (result f32)
    (f32.div
        (f32.convert_i32_u (local.get $byte))
        (f32.const 255)))

;; 0.0..1.0 -> 0..255
(func $denormalizeByte (param $f f32) (result i32)
    (i32.trunc_f32_u
        (f32.mul
            (local.get $f)
            (f32.const 255))))

;; get the mandelbrot value of a given graph coordinate and max number of iterations
(func $mandelbrot (param $cx f32) (param $cy f32) (param $iter i32) (result f32)
    (local $tempZx f32)
    (local $zx f32)
    (local $zy f32)
    (local $i i32)

    (local.set $zx (f32.const 0))
    (local.set $zy (f32.const 0))
    (local.set $i (i32.const 0))

    (loop $loop
        ;; z = z^2 + c
        (local.set $tempZx
            (f32.add
                (call $complexSqX
                    (local.get $zx)
                    (local.get $zy))
                (local.get $cx)))
        (local.set $zy
            (f32.add
                (call $complexSqY
                    (local.get $zx)
                    (local.get $zy))
                (local.get $cy)))
        (local.set $zx (local.get $tempZx))
        ;; early return if z escapes past 2, meaning it's definitely not in the mandelbrot set
        (if
            (f32.gt
                (call $vectorLength
                    (local.get $zx)
                    (local.get $zy))
                (f32.const 2))
            (then
                ;; return 0.0..1.0 based on how many iterations it takes for the number to escape past 2
                (return
                    (f32.div
                        (f32.convert_i32_u (local.get $i))
                        (f32.convert_i32_u (local.get $iter))))))
        ;; continue looping while i < iter
        (br_if $loop
            (i32.lt_u
                ;; i++
                (local.tee $i (call $inc (local.get $i)))
                (local.get $iter))))
    ;; we consider this point to be in the mandelbrot set because the iteration max was exceeded
    (f32.const 1))

(func $inc (param $i i32) (result i32)
    (i32.add (local.get $i) (i32.const 1)))

;; get the x-component result of squaring a complex number
(func $complexSqX (param $cx f32) (param $cy f32) (result f32)
    (f32.sub
        (f32.mul
            (local.get $cx)
            (local.get $cx))
        (f32.mul
            (local.get $cy)
            (local.get $cy))))

;; get the y-component result of squaring a complex number
(func $complexSqY (param $cx f32) (param $cy f32) (result f32)
    (f32.add
        (f32.mul
            (local.get $cx)
            (local.get $cy))
        (f32.mul
            (local.get $cx)
            (local.get $cy))))

;; sqrt(x^2 + y^2)
(func $vectorLength (param $vx f32) (param $vy f32) (result f32)
    (call $sqrt
        (f32.add
            (f32.mul
                (local.get $vx)
                (local.get $vx))
            (f32.mul
                (local.get $vy)
                (local.get $vy)))))

;; encode an rgb value into an i32 (alpha is always 255)
(func $color (param $red i32) (param $green i32) (param $blue i32) (result i32)
    (i32.or
        (i32.shl
            (i32.and
                (local.get $red)
                (i32.const 0x000000ff))
            (i32.const 24))
        (i32.or
            (i32.shl
                (i32.and
                    (local.get $green)
                    (i32.const 0x000000ff))
                (i32.const 16))
            (i32.or
                (i32.shl
                    (i32.and
                        (local.get $blue)
                        (i32.const 0x000000ff))
                    (i32.const 8))
                (i32.const 0x000000ff)))))

(export "render" (func $render))
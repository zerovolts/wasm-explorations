fetch('/fractal/fractal.wasm').then(response =>
    response.arrayBuffer()
).then(bytes => WebAssembly.instantiate(bytes, { Math })).then(({ module, instance }) => {
    const canvas = document.getElementById("canvas");
    instance.exports.render();
    const ctx = canvas.getContext("2d");
    const membuf = instance.exports.memory.buffer;
    const view = new DataView(membuf);

    const arr = new Uint8ClampedArray(1024 * 1024 * 4);
    for (let x = 0; x < canvas.width; x++) {
        for (let y = 0; y < canvas.height; y++) {
            const i = (x + y * canvas.width) * 4;
            // reversed as wasm is little-endian
            arr[i] = view.getUint8(i + 3);
            arr[i + 1] = view.getUint8(i + 2);
            arr[i + 2] = view.getUint8(i + 1);
            arr[i + 3] = view.getUint8(i);
        }
    }

    const imageData = new ImageData(arr, canvas.width, canvas.height);
    ctx.putImageData(imageData, 0, 0);
}).catch(console.error);

const mandelbrot = (c, iter) => {
    let z = [0, 0];
    for (let i = 0; i < iter; i++) {
        z = complexAdd(complexMul(z, z), c)
        if (complexLength(z) > 2) return i / iter;
    }
    return 1;
}

const complexMul = (c1, c2) =>
    [(c1[0] * c2[0]) - (c1[1] * c2[1]), (c1[0] * c2[1]) + (c1[1] * c2[0])]

const complexAdd = (c1, c2) =>
    [c1[0] + c2[0], c1[1] + c2[1]]

const complexLength = (c) =>
    Math.sqrt(c[0] * c[0] + c[1] * c[1])
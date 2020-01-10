const dimensions = {
    width: canvas.width,
    height: canvas.height
}
const fps = 30;
const frameMillis = 1000 / fps;

fetch('/life/life.wasm').then(response =>
    response.arrayBuffer()
).then(bytes => WebAssembly.instantiate(bytes, { Math, dimensions })).then(({ module, instance }) => {
    const canvas = document.getElementById("canvas");
    const ctx = canvas.getContext("2d");
    const membuf = instance.exports.memory.buffer;
    const dataview = new DataView(membuf);

    randomizeCells(dataview);
    render(ctx, dataview);

    setInterval(() => {
        instance.exports.stepSimulation();
        render(ctx, dataview);
    }, frameMillis);

}).catch(console.error);

const randomizeCells = (dataview) => {
    for (let x = 0; x < canvas.width; x++) {
        for (let y = 0; y < canvas.height; y++) {
            const lifeIndex = (x + y * canvas.width);
            const randBit = Math.round(Math.random());
            dataview.setUint8(lifeIndex, randBit);
        }
    }
}

const render = (ctx, dataview) => {
    // 4 color components for each pixel
    const pixelArray = new Uint8ClampedArray(canvas.width * canvas.height * 4);

    for (let x = 0; x < canvas.width; x++) {
        for (let y = 0; y < canvas.height; y++) {
            const lifeIndex = (x + y * canvas.width);
            // invert and scale value so that 0 is white and 1 is black
            const lifeValue = (1 - dataview.getUint8(lifeIndex)) * 255;
            const pixelIndex = lifeIndex * 4;
            pixelArray[pixelIndex] = lifeValue;
            pixelArray[pixelIndex + 1] = lifeValue;
            pixelArray[pixelIndex + 2] = lifeValue;
            pixelArray[pixelIndex + 3] = 255;
        }
    }

    const imageData = new ImageData(pixelArray, canvas.width, canvas.height);
    ctx.putImageData(imageData, 0, 0);
}
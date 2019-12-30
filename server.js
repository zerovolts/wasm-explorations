const express = require('express');
const app = express();
const port = 3000;

app.use(express.static('static'));

app.get('/fractal', (req, res) =>
    res.send(path.join(`${__dirname}/fractal/index.html`))
);

app.listen(port, () => console.log(`Listening on port ${port}`));
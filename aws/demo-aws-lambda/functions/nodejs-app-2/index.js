
const express = require('express');
const serverless = require('serverless-http');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello Express nodejs app 2 ! version 2026');
});

exports.handler = serverless(app);

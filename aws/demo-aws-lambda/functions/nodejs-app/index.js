
const express = require('express');
const serverless = require('serverless-http');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello Express version 6! version 2026');
});

exports.handler = serverless(app);

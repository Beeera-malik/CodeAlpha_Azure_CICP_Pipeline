const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>CodeAlpha Azure CI/CD Demo</title></head>
      <body style="font-family: sans-serif; padding: 40px;">
        <h1>🚀 CodeAlpha DevOps Task 1</h1>
        <p>This app was built by an Azure Pipeline, pushed to Azure Container Registry,
           and deployed to Azure App Service automatically.</p>
        <p><strong>Version:</strong> ${process.env.APP_VERSION || 'local-dev'}</p>
        <p>Health check: <a href="/health">/health</a></p>
      </body>
    </html>
  `);
});

// Used by App Service / monitoring to confirm the container is healthy
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', uptime: process.uptime() });
});

app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});

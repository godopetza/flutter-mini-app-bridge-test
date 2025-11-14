const express = require('express');
const path = require('path');

const app = express();
const PORT = 3000;

// Serve static files from public directory
app.use(express.static('public'));

// Main route serving the host app page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'mini-app-bridge-test host app',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Host app running on http://localhost:${PORT}`);
  console.log('📱 This simulates a bank app hosting the Flutter mini app via WebView/iframe');
  console.log('🔗 The JavaScript bridge enables communication between host and mini app');
  console.log('');
  console.log('Available routes:');
  console.log(`  📄 http://localhost:${PORT}     - Host app with embedded Flutter mini app`);
  console.log(`  ❤️  http://localhost:${PORT}/health - Health check`);
  console.log('');
  console.log('💡 Open your browser and navigate to the host app to test the bridge!');
});
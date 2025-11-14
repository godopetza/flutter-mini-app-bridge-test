const fs = require('fs');
const path = require('path');

// Build script to convert Express app to static files for deployment
console.log('🔧 Building static host app for deployment...');

// Create build directory
const buildDir = path.join(__dirname, 'build');
if (fs.existsSync(buildDir)) {
    fs.rmSync(buildDir, { recursive: true, force: true });
}
fs.mkdirSync(buildDir, { recursive: true });

// Read the original index.html
const indexPath = path.join(__dirname, 'public', 'index.html');
let indexContent = fs.readFileSync(indexPath, 'utf8');

// Environment-specific replacements for production
const isProduction = process.env.NODE_ENV === 'production';
const flutterUrl = process.env.FLUTTER_URL || 'http://localhost:8081';
const backendUrl = process.env.BACKEND_URL || (isProduction ? 'https://flutter-mini-app-bridge-test-production.up.railway.app' : 'http://localhost:8080');

if (isProduction) {
    console.log('🌍 Building for production environment');
    console.log(`📱 Flutter URL: ${flutterUrl}`);
    console.log(`🔧 Backend URL: ${backendUrl}`);

    // Replace URLs in the HTML
    indexContent = indexContent.replace(/http:\/\/localhost:8081/g, flutterUrl);
    indexContent = indexContent.replace(/http:\/\/localhost:8080/g, backendUrl);

    // Add production configuration script
    const productionScript = `
    <script>
        // Production environment configuration
        window.isProduction = true;
        window.config = {
            flutterAppUrl: '${flutterUrl}',
            backendApiUrl: '${backendUrl}',
            environment: 'production'
        };
        console.log('🚀 Host App running in production mode');
        console.log('📱 Flutter Mini App URL:', window.config.flutterAppUrl);
        console.log('🔧 Backend API URL:', window.config.backendApiUrl);
    </script>
    `;

    // Insert before closing body tag
    indexContent = indexContent.replace('</body>', productionScript + '\n</body>');
} else {
    console.log('🏠 Building for development environment');
}

// Write the processed index.html
fs.writeFileSync(path.join(buildDir, 'index.html'), indexContent);

console.log('✅ Static build completed successfully!');
console.log(`📁 Build output: ${buildDir}`);
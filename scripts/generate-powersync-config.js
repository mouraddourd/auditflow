// PowerSync configuration with env var substitution via Node.js
// Usage: node scripts/generate-powersync-config.js [dev|prod]

const fs = require('fs');
const path = require('path');

const env = process.argv[2] || 'dev';
const templateFile = 'powersync.template.yaml';
const outputFile = env === 'prod' ? 'powersync.prod.yaml' : 'powersync.yaml';

console.log(`Generating ${env} PowerSync config...`);

// Read .env file
if (!fs.existsSync('.env')) {
    console.error('Error: .env file not found');
    process.exit(1);
}

const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};

envContent.split('\n').forEach(line => {
    line = line.trim();
    if (line && !line.startsWith('#')) {
        const match = line.match(/^([^=]+)=(.*)$/);
        if (match) {
            let key = match[1].trim();
            let value = match[2].trim();
            // Remove quotes
            value = value.replace(/^["']|["']$/g, '');
            envVars[key] = value;
        }
    }
});

// Read template
const template = fs.readFileSync(templateFile, 'utf8');

// Replace variables
let content = template;
Object.keys(envVars).forEach(key => {
    const regex = new RegExp('\\$\\{' + key + '\\}', 'g');
    content = content.replace(regex, envVars[key]);
});

// Write output
fs.writeFileSync(outputFile, content, 'utf8');

console.log(`✅ Config generated: ${outputFile}`);
console.log('');
console.log('Preview (first 10 lines):');
console.log(content.split('\n').slice(0, 10).join('\n'));

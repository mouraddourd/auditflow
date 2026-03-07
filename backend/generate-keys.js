const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const keysDir = path.join(__dirname, 'keys');

// Ensure keys directory exists
if (!fs.existsSync(keysDir)) {
  fs.mkdirSync(keysDir, { recursive: true });
}

// Generate RSA key pair
const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: {
    type: 'spki',
    format: 'pem'
  },
  privateKeyEncoding: {
    type: 'pkcs8',
    format: 'pem'
  }
});

// Save keys
fs.writeFileSync(path.join(keysDir, 'private.pem'), privateKey);
fs.writeFileSync(path.join(keysDir, 'public.pem'), publicKey);

// Output public key for env var (single line)
const publicKeySingleLine = publicKey.replace(/\n/g, '\\n');

console.log('✅ Keys generated in backend/keys/');
console.log('\n=== Add to docker-compose.dev.yml ===');
console.log('POWERSYNC_PUBLIC_KEY: |');
publicKey.split('\n').forEach(line => {
  if (line) console.log(`      ${line}`);
});

console.log('\n=== Or add to .env ===');
console.log(`POWERSYNC_PUBLIC_KEY="${publicKeySingleLine}"`);

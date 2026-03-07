const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const publicKeyPem = fs.readFileSync(path.join(__dirname, 'keys/public.pem'), 'utf8');

// Create key object
const publicKey = crypto.createPublicKey(publicKeyPem);

// Export as JWK
const jwk = publicKey.export({ format: 'jwk' });

console.log('=== JWK Format for powersync.yaml ===');
console.log(JSON.stringify(jwk, null, 2));

console.log('\n=== YAML Format ===');
console.log(`client_auth:
  jwks:
    keys:
      - kty: ${jwk.kty}
        alg: RS256
        n: ${jwk.n}
        e: ${jwk.e}`);

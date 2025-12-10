// src/script/signNonce.ts
import { ethers } from 'ethers';

async function main() {
  // Ganti dengan private key dari akun Anvil
  const PRIVATE_KEY =
    '0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a';

  // Ganti dengan nonce yang didapat dari requestNonce API
  const nonce = 566413;
  const message = `Login nonce: ${nonce}`;

  // Buat wallet dari private key
  const wallet = new ethers.Wallet(PRIVATE_KEY);

  // Sign message
  const signature = await wallet.signMessage(message);

  console.log('Message:', message);
  console.log('Signature:', signature);
}

// Jalankan main
main().catch((err) => {
  console.error('Error signing nonce:', err);
});

const crypto = require('crypto');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// Persistent storage for dynamically registered devices
const DEVICES_FILE = path.join(__dirname, '../data/devices.json');

// Ensure data directory exists
const dataDir = path.join(__dirname, '../data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Generate valid Curve25519 WireGuard keypair
function generateKeyPair() {
  const { privateKey, publicKey } = crypto.generateKeyPairSync('x25519', {
    publicKeyEncoding: { type: 'spki', format: 'der' },
    privateKeyEncoding: { type: 'pkcs8', format: 'der' },
  });

  return {
    privateKey: privateKey.subarray(-32).toString('base64'),
    publicKey: publicKey.subarray(-32).toString('base64'),
  };
}

// Load devices database
function loadDevices() {
  if (fs.existsSync(DEVICES_FILE)) {
    try {
      return JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf-8'));
    } catch {
      return {};
    }
  }
  return {};
}

// Save devices database
function saveDevices(devices) {
  fs.writeFileSync(DEVICES_FILE, JSON.stringify(devices, null, 2), 'utf-8');
}

// Fully dynamic IP allocator (Subnet: 10.66.0.0/16, supports up to 65,534 users)
function allocateNextIp(devices) {
  const assignedIps = new Set(Object.values(devices).map((d) => d.clientIp));
  
  // Start from 10.66.0.2 up to 10.66.255.254
  for (let subnet = 0; subnet <= 255; subnet++) {
    for (let host = 2; host <= 254; host++) {
      const candidateIp = `10.66.${subnet}.${host}`;
      if (!assignedIps.has(candidateIp)) {
        return candidateIp;
      }
    }
  }
  throw new Error('IP address pool is completely full (65,000+ users limit reached)');
}

// Automatically add peer to the WireGuard server in real time
function syncPeerToWireguard(clientPublicKey, clientIp) {
  const isLinux = process.platform === 'linux';
  const wgInterface = process.env.WG_INTERFACE || 'wg0';

  if (!isLinux) {
    console.log(`[DEV MODE] Skipping wg command on non-Linux OS. Dynamically allocated Peer: ${clientPublicKey} -> ${clientIp}`);
    return;
  }

  // 1. Instantly register peer with live kernel interface (takes ~5ms, no restart required)
  const cmd = `wg set ${wgInterface} peer ${clientPublicKey} allowed-ips ${clientIp}/32`;
  exec(cmd, (error, stdout, stderr) => {
    if (error) {
      console.warn(`[WireGuard] Warning executing '${cmd}':`, stderr || error.message);
    } else {
      console.log(`[WireGuard] ✅ Live peer registered in kernel: ${clientPublicKey} (${clientIp})`);
    }
  });

  // 2. Persist to /etc/wireguard/wg0.conf so it survives server reboots
  const confPath = `/etc/wireguard/${wgInterface}.conf`;
  if (fs.existsSync(confPath)) {
    try {
      const peerBlock = `\n[Peer]\n# Auto-assigned on ${new Date().toISOString()}\nPublicKey = ${clientPublicKey}\nAllowedIPs = ${clientIp}/32\n`;
      fs.appendFileSync(confPath, peerBlock, 'utf-8');
    } catch (err) {
      console.warn(`[WireGuard] Could not append to ${confPath}:`, err.message);
    }
  }
}

/**
 * 100% On-Demand & Dynamic Configuration Generator
 * Automatically creates new WireGuard keys and IP for any new device (1, 50, 500, or 10,000 users)
 */
function getOrCreateConfig({ deviceId, serverConfig }) {
  const devices = loadDevices();
  let device = devices[deviceId];

  // If this device has connected before, return its existing configuration
  if (!device) {
    console.log(`🆕 New user/device detected: ${deviceId}. Generating on-demand WireGuard credentials...`);

    const keys = generateKeyPair();
    const clientIp = allocateNextIp(devices);

    device = {
      deviceId,
      clientIp,
      privateKey: keys.privateKey,
      publicKey: keys.publicKey,
      createdAt: new Date().toISOString(),
      lastSeen: new Date().toISOString(),
    };

    devices[deviceId] = device;
    saveDevices(devices);

    // Register with server in real time
    syncPeerToWireguard(device.publicKey, device.clientIp);
  } else {
    // Update last seen timestamp
    device.lastSeen = new Date().toISOString();
    devices[deviceId] = device;
    saveDevices(devices);

    // Re-verify peer is registered in kernel (e.g. after server reboot)
    syncPeerToWireguard(device.publicKey, device.clientIp);
  }

  const dns = serverConfig.dns || '1.1.1.1, 8.8.8.8';
  const endpoint = `${serverConfig.host}:${serverConfig.port}`;
  const serverPublicKey = serverConfig.publicKey;

  const wgQuickConfig = `[Interface]
PrivateKey = ${device.privateKey}
Address = ${device.clientIp}/32
DNS = ${dns}

[Peer]
PublicKey = ${serverPublicKey}
Endpoint = ${endpoint}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
`;

  return {
    deviceId,
    clientIp: device.clientIp,
    clientPublicKey: device.publicKey,
    serverPublicKey,
    endpoint,
    dns,
    wgQuickConfig,
    isExistingUser: Boolean(devices[deviceId]),
  };
}

module.exports = {
  generateKeyPair,
  getOrCreateConfig,
  loadDevices,
};

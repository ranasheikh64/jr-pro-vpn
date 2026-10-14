require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { getOrCreateConfig, loadDevices } = require('./wireguard');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// List of available VPN locations
// The default active server will use the real environment variables configured in .env
function getAvailableServers() {
  const primaryHost = process.env.WG_SERVER_HOST || '127.0.0.1';
  const primaryPort = process.env.WG_SERVER_PORT || '51820';
  const primaryPublicKey = process.env.WG_SERVER_PUBLIC_KEY || 'REPLACE_WITH_YOUR_SERVER_PUBLIC_KEY';
  const primaryDns = process.env.WG_DNS || '1.1.1.1, 8.8.8.8';

  return [
    {
      id: 'us-central',
      country: 'United States',
      city: 'Iowa / Central',
      countryCode: 'US',
      flag: '🇺🇸',
      host: primaryHost,
      port: primaryPort,
      publicKey: primaryPublicKey,
      dns: primaryDns,
      ping: '45 ms',
      status: 'optimal',
      load: '28%',
      isDefault: true,
    },
    {
      id: 'de-frankfurt',
      country: 'Germany',
      city: 'Frankfurt',
      countryCode: 'DE',
      flag: '🇩🇪',
      host: process.env.WG_DE_HOST || primaryHost,
      port: primaryPort,
      publicKey: process.env.WG_DE_PUBLIC_KEY || primaryPublicKey,
      dns: primaryDns,
      ping: '110 ms',
      status: 'online',
      load: '42%',
      isDefault: false,
    },
    {
      id: 'sg-singapore',
      country: 'Singapore',
      city: 'Jurong',
      countryCode: 'SG',
      flag: '🇸🇬',
      host: process.env.WG_SG_HOST || primaryHost,
      port: primaryPort,
      publicKey: process.env.WG_SG_PUBLIC_KEY || primaryPublicKey,
      dns: primaryDns,
      ping: '38 ms',
      status: 'optimal',
      load: '35%',
      isDefault: false,
    },
    {
      id: 'uk-london',
      country: 'United Kingdom',
      city: 'London',
      countryCode: 'GB',
      flag: '🇬🇧',
      host: process.env.WG_UK_HOST || primaryHost,
      port: primaryPort,
      publicKey: process.env.WG_UK_PUBLIC_KEY || primaryPublicKey,
      dns: primaryDns,
      ping: '125 ms',
      status: 'online',
      load: '50%',
      isDefault: false,
    },
    {
      id: 'jp-tokyo',
      country: 'Japan',
      city: 'Tokyo',
      countryCode: 'JP',
      flag: '🇯🇵',
      host: process.env.WG_JP_HOST || primaryHost,
      port: primaryPort,
      publicKey: process.env.WG_JP_PUBLIC_KEY || primaryPublicKey,
      dns: primaryDns,
      ping: '95 ms',
      status: 'online',
      load: '60%',
      isDefault: false,
    },
  ];
}

// 1. Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    appName: 'JRonix VPN Backend',
    timestamp: new Date().toISOString(),
  });
});

// 2. Get list of all available VPN servers / countries
app.get('/api/servers', (req, res) => {
  const servers = getAvailableServers().map((s) => ({
    
    id: s.id,
    country: s.country,
    city: s.city,
    countryCode: s.countryCode,
    flag: s.flag,
    ping: s.ping,
    status: s.status,
    load: s.load,
    isDefault: s.isDefault,
  }));

  res.json({
    success: true,
    count: servers.length,
    servers,
  });
});

// 3. Request WireGuard config for a specific device and server
app.post('/api/vpn/config', (req, res) => {
  try {
    const { deviceId, serverId } = req.body;

    if (!deviceId) {
      return res.status(400).json({
        success: false,
        message: 'deviceId is required for anonymous config generation',
      });
    }

    const servers = getAvailableServers();
    const targetServer = servers.find((s) => s.id === serverId) || servers[0];

    const configData = getOrCreateConfig({
      deviceId,
      serverConfig: targetServer,
    });

    res.json({
      success: true,
      server: {
        id: targetServer.id,
        country: targetServer.country,
        flag: targetServer.flag,
        endpoint: configData.endpoint,
      },
      clientIp: configData.clientIp,
      wgQuickConfig: configData.wgQuickConfig,
    });
  } catch (error) {
    console.error('Error generating VPN config:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Internal server error while generating VPN config',
    });
  }
});

// 4. View active peer allocations (for admin/monitoring)
app.get('/api/peers', (req, res) => {
  const devices = loadDevices();
  res.json({
    totalUsers: Object.keys(devices).length,
    users: Object.values(devices).map((d) => ({
      deviceId: d.deviceId,
      clientIp: d.clientIp,
      publicKey: d.publicKey,
      createdAt: d.createdAt,
      lastSeen: d.lastSeen,
    })),
  });
});

// Start Express server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 JRonix VPN Backend running on http://0.0.0.0:${PORT}`);
  console.log(`📡 Endpoints:`);
  console.log(`   - GET  /api/health`);
  console.log(`   - GET  /api/servers`);
  console.log(`   - POST /api/vpn/config`);
  console.log(`   - GET  /api/peers`);
});

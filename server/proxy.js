const http = require('http');
const https = require('https');

const PORT = process.env.PORT || 3000;
const TARGET_HOST = 'bernard100.app.n8n.cloud';
const TARGET_BASE = '/';

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    });
    res.end();
    return;
  }

  const pathname = req.url || '/';
  const url = new URL(pathname, 'http://localhost');
  const route = url.pathname;

  if (route === '/health') {
    sendJson(res, 200, { ok: true, service: 'apollo-cors-proxy' });
    return;
  }

  const routeMap = {
    '/api/auth': '/webhook/apollo-auth',
    '/api/booking-update': '/webhook/apollo-booking-update',
    '/api/booking-status': '/webhook/apollo-booking-status',
    '/api/booking-list': '/webhook/apollo-booking-list',
    '/api/consultation-booked': '/webhook/consultation-booked',
  };

  const targetPath = routeMap[route];
  if (!targetPath) {
    sendJson(res, 404, { ok: false, error: 'Unknown proxy route' });
    return;
  }

  const chunks = [];
  req.on('data', (chunk) => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const options = {
      hostname: TARGET_HOST,
      port: 443,
      path: `${TARGET_BASE}${targetPath.replace(/^\//, '')}`,
      method: req.method,
      headers: {
        ...req.headers,
        host: TARGET_HOST,
        'Content-Length': body.length,
        'Content-Type': req.headers['content-type'] || 'application/json',
      },
    };

    const proxyReq = https.request(options, (proxyRes) => {
      const responseChunks = [];
      proxyRes.on('data', (chunk) => responseChunks.push(chunk));
      proxyRes.on('end', () => {
        const buffer = Buffer.concat(responseChunks);
        res.writeHead(proxyRes.statusCode || 502, {
          'Content-Type': proxyRes.headers['content-type'] || 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Cache-Control': 'no-store',
        });
        res.end(buffer);
      });
    });

    proxyReq.on('error', (err) => {
      sendJson(res, 502, { ok: false, error: `Proxy error: ${err.message}` });
    });

    if (body.length > 0) {
      proxyReq.write(body);
    }
    proxyReq.end();
  });
});

server.listen(PORT, () => {
  console.log(`CORS proxy listening on http://localhost:${PORT}`);
});

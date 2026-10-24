// Serve the release build locally: node tool/serve.cjs
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../build/web');
const port = Number(process.env.PORT || 5174);
const types = {'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm',
  '.json':'application/json','.png':'image/png','.m4a':'audio/mp4','.otf':'font/otf','.ttf':'font/ttf'};
http.createServer((req, res) => {
  const target = path.resolve(root, '.' + decodeURIComponent((req.url || '/').split('?')[0]));
  if (!target.startsWith(root + path.sep) && target !== root) {
    res.writeHead(403); return res.end();
  }
  const file = target === root ? path.join(root, 'index.html') : target;
  fs.readFile(file, (error, data) => {
    if (error) {res.writeHead(404); res.end(); return;}
    res.writeHead(200, {'Content-Type':types[path.extname(file)] || 'application/octet-stream'});
    res.end(data);
  });
}).listen(port, '127.0.0.1', () => console.log(`KidBook: http://127.0.0.1:${port}`));

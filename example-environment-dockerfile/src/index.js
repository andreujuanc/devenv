const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');

const port = Number(process.env.PORT || 8000);
const host = process.env.HOST || '0.0.0.0';
const htmlPath = path.join(__dirname, '..', 'public', 'index.html');

const server = http.createServer((request, response) => {
	if (request.url !== '/' && request.url !== '/index.html') {
		response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
		response.end('Not found');
		return;
	}

	const html = fs.readFileSync(htmlPath, 'utf8');
	response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
	response.end(html);
});

server.listen(port, host, () => {
	console.log(`Serving example page on http://${host}:${port}`);
});
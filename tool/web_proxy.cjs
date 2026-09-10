'use strict';
// Development-only relay. Binds loopback and accepts only the local preview origin.
const http = require('http'), https = require('https');
const port = Number(process.env.SORNAZ_PROXY_PORT || 8081);
const front = Number(process.env.SORNAZ_WEB_PORT || 8080);
const allowed = new Set([`http://localhost:${front}`, `http://127.0.0.1:${front}`]);
const local = `http://localhost:${port}`;
http.createServer((req,res) => {
  const origin = req.headers.origin;
  if (!['localhost','127.0.0.1'].includes((req.headers.host || '').split(':')[0]) || (origin && !allowed.has(origin))) {
    res.writeHead(403); res.end('Local preview only'); return;
  }
  if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Vary','Origin');
  res.setHeader('Access-Control-Allow-Credentials','true');
  res.setHeader('Access-Control-Allow-Headers','authorization,content-type,accept,accept-language,range,x-requested-with');
  res.setHeader('Access-Control-Allow-Methods','GET,HEAD,POST,PUT,PATCH,DELETE,OPTIONS');
  res.setHeader('Access-Control-Expose-Headers','Content-Length,Content-Range,Accept-Ranges');
  res.setHeader('Cache-Control','no-store');
  if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
  if (req.url === '/__health') { res.end('sornaz-preview-proxy'); return; }
  if (!req.url.startsWith('/') || req.url.startsWith('//') || (!['GET','HEAD'].includes(req.method) && !req.url.startsWith('/api/sornaz/v1/'))) {
    res.writeHead(403); res.end(); return;
  }
  const headers = {accept: req.headers.accept || '*/*', 'accept-encoding':'identity'};
  for (const key of ['authorization','content-type','content-length','accept-language','range','x-requested-with','cookie']) if(req.headers[key]) headers[key]=req.headers[key];
  const upstream = https.request({hostname:'sornaz.com', port:443, path:req.url, method:req.method, headers}, response => {
    const type = response.headers['content-type'] || 'application/octet-stream';
    res.statusCode=response.statusCode;
    res.setHeader('Content-Type',type);
    if(response.headers['set-cookie']) res.setHeader('Set-Cookie',response.headers['set-cookie'].map(cookie=>cookie.replace(/;\s*Domain=[^;]+/ig,'').replace(/;\s*Secure/ig,'')));
    for(const key of ['content-range','accept-ranges','content-disposition']) if(response.headers[key])res.setHeader(key,response.headers[key]);
    if(response.headers.location) res.setHeader('Location',response.headers.location.replace(/^https?:\/\/(www\.)?sornaz\.com/,local));
    if(type.includes('application/json')) {
      const chunks=[]; let length=0;
      response.on('data',chunk=>{length+=chunk.length;if(length>32*1024*1024)response.destroy();else chunks.push(chunk);});
      response.on('end',()=>res.end(Buffer.concat(chunks).toString('utf8').replace(/https?:\/\/(?:www\.)?sornaz\.com/g,local)));
    } else response.pipe(res);
    response.on('error',()=>res.destroy());
  });
  upstream.setTimeout(45000,()=>upstream.destroy(Error('Upstream timeout')));
  upstream.on('error',()=>{if(!res.headersSent)res.writeHead(502,{'Content-Type':'application/json'});res.end('{"error":"Sornaz API is unreachable"}');});
  req.on('aborted',()=>upstream.destroy()); req.pipe(upstream);
}).listen(port,'127.0.0.1',()=>console.log(`Sornaz API preview relay: ${local}`));

// Render actual recorded output as a readable screenshot; never synthesizes results.
const fs = require('fs');
const {chromium} = require('playwright');
(async()=>{
 const [source, output, first='1', count='90'] = process.argv.slice(2);
 if(!source||!output) throw Error('Usage: SOURCE OUTPUT.png [FIRST_LINE] [LINE_COUNT]');
 const lines=fs.readFileSync(source,'utf8').replace(/\x1b\[[0-9;]*m/g,'').split('\n');
 const text=lines.slice(Number(first)-1,Number(first)-1+Number(count)).join('\n');
 const escape=s=>s.replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const browser=await chromium.launch({executablePath:process.env.CHROME_PATH||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1400,height:900}});
 await page.setContent(`<html><head><style>body{font-family:system-ui;background:#f5f7fb;padding:28px;color:#172033}h1{font-size:25px}p{font-size:14px}pre{background:#101827;color:#e1ebfa;padding:22px;border-radius:10px;font:15px/1.45 monospace;white-space:pre-wrap;overflow-wrap:anywhere}</style></head><body><h1>DevOps Homework — Recorded output</h1><p>Aryan Jakhar · 24BCS10305</p><p>Source: ${escape(source)} · Lines ${first}–${Math.min(lines.length,Number(first)+Number(count)-1)}</p><p>This is a rendering of the captured transcript. The original file contains the complete output.</p><pre>${escape(text)}</pre></body></html>`);
 await page.screenshot({path:output,fullPage:true});await browser.close();console.log(output);
})().catch(e=>{console.error(e);process.exit(1)});

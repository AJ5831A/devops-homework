// npm install playwright; NODE_PATH may point to an external installation.
const { chromium } = require('playwright');
(async () => {
  const [url, output] = process.argv.slice(2);
  if (!url || !output) throw new Error('Usage: node scripts/capture-page.cjs URL OUTPUT.png');
  const browser = await chromium.launch({executablePath: process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless:true});
  const page = await browser.newPage({viewport: {width:1440,height:1000}});
  await page.goto(url, {waitUntil:'networkidle', timeout:60000});
  await page.screenshot({path:output, fullPage:true});
  console.log(JSON.stringify({url, output, title:await page.title(), capturedAt:new Date().toISOString()}));
  await browser.close();
})().catch(err => {console.error(err);process.exit(1)});

const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({headless: true});
  const page = await browser.newPage({viewport: {width: 1440, height: 1000}});
  await page.goto('http://localhost:8088');
  await page.locator('form input').first().fill('admin');
  await page.locator('input[type="password"]').fill(fs.readFileSync('/tmp/argocd-password','utf8'));
  await page.getByRole('button', {name: 'Sign In'}).click();
  await page.waitForURL('**/applications**');
  await page.locator('.applications-list__title').filter({hasText: 'monitoring-gitops-lab'}).waitFor();
  await page.screenshot({path:'evidence/gitops/argocd-applications.png',fullPage:true});
  await page.goto('http://localhost:8088/applications/argocd/devops-final');
  await page.waitForTimeout(4000);
  await page.screenshot({path:'evidence/gitops/argocd-final.png',fullPage:true});
  await browser.close();
})();

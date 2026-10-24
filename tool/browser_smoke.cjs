// Run after `flutter build web` and serving build/web at KIDBOOK_URL.
// npm install --prefix tool; node tool/browser_smoke.cjs
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'docs/screenshots');
const url = process.env.KIDBOOK_URL || 'http://127.0.0.1:5174';
(async () => {
  const browser = await chromium.launch({headless: true,
    executablePath: process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream', '--autoplay-policy=no-user-gesture-required']});
  const context = await browser.newContext({viewport: {width: 390, height: 844},
    deviceScaleFactor: 2, permissions: ['microphone']});
  const page = await context.newPage();
  // Supply a synthetic microphone stream; MediaRecorder and playback remain real.
  // Chrome on some macOS hosts waits for OS audio even with its fake-device flag.
  await page.addInitScript(() => {
    const original = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
    navigator.mediaDevices.getUserMedia = async constraints => {
      if (!constraints.audio || constraints.video) return original(constraints);
      const audio = new AudioContext();
      const oscillator = audio.createOscillator();
      const gain = audio.createGain();
      const destination = audio.createMediaStreamDestination();
      oscillator.frequency.value = 220; gain.gain.value = .03;
      oscillator.connect(gain); gain.connect(destination); oscillator.start();
      await audio.resume();
      destination.stream.getTracks().forEach(track => {
        const stop = track.stop.bind(track);
        track.stop = () => {stop(); oscillator.stop(); audio.close();};
      });
      return destination.stream;
    };
  });
  const errors = []; page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') console.log('Browser:', m.text()); });
  const button = name => page.getByRole('button', {name, exact: true});
  const shot = async name => {await page.mouse.move(1, 1); await page.waitForTimeout(650); await page.screenshot({path: path.join(output, name + '.png')}); console.log('Screenshot:', name);};
  const enable = async () => {await page.locator('flt-semantics-placeholder').waitFor(); await page.locator('flt-semantics-placeholder').evaluate(e => e.click());};
  try {
    fs.mkdirSync(output, {recursive: true});
    await page.goto(url); await enable(); await button('Create first book').waitFor();
    await shot('01-welcome');
    await button('Create first book').click(); await shot('02-new-book');
    await button('Add cover').click(); await shot('06-camera');
    const chooser = page.waitForEvent('filechooser'); await button('Choose photo').click();
    await (await chooser).setFiles(path.join(root, 'assets/images/bedtime.png'));
    await shot('07-camera-check'); await button('Use cover').last().click();
    await page.getByRole('textbox').fill('Our bedtime story');
    await button('Record a page').click(); await button('Start recording').click();
    await button('Stop recording').waitFor(); await page.waitForTimeout(1500);
    await shot('03-recording'); await button('Stop recording').click();
    await button('SAVE').waitFor(); await shot('04-recording-stop');
    await button('Listen to recording').click(); await shot('05-recording-listen');
    await button('SAVE').click(); await page.mouse.click(25,430); await shot('08-book-content');
    await button('Edit Page 1').click(); await page.getByRole('menuitem', {name: 'Rename page'}).click();
    await page.getByRole('textbox').last().fill('Good night, little one');
    await button('Save').last().click(); await button('Edit Good night, little one').click(); await shot('09-page-edit'); await page.keyboard.press('Escape');
    await button('Save').click();
    // Verify serialized audio is durable rather than an expiring blob URL.
    let saved = await page.evaluate(() => JSON.parse(JSON.parse(localStorage.getItem('flutter.kidbook.library.v1'))));
    assert.equal(saved.books.length, 1); assert.ok(saved.books[0].pages[0].audio.startsWith('data:audio/webm;base64,'));
    await page.reload(); await enable();
    await page.getByRole('button', {name: /Our bedtime story, 1 pages/}).waitFor();
    // Play recorded audio after reload.
    await page.getByRole('button', {name: /Our bedtime story, 1 pages/}).click();
    await button('Play story').click(); await button('Play story').waitFor(); await button('Play story').click();
    await button('Pause story').waitFor(); await button('Pause story').click();
    await button('‹ Library').click();
    // Start a separate sample-library scenario in this isolated browser context.
    await page.evaluate(() => localStorage.clear());
    await page.reload(); await enable();
    await button('Explore sample library').click(); await button('List view').waitFor();
    await shot('10-library-grid'); await button('List view').click(); await shot('11-library-list');
    await button('Grid view').click(); await button('Edit library').click();
    await page.getByRole('button', {name: /Bedtime story, 3 pages/}).click(); await shot('12-library-edit');
    await button('Done editing').click(); await button('Playlists').click(); await shot('13-playlists-empty');
    await button('Create Playlist').click(); await page.getByRole('textbox').fill('Sleep, sleep tight'); await shot('14-playlist-name');
    await button('Create').click(); await shot('15-choose-books');
    await page.getByRole('checkbox', {name: 'Bedtime story', exact: true}).click();
    await page.getByRole('checkbox', {name: 'A song for you', exact: true}).click(); await shot('16-choose-books-selected');
    await button('Add to playlist').click(); await shot('19-playlists');
    await button('Play Sleep, sleep tight').click(); await button('Play story').waitFor();
    await button('Play story').click(); await button('Pause story').waitFor(); await page.waitForTimeout(1000); await shot('17-player-playing');
    await button('Pause story').click(); await shot('18-player-paused');
    await button('Next page').click(); await button('Play story').waitFor();
    await page.waitForFunction(() => document.querySelector('flt-semantics-host')?.textContent.includes('Page 2'));
    await button('Previous page').click(); await page.waitForFunction(() => document.querySelector('flt-semantics-host')?.textContent.includes('Page 1')); await button('Play story').waitFor();
    await button('Play story').click();
    await page.waitForFunction(() => document.querySelector('flt-semantics-host')?.textContent.includes('Page 2'));
    await button('Pause story').click();
    await button('Repeat off').click(); await page.mouse.move(1,1); await page.waitForTimeout(400); await button('Repeat on').waitFor();
    // Responsive smoke screenshots from the real release build.
    await page.setViewportSize({width:320,height:640}); await page.mouse.wheel(0,-1200); await shot('20-player-small');
    await page.setViewportSize({width:768,height:1024}); await page.mouse.wheel(0,-1200); await shot('21-player-tablet');
    saved=await page.evaluate(()=>JSON.parse(JSON.parse(localStorage.getItem('flutter.kidbook.library.v1'))));
    assert.equal(saved.playlists[0].bookIds.length,2); assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(root,'docs/browser-test-result.json'), JSON.stringify({
      passed:true,viewport:'390 × 844 @2x',screenshots:21,bookCount:saved.books.length,
      recordedAudioPersisted:true,playlistBooks:2,uncaughtErrors:errors,
      checks:['record / stop / listen / save','photo import and cover preview','reload persistence',
        'recorded audio playback after reload','grid / list / edit selection','playlist create and selection',
        'sample playback / pause / next / previous / automatic advance / repeat','320px and 768px layout'],
    },null,2));
    console.log('PASS: KidBook browser flow and 21 screenshots');
  } catch(e) { await page.screenshot({path:path.join(output,'failure.png')}); console.log(await page.locator('[role]').evaluateAll(es=>es.map(e=>({label:e.getAttribute('aria-label'),text:e.textContent,html:e.outerHTML.slice(0,700)})))); throw e; }
  finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});

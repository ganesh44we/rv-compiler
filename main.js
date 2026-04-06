const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { exec } = require('child_process');
const fs = require('fs');

const __current_dir = process.cwd();
const rvBinary = path.join(__current_dir, 'bin', 'rv');

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 960,
    minWidth: 1024,
    minHeight: 700,
    titleBarStyle: 'hidden',
    trafficLightPosition: { x: 15, y: 18 },
    backgroundColor: '#08090c',
    webPreferences: {
      preload: path.join(__current_dir, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  win.loadFile('index.html');
}

// ═══ COMPILE HANDLER ═══
ipcMain.handle('compile', async (event, { code, lang, optimize }) => {
  return new Promise((resolve) => {
    const ext = lang === 'ruby' ? 'rb' : 'py';
    const tmpFile = path.join(__current_dir, `gui_tmp.${ext}`);
    fs.writeFileSync(tmpFile, code);

    const optFlag = optimize ? ' --optimize' : '';
    exec(`${rvBinary} ${tmpFile}${optFlag} --verbose`, (error, stdout, stderr) => {
      const generatedJsPath = path.join(__current_dir, 'test.js');
      const generatedJs = fs.existsSync(generatedJsPath)
        ? fs.readFileSync(generatedJsPath, 'utf8')
        : '';

      resolve({
        success: !error,
        stdout: stdout,
        stderr: stderr,
        js: generatedJs
      });
    });
  });
});

// ═══ RUN HANDLER ═══
ipcMain.handle('run', async (event, { code, lang, optimize }) => {
  return new Promise((resolve) => {
    const ext = lang === 'ruby' ? 'rb' : 'py';
    const tmpFile = path.join(__current_dir, `gui_tmp.${ext}`);
    fs.writeFileSync(tmpFile, code);

    const optFlag = optimize ? ' --optimize' : '';
    exec(`${rvBinary} ${tmpFile}${optFlag} -r`, { timeout: 30000 }, (error, stdout, stderr) => {
      resolve({
        success: !error,
        stdout: stdout,
        stderr: stderr
      });
    });
  });
});

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

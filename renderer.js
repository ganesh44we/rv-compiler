// ═══════════════════════════════════════════════════════════
// RV Studio — Renderer v2.0 (Premium UX)
// ═══════════════════════════════════════════════════════════

const sourceEditor = document.getElementById('source-editor');
const jsOutput     = document.getElementById('js-output');
const consoleOut   = document.getElementById('console-output');
const langSelect   = document.getElementById('lang-select');
const btnRun       = document.getElementById('btn-run');
const btnOptimize  = document.getElementById('btn-optimize');
const btnClear     = document.getElementById('btn-clear');
const lineCount    = document.getElementById('line-count');
const compileStatus = document.getElementById('compile-status');
const statusLang   = document.getElementById('status-lang');
const statusLines  = document.getElementById('status-lines');
const statusMsg    = document.getElementById('status-message');
const statusPerf   = document.getElementById('status-perf');
const targetSection = document.getElementById('target-section');
const fileName     = document.getElementById('file-name');

let compileTimeout;
let optimizeEnabled = false;

// ═══ HELPERS ═══
function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// Strip the rv_lib.js preamble — only show the user's compiled code.
// The lib ends with 'const git = RV.Git;' followed by a blank line.
function stripPreamble(js) {
  const MARKER = 'const git = RV.Git;';
  const idx = js.indexOf(MARKER);
  if (idx === -1) return js; // safety: show everything if marker not found
  return js.slice(idx + MARKER.length).replace(/^\n+/, '');
}

// Display the compiled output — strips lib and scrolls to top
function showCompiledOutput(js) {
  const userCode = stripPreamble(js);
  jsOutput.textContent = userCode || '// (no user code compiled yet)';
  // Scroll the output wrapper back to the top
  const wrap = jsOutput.parentElement;
  if (wrap) wrap.scrollTop = 0;
}

function updateLineInfo() {
  const lines = sourceEditor.value.split('\n');
  lineCount.textContent = `${lines.length} line${lines.length !== 1 ? 's' : ''}`;

  const pos = sourceEditor.selectionStart;
  const before = sourceEditor.value.substring(0, pos);
  const ln = before.split('\n').length;
  const col = pos - before.lastIndexOf('\n');
  statusLines.textContent = `Ln ${ln}, Col ${col}`;
}

// ═══ LIVE COMPILATION (Debounced) ═══
async function doCompile() {
  const code = sourceEditor.value;
  const lang = langSelect.value;

  if (!code.trim()) {
    jsOutput.textContent = '// Write some code to see live compilation...';
    compileStatus.textContent = 'Ready';
    targetSection.className = 'pane target-pane';
    return;
  }

  // Show compiling state
  compileStatus.textContent = 'Compiling…';
  targetSection.className = 'pane target-pane compiling';

  const startTime = performance.now();
  const result = await window.rv.compile({ code, lang, optimize: optimizeEnabled });
  const elapsed = (performance.now() - startTime).toFixed(0);

  if (result.success) {
    showCompiledOutput(result.js);
    compileStatus.textContent = `✓ ${elapsed}ms`;
    targetSection.className = 'pane target-pane compile-ok';
    statusPerf.textContent = `Build: ${elapsed}ms`;
  } else {
    // Show the error message, preferring stderr
    const errText = result.stderr || result.stdout || 'Unknown compilation error';
    jsOutput.textContent = errText;  // use textContent for safety
    compileStatus.textContent = '✗ Error';
    targetSection.className = 'pane target-pane compile-err';
    statusPerf.textContent = '';
    // Scroll to top so error is visible
    const wrap = jsOutput.parentElement;
    if (wrap) wrap.scrollTop = 0;
  }
}

sourceEditor.addEventListener('input', () => {
  clearTimeout(compileTimeout);
  compileTimeout = setTimeout(doCompile, 400);
  updateLineInfo();
  fileName.textContent = langSelect.value === 'python' ? 'script.py' : 'script.rb';
});

sourceEditor.addEventListener('click', updateLineInfo);
sourceEditor.addEventListener('keyup', updateLineInfo);

// ═══ LANGUAGE SWITCH ═══
langSelect.addEventListener('change', () => {
  const lang = langSelect.value;
  statusLang.textContent = lang === 'python' ? 'Python' : 'Ruby';
  fileName.textContent = lang === 'python' ? 'script.py' : 'script.rb';
  sourceEditor.value = initialCode[lang];
  updateLineInfo();
  doCompile();
});

// ═══ OPTIMIZER TOGGLE ═══
btnOptimize.addEventListener('click', () => {
  optimizeEnabled = !optimizeEnabled;
  btnOptimize.classList.toggle('active', optimizeEnabled);
  statusMsg.textContent = optimizeEnabled
    ? 'Peephole Optimizer: ON'
    : 'Peephole Optimizer: OFF';
  doCompile();
});

// ═══ CLEAR CONSOLE ═══
btnClear.addEventListener('click', () => {
  consoleOut.innerHTML = '<span class="console-welcome">Console cleared.</span>';
});

// ═══ EXECUTION ═══
async function doRun() {
  const code = sourceEditor.value;
  const lang = langSelect.value;

  if (!code.trim()) return;

  consoleOut.innerHTML = '<span style="color:var(--amber)">⏳ Running…</span>';
  statusMsg.textContent = 'Executing…';

  const startTime = performance.now();
  const result = await window.rv.run({ code, lang, optimize: optimizeEnabled });
  const elapsed = (performance.now() - startTime).toFixed(0);

  if (result.success) {
    consoleOut.innerHTML = `<span class="success">${escapeHtml(result.stdout)}</span>`;
    statusMsg.textContent = `Execution complete (${elapsed}ms)`;
  } else {
    consoleOut.innerHTML = `<span class="error">${escapeHtml(result.stderr || result.stdout)}</span>`;
    statusMsg.textContent = `Execution failed`;
  }
}

btnRun.addEventListener('click', doRun);

// Keyboard shortcut: Cmd/Ctrl + Enter to Run
document.addEventListener('keydown', (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
    e.preventDefault();
    doRun();
  }
});

// Tab key support in editor
sourceEditor.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    e.preventDefault();
    const start = sourceEditor.selectionStart;
    const end = sourceEditor.selectionEnd;
    sourceEditor.value = sourceEditor.value.substring(0, start) + '  ' + sourceEditor.value.substring(end);
    sourceEditor.selectionStart = sourceEditor.selectionEnd = start + 2;
  }
});

// ═══ INITIAL CODE SCAFFOLDS ═══
const initialCode = {
  python: `# 🐍 RV Python — Full-Stack Example
import requests
import numpy as np

# Networking — fetch from GitHub API
response = requests.get("https://api.github.com")
print("GitHub API status:", response.status_code)

# Data Science — NumPy array analysis
scores = np.array([85, 92, 78, 90, 88])
print("Mean score:", scores.mean())

# Classic OOP
class Robot:
    def __init__(self, name):
        self.name = name
    def greet(self):
        return "Hello from " + self.name

bot = Robot("RV-Python")
print(bot.greet())`,

  ruby: `# 💎 RV Ruby — Full-Stack Example
require "net/http"

# Networking — fetch from GitHub API
response = Net::HTTP.get("https://api.github.com")
puts "GitHub response length: " + response.length.to_s

# Git status check
status = git.status()
puts "Git Status:"
puts status

# Classic OOP
class Robot
  def initialize(name)
    @name = name
  end
  def greet
    "Hello from " + @name
  end
end

bot = Robot.new("RV-Ruby")
puts bot.greet`
};

// ═══ BOOT ═══
sourceEditor.value = initialCode.python;
updateLineInfo();
doCompile();
statusMsg.textContent = 'RV Compiler v2.0 — Networking & Git Ready ⚡';

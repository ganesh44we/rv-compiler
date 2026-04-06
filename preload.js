const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('rv', {
  compile: (data) => ipcRenderer.invoke('compile', data),
  run: (data) => ipcRenderer.invoke('run', data)
});

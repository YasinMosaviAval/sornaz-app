'use strict';
(() => {
  let database, pitchStream, audioContext, analyser, source;
  const urls = new Map();
  async function db() {
    if (!database) database = new Promise((resolve, reject) => {
      const request = indexedDB.open('sornaz-browser-recordings', 1);
      request.onupgradeneeded = () => request.result.createObjectStore('recordings', { keyPath: 'id' });
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    return database;
  }
  async function transaction(mode, action) {
    const database = await db();
    return new Promise((resolve, reject) => {
      const tx = database.transaction('recordings', mode);
      const request = action(tx.objectStore('recordings'));
      tx.oncomplete = () => resolve(request.result);
      tx.onerror = () => reject(tx.error);
      tx.onabort = () => reject(tx.error || Error('Storage transaction aborted'));
    });
  }
  async function get(id) {
    const row = await transaction('readonly', store => store.get(id));
    if (!row) throw Error('Recording not found');
    return row;
  }
  function revoke(id) { if (urls.has(id)) URL.revokeObjectURL(urls.get(id)); urls.delete(id); }
  async function download(blob, name) {
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a'); link.href = url; link.download = name;
    document.body.append(link); link.click(); link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 30000);
  }
  async function stopPitch() {
    if (source) source.disconnect();
    if (pitchStream) pitchStream.getTracks().forEach(track => track.stop());
    if (audioContext && audioContext.state !== 'closed') await audioContext.close();
    source = analyser = pitchStream = audioContext = null;
  }
  async function startPitch() {
    await stopPitch();
    try {
      pitchStream = await navigator.mediaDevices.getUserMedia({audio: {
        echoCancellation: false, noiseSuppression: false, autoGainControl: false
      }});
      audioContext = new AudioContext(); await audioContext.resume();
      source = audioContext.createMediaStreamSource(pitchStream);
      analyser = audioContext.createAnalyser(); analyser.fftSize = 8192;
      source.connect(analyser);
    } catch (error) { await stopPitch(); throw error; }
  }
  function readPitch() {
    if (!analyser) return -1;
    const samples = new Float32Array(analyser.fftSize);
    analyser.getFloatTimeDomainData(samples);
    // Normalized autocorrelation; first strong local peak avoids octave-down errors.
    let energy = 0; for (const value of samples) energy += value * value;
    if (Math.sqrt(energy / samples.length) < 0.002) return -1;
    const min = Math.floor(audioContext.sampleRate / 2000);
    const max = Math.min(Math.floor(audioContext.sampleRate / 35), samples.length / 2);
    const correlations = new Float32Array(max + 2);
    for (let lag = min; lag <= max + 1; lag++) {
      let sum = 0, left = 0, right = 0;
      for (let i = 0; i < 2048; i++) {
        sum += samples[i] * samples[i + lag]; left += samples[i] ** 2; right += samples[i + lag] ** 2;
      }
      correlations[lag] = sum / Math.sqrt(left * right || 1);
      if (lag > min + 1 && correlations[lag - 1] > 0.8 && correlations[lag - 1] > correlations[lag] && correlations[lag - 1] >= correlations[lag - 2]) {
        const a = correlations[lag - 2], b = correlations[lag - 1], c = correlations[lag];
        const offset = (a - c) / (2 * (a - 2 * b + c) || 1);
        return audioContext.sampleRate / (lag - 1 + offset);
      }
    }
    return -1;
  }
  const operations = {
    startPitch, stopPitch, readPitch,
    recordingsInit: async () => { await db(); },
    recordingsSave: async ({id, source}) => {
      const response = await fetch(source); if (!response.ok) throw Error('Recording unavailable');
      const blob = await response.blob(); if (!blob.size) throw Error('Empty recording');
      const ext = blob.type.includes('ogg') ? 'ogg' : blob.type.includes('mp4') ? 'm4a' : 'webm';
      await transaction('readwrite', store => store.put({id, name: `Sornaz_${Date.now()}.${ext}`, modified: Date.now(), blob}));
      URL.revokeObjectURL(source);
    },
    recordingsList: async () => (await transaction('readonly', store => store.getAll()))
      .sort((a,b) => b.modified - a.modified).map(({id,name,modified}) => ({id,name,modified})),
    recordingsUrl: async ({id}) => {
      if (id.startsWith('blob:')) return id;
      if (!urls.has(id)) urls.set(id, URL.createObjectURL((await get(id)).blob));
      return urls.get(id);
    },
    recordingsDelete: async ({id}) => { await transaction('readwrite', store => store.delete(id)); revoke(id); },
    recordingsRename: async ({id,name}) => {
      const row = await get(id), ext = row.name.split('.').pop();
      row.name = name.endsWith('.' + ext) ? name : name + '.' + ext;
      await transaction('readwrite', store => store.put(row));
    },
    recordingsDownload: async ({id}) => { const row = await get(id); await download(row.blob, row.name); },
    download: async ({url,name,headers}) => {
      const response = await fetch(url, {headers}); if (!response.ok) throw Error('Download failed');
      await download(await response.blob(), name || 'sornaz-download');
    },
    exportText: async ({text,name}) => download(new Blob([text], {type:'application/json'}), name),
  };
  window.SornazBrowser = {call: async (action, payload) => {
    if (!Object.hasOwn(operations, action)) throw Error('Unknown browser operation');
    return JSON.stringify((await operations[action](JSON.parse(payload))) ?? null);
  }};
})();

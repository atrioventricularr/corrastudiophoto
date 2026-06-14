// Retro sound effect synthesiser using Web Audio API

let audioCtx: AudioContext | null = null;

function getAudioContext(): AudioContext | null {
  if (typeof window === 'undefined') return null;
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (AudioContextClass) {
      audioCtx = new AudioContextClass();
    }
  }
  return audioCtx;
}

export function playRetroBeep(type: 'click' | 'select' | 'shutter' | 'success' | 'countdown') {
  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    
    // Resume context if suspended (browser security autoplays limitation)
    if (ctx.state === 'suspended') {
      ctx.resume();
    }

    const osc = ctx.createOscillator();
    const gainNode = ctx.createGain();
    osc.connect(gainNode);
    gainNode.connect(ctx.destination);

    const now = ctx.currentTime;

    if (type === 'click') {
      // Classic quick click
      osc.type = 'sine';
      osc.frequency.setValueAtTime(800, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.05);
      gainNode.gain.setValueAtTime(0.08, now);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
      osc.start(now);
      osc.stop(now + 0.05);
    } else if (type === 'countdown') {
      // Shorter, softer beep for countdown tick
      osc.type = 'sine';
      osc.frequency.setValueAtTime(600, now);
      gainNode.gain.setValueAtTime(0.05, now);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
      osc.start(now);
      osc.stop(now + 0.12);
    } else if (type === 'select') {
      // Nice ascending arcade 2-tone
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(500, now);
      osc.frequency.setValueAtTime(750, now + 0.08);
      gainNode.gain.setValueAtTime(0.05, now);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
      osc.start(now);
      osc.stop(now + 0.25);
    } else if (type === 'shutter') {
      // Retro camera mechanical snap + high pitch blink
      // Synthesize noise-like crunch
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(150, now);
      osc.frequency.exponentialRampToValueAtTime(50, now + 0.15);
      gainNode.gain.setValueAtTime(0.18, now);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
      osc.start(now);
      osc.stop(now + 0.15);

      // Add high-pitched electronic indicator beep on top
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(2000, now);
      gain2.gain.setValueAtTime(0.05, now);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
      osc2.start(now);
      osc2.stop(now + 0.08);
    } else if (type === 'success') {
      // Fun retro success melody
      const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
      const dur = 0.08;
      
      notes.forEach((freq, idx) => {
        const oscNote = ctx.createOscillator();
        const gainNoteNode = ctx.createGain();
        oscNote.connect(gainNoteNode);
        gainNoteNode.connect(ctx.destination);
        
        oscNote.type = 'triangle';
        oscNote.frequency.setValueAtTime(freq, now + idx * dur);
        gainNoteNode.gain.setValueAtTime(0.04, now + idx * dur);
        gainNoteNode.gain.exponentialRampToValueAtTime(0.001, now + idx * dur + dur);
        
        oscNote.start(now + idx * dur);
        oscNote.stop(now + idx * dur + dur);
      });
    }
  } catch (e) {
    // Fail silently if browser blocks sound API
    console.warn('Audio Context synthesiser error:', e);
  }
}

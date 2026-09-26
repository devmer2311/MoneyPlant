// Tiny text scramble: characters flicker through glyphs, then settle left to right.
const GLYPHS = '₹#%&*+=<>abcdefghijkmnopqrstuvwxyz0123456789';

export function scrambleTo(el: Element, text: string, duration = 450): Promise<void> {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    el.textContent = text;
    return Promise.resolve();
  }
  const start = performance.now();
  return new Promise((resolve) => {
    const tick = (now: number) => {
      const t = Math.min((now - start) / duration, 1);
      const settled = Math.floor(t * text.length);
      let out = text.slice(0, settled);
      for (let i = settled; i < text.length; i++) {
        out += text[i] === ' ' ? ' ' : GLYPHS[Math.floor(Math.random() * GLYPHS.length)];
      }
      el.textContent = out;
      if (t < 1) requestAnimationFrame(tick);
      else resolve();
    };
    requestAnimationFrame(tick);
  });
}

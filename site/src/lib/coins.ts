// Canvas coin/leaf particle bursts, themed via CSS variables.

type Particle = {
  x: number; y: number; vx: number; vy: number;
  rot: number; vr: number; size: number; kind: 'coin' | 'leaf';
  life: number;
};

const cssVar = (name: string) =>
  getComputedStyle(document.documentElement).getPropertyValue(name).trim() || '#888';

function drawCoin(ctx: CanvasRenderingContext2D, p: Particle) {
  const squish = Math.abs(Math.cos(p.rot)); // fake 3D spin
  ctx.save();
  ctx.translate(p.x, p.y);
  ctx.scale(squish * 0.6 + 0.4, 1);
  ctx.beginPath();
  ctx.arc(0, 0, p.size, 0, Math.PI * 2);
  ctx.fillStyle = cssVar('--coin-shade');
  ctx.fill();
  ctx.lineWidth = Math.max(1.5, p.size * 0.18);
  ctx.strokeStyle = cssVar('--coin-edge');
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(-p.size * 0.25, -p.size * 0.25, p.size * 0.55, 0, Math.PI * 2);
  ctx.fillStyle = cssVar('--coin-hi');
  ctx.fill();
  ctx.fillStyle = cssVar('--coin-ink');
  ctx.font = `bold ${p.size * 1.1}px sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('₹', 0, 1);
  ctx.restore();
}

function drawLeaf(ctx: CanvasRenderingContext2D, p: Particle) {
  ctx.save();
  ctx.translate(p.x, p.y);
  ctx.rotate(p.rot);
  ctx.beginPath();
  ctx.ellipse(0, 0, p.size * 1.3, p.size * 0.55, 0, 0, Math.PI * 2);
  ctx.fillStyle = Math.random() > 0.5 ? cssVar('--leaf-mid') : cssVar('--leaf-hi');
  ctx.fill();
  ctx.restore();
}

/** Easter egg: it rains coins and notes from the top for `duration` ms. */
export function rainMoney(canvas: HTMLCanvasElement, duration = 3000): Promise<void> {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return Promise.resolve();
  const ctx = canvas.getContext('2d');
  if (!ctx) return Promise.resolve();
  const dpr = Math.min(devicePixelRatio, 2);
  canvas.width = canvas.clientWidth * dpr;
  canvas.height = canvas.clientHeight * dpr;
  ctx.scale(dpr, dpr);
  const parts: (Particle & { note?: boolean })[] = [];
  const start = performance.now();

  return new Promise((resolve) => {
    let last = start;
    const tick = (now: number) => {
      const dt = Math.min((now - last) / 1000, 0.032);
      last = now;
      if (now - start < duration) {
        for (let i = 0; i < 2; i++) {
          parts.push({
            x: Math.random() * canvas.clientWidth,
            y: -20,
            vx: (Math.random() - 0.5) * 60,
            vy: 220 + Math.random() * 260,
            rot: Math.random() * Math.PI * 2,
            vr: (Math.random() - 0.5) * 8,
            size: 8 + Math.random() * 9,
            kind: 'coin',
            life: 1,
            note: Math.random() < 0.25,
          });
        }
      }
      ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
      let alive = 0;
      for (const p of parts) {
        p.y += p.vy * dt;
        p.x += p.vx * dt;
        p.rot += p.vr * dt;
        if (p.y > canvas.clientHeight + 30) continue;
        alive++;
        if (p.note) {
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rot);
          ctx.fillStyle = cssVar('--leaf-mid');
          ctx.fillRect(-p.size, -p.size / 2, p.size * 2, p.size);
          ctx.fillStyle = cssVar('--leaf-hi');
          ctx.font = `bold ${p.size}px sans-serif`;
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText('₹', 0, 1);
          ctx.restore();
        } else {
          drawCoin(ctx, p);
        }
      }
      if (alive > 0 || now - start < duration) requestAnimationFrame(tick);
      else {
        ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
        resolve();
      }
    };
    requestAnimationFrame(tick);
  });
}

/** Fire-and-forget burst on an overlay canvas. Resolves when done. */
export function burstCoins(
  canvas: HTMLCanvasElement,
  origin: { x: number; y: number },
  opts: { count?: number; leaves?: boolean; gravity?: number } = {},
): Promise<void> {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return Promise.resolve();
  const ctx = canvas.getContext('2d');
  if (!ctx) return Promise.resolve();
  const dpr = Math.min(devicePixelRatio, 2);
  canvas.width = canvas.clientWidth * dpr;
  canvas.height = canvas.clientHeight * dpr;
  ctx.scale(dpr, dpr);
  const { count = 26, leaves = true, gravity = 1300 } = opts;

  const parts: Particle[] = Array.from({ length: count }, (_, i) => {
    const angle = -Math.PI / 2 + (Math.random() - 0.5) * 1.9;
    const speed = 380 + Math.random() * 520;
    return {
      x: origin.x,
      y: origin.y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      rot: Math.random() * Math.PI * 2,
      vr: (Math.random() - 0.5) * 14,
      size: 7 + Math.random() * 8,
      kind: leaves && i % 4 === 3 ? 'leaf' : 'coin',
      life: 1,
    };
  });

  return new Promise((resolve) => {
    let last = performance.now();
    const tick = (now: number) => {
      const dt = Math.min((now - last) / 1000, 0.032);
      last = now;
      ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
      let alive = 0;
      for (const p of parts) {
        p.vy += gravity * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.rot += p.vr * dt;
        p.life -= dt * 0.55;
        if (p.life <= 0 || p.y > canvas.clientHeight + 40) continue;
        alive++;
        ctx.globalAlpha = Math.min(1, p.life * 2.5);
        (p.kind === 'coin' ? drawCoin : drawLeaf)(ctx, p);
      }
      ctx.globalAlpha = 1;
      if (alive > 0) requestAnimationFrame(tick);
      else {
        ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
        resolve();
      }
    };
    requestAnimationFrame(tick);
  });
}

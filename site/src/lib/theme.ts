// Client-side theme switching with persistence and a circular colour wipe.
import { defaultMode, defaultTheme, themePacks, type Mode } from './themes';

const KEY = 'mp-theme';

export function storedTheme(): { theme: string; mode: Mode } {
  let theme = defaultTheme;
  let mode: Mode = defaultMode;
  try {
    const [t, m] = (localStorage.getItem(KEY) ?? '').split(':');
    if (t && themePacks.some((p) => p.id === t)) theme = t;
    if (m === 'light' || m === 'dark') mode = m;
  } catch {
    /* storage blocked: defaults apply */
  }
  return { theme, mode };
}

/** Applies + persists the theme. With an origin point, wipes the new colours in
 *  from there via the View Transitions API (falls back to an instant swap). */
export function setTheme(theme: string, mode: Mode, origin?: { x: number; y: number }) {
  const root = document.documentElement;
  const apply = () => {
    root.dataset.theme = theme;
    root.dataset.mode = mode;
    try {
      localStorage.setItem(KEY, `${theme}:${mode}`);
    } catch {
      /* storage blocked: theme still applies for this page */
    }
    window.dispatchEvent(new CustomEvent('mp:theme', { detail: { theme, mode } }));
  };

  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduce && origin && document.startViewTransition) {
    const vt = document.startViewTransition(apply);
    vt.ready.then(() => {
      const r = Math.hypot(
        Math.max(origin.x, innerWidth - origin.x),
        Math.max(origin.y, innerHeight - origin.y),
      );
      root.animate(
        {
          clipPath: [
            `circle(0px at ${origin.x}px ${origin.y}px)`,
            `circle(${r}px at ${origin.x}px ${origin.y}px)`,
          ],
        },
        {
          duration: 550,
          easing: 'cubic-bezier(0.16, 1, 0.3, 1)',
          pseudoElement: '::view-transition-new(root)',
        },
      );
    });
  } else {
    root.classList.add('theme-anim');
    apply();
    setTimeout(() => root.classList.remove('theme-anim'), 450);
  }
}

export function currentTheme(): { theme: string; mode: Mode } {
  const root = document.documentElement;
  return {
    theme: root.dataset.theme ?? defaultTheme,
    mode: (root.dataset.mode as Mode) ?? defaultMode,
  };
}

export function nextTheme(): string {
  const { theme } = currentTheme();
  const i = themePacks.findIndex((p) => p.id === theme);
  return themePacks[(i + 1) % themePacks.length]!.id;
}

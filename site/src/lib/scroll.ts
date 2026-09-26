// Lenis smooth scroll wired into GSAP's ticker, off under reduced motion.
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Lenis from 'lenis';

gsap.registerPlugin(ScrollTrigger);

let lenis: Lenis | null = null;
let tickerAdded = false;

export function initScroll() {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  lenis?.destroy();
  lenis = new Lenis({ lerp: 0.12 });
  lenis.on('scroll', ScrollTrigger.update);
  if (!tickerAdded) {
    gsap.ticker.add((time) => lenis?.raf(time * 1000));
    gsap.ticker.lagSmoothing(0);
    tickerAdded = true;
  }
}

export function getLenis() {
  return lenis;
}

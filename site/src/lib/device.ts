export type Device = 'android' | 'ios' | 'desktop';

export function detectDevice(): Device {
  const ua = navigator.userAgent;
  if (/android/i.test(ua)) return 'android';
  // iPadOS 13+ reports as Mac, but has touch points.
  if (/iphone|ipod|ipad/i.test(ua) || (/mac/i.test(ua) && navigator.maxTouchPoints > 1)) return 'ios';
  return 'desktop';
}

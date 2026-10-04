export type Palette = {
  bg: string;
  surface: string;
  text: string;
  textSecondary: string;
  textTertiary: string;
  fill: string;
  separator: string;
  accent: string;
  accentSoft: string;
  star: string;
  danger: string;
  codeBg: string;
  codeText: string;
  toastBg: string;
};

export const lightColors: Palette = {
  bg: '#F5F5F7',
  surface: '#FFFFFF',
  text: '#1C1C1E',
  textSecondary: '#6E6E73',
  textTertiary: '#8E8E93',
  fill: '#E9E9EE',
  separator: '#E5E5EA',
  accent: '#5B4FE9',
  accentSoft: '#ECEBFF',
  star: '#F5A623',
  danger: '#E5484D',
  codeBg: '#1C1C1E',
  codeText: '#F5F5F7',
  toastBg: '#1C1C1E',
};

export const darkColors: Palette = {
  bg: '#000000',
  surface: '#1C1C1E',
  text: '#F5F5F7',
  textSecondary: '#A1A1A6',
  textTertiary: '#8E8E93',
  fill: '#2C2C2E',
  separator: '#38383A',
  accent: '#7D74FF',
  accentSoft: '#2A2650',
  star: '#FFB340',
  danger: '#FF6369',
  codeBg: '#2C2C2E',
  codeText: '#F5F5F7',
  toastBg: '#3A3A3C',
};

/**
 * The active palette. Mutated in place by `applyTheme` at the top of every App
 * render, so components read the current theme's tokens while rendering.
 */
export const colors: Palette = { ...lightColors };

export type ColorScheme = 'light' | 'dark';

export function applyTheme(scheme: ColorScheme): void {
  Object.assign(colors, scheme === 'dark' ? darkColors : lightColors);
}

export const MONO = 'Menlo';

export const IS_ANDROID = typeof SystemInfo !== 'undefined' && SystemInfo.platform === 'Android';

export interface SafeArea {
  top: number;
  bottom: number;
}

export function getSafeArea(): SafeArea {
  const gp = (lynx.__globalProps ?? {}) as { safeAreaTop?: number; safeAreaBottom?: number };
  return {
    top: typeof gp.safeAreaTop === 'number' ? gp.safeAreaTop : 62,
    bottom: typeof gp.safeAreaBottom === 'number' ? gp.safeAreaBottom : 34,
  };
}

/**
 * Accessibility props for an element that automated tests drive by identifier.
 * `flatten: false` guarantees a real native view exists to carry the identifier.
 */
export function a11y(id: string, label?: string, extra: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    'ios-platform-accessibility-id': id,
    'accessibility-element': true,
    ...(label !== undefined ? { 'accessibility-label': label } : {}),
    flatten: false,
    ...extra,
  };
}

/** System colour scheme reported by the host (follows iOS appearance). */
export function getSystemScheme(): ColorScheme {
  const gp = (lynx.__globalProps ?? {}) as { systemColorScheme?: string };
  return gp.systemColorScheme === 'dark' ? 'dark' : 'light';
}

/** Persisted appearance setting passed by the host at launch (avoids a flash). */
export function getInitialAppearance(): 'system' | 'light' | 'dark' {
  const gp = (lynx.__globalProps ?? {}) as { appearance?: string };
  return gp.appearance === 'light' || gp.appearance === 'dark' ? gp.appearance : 'system';
}

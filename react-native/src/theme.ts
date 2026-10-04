import React, { createContext, useContext, useMemo } from 'react';
import { Platform, StyleSheet } from 'react-native';

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

/** Menlo on iOS; Android has no Menlo, so use its built-in monospace face. */
export const mono = Platform.select({ ios: 'Menlo', default: 'monospace' });

export type Theme = { dark: boolean; colors: Palette };

const ThemeCtx = createContext<Theme>({ dark: false, colors: lightColors });

export function ThemeProvider({ dark, children }: { dark: boolean; children: React.ReactNode }) {
  const value = useMemo(() => ({ dark, colors: dark ? darkColors : lightColors }), [dark]);
  return React.createElement(ThemeCtx.Provider, { value }, children);
}

export const useTheme = () => useContext(ThemeCtx);
export const useColors = () => useContext(ThemeCtx).colors;

/** Creates a hook returning a StyleSheet built for the active palette (cached per palette). */
export function makeStyles<T extends StyleSheet.NamedStyles<T>>(factory: (colors: Palette) => T) {
  const cache = new Map<Palette, T>();
  return function useStyles(): T {
    const colors = useColors();
    let s = cache.get(colors);
    if (!s) {
      s = StyleSheet.create(factory(colors));
      cache.set(colors, s);
    }
    return s;
  };
}

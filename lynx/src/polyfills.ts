/**
 * ES2022 built-ins used by `marked` that the PrimJS engine on Android lacks
 * (`Array.prototype.at`, `Object.hasOwn`). No-ops where they already exist (iOS).
 */
function at<T>(this: ArrayLike<T>, index: number): T | undefined {
  const len = this.length;
  let i = Math.trunc(index) || 0;
  if (i < 0) i += len;
  return i < 0 || i >= len ? undefined : this[i];
}

for (const proto of [Array.prototype, String.prototype] as object[]) {
  if (typeof (proto as { at?: unknown }).at !== 'function') {
    Object.defineProperty(proto, 'at', { value: at, writable: true, configurable: true });
  }
}

if (typeof (Object as { hasOwn?: unknown }).hasOwn !== 'function') {
  Object.defineProperty(Object, 'hasOwn', {
    value: (obj: object, key: PropertyKey) => Object.prototype.hasOwnProperty.call(obj, key),
    writable: true,
    configurable: true,
  });
}

export {};

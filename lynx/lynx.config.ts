import { pluginReactLynx } from '@lynx-js/react-rsbuild-plugin';
import { defineConfig } from '@lynx-js/rspeedy';
import { pluginTypeCheck } from '@rsbuild/plugin-type-check';

export default defineConfig({
  server: { port: 3005 },
  plugins: [pluginReactLynx({ enableCSSInheritance: true }), pluginTypeCheck()],
});

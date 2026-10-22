import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // Relative base supaya hasil build tetap jalan di GitHub Pages subpath
  // (mis. /Centauri/) maupun di root domain.
  base: "./",
  build: {
    outDir: "dist",
    sourcemap: false,
  },
});

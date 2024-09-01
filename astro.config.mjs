import { defineConfig } from 'astro/config';
import svelte from "@astrojs/svelte";
import mdx from "@astrojs/mdx";

export default defineConfig({
  site: 'https://lunarmagpie.github.io',
  markdown: {
    drafts: true,
  },
  integrations: [
    mdx({
      drafts: true,
    }),
    svelte()
  ],
});


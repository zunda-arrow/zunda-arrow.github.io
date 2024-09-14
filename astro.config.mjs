import { defineConfig } from "astro/config";
import svelte from "@astrojs/svelte";
import mdx from "@astrojs/mdx";
import tabBlocks from "docusaurus-remark-plugin-tab-blocks";

export default defineConfig({
	site: "https://lunarmagpie.github.io",
	markdown: {
		drafts: true,
	},
	integrations: [
		mdx({
			drafts: true,
		}),
		svelte(),
	],
});

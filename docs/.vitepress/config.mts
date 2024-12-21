import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import taskLists from 'markdown-it-task-lists'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: 'Blink Completion (blink.cmp)',
  description: 'Performant, batteries-included completion plugin for Neovim',
  sitemap: { hostname: 'https://cmp.saghen.dev/' },
  head: [['link', { rel: 'icon', href: '/favicon.png' }]],
  themeConfig: {
    sidebar: [
      { text: 'Introduction', link: '/' },
      { text: 'Installation', link: '/installation' },
      { text: 'Recipes', link: '/recipes' },
      {
        text: 'Configuration',
        items: [
          { text: 'General', link: '/configuration/general' },
          { text: 'Appearance', link: '/configuration/appearance' },
          { text: 'Completion', link: '/configuration/completion' },
          { text: 'Fuzzy', link: '/configuration/fuzzy' },
          { text: 'Keymap', link: '/configuration/keymap' },
          { text: 'Signature', link: '/configuration/signature' },
          { text: 'Sources', link: '/configuration/sources' },
          { text: 'Snippets', link: '/configuration/snippets' },
          { text: 'Reference', link: '/configuration/reference' },
        ],
      },
      {
        text: 'Development',
        items: [
          { text: 'Architecture', link: '/development/architecture' },
          { text: 'Writing Sources', link: '/development/writing-sources' },
          { text: 'LSP Tracker', link: '/development/lsp-tracker' },
        ],
      },
    ],

    socialLinks: [{ icon: 'github', link: 'https://github.com/saghen/blink.cmp' }],

    search: {
      provider: 'local',
    },
  },

  markdown: {
    theme: {
      light: 'catppuccin-latte',
      dark: 'catppuccin-mocha',
    },
    config(md) {
      md.use(tabsMarkdownPlugin)
      md.use(taskLists)
    },
  },
})

import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import taskLists from 'markdown-it-task-lists'
import { execSync } from 'node:child_process'

const isMain = process.env.IS_RELEASE !== 'true'
const version = execSync('git describe --tags --abbrev=0', { encoding: 'utf-8' }).trim()

const siteUrl = isMain ? 'https://main.cmp.saghen.dev' : 'https://cmp.saghen.dev'
const otherSiteUrl = isMain ? 'https://cmp.saghen.dev' : 'https://main.cmp.saghen.dev'

const title = isMain ? 'Main' : version
const otherTitle = isMain ? version : 'Main'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: 'Blink Completion (blink.cmp)',
  description: 'Performant, batteries-included completion plugin for Neovim',
  sitemap: { hostname: siteUrl },
  head: [['link', { rel: 'icon', href: '/favicon.png' }]],
  themeConfig: {
    nav: [{ text: `Version: ${title}`, items: [{ text: otherTitle, link: otherSiteUrl }] }],
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
        text: 'Modes',
        items: [
          { text: 'Cmdline', link: '/modes/cmdline' },
          { text: 'Terminal', link: '/modes/term' },
        ],
      },
      {
        text: 'Development',
        items: [
          { text: 'Architecture', link: '/development/architecture' },
          { text: 'Source Boilerplate', link: '/development/source-boilerplate' },
          { text: 'LSP Tracker', link: '/development/lsp-tracker' },
        ],
      },
    ],

    socialLinks: [{ icon: 'github', link: 'https://github.com/saghen/blink.cmp' }],
    editLink: { pattern: 'https://github.com/saghen/blink.cmp/edit/main/doc/:path' },

    search: { provider: 'local' },
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
    anchor: {
      getTokensText(tokens) {
        let text = ''
        for (const t of tokens) {
          if (t.type === 'text' || t.type === 'code_inline') text += t.content
          if (t.type === 'html_inline' && /<badge/i.test(t.content)) return text
        }
        return text
      },
    },
  },
})

import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Gas Town Documentation',
  tagline: 'Multi-agent orchestration for AI coding agents',
  favicon: 'img/logo.svg',

  url: 'https://docs.gt.villamarket.ai',
  baseUrl: '/',

  organizationName: 'thanakijwanavit',
  projectName: 'gastown-docs',
  trailingSlash: true,

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/steveyegge/gastown/tree/master/gastowndocs/mayor/rig/',
        },
        blog: {
          showReadingTime: true,
          blogSidebarTitle: 'Recent posts',
          blogSidebarCount: 5,
          onInlineAuthors: 'ignore',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
        sitemap: {
          lastmod: 'date',
          changefreq: 'weekly',
          priority: 0.5,
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/logo.svg',
    metadata: [
      {name: 'description', content: 'Gas Town is a multi-agent orchestration system for AI coding agents. Coordinate fleets of 20-30 concurrent workers through the gt CLI.'},
      {name: 'keywords', content: 'AI agents, multi-agent orchestration, Claude Code, AI coding, agent coordination, Gas Town, gt CLI'},
      {name: 'author', content: 'Steve Yegge'},
      {name: 'robots', content: 'index, follow'},
      {name: 'og:type', content: 'website'},
      {name: 'og:site_name', content: 'Gas Town Documentation'},
      {name: 'og:title', content: 'Gas Town - Multi-Agent Orchestration for AI Coding Agents'},
      {name: 'og:description', content: 'Coordinate fleets of AI coding agents working on your projects simultaneously. Built on Claude Code, scales from 1 to 30 agents.'},
      {name: 'og:image', content: 'https://docs.gt.villamarket.ai/img/logo.svg'},
      {name: 'twitter:card', content: 'summary_large_image'},
      {name: 'twitter:title', content: 'Gas Town - Multi-Agent Orchestration'},
      {name: 'twitter:description', content: 'Coordinate fleets of AI coding agents. Scales from 1 to 30 concurrent workers.'},
      {name: 'twitter:image', content: 'https://docs.gt.villamarket.ai/img/logo.svg'},
    ],
    headTags: [
      {
        tagName: 'link',
        attributes: {
          rel: 'canonical',
          href: 'https://docs.gt.villamarket.ai/',
        },
      },
    ],
    navbar: {
      title: 'Gas Town',
      logo: {
        alt: 'Gas Town Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://github.com/steveyegge/gastown',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {label: 'Getting Started', to: '/docs/getting-started'},
            {label: 'Architecture', to: '/docs/architecture'},
            {label: 'CLI Reference', to: '/docs/cli-reference'},
          ],
        },
        {
          title: 'Learn',
          items: [
            {label: 'Core Concepts', to: '/docs/concepts'},
            {label: 'Workflows', to: '/docs/workflows'},
            {label: 'Guides', to: '/docs/guides'},
          ],
        },
        {
          title: 'More',
          items: [
            {label: 'GitHub', href: 'https://github.com/steveyegge/gastown'},
            {
              label: 'Welcome to Gas Town (Medium)',
              href: 'https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04',
            },
          ],
        },
      ],
      copyright: `Copyright ${new Date().getFullYear()} Villa Market AI. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'toml', 'go'],
    },
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    mermaid: {
      theme: {light: 'neutral', dark: 'dark'},
    },
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 3,
    },
  } satisfies Preset.ThemeConfig,

  plugins: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        language: ['en'],
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
      },
    ],
  ],
};

export default config;

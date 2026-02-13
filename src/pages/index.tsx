import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import DeploymentStatus from '@site/src/components/DeploymentStatus';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting-started">
            Get Started
          </Link>
          <Link
            className="button button--secondary button--outline button--lg"
            to="/docs"
            style={{marginLeft: '1rem'}}>
            Read the Docs
          </Link>
        </div>
      </div>
    </header>
  );
}

const features = [
  {
    title: 'Multi-Agent Orchestration',
    description:
      'Coordinate 10-30 AI coding agents working on your projects simultaneously. The Mayor handles assignment, tracking, and coordination.',
  },
  {
    title: 'Crash-Safe Execution',
    description:
      'Work persists in git-backed hooks and beads. Agents resume from exactly where they left off after crashes, restarts, or handoffs.',
  },
  {
    title: 'Serialized Merge Queue',
    description:
      'The Refinery processes merges one at a time with automatic rebase, eliminating the chaos of parallel agent commits.',
  },
  {
    title: 'Built-in Monitoring',
    description:
      'Witness agents monitor health, the Deacon coordinates recovery, and the feed gives you real-time visibility into all activity.',
  },
  {
    title: 'Multi-Runtime Support',
    description:
      'Works with Claude Code, Gemini CLI, Codex, Cursor, Augment, and more. Mix and match runtimes across rigs.',
  },
  {
    title: 'Git-Native Issue Tracking',
    description:
      'Beads is a git-backed issue tracker designed for AI agents. No external services needed — everything lives in your repository.',
  },
];

function Feature({title, description}: {title: string; description: string}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="feature-card padding--lg">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function Home(): JSX.Element {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={siteConfig.tagline}>
      <HomepageHeader />
      <main>
        <section className="padding-vert--xl">
          <div className="container">
            <div className="row">
              {features.map((props, idx) => (
                <Feature key={idx} {...props} />
              ))}
            </div>
            <DeploymentStatus />
          </div>
        </section>
      </main>
    </Layout>
  );
}

import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';

export default function NotFound(): JSX.Element {
  return (
    <Layout title="Page Not Found">
      <main className="container margin-vert--xl">
        <div className="row">
          <div className="col col--6 col--offset-3">
            <h1 className="hero__title">404</h1>
            <p style={{fontSize: '1.2rem'}}>
              This page doesn't exist. It may have been moved or removed.
            </p>
            <div style={{marginTop: '2rem'}}>
              <h3>Try these instead:</h3>
              <ul style={{fontSize: '1.1rem', lineHeight: '2'}}>
                <li><Link to="/docs/">Documentation Home</Link></li>
                <li><Link to="/docs/getting-started/">Getting Started</Link></li>
                <li><Link to="/docs/cli-reference/">CLI Reference</Link></li>
                <li><Link to="/docs/concepts/">Core Concepts</Link></li>
                <li><Link to="/docs/guides/glossary/">Glossary</Link></li>
              </ul>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}

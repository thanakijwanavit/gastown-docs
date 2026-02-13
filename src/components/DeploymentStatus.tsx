import React from 'react';

interface DeploymentStatusProps {
  inline?: boolean;
}

export default function DeploymentStatus({inline = false}: DeploymentStatusProps): React.JSX.Element {
  // Get build information from environment or package.json
  const version = '1.0.0';
  const buildDate = new Date().toISOString().split('T')[0];

  const statusStyle: React.CSSProperties = inline ? {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '0.5rem',
    fontSize: '0.85rem',
    opacity: 0.7,
  } : {
    display: 'flex',
    flexDirection: 'column',
    gap: '0.5rem',
    padding: '1rem',
    borderTop: '1px solid var(--ifm-color-emphasis-200)',
    marginTop: '2rem',
    fontSize: '0.85rem',
    opacity: 0.7,
  };

  const badgeStyle: React.CSSProperties = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '0.25rem',
    padding: '0.25rem 0.5rem',
    borderRadius: '4px',
    backgroundColor: 'var(--ifm-color-success-contrast-background)',
    color: 'var(--ifm-color-success-contrast-foreground)',
    fontSize: '0.75rem',
    fontWeight: 500,
  };

  const dotStyle: React.CSSProperties = {
    width: '8px',
    height: '8px',
    borderRadius: '50%',
    backgroundColor: 'var(--ifm-color-success)',
    animation: 'pulse 2s ease-in-out infinite',
  };

  return (
    <div style={statusStyle}>
      <style>
        {`
          @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
          }
        `}
      </style>
      <div style={badgeStyle}>
        <span style={dotStyle}></span>
        <span>Live</span>
      </div>
      <span>v{version}</span>
      <span>•</span>
      <span>Updated {buildDate}</span>
      <span>•</span>
      <a
        href="https://github.com/thanakijwanavit/gastown-docs/commits/master"
        target="_blank"
        rel="noopener noreferrer"
        style={{color: 'inherit', textDecoration: 'none'}}
      >
        View Changes
      </a>
    </div>
  );
}

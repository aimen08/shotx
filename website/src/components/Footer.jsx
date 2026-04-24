import { AppIcon, useIsMobile } from './ShotXUI.jsx';

const GITHUB_URL = 'https://github.com/aimen08/shotx';
const RELEASES_URL = 'https://github.com/aimen08/shotx/releases/latest';
const ISSUES_URL = 'https://github.com/aimen08/shotx/issues';

const link = {
  color: 'rgba(235,235,245,.65)',
  textDecoration: 'none',
  fontSize: 14,
  fontWeight: 500,
};

export default function Footer() {
  const isMobile = useIsMobile();
  return (
    <footer style={{ background: 'linear-gradient(to bottom, transparent 0px, #050710 90px)', color: '#fff', borderTop: '1px solid rgba(255,255,255,.06)', padding: isMobile ? '56px 24px 40px' : '72px 48px 48px', fontFamily: 'Inter, sans-serif' }}>
      <div style={{ maxWidth: 1280, margin: '0 auto', display: 'grid', gridTemplateColumns: isMobile ? '1fr 1fr' : 'minmax(260px, 1.3fr) repeat(3, minmax(140px, 1fr))', gap: isMobile ? 32 : 48 }}>
        <div style={isMobile ? { gridColumn: '1 / -1' } : undefined}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 18 }}>
            <AppIcon size={40} />
            <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: -.3 }}>ShotX</div>
          </div>
          <p style={{ fontSize: 14, lineHeight: 1.55, color: 'rgba(235,235,245,.55)', margin: 0, maxWidth: 320 }}>
            Modern macOS screen capture for the menu bar. Screenshots, screen recording, GIF export, annotation, and searchable history — all from your keyboard.
          </p>
        </div>

        <div>
          <div style={{ fontSize: 12, letterSpacing: 2, textTransform: 'uppercase', color: 'rgba(235,235,245,.45)', fontWeight: 600, marginBottom: 18 }}>Product</div>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'grid', gap: 12 }}>
            <li><a style={link} href={RELEASES_URL} target="_blank" rel="noreferrer">Download</a></li>
            <li><a style={link} href={`${GITHUB_URL}/releases`} target="_blank" rel="noreferrer">Changelog</a></li>
            <li><a style={link} href={`${GITHUB_URL}#features`} target="_blank" rel="noreferrer">Features</a></li>
          </ul>
        </div>

        <div>
          <div style={{ fontSize: 12, letterSpacing: 2, textTransform: 'uppercase', color: 'rgba(235,235,245,.45)', fontWeight: 600, marginBottom: 18 }}>Project</div>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'grid', gap: 12 }}>
            <li><a style={link} href={GITHUB_URL} target="_blank" rel="noreferrer">GitHub</a></li>
            <li><a style={link} href={ISSUES_URL} target="_blank" rel="noreferrer">Report an issue</a></li>
            <li><a style={link} href={`${GITHUB_URL}/blob/main/README.md`} target="_blank" rel="noreferrer">Documentation</a></li>
          </ul>
        </div>

        <div>
          <div style={{ fontSize: 12, letterSpacing: 2, textTransform: 'uppercase', color: 'rgba(235,235,245,.45)', fontWeight: 600, marginBottom: 18 }}>System</div>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'grid', gap: 12 }}>
            <li style={{ fontSize: 14, color: 'rgba(235,235,245,.65)' }}>macOS 13+</li>
            <li style={{ fontSize: 14, color: 'rgba(235,235,245,.65)' }}>Apple Silicon &amp; Intel</li>
            <li style={{ fontSize: 14, color: 'rgba(235,235,245,.65)' }}>MIT licensed</li>
          </ul>
        </div>
      </div>

      <div style={{ maxWidth: 1280, margin: '56px auto 0', paddingTop: 24, borderTop: '1px solid rgba(255,255,255,.06)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
        <div style={{ fontSize: 13, color: 'rgba(235,235,245,.45)' }}>© {new Date().getFullYear()} ShotX · Open source and free</div>
        <div style={{ fontSize: 13, color: 'rgba(235,235,245,.45)', fontFamily: 'JetBrains Mono, monospace', letterSpacing: .3 }}>github.com/aimen08/shotx</div>
      </div>
    </footer>
  );
}

import { Icon, useIsMobile } from './ShotXUI.jsx';

const DOWNLOAD_URL = 'https://github.com/aimen08/shotx/releases/latest';
const GITHUB_URL = 'https://github.com/aimen08/shotx';

const GridBg = ({ opacity = .04, size = 48 }) => (
  <div aria-hidden style={{ position:'absolute', inset:0, backgroundImage: `linear-gradient(rgba(255,255,255,${opacity}) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,${opacity}) 1px, transparent 1px)`, backgroundSize: `${size}px ${size}px`, maskImage:'radial-gradient(ellipse at 50% 50%, #000 30%, transparent 80%)', WebkitMaskImage:'radial-gradient(ellipse at 50% 50%, #000 30%, transparent 80%)' }}/>
);

const Glow = ({ color = '#3566E0', x = '50%', y = '50%', size = 900, opacity = .35 }) => (
  <div aria-hidden style={{ position:'absolute', left:x, top:y, transform:'translate(-50%,-50%)', width:size, height:size, borderRadius:'50%', background:`radial-gradient(circle, ${color} 0%, transparent 60%)`, opacity, filter:'blur(10px)', pointerEvents:'none' }}/>
);

// ================================================================
// Section divider — smooth gradient bridge between two sections
// ================================================================
export const SectionDivider = ({ height = 120, from = 'transparent', to = 'transparent' }) => (
  <div aria-hidden style={{ height, background: `linear-gradient(180deg, ${from} 0%, ${to} 100%)`, width: '100%', pointerEvents: 'none' }}/>
);

// ================================================================
// Features — grid of what the app does
// ================================================================
const FEATURES = [
  { icon: 'area',      title: 'Screenshots, every shape',   text: 'Area, fullscreen, window, and previous-area capture — all from a global shortcut or the menu bar.' },
  { icon: 'record',    title: 'Screen recording',           text: 'MP4 or GIF export, microphone and system audio, with mouse-click highlights for demos.' },
  { icon: 'arrow',     title: 'Annotate in place',          text: 'Arrows, rectangles, text, and numbered callouts — copy straight to clipboard when you\'re done.' },
  { icon: 'textscan',  title: 'Extract text (OCR)',         text: 'Drag a region, Apple Vision recognizes the text on-device, and it lands on your clipboard.' },
  { icon: 'history',   title: 'Searchable history',         text: 'Every capture kept locally, with thumbnails and quick re-open. Nothing leaves your Mac.' },
  { icon: 'timer',     title: 'Self-timer & pin',           text: 'Stage tricky shots with a self-timer, and pin captures on top of any window while you compare.' },
  { icon: 'power',     title: 'Free and open source',       text: 'MIT licensed. Universal binary for Apple Silicon and Intel. Auto-updates via Sparkle.' },
];

const FeatureCard = ({ icon, title, text }) => (
  <div style={{ padding: 28, borderRadius: 18, background: 'linear-gradient(180deg, rgba(255,255,255,.04) 0%, rgba(255,255,255,.015) 100%)', border: '1px solid rgba(255,255,255,.07)', position: 'relative', overflow: 'hidden' }}>
    <div style={{ width: 44, height: 44, borderRadius: 11, background: 'linear-gradient(180deg, rgba(106,155,255,.18), rgba(30,63,168,.18))', border: '1px solid rgba(106,155,255,.25)', display: 'grid', placeItems: 'center', color: '#9EB9FF', marginBottom: 18 }}>
      <Icon name={icon} size={22} stroke={1.6} />
    </div>
    <div style={{ fontSize: 18, fontWeight: 600, letterSpacing: -.2, marginBottom: 8 }}>{title}</div>
    <div style={{ fontSize: 14, lineHeight: 1.55, color: 'rgba(235,235,245,.6)' }}>{text}</div>
  </div>
);

export const FeaturesSection = () => {
  const isMobile = useIsMobile();
  return (
    <section style={{ position: 'relative', padding: isMobile ? '72px 22px' : '120px 32px', overflow: 'hidden' }}>

      <div style={{ maxWidth: 1200, margin: '0 auto', position: 'relative' }}>
        <div style={{ textAlign: 'center', marginBottom: isMobile ? 40 : 64 }}>
          <div style={{ display:'inline-flex', alignItems:'center', gap: 8, padding:'6px 14px', borderRadius: 999, border: '1px solid rgba(255,255,255,.1)', background: 'rgba(255,255,255,.03)', fontSize: 12, color: 'rgba(235,235,245,.7)', fontWeight: 500, letterSpacing: .5, marginBottom: 20 }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#6ED37A', boxShadow: '0 0 8px rgba(110,211,122,.8)' }}/>
            Built for macOS, fast and native
          </div>
          <h2 style={{ fontSize: 'clamp(32px, 7vw, 56px)', fontWeight: 800, letterSpacing: -1.5, lineHeight: 1.05, margin: 0, maxWidth: 720, marginLeft: 'auto', marginRight: 'auto' }}>
            Everything you need{isMobile ? ' ' : <br/>}to <span style={{ background:'linear-gradient(90deg,#6A9BFF,#C8D4F0)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>capture and share</span>.
          </h2>
          <p style={{ fontSize: isMobile ? 15 : 17, color:'rgba(235,235,245,.6)', maxWidth: 600, margin: '18px auto 0', lineHeight: 1.55 }}>
            A small menu-bar app that covers the whole capture workflow — no accounts, no cloud uploads, no subscriptions.
          </p>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 16 }}>
          {FEATURES.map((f, i) => <FeatureCard key={i} {...f} />)}
        </div>
      </div>
    </section>
  );
};

// ================================================================
// Shortcuts — keyboard-driven workflow showcase
// ================================================================
const KeyCap = ({ children, wide }) => (
  <div style={{ minWidth: wide ? 64 : 48, height: 48, padding: wide ? '0 14px' : 0, borderRadius: 10, background: 'rgba(255,255,255,.06)', border: '1px solid rgba(255,255,255,.14)', boxShadow: 'inset 0 -2px 0 rgba(0,0,0,.25), 0 2px 0 rgba(0,0,0,.2)', display: 'grid', placeItems: 'center', fontFamily: 'JetBrains Mono, monospace', fontSize: 18, fontWeight: 600, color: 'rgba(235,235,245,.9)' }}>{children}</div>
);

const Plus = () => <div style={{ fontSize: 14, color: 'rgba(235,235,245,.35)', fontWeight: 400 }}>+</div>;

const SHORTCUTS = [
  { keys: ['⌥', 'X'],  label: 'Capture area',        icon: 'area' },
  { keys: ['⌥⇧', 'X'], label: 'Capture fullscreen',  icon: 'fullscreen' },
  { keys: ['⌥⇧', 'T'], label: 'Extract text (OCR)', icon: 'textscan' },
  { keys: ['⌥⇧', 'C'], label: 'Pick color',          icon: 'eyedropper' },
  { keys: ['⌘', '.'],  label: 'Stop recording',      icon: 'record' },
  { keys: ['⇧⌘', 'V'], label: 'Open from clipboard', icon: 'clipboard' },
];

export const ShortcutsSection = () => {
  const isMobile = useIsMobile();
  return (
  <section style={{ position: 'relative', padding: isMobile ? '80px 22px 72px' : '200px 32px 140px' }}>
    <div aria-hidden style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
      <Glow color="#4A7BEE" x="50%" y="50%" size={1200} opacity={.22}/>
    </div>

    <div style={{ maxWidth: 1100, margin: '0 auto', position: 'relative', display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'minmax(280px, 1fr) minmax(320px, 1.1fr)', gap: isMobile ? 40 : 72, alignItems: 'center' }}>
      <div>
        <div style={{ fontSize: 12, letterSpacing: 3, textTransform: 'uppercase', color: '#6A9BFF', fontWeight: 600, marginBottom: 18 }}>Live on the keyboard</div>
        <h2 style={{ fontSize: 52, fontWeight: 800, letterSpacing: -1.5, lineHeight: 1.05, margin: 0 }}>
          One keystroke<br/>to <span style={{ fontStyle:'italic', color:'#6A9BFF' }}>every capture</span>.
        </h2>
        <p style={{ fontSize: 17, color:'rgba(235,235,245,.6)', lineHeight: 1.55, margin: '22px 0 0', maxWidth: 440 }}>
          Global shortcuts stay out of your way and route every capture mode directly to the tool you need — no menus, no mouse hunting.
        </p>
        <a href={`${GITHUB_URL}#keyboard-shortcuts`} target="_blank" rel="noreferrer" style={{ display: 'inline-flex', alignItems: 'center', gap: 8, marginTop: 28, fontSize: 14, fontWeight: 500, color: '#6A9BFF', textDecoration: 'none' }}>
          See all shortcuts
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="M13 5l7 7-7 7"/></svg>
        </a>
      </div>

      <div style={{ display: 'grid', gap: 12 }}>
        {SHORTCUTS.map((s, i) => (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: 'auto 1fr auto', alignItems: 'center', gap: 18, padding: '14px 18px', borderRadius: 14, background: 'linear-gradient(180deg, rgba(255,255,255,.04), rgba(255,255,255,.015))', border: '1px solid rgba(255,255,255,.07)' }}>
            <div style={{ width: 36, height: 36, borderRadius: 9, background: 'rgba(106,155,255,.14)', border: '1px solid rgba(106,155,255,.22)', display: 'grid', placeItems: 'center', color: '#9EB9FF' }}>
              <Icon name={s.icon} size={18} stroke={1.6}/>
            </div>
            <div style={{ fontSize: 15, color: 'rgba(235,235,245,.85)', fontWeight: 500 }}>{s.label}</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <KeyCap wide={s.keys[0].length > 1}>{s.keys[0]}</KeyCap>
              <Plus/>
              <KeyCap wide={s.keys[1].length > 1}>{s.keys[1]}</KeyCap>
            </div>
          </div>
        ))}
      </div>
    </div>
  </section>
  );
};

// ================================================================
// Final CTA — big download prompt above the footer
// ================================================================
export const CTASection = () => {
  const isMobile = useIsMobile();
  return (
    <section style={{ position: 'relative', padding: isMobile ? '80px 22px 72px' : '140px 32px 120px' }}>
      <div aria-hidden style={{ position: 'absolute', top: -90, bottom: -70, left: 0, right: 0, overflow: 'hidden', pointerEvents: 'none', maskImage: 'linear-gradient(to bottom, transparent 0%, black 14%, black 88%, transparent 100%)', WebkitMaskImage: 'linear-gradient(to bottom, transparent 0%, black 14%, black 88%, transparent 100%)' }}>
        <Glow color="#3566E0" x="50%" y="58%" size={1100} opacity={.4}/>
        <Glow color="#6A9BFF" x="50%" y="72%" size={550} opacity={.32}/>
      </div>

      <div style={{ maxWidth: 920, margin: '0 auto', textAlign: 'center', position: 'relative' }}>
        <h2 style={{ fontSize: 'clamp(48px, 12vw, 84px)', lineHeight: 1, letterSpacing: -2, fontWeight: 800, margin: 0 }}>
          Grab it.<br/>
          <span style={{ background:'linear-gradient(90deg,#6A9BFF,#C8D4F0 60%,#6A9BFF)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>It’s free.</span>
        </h2>
        <p style={{ fontSize: isMobile ? 15 : 18, color:'rgba(235,235,245,.65)', lineHeight: 1.55, margin: '22px auto 0', maxWidth: 560 }}>
          ShotX is MIT licensed, auto-updating, and works on any Mac from macOS 13 onwards.
        </p>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 36, flexWrap: 'wrap', justifyContent: 'center', flexDirection: isMobile ? 'column' : 'row' }}>
          <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer" style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '16px 28px', borderRadius: 12, background: '#fff', color: '#0A0E1A', fontSize: 15, fontWeight: 600, textDecoration: 'none', boxShadow: '0 20px 40px rgba(106,155,255,.25)', width: isMobile ? '100%' : 'auto' }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>
            Download for Mac
          </a>
          <a href={GITHUB_URL} target="_blank" rel="noreferrer" style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '16px 26px', borderRadius: 12, background: 'rgba(255,255,255,.05)', border: '1px solid rgba(255,255,255,.14)', color: 'rgba(235,235,245,.9)', fontSize: 15, fontWeight: 500, textDecoration: 'none', width: isMobile ? '100%' : 'auto' }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="6" r="2.5"/><circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="12" r="2.5"/><path d="M6 8.5v7"/><path d="M6 15.5c8 0 10-3 10-5"/></svg>
            Star on GitHub
          </a>
        </div>

        <div style={{ marginTop: 24, fontSize: 12, color: 'rgba(235,235,245,.45)', fontFamily: 'JetBrains Mono, monospace', letterSpacing: .3 }}>
          macOS 13+  ·  Apple Silicon &amp; Intel  ·  Auto-updates
        </div>
      </div>
    </section>
  );
};

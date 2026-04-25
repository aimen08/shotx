// Six hero image explorations for ShotX.
// All composed from original UI components (see ShotXUI.jsx).

import {
  Icon,
  AppIcon,
  CaptureToolbar,
  AnnotateBar,
  ShotXMenu,
  MenuBar,
  CapturedSample,
  Marquee,
  useIsMobile,
} from './ShotXUI.jsx';
import ScaledArtboard from './ScaledArtboard.jsx';

const GITHUB_URL = 'https://github.com/aimen08/shotx';
const DOWNLOAD_URL = 'https://github.com/aimen08/shotx/releases/latest';

const linkReset = { textDecoration: 'none', color: 'inherit' };

const GridBg = ({ color = 'rgba(255,255,255,.035)', size = 48 }) => (
  <div style={{ position:'absolute', inset: 0, backgroundImage: `linear-gradient(${color} 1px, transparent 1px), linear-gradient(90deg, ${color} 1px, transparent 1px)`, backgroundSize: `${size}px ${size}px`, maskImage:'radial-gradient(ellipse at 60% 50%, #000 30%, transparent 75%)', WebkitMaskImage:'radial-gradient(ellipse at 60% 50%, #000 30%, transparent 75%)' }}/>
);

const BigGlow = ({ color = '#4A7BEE', x = '70%', y = '50%', size = 900, opacity = .45 }) => (
  <div style={{ position:'absolute', left:x, top:y, transform:'translate(-50%,-50%)', width:size, height:size, borderRadius:'50%', background:`radial-gradient(circle, ${color} 0%, transparent 60%)`, opacity, filter:'blur(10px)' }}/>
);

// ================================================================
// 01 · Classic dark — headline left, floating UI stack right
// ================================================================
export const HeroClassic = () => (
  <div style={{ position:'absolute', inset:0, color:'#fff', fontFamily:'Inter, sans-serif' }}>
    <div aria-hidden style={{ position:'absolute', inset:0, background:'radial-gradient(ellipse 70% 70% at 78% 32%, #15233F 0%, rgba(10,14,26,.55) 40%, transparent 80%)', pointerEvents:'none' }}/>
    <BigGlow color="#3566E0" x="78%" y="48%" size={1100} opacity={.55} />
    <BigGlow color="#6A9BFF" x="85%" y="30%" size={500} opacity={.4} />

    <div style={{ position:'absolute', top:40, left:60, right:60, display:'flex', justifyContent:'space-between', alignItems:'center', zIndex: 5 }}>
      <div style={{ display:'flex', alignItems:'center', gap: 14 }}>
        <AppIcon size={44} />
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -.3 }}>ShotX</div>
      </div>
      <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
        <a href={GITHUB_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display:'inline-flex', alignItems:'center', gap: 8, padding:'9px 14px', borderRadius: 10, border:'1px solid rgba(255,255,255,.14)', background:'rgba(255,255,255,.04)', color:'rgba(235,235,245,.85)', fontSize: 13, fontWeight: 500 }}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="6" r="2.5"/><circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="12" r="2.5"/><path d="M6 8.5v7"/><path d="M6 15.5c8 0 10-3 10-5"/></svg>
          Open source
        </a>
        <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, padding:'10px 18px', fontSize: 14, fontWeight: 600, background:'#fff', color:'#0A0E1A', borderRadius: 10 }}>Download for Mac</a>
      </div>
    </div>

    <div style={{ position:'absolute', left: 100, top: 240, width: 700, zIndex: 4 }}>
      <h1 style={{ fontSize: 92, lineHeight: .98, letterSpacing: -2.5, fontWeight: 800, margin: 0 }}>
        Capture<br/>anything.<br/>
        <span style={{ background:'linear-gradient(90deg,#6A9BFF,#C8D4F0)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>Annotate instantly.</span>
      </h1>
      <p style={{ fontSize: 19, lineHeight: 1.5, color:'rgba(235,235,245,.68)', maxWidth: 520, marginTop: 26, fontWeight: 400 }}>
        Modern macOS screen capture for the menu bar. Screenshots, recording with webcam, GIFs, OCR text extraction, annotation, and a searchable history — without ever leaving your keyboard.
      </p>
      <div style={{ display:'flex', alignItems:'center', gap: 12, marginTop: 32, flexWrap:'wrap' }}>
        <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display:'inline-flex', alignItems:'center', gap: 10, padding:'14px 24px', borderRadius: 12, background:'#fff', color:'#0A0E1A', fontSize: 15, fontWeight: 600, boxShadow:'0 20px 40px rgba(106,155,255,.22)' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>
          Download for Mac
        </a>
        <a href={GITHUB_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display:'inline-flex', alignItems:'center', gap: 10, padding:'14px 22px', borderRadius: 12, background:'rgba(255,255,255,.05)', border:'1px solid rgba(255,255,255,.14)', color:'rgba(235,235,245,.9)', fontSize: 15, fontWeight: 500 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.58 2 12.25c0 4.54 2.87 8.38 6.84 9.74.5.1.68-.22.68-.49 0-.24-.01-.87-.01-1.7-2.78.62-3.37-1.37-3.37-1.37-.46-1.18-1.12-1.5-1.12-1.5-.92-.64.07-.63.07-.63 1.01.08 1.54 1.07 1.54 1.07.9 1.56 2.35 1.11 2.93.85.09-.67.35-1.12.63-1.38-2.22-.26-4.56-1.14-4.56-5.06 0-1.12.39-2.03 1.03-2.75-.1-.26-.45-1.3.1-2.71 0 0 .84-.28 2.75 1.05.8-.23 1.65-.34 2.5-.34.85 0 1.7.11 2.5.34 1.91-1.33 2.75-1.05 2.75-1.05.55 1.41.2 2.45.1 2.71.64.72 1.03 1.63 1.03 2.75 0 3.93-2.34 4.8-4.57 5.05.36.32.68.93.68 1.88 0 1.36-.01 2.45-.01 2.79 0 .27.18.6.69.49A10.02 10.02 0 0 0 22 12.25C22 6.58 17.52 2 12 2z"/></svg>
          View on GitHub
        </a>
      </div>
      <div style={{ display:'flex', alignItems:'center', gap: 10, marginTop: 28, fontSize: 13, color:'rgba(235,235,245,.55)', fontFamily:'JetBrains Mono, monospace', letterSpacing: .3 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6ED37A" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="6" r="2.5"/><circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="12" r="2.5"/><path d="M6 8.5v7"/><path d="M6 15.5c8 0 10-3 10-5"/></svg>
        <span style={{ color:'#6ED37A' }}>100% open source</span>
        <span style={{ opacity:.4 }}>//</span>
        <span>MIT licensed</span>
        <span style={{ opacity:.4 }}>//</span>
        <span>github.com/aimen08/shotx</span>
      </div>
    </div>

    <div style={{ position:'absolute', right: -80, top: 120, width: 900, height: 780, zIndex: 3 }}>
      <div style={{ position:'absolute', top: 0, right: 40, transform:'rotate(-2deg)' }}>
        <MenuBar scale={1.1}/>
      </div>
      <div style={{ position:'absolute', top: 70, right: 90, transform:'rotate(-2deg)' }}>
        <ShotXMenu scale={1.05}/>
      </div>
      <div style={{ position:'absolute', top: 250, left: 50, transform:'rotate(3deg)' }}>
        <div style={{ position:'relative' }}>
          <CapturedSample scale={1} w={520} h={340} tone="dark"/>
          <div style={{ position:'absolute', top: 90, left: 80 }}>
            <Marquee w={360} h={200} color="#6A9BFF" dims="360 × 200"/>
          </div>
        </div>
      </div>
      <div style={{ position:'absolute', bottom: 40, left: 0, transform:'rotate(3deg)' }}>
        <CaptureToolbar scale={1}/>
      </div>
      <div style={{ position:'absolute', bottom: -10, left: 140, transform:'rotate(3deg)' }}>
        <div style={{ width: 680 }}>
          <AnnotateBar scale={1}/>
        </div>
      </div>
    </div>
  </div>
);

// ================================================================
// 02 · Product-forward — centered UI stack, headline above/below
// ================================================================
export const HeroProduct = () => (
  <div style={{ position:'absolute', inset:0, color:'#fff', fontFamily:'Inter, sans-serif' }}>
    <BigGlow color="#3566E0" x="50%" y="65%" size={1300} opacity={.5} />
    <BigGlow color="#6A9BFF" x="50%" y="70%" size={600} opacity={.4} />

    <div style={{ position:'absolute', top: 90, left: 0, right: 0, textAlign:'center', zIndex: 5 }}>
      <div style={{ display:'inline-flex', alignItems:'center', gap:10, padding:'8px 16px', borderRadius: 999, background:'rgba(255,255,255,.06)', border:'1px solid rgba(255,255,255,.1)', color:'rgba(235,235,245,.75)', fontSize: 13, fontWeight: 500, marginBottom: 28 }}>
        <AppIcon size={18} radius={5}/>
        ShotX for macOS
      </div>
      <h1 style={{ fontSize: 108, lineHeight: .96, letterSpacing: -3, fontWeight: 800, margin: 0 }}>
        The fastest way to<br/>
        <span style={{ fontStyle:'italic', fontWeight: 700, background:'linear-gradient(90deg,#6A9BFF 0%,#fff 50%,#6A9BFF 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>capture your screen.</span>
      </h1>
    </div>

    <div style={{ position:'absolute', left: '50%', top: 520, transform:'translateX(-50%)', zIndex: 4 }}>
      <div style={{ position:'relative', width: 1100, height: 420 }}>
        <div style={{ position:'absolute', left: '50%', top: 0, transform:'translateX(-50%)' }}>
          <div style={{ position:'relative' }}>
            <CapturedSample scale={1.2} w={720} h={420} tone="light"/>
            <div style={{ position:'absolute', top: 140, left: 180 }}>
              <Marquee w={420} h={200} color="#4A7BEE" dims="1284 × 632"/>
            </div>
          </div>
        </div>
        <div style={{ position:'absolute', left: 120, top: -60 }}>
          <CaptureToolbar scale={1.05}/>
        </div>
        <div style={{ position:'absolute', left: 160, bottom: -30, width: 820 }}>
          <AnnotateBar scale={1.05}/>
        </div>
      </div>
    </div>

    <div style={{ position:'absolute', bottom: 60, left: 0, right: 0, textAlign:'center' }}>
      <div style={{ display:'inline-flex', gap: 14, alignItems:'center' }}>
        <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, padding:'14px 26px', borderRadius: 12, background:'#fff', color:'#0A0E1A', fontSize: 15, fontWeight: 600 }}>Download free</a>
        <a href={GITHUB_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, padding:'14px 26px', borderRadius: 12, color:'rgba(235,235,245,.75)', fontSize: 15, fontWeight: 500 }}>⌥ X · try now ↗</a>
      </div>
    </div>
  </div>
);

// ================================================================
// 03 · Light editorial — minimal, bright, marquee as hero motif
// ================================================================
export const HeroEditorial = () => (
  <div style={{ position:'absolute', inset:0, background:'linear-gradient(180deg,#F6F7FB 0%,#EAEDF5 100%)', overflow:'hidden', color:'#0A0E1A', fontFamily:'Inter, sans-serif' }}>
    <div style={{ position:'absolute', right: -200, top: -200, width: 900, height: 900, borderRadius: '50%', background:'radial-gradient(circle,#6A9BFF33,transparent 60%)' }}/>
    <div style={{ position:'absolute', inset:0, backgroundImage:'linear-gradient(rgba(10,14,26,.035) 1px, transparent 1px), linear-gradient(90deg, rgba(10,14,26,.035) 1px, transparent 1px)', backgroundSize:'40px 40px' }}/>

    <div style={{ position:'absolute', top:40, left:60, right:60, display:'flex', justifyContent:'space-between', alignItems:'center', zIndex: 5 }}>
      <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
        <AppIcon size={38} />
        <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: -.3 }}>ShotX</div>
      </div>
      <div style={{ display:'flex', gap: 36, fontSize: 14, color:'rgba(10,14,26,.65)', fontWeight: 500 }}>
        <span>Features</span><span>Changelog</span><span>Pricing</span><span>Support</span>
      </div>
      <div style={{ padding:'10px 18px', fontSize: 14, fontWeight: 600, background:'#0A0E1A', color:'#fff', borderRadius: 10 }}>Download</div>
    </div>

    <div style={{ position:'absolute', left: 100, top: 230, width: 680 }}>
      <div style={{ fontSize: 12, letterSpacing: 3, textTransform:'uppercase', color:'#4A7BEE', fontWeight: 600, marginBottom: 20 }}>Introducing ShotX 2.0</div>
      <h1 style={{ fontSize: 110, lineHeight: .94, letterSpacing: -3.5, fontWeight: 800, margin: 0 }}>
        Screenshots,<br/>
        reimagined<br/>
        for <span style={{ fontStyle:'italic', color:'#4A7BEE'}}>macOS</span>.
      </h1>
      <p style={{ fontSize: 19, lineHeight: 1.55, color:'rgba(10,14,26,.6)', maxWidth: 500, marginTop: 32, fontWeight: 400 }}>
        Capture, record, annotate, and search. A modern menu-bar app built for people who live on the keyboard.
      </p>
      <div style={{ display:'flex', gap: 28, marginTop: 40, alignItems:'center' }}>
        <div style={{ padding:'14px 22px', borderRadius: 12, background:'#0A0E1A', color:'#fff', fontSize: 15, fontWeight: 600 }}>Download for Mac →</div>
        <div style={{ fontSize: 13, color:'rgba(10,14,26,.5)' }}>Free · macOS 13+<br/>Apple Silicon &amp; Intel</div>
      </div>
    </div>

    <div style={{ position:'absolute', right: 80, top: 200, width: 700, height: 560 }}>
      <div style={{ position:'absolute', inset: 0, borderRadius: 24, overflow:'hidden', boxShadow:'0 40px 80px rgba(10,14,26,.2)', background:'linear-gradient(135deg,#CCD6EC,#9FB4DE)' }}>
        <div style={{ position:'absolute', inset: 0, background:'linear-gradient(180deg, rgba(255,255,255,.3), transparent 30%)' }}/>
        <div style={{ position:'absolute', top: 40, right: 30, display:'flex', flexDirection:'column', gap: 24, alignItems:'center' }}>
          {[0,1,2].map(i=>(
            <div key={i} style={{ width: 56, height: 56, borderRadius: 12, background:'rgba(255,255,255,.5)', border:'1px solid rgba(255,255,255,.7)' }}/>
          ))}
        </div>
        <div style={{ position:'absolute', top: 80, left: 60, right: 130 }}>
          <CapturedSample scale={.85} w={500} h={360} tone="light"/>
        </div>
      </div>
      <div style={{ position:'absolute', top: 140, left: 40, zIndex: 2 }}>
        <Marquee w={540} h={320} color="#0A0E1A" thickness={2.5} dash={10} dims="540 × 320"/>
      </div>
      <div style={{ position:'absolute', bottom: -40, left: '50%', transform:'translateX(-50%)', zIndex: 3 }}>
        <CaptureToolbar scale={.85}/>
      </div>
    </div>
  </div>
);

// ================================================================
// 04 · Abstract marquee — typographic, big shortcut key
// ================================================================
export const HeroMarquee = () => (
  <div style={{ position:'absolute', inset:0, background:'radial-gradient(ellipse at 50% 60%, #1B2E5F 0%, #0A1028 50%, #04060F 100%)', overflow:'hidden', color:'#fff', fontFamily:'Inter, sans-serif' }}>
    <GridBg size={60} />
    <BigGlow color="#4A7BEE" x="50%" y="55%" size={1400} opacity={.55} />

    <div style={{ position:'absolute', top: 50, left: 60, display:'flex', alignItems:'center', gap: 12, zIndex: 10 }}>
      <AppIcon size={38}/>
      <div style={{ fontSize: 20, fontWeight: 700 }}>ShotX</div>
    </div>
    <div style={{ position:'absolute', top: 60, right: 60, fontSize: 13, color:'rgba(235,235,245,.5)', letterSpacing: 2, textTransform:'uppercase' }}>HERO · 01 / 04</div>

    <div style={{ position:'absolute', top: 130, left: 140, right: 140, bottom: 200, pointerEvents:'none' }}>
      <svg width="100%" height="100%" style={{ position:'absolute', inset:0 }}>
        <rect x="1" y="1" width="calc(100% - 2px)" height="calc(100% - 2px)" fill="none" stroke="#6A9BFF" strokeWidth="2.5" strokeDasharray="14 10" rx="4"/>
      </svg>
      {[{t:'top',l:'left'},{t:'top',r:'right'},{b:'bottom',l:'left'},{b:'bottom',r:'right'}].map((p,i)=>{
        const style = { position:'absolute', width:14, height:14, background:'#fff', border:'2px solid #6A9BFF', borderRadius:3, boxShadow:'0 4px 8px rgba(0,0,0,.5)' };
        if (p.t) style.top = -7; if (p.b) style.bottom = -7;
        if (p.l) style.left = -7; if (p.r) style.right = -7;
        return <div key={i} style={style}/>;
      })}
      <div style={{ position:'absolute', top: -36, left: 0, padding:'5px 10px', background:'#0A0E1A', color:'#6A9BFF', fontSize: 13, fontFamily:'JetBrains Mono, monospace', fontWeight: 600, borderRadius: 5, border:'1px solid rgba(106,155,255,.35)' }}>1320 × 560</div>
    </div>

    <div style={{ position:'absolute', top: '50%', left: '50%', transform:'translate(-50%,-55%)', textAlign:'center', width:'80%', zIndex: 5 }}>
      <h1 style={{ fontSize: 180, lineHeight: .88, letterSpacing: -6, fontWeight: 800, margin: 0, background:'linear-gradient(180deg,#fff 10%,#6A9BFF 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>
        Drag.<br/>Shoot.<br/>Ship.
      </h1>
      <p style={{ fontSize: 20, color:'rgba(235,235,245,.7)', marginTop: 32, fontWeight: 400, letterSpacing: .2 }}>
        Modern macOS screen capture — from your menu bar to your clipboard in one keystroke.
      </p>
    </div>

    <div style={{ position:'absolute', bottom: 70, left: 0, right: 0, display:'flex', justifyContent:'space-between', alignItems:'center', padding:'0 100px' }}>
      <div style={{ display:'flex', gap: 8, alignItems:'center', fontFamily:'JetBrains Mono, monospace' }}>
        {['⌥','⇧','4'].map((k,i)=>(
          <div key={i} style={{ width: 48, height: 48, borderRadius: 10, background:'rgba(255,255,255,.08)', border:'1px solid rgba(255,255,255,.14)', display:'grid', placeItems:'center', fontSize: 22, fontWeight: 600 }}>{k}</div>
        ))}
        <div style={{ marginLeft: 12, fontSize: 13, color:'rgba(235,235,245,.55)' }}>global shortcut</div>
      </div>
      <div style={{ opacity: .95 }}>
        <CaptureToolbar scale={.8}/>
      </div>
    </div>
  </div>
);

// ================================================================
// 05 · Social card 1200×1200 — square, product-forward
// ================================================================
export const HeroSocial = () => (
  <div style={{ position:'absolute', inset:0, background:'radial-gradient(ellipse at 50% 55%, #1B2E5F 0%, #0A1028 55%, #04060F 100%)', overflow:'hidden', color:'#fff', fontFamily:'Inter, sans-serif' }}>
    <GridBg size={56}/>
    <BigGlow color="#4A7BEE" x="50%" y="58%" size={900} opacity={.55} />

    <div style={{ position:'absolute', top: 60, left: 70, display:'flex', alignItems:'center', gap: 14 }}>
      <AppIcon size={56}/>
      <div>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -.3 }}>ShotX</div>
        <div style={{ fontSize: 13, color:'rgba(235,235,245,.55)' }}>Modern macOS screen capture</div>
      </div>
    </div>

    <div style={{ position:'absolute', left: '50%', top: 350, transform:'translateX(-50%)' }}>
      <div style={{ position:'relative' }}>
        <CapturedSample scale={1.1} w={760} h={480} tone="light"/>
        <div style={{ position:'absolute', top: 160, left: 180 }}>
          <Marquee w={460} h={240} color="#4A7BEE" dims="Capture"/>
        </div>
      </div>
      <div style={{ position:'absolute', bottom: -40, left: '50%', transform:'translateX(-50%)' }}>
        <CaptureToolbar scale={.95}/>
      </div>
    </div>

    <div style={{ position:'absolute', left: 70, right: 70, bottom: 70 }}>
      <h1 style={{ fontSize: 72, lineHeight: .98, letterSpacing: -2, fontWeight: 800, margin: 0 }}>
        Capture anything.<br/>
        <span style={{ color:'#6A9BFF' }}>Annotate instantly.</span>
      </h1>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-end', marginTop: 24 }}>
        <p style={{ fontSize: 17, color:'rgba(235,235,245,.65)', margin: 0, maxWidth: 500 }}>
          Screenshots, recording, GIFs, annotation, and searchable history — all from your menu bar.
        </p>
        <div style={{ padding:'12px 20px', borderRadius: 10, background:'#fff', color:'#0A0E1A', fontSize: 14, fontWeight: 600 }}>shotx.app</div>
      </div>
    </div>
  </div>
);

// ================================================================
// 06 · Minimal portrait — App Store / print-style
// ================================================================
export const HeroMinimal = () => (
  <div style={{ position:'absolute', inset:0, background:'#F4F5F9', overflow:'hidden', color:'#0A0E1A', fontFamily:'Inter, sans-serif' }}>
    <div style={{ position:'absolute', top: -300, left: -200, width: 900, height: 900, borderRadius:'50%', background:'radial-gradient(circle,#C6D6F8,transparent 55%)' }}/>
    <div style={{ position:'absolute', inset:0, backgroundImage:'linear-gradient(rgba(10,14,26,.03) 1px, transparent 1px), linear-gradient(90deg, rgba(10,14,26,.03) 1px, transparent 1px)', backgroundSize:'40px 40px' }}/>

    <div style={{ position:'absolute', top: 90, left: '50%', transform:'translateX(-50%)' }}>
      <AppIcon size={128} />
    </div>

    <div style={{ position:'absolute', top: 260, left: 80, right: 80, textAlign:'center' }}>
      <div style={{ fontSize: 13, letterSpacing: 4, textTransform:'uppercase', color:'#4A7BEE', fontWeight: 600, marginBottom: 18 }}>ShotX · for macOS</div>
      <h1 style={{ fontSize: 96, lineHeight: .96, letterSpacing: -3, fontWeight: 800, margin: 0 }}>
        Screen capture,<br/>without the fuss.
      </h1>
      <p style={{ fontSize: 18, color:'rgba(10,14,26,.55)', maxWidth: 680, margin: '24px auto 0', lineHeight: 1.5 }}>
        Screenshots, recording, GIFs, OCR text extraction, annotation, and a searchable history — all from the menu bar, all on your keyboard.
      </p>
    </div>

    <div style={{ position:'absolute', left: 90, bottom: 120, transform:'rotate(-4deg)' }}>
      <ShotXMenu scale={.95}/>
    </div>
    <div style={{ position:'absolute', right: 100, bottom: 200, transform:'rotate(3deg)' }}>
      <CaptureToolbar scale={1}/>
    </div>
    <div style={{ position:'absolute', right: 130, bottom: 90, transform:'rotate(3deg)', width: 720 }}>
      <AnnotateBar scale={.9}/>
    </div>

    <div style={{ position:'absolute', left: 0, right: 0, bottom: 40, textAlign:'center', fontSize: 13, color:'rgba(10,14,26,.45)', letterSpacing: 2, textTransform:'uppercase', fontWeight: 500 }}>
      Available on the Mac App Store  ·  shotx.app
    </div>
  </div>
);

// ================================================================
// Mobile hero — stacked, no scaled artboard
// ================================================================
const MobileHeroClassic = () => (
  <div style={{ position: 'relative', padding: '64px 22px 48px', overflow: 'hidden', fontFamily: 'Inter, sans-serif' }}>
    <div aria-hidden style={{ position:'absolute', inset:0, background:'radial-gradient(ellipse 120% 70% at 60% 28%, #15233F 0%, rgba(10,14,26,.5) 40%, transparent 80%)', pointerEvents:'none' }}/>
    <BigGlow color="#3566E0" x="70%" y="22%" size={520} opacity={.5} />

    <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 72 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <AppIcon size={34} />
        <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: -.2 }}>ShotX</div>
      </div>
      <a href={GITHUB_URL} target="_blank" rel="noreferrer" aria-label="GitHub" style={{ ...linkReset, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 40, height: 40, borderRadius: 10, border: '1px solid rgba(255,255,255,.14)', background: 'rgba(255,255,255,.04)', color: 'rgba(235,235,245,.85)' }}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.58 2 12.25c0 4.54 2.87 8.38 6.84 9.74.5.1.68-.22.68-.49 0-.24-.01-.87-.01-1.7-2.78.62-3.37-1.37-3.37-1.37-.46-1.18-1.12-1.5-1.12-1.5-.92-.64.07-.63.07-.63 1.01.08 1.54 1.07 1.54 1.07.9 1.56 2.35 1.11 2.93.85.09-.67.35-1.12.63-1.38-2.22-.26-4.56-1.14-4.56-5.06 0-1.12.39-2.03 1.03-2.75-.1-.26-.45-1.3.1-2.71 0 0 .84-.28 2.75 1.05.8-.23 1.65-.34 2.5-.34.85 0 1.7.11 2.5.34 1.91-1.33 2.75-1.05 2.75-1.05.55 1.41.2 2.45.1 2.71.64.72 1.03 1.63 1.03 2.75 0 3.93-2.34 4.8-4.57 5.05.36.32.68.93.68 1.88 0 1.36-.01 2.45-.01 2.79 0 .27.18.6.69.49A10.02 10.02 0 0 0 22 12.25C22 6.58 17.52 2 12 2z"/></svg>
      </a>
    </div>

    <div style={{ position: 'relative' }}>
      <h1 style={{ fontSize: 'clamp(40px, 11vw, 64px)', lineHeight: 1, letterSpacing: -1.5, fontWeight: 800, margin: 0 }}>
        Capture<br/>anything.<br/>
        <span style={{ background:'linear-gradient(90deg,#6A9BFF,#C8D4F0)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>Annotate instantly.</span>
      </h1>
      <p style={{ fontSize: 16, lineHeight: 1.55, color: 'rgba(235,235,245,.68)', margin: '20px 0 0', fontWeight: 400 }}>
        Modern macOS screen capture for the menu bar. Screenshots, recording, GIFs, OCR, annotation, and a searchable history — all from your keyboard.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 28 }}>
        <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '14px 20px', borderRadius: 12, background: '#fff', color: '#0A0E1A', fontSize: 15, fontWeight: 600, boxShadow: '0 20px 40px rgba(106,155,255,.22)' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>
          Download for Mac
        </a>
        <a href={GITHUB_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '14px 20px', borderRadius: 12, background: 'rgba(255,255,255,.05)', border: '1px solid rgba(255,255,255,.14)', color: 'rgba(235,235,245,.9)', fontSize: 15, fontWeight: 500 }}>
          View on GitHub
        </a>
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 8, marginTop: 24, fontSize: 11, color: 'rgba(235,235,245,.55)', fontFamily: 'JetBrains Mono, monospace', letterSpacing: .3 }}>
        <span style={{ color: '#6ED37A' }}>100% open source</span>
        <span style={{ opacity: .4 }}>//</span>
        <span>MIT licensed</span>
        <span style={{ opacity: .4 }}>//</span>
        <span>macOS 13+</span>
      </div>

      <div style={{ marginTop: 56, display: 'flex', justifyContent: 'center' }}>
        <div style={{ transform: 'scale(.82)', transformOrigin: 'center top' }}>
          <CaptureToolbar scale={.85}/>
        </div>
      </div>
    </div>
  </div>
);

const MobileHeroProduct = () => (
  <div style={{ position: 'relative', padding: '72px 22px 64px', overflow: 'hidden', fontFamily: 'Inter, sans-serif' }}>
    <BigGlow color="#3566E0" x="50%" y="55%" size={700} opacity={.45} />

    <div style={{ position: 'relative', textAlign: 'center' }}>
      <div style={{ display:'inline-flex', alignItems:'center', gap:10, padding:'8px 14px', borderRadius: 999, background:'rgba(255,255,255,.06)', border:'1px solid rgba(255,255,255,.1)', color:'rgba(235,235,245,.75)', fontSize: 12, fontWeight: 500, marginBottom: 22 }}>
        <AppIcon size={16} radius={4}/>
        ShotX for macOS
      </div>
      <h2 style={{ fontSize: 'clamp(36px, 10vw, 56px)', lineHeight: 1, letterSpacing: -1.5, fontWeight: 800, margin: 0 }}>
        The fastest way to<br/>
        <span style={{ fontStyle:'italic', fontWeight: 700, background:'linear-gradient(90deg,#6A9BFF 0%,#fff 50%,#6A9BFF 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>capture your screen.</span>
      </h2>
      <p style={{ fontSize: 15, color:'rgba(235,235,245,.65)', lineHeight: 1.55, margin: '20px auto 0', maxWidth: 460 }}>
        Area, fullscreen, window, or record — then annotate and copy to clipboard without leaving your keyboard.
      </p>
    </div>

    <div style={{ position: 'relative', marginTop: 36, display: 'flex', justifyContent: 'center' }}>
      <div style={{ transform: 'scale(.72)', transformOrigin: 'center top' }}>
        <CapturedSample scale={.7} w={480} h={320} tone="light"/>
      </div>
    </div>

    <div style={{ position: 'relative', marginTop: -20, display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'stretch' }}>
      <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '14px 20px', borderRadius: 12, background: '#fff', color: '#0A0E1A', fontSize: 15, fontWeight: 600 }}>
        Download free
      </a>
      <a href={GITHUB_URL} target="_blank" rel="noreferrer" style={{ ...linkReset, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', padding: '12px 20px', borderRadius: 12, color: 'rgba(235,235,245,.7)', fontSize: 14, fontWeight: 500 }}>
        ⌥ X · try now ↗
      </a>
    </div>
  </div>
);

// ================================================================
// Responsive section wrappers — pick artboard vs mobile layout
// ================================================================
export const HeroClassicSection = () => {
  const isMobile = useIsMobile();
  if (isMobile) return <MobileHeroClassic />;
  return (
    <ScaledArtboard width={1600} height={900}>
      <HeroClassic />
    </ScaledArtboard>
  );
};

export const HeroProductSection = () => {
  const isMobile = useIsMobile();
  if (isMobile) return <MobileHeroProduct />;
  return (
    <ScaledArtboard width={1600} height={900}>
      <HeroProduct />
    </ScaledArtboard>
  );
};

// Original ShotX UI recreated as crisp HTML/CSS components.
// These mirror the user's own app UI (menu bar menu, capture toolbar, annotation bar).

import { useEffect, useState } from 'react';

export function useIsMobile(breakpoint = 820) {
  const query = `(max-width: ${breakpoint - 1}px)`;
  const [matches, setMatches] = useState(
    () => typeof window !== 'undefined' && window.matchMedia(query).matches
  );
  useEffect(() => {
    const mql = window.matchMedia(query);
    const handler = (e) => setMatches(e.matches);
    mql.addEventListener('change', handler);
    setMatches(mql.matches);
    return () => mql.removeEventListener('change', handler);
  }, [query]);
  return matches;
}

export const Icon = ({ name, size = 18, stroke = 1.75, color = 'currentColor' }) => {
  const s = size;
  const common = { width: s, height: s, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'grid':
      return <svg {...common}><rect x="3.5" y="3.5" width="7" height="7" rx="1.2"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.2"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.2"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.2"/></svg>;
    case 'area':
      return <svg {...common}><path d="M4 8V5.5A1.5 1.5 0 0 1 5.5 4H8"/><path d="M16 4h2.5A1.5 1.5 0 0 1 20 5.5V8"/><path d="M20 16v2.5a1.5 1.5 0 0 1-1.5 1.5H16"/><path d="M8 20H5.5A1.5 1.5 0 0 1 4 18.5V16"/></svg>;
    case 'previous':
      return <svg {...common}><path d="M4 4v6h6"/><path d="M20 12a8 8 0 1 0-2.34 5.66"/></svg>;
    case 'fullscreen':
      return <svg {...common}><rect x="3" y="5" width="18" height="12" rx="1.5"/><path d="M9 21h6"/><path d="M12 17v4"/></svg>;
    case 'window':
      return <svg {...common}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 9h18"/><circle cx="6" cy="7" r=".5" fill={color}/><circle cx="8" cy="7" r=".5" fill={color}/><circle cx="10" cy="7" r=".5" fill={color}/></svg>;
    case 'camera':
      return <svg {...common}><rect x="2" y="6" width="14" height="12" rx="2"/><path d="M16 10l5-2.5v9L16 14"/></svg>;
    case 'timer':
      return <svg {...common}><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 1.5"/><path d="M9 3h6"/></svg>;
    case 'check':
      return <svg {...common}><path d="M4 12l5 5L20 6"/></svg>;
    case 'folder':
      return <svg {...common}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>;
    case 'clipboard':
      return <svg {...common}><rect x="6" y="4" width="12" height="17" rx="2"/><path d="M9 4h6v3H9z"/></svg>;
    case 'pin':
      return <svg {...common}><path d="M12 2v6"/><path d="M8 8h8l-1 7H9z"/><path d="M12 15v6"/></svg>;
    case 'history':
      return <svg {...common}><path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/><path d="M12 8v4l3 2"/></svg>;
    case 'info':
      return <svg {...common}><circle cx="12" cy="12" r="9"/><path d="M12 11v5"/><circle cx="12" cy="8" r=".6" fill={color}/></svg>;
    case 'gear':
      return <svg {...common}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>;
    case 'power':
      return <svg {...common}><path d="M12 3v9"/><path d="M6.5 7.5a7 7 0 1 0 11 0"/></svg>;
    case 'record':
      return <svg {...common}><rect x="3" y="7" width="13" height="10" rx="2"/><path d="M16 11l5-2v6l-5-2"/></svg>;
    case 'arrow':
      return <svg {...common}><path d="M5 19L19 5"/><path d="M9 5h10v10"/></svg>;
    case 'rect':
      return <svg {...common}><rect x="4" y="6" width="16" height="12" rx="1.5"/></svg>;
    case 'undo':
      return <svg {...common}><path d="M9 14L4 9l5-5"/><path d="M4 9h9a7 7 0 0 1 0 14h-3"/></svg>;
    case 'copy':
      return <svg {...common}><rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/></svg>;
    case 'save':
      return <svg {...common}><path d="M12 3v12"/><path d="M7 10l5 5 5-5"/><path d="M5 21h14"/></svg>;
    case 'number':
      return <svg {...common}><circle cx="12" cy="12" r="9"/><text x="12" y="16" textAnchor="middle" fontSize="11" fontWeight="700" fill={color} stroke="none">1</text></svg>;
    case 'text':
      return <svg {...common} strokeWidth={stroke}><path d="M5 6h14"/><path d="M12 6v14"/></svg>;
    case 'chevron':
      return <svg {...common}><path d="M9 6l6 6-6 6"/></svg>;
    case 'bell':
      return <svg {...common}><path d="M18 16v-5a6 6 0 1 0-12 0v5l-2 2h16z"/><path d="M10 21a2 2 0 0 0 4 0"/></svg>;
    case 'wifi':
      return <svg {...common}><path d="M2 9a15 15 0 0 1 20 0"/><path d="M5 12.5a10 10 0 0 1 14 0"/><path d="M8.5 16a5 5 0 0 1 7 0"/><circle cx="12" cy="19" r=".8" fill={color}/></svg>;
    case 'battery':
      return <svg {...common}><rect x="2" y="8" width="18" height="9" rx="2"/><path d="M22 11v3"/><rect x="4" y="10" width="12" height="5" rx="1" fill={color} stroke="none"/></svg>;
    case 'search':
      return <svg {...common}><circle cx="11" cy="11" r="6"/><path d="M20 20l-4-4"/></svg>;
    case 'textscan':
      return <svg {...common}><path d="M4 8V6a2 2 0 0 1 2-2h2"/><path d="M16 4h2a2 2 0 0 1 2 2v2"/><path d="M20 16v2a2 2 0 0 1-2 2h-2"/><path d="M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M7 10h10"/><path d="M7 14h6"/></svg>;
    case 'eyedropper':
      return <svg {...common}><path d="M14 4l6 6"/><path d="M16 2l6 6-3 3-6-6z"/><path d="M13 7l4 4L6.5 21.5a1.8 1.8 0 0 1-2.5 0 1.8 1.8 0 0 1 0-2.5z"/></svg>;
    default: return null;
  }
};

export const AppIcon = ({ size = 96, radius }) => {
  const r = radius ?? size * 0.23;
  return (
    <div style={{ width: size, height: size, borderRadius: r, background: 'linear-gradient(180deg, #6A9BFF 0%, #3566E0 65%, #1E3FA8 100%)', boxShadow: `0 ${size*0.06}px ${size*0.2}px rgba(30,63,168,.45), inset 0 1px 0 rgba(255,255,255,.35), inset 0 -2px 0 rgba(0,0,0,.12)`, display: 'grid', placeItems: 'center', position: 'relative', overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(120% 80% at 50% 0%, rgba(255,255,255,.25), transparent 55%)' }} />
      <svg width={size*0.64} height={size*0.64} viewBox="0 0 64 64" fill="none" style={{ position: 'relative' }}>
        <path d="M6 18V10a4 4 0 0 1 4-4h8" stroke="#fff" strokeWidth="6.5" strokeLinecap="round" fill="none"/>
        <path d="M46 6h8a4 4 0 0 1 4 4v8" stroke="#fff" strokeWidth="6.5" strokeLinecap="round" fill="none"/>
        <path d="M58 46v8a4 4 0 0 1-4 4h-8" stroke="#fff" strokeWidth="6.5" strokeLinecap="round" fill="none"/>
        <path d="M18 58h-8a4 4 0 0 1-4-4v-8" stroke="#fff" strokeWidth="6.5" strokeLinecap="round" fill="none"/>
        <path d="M24 24l16 16M40 24L24 40" stroke="#fff" strokeWidth="6.5" strokeLinecap="round"/>
      </svg>
    </div>
  );
};

export const CaptureToolbar = ({ scale = 1 }) => (
  <div style={{ display: 'inline-flex', alignItems: 'center', gap: 28*scale, padding: `${18*scale}px ${30*scale}px`, background: 'rgba(22,22,24,.92)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', border: '1px solid rgba(255,255,255,.08)', borderRadius: 22*scale, boxShadow: `0 ${30*scale}px ${60*scale}px rgba(0,0,0,.55), 0 1px 0 rgba(255,255,255,.06) inset` }}>
    {[
      {icon:'area', label:'Area', active:true},
      {icon:'fullscreen', label:'Fullscreen'},
      {icon:'window', label:'Window'},
      {icon:'previous', label:'Previous'},
      {icon:'timer', label:'Timer'},
      {icon:'record', label:'Record'},
    ].map((it,i)=>(
      <div key={i} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:6*scale, color: it.active ? '#fff' : 'rgba(235,235,240,.82)', padding: `${4*scale}px ${6*scale}px`, borderRadius: 10*scale, background: it.active ? 'rgba(255,255,255,.08)' : 'transparent' }}>
        <Icon name={it.icon} size={26*scale} stroke={1.6} />
        <div style={{ fontSize: 12*scale, fontWeight: 500, letterSpacing: .2 }}>{it.label}</div>
      </div>
    ))}
  </div>
);

export const AnnotateBar = ({ scale = 1 }) => {
  const colors = ['#E34444', '#F08A2B', '#F3C53A', '#3EBB6A', '#2F86FF', '#8856E6', '#111'];
  return (
    <div style={{ display:'inline-flex', alignItems:'center', gap: 14*scale, padding: `${10*scale}px ${14*scale}px`, background: '#1C1C1E', border: '1px solid rgba(255,255,255,.06)', borderRadius: 14*scale, boxShadow: `0 ${24*scale}px ${40*scale}px rgba(0,0,0,.5)` }}>
      <div style={{ display:'flex', gap: 6*scale }}>
        <div style={{ width: 34*scale, height: 34*scale, borderRadius: 9*scale, background:'#F08A2B', display:'grid', placeItems:'center', color:'#fff' }}><Icon name="arrow" size={18*scale} stroke={2}/></div>
        <div style={{ width: 34*scale, height: 34*scale, borderRadius: 9*scale, background:'rgba(255,255,255,.06)', display:'grid', placeItems:'center', color:'#eaeaea' }}><Icon name="rect" size={18*scale} stroke={1.8}/></div>
        <div style={{ width: 34*scale, height: 34*scale, borderRadius: 9*scale, background:'rgba(255,255,255,.06)', display:'grid', placeItems:'center', color:'#eaeaea', fontWeight:700, fontSize:14*scale }}>Aa</div>
        <div style={{ width: 34*scale, height: 34*scale, borderRadius: 9*scale, background:'rgba(255,255,255,.06)', display:'grid', placeItems:'center', color:'#eaeaea' }}><Icon name="number" size={20*scale} stroke={1.6}/></div>
      </div>
      <div style={{ width: 1, height: 24*scale, background:'rgba(255,255,255,.08)' }}/>
      <div style={{ display:'flex', gap: 8*scale }}>
        {colors.map((c,i)=>(
          <div key={i} style={{ width: 16*scale, height: 16*scale, borderRadius: '50%', background: c, boxShadow: i===0 ? `0 0 0 ${2*scale}px rgba(227,68,68,.35)` : 'none', border: c === '#111' ? '1px solid rgba(255,255,255,.15)' : 'none' }}/>
        ))}
        <div style={{ width: 16*scale, height: 16*scale, borderRadius: '50%', background:'#fff' }}/>
      </div>
      <div style={{ flex: 1, minWidth: 40*scale }}/>
      <div style={{ width: 34*scale, height: 34*scale, borderRadius: 9*scale, background:'rgba(255,255,255,.06)', display:'grid', placeItems:'center', color:'#eaeaea' }}><Icon name="undo" size={16*scale} stroke={1.8}/></div>
      <div style={{ padding: `${8*scale}px ${14*scale}px`, color:'#d7d7da', fontSize: 13*scale, fontWeight: 500 }}>Cancel</div>
      <div style={{ padding: `${8*scale}px ${14*scale}px`, borderRadius: 9*scale, background:'rgba(255,255,255,.06)', color:'#eaeaea', fontSize: 13*scale, fontWeight: 500, display:'flex', alignItems:'center', gap:6*scale }}><Icon name="save" size={14*scale} stroke={1.8}/> Save</div>
      <div style={{ padding: `${8*scale}px ${14*scale}px`, borderRadius: 9*scale, background:'#F08A2B', color:'#fff', fontSize: 13*scale, fontWeight: 600, display:'flex', alignItems:'center', gap:6*scale }}><Icon name="copy" size={14*scale} stroke={1.8}/> Copy</div>
    </div>
  );
};

const MenuRow = ({ icon, label, shortcut, checked, faded, scale = 1 }) => (
  <div style={{ display:'grid', gridTemplateColumns: `${18*scale}px ${18*scale}px 1fr auto`, alignItems:'center', gap: 10*scale, padding: `${7*scale}px ${14*scale}px`, color: faded ? 'rgba(235,235,240,.45)' : '#ececef', fontSize: 13*scale }}>
    <div style={{ color:'#6ED37A' }}>{checked ? <Icon name="check" size={13*scale} stroke={2.2}/> : null}</div>
    {icon ? <Icon name={icon} size={15*scale} stroke={1.6} color="rgba(235,235,240,.9)"/> : <div/>}
    <div style={{ fontWeight: 500 }}>{label}</div>
    <div style={{ color:'rgba(235,235,240,.45)', fontSize: 12*scale, display:'flex', alignItems:'center', gap: 2*scale }}>{shortcut}</div>
  </div>
);

const MenuSep = ({ scale = 1 }) => <div style={{ height: 1, margin: `${5*scale}px ${10*scale}px`, background:'rgba(255,255,255,.07)' }}/>;

export const ShotXMenu = ({ scale = 1 }) => (
  <div style={{ width: 300*scale, background:'rgba(38,38,40,.94)', backdropFilter:'blur(26px)', WebkitBackdropFilter:'blur(26px)', border:'1px solid rgba(255,255,255,.08)', borderRadius: 12*scale, padding: `${6*scale}px 0`, boxShadow:`0 ${30*scale}px ${60*scale}px rgba(0,0,0,.6)`, color:'#fff' }}>
    <MenuRow scale={scale} icon="grid" label="All-In-One" />
    <MenuSep scale={scale}/>
    <MenuRow scale={scale} icon="area" label="Capture Area" shortcut="⌥X"/>
    <MenuRow scale={scale} icon="previous" label="Capture Previous Area" />
    <MenuRow scale={scale} icon="fullscreen" label="Capture Fullscreen" />
    <MenuRow scale={scale} icon="window" label="Capture Window" />
    <MenuRow scale={scale} icon="textscan" label="Extract Text (OCR)" shortcut="⌥⇧T"/>
    <MenuSep scale={scale}/>
    <MenuRow scale={scale} icon="camera" label="Record Screen" />
    <MenuRow scale={scale} icon="timer" label="Self-Timer" shortcut={<Icon name="chevron" size={11*scale} stroke={2}/>}/>
    <MenuSep scale={scale}/>
    <MenuRow scale={scale} icon="fullscreen" label="Show Desktop Icons" checked/>
    <MenuRow scale={scale} icon="folder" label="Open…" />
    <MenuRow scale={scale} icon="clipboard" label="Open from Clipboard" shortcut="⇧⌘V"/>
    <MenuRow scale={scale} icon="pin" label="Pin to the Screen…" />
    <MenuSep scale={scale}/>
    <MenuRow scale={scale} icon="history" label="Capture History…"/>
    <MenuSep scale={scale}/>
    <div style={{ display:'flex', alignItems:'center', gap: 10*scale, padding: `${7*scale}px ${14*scale}px`, fontSize: 13*scale, color:'rgba(235,235,240,.55)'}}>
      <span style={{ width: 10*scale, height: 10*scale, borderRadius: '50%', background:'#3EBB6A', boxShadow:'0 0 8px rgba(62,187,106,.7)' }}/>
      Permissions Granted
    </div>
    <MenuRow scale={scale} icon="info" label="About ShotX" />
    <MenuRow scale={scale} icon="gear" label="Settings…" shortcut="⌘,"/>
    <MenuRow scale={scale} icon="power" label="Quit ShotX" shortcut="⌘Q"/>
  </div>
);

export const MenuBar = ({ scale = 1 }) => (
  <div style={{ display:'flex', alignItems:'center', gap: 18*scale, padding: `${6*scale}px ${14*scale}px`, background:'rgba(40,40,44,.6)', backdropFilter:'blur(18px)', WebkitBackdropFilter:'blur(18px)', borderRadius: 8*scale, color:'rgba(235,235,240,.9)' }}>
    <div style={{ padding: `${3*scale}px ${6*scale}px`, borderRadius: 5*scale, background:'rgba(255,255,255,.14)', display:'grid', placeItems:'center' }}>
      <Icon name="area" size={16*scale} stroke={1.8}/>
    </div>
    <Icon name="bell" size={16*scale} stroke={1.6}/>
    <Icon name="wifi" size={16*scale} stroke={1.6}/>
    <Icon name="battery" size={18*scale} stroke={1.6}/>
    <div style={{ fontSize: 12*scale, fontWeight: 500, fontVariantNumeric:'tabular-nums' }}>Wed 9:41</div>
    <Icon name="search" size={14*scale} stroke={1.8}/>
  </div>
);

export const CapturedSample = ({ scale = 1, w = 520, h = 340, tone = 'light' }) => (
  <div style={{ width: w*scale, height: h*scale, borderRadius: 14*scale, overflow:'hidden', background: tone === 'light' ? 'linear-gradient(180deg,#F6F7FA,#E7EAF2)' : 'linear-gradient(180deg,#2A2A2E,#1A1A1D)', boxShadow: `0 ${30*scale}px ${70*scale}px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.06)`, position:'relative' }}>
    <div style={{ height: 36*scale, background: tone === 'light' ? 'rgba(245,246,249,.9)' : 'rgba(28,28,30,.9)', borderBottom: `1px solid ${tone==='light' ? 'rgba(0,0,0,.06)' : 'rgba(255,255,255,.06)'}`, display:'flex', alignItems:'center', padding: `0 ${14*scale}px`, gap: 6*scale }}>
      <span style={{ width: 12*scale, height: 12*scale, borderRadius:'50%', background:'#FF5F57'}}/>
      <span style={{ width: 12*scale, height: 12*scale, borderRadius:'50%', background:'#FEBC2E'}}/>
      <span style={{ width: 12*scale, height: 12*scale, borderRadius:'50%', background:'#28C840'}}/>
    </div>
    <div style={{ padding: 24*scale, display:'flex', flexDirection:'column', gap: 14*scale }}>
      <div style={{ width: '55%', height: 18*scale, borderRadius: 5*scale, background: tone==='light' ? '#D0D5E0' : '#3A3A3E'}}/>
      <div style={{ width: '90%', height: 10*scale, borderRadius: 5*scale, background: tone==='light' ? '#DFE3EC' : '#34343A'}}/>
      <div style={{ width: '78%', height: 10*scale, borderRadius: 5*scale, background: tone==='light' ? '#DFE3EC' : '#34343A'}}/>
      <div style={{ width: '64%', height: 10*scale, borderRadius: 5*scale, background: tone==='light' ? '#DFE3EC' : '#34343A'}}/>
      <div style={{ height: 12*scale }}/>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 12*scale }}>
        <div style={{ aspectRatio: '4/3', borderRadius: 10*scale, background: tone==='light' ? 'linear-gradient(135deg,#E5ECFA,#C8D4F0)' : 'linear-gradient(135deg,#2E3B5F,#1E2A4A)'}}/>
        <div style={{ aspectRatio: '4/3', borderRadius: 10*scale, background: tone==='light' ? 'linear-gradient(135deg,#FFE6D0,#F6C89D)' : 'linear-gradient(135deg,#4B361F,#2E2214)'}}/>
        <div style={{ aspectRatio: '4/3', borderRadius: 10*scale, background: tone==='light' ? 'linear-gradient(135deg,#E0F2E5,#B8DDC3)' : 'linear-gradient(135deg,#1E3F2B,#152A1E)'}}/>
      </div>
    </div>
  </div>
);

export const Marquee = ({ w, h, color = '#6A9BFF', dash = 8, thickness = 2, showHandles = true, dims }) => (
  <div style={{ position:'relative', width: w, height: h, pointerEvents:'none' }}>
    <svg width={w} height={h} style={{ display:'block' }}>
      <rect x={thickness/2} y={thickness/2} width={w-thickness} height={h-thickness} fill="none" stroke={color} strokeWidth={thickness} strokeDasharray={`${dash} ${dash}`} rx="2"/>
    </svg>
    {showHandles && [[0,0],[w,0],[0,h],[w,h],[w/2,0],[w/2,h],[0,h/2],[w,h/2]].map((p,i)=>(
      <div key={i} style={{ position:'absolute', left: p[0]-4, top: p[1]-4, width:8, height:8, borderRadius:2, background:'#fff', border:`1px solid ${color}`, boxShadow:'0 2px 4px rgba(0,0,0,.4)' }}/>
    ))}
    {dims && (
      <div style={{ position:'absolute', top: -28, left: 0, padding: '3px 8px', background: 'rgba(12,13,15,.85)', color:'#fff', fontSize: 11, fontWeight: 600, borderRadius: 4, fontFamily:'JetBrains Mono, monospace', letterSpacing:.3 }}>{dims}</div>
    )}
  </div>
);

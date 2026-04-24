import { useEffect, useRef, useState } from 'react';

// Shell that centers sections on a dark background
export const DesignCanvas = ({ title, subtitle, children }) => (
  <div style={{ minHeight: '100vh', padding: '64px 32px 96px', color: '#fff' }}>
    <div style={{ maxWidth: 1480, margin: '0 auto' }}>
      <div style={{ marginBottom: 48 }}>
        {title && <h1 style={{ fontSize: 32, fontWeight: 700, letterSpacing: -.5, margin: 0 }}>{title}</h1>}
        {subtitle && <p style={{ fontSize: 15, color: 'rgba(235,235,245,.6)', marginTop: 10, maxWidth: 760 }}>{subtitle}</p>}
      </div>
      {children}
    </div>
  </div>
);

// A titled group of artboards laid out in a responsive grid
export const DCSection = ({ id, title, children }) => (
  <section id={id} style={{ marginBottom: 72 }}>
    {title && (
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginBottom: 24 }}>
        <h2 style={{ fontSize: 14, fontWeight: 600, letterSpacing: 2, textTransform: 'uppercase', color: 'rgba(235,235,245,.55)', margin: 0 }}>{title}</h2>
        <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,.08)' }}/>
      </div>
    )}
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(min(100%, 720px), 1fr))', gap: 28 }}>
      {children}
    </div>
  </section>
);

// A fixed-dimension artboard that scales itself to whatever width the column gives it
export const DCArtboard = ({ id, label, width, height, children }) => {
  const wrapRef = useRef(null);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const measure = () => {
      const w = el.clientWidth;
      setScale(w / width);
    };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [width]);

  return (
    <figure id={id} style={{ margin: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12, fontSize: 12, color: 'rgba(235,235,245,.55)', fontFamily: 'JetBrains Mono, monospace', letterSpacing: .3 }}>
        <span>{label}</span>
        <span style={{ opacity: .5 }}>·</span>
        <span>{width} × {height}</span>
      </div>
      <div
        ref={wrapRef}
        style={{
          position: 'relative',
          width: '100%',
          height: height * scale,
          borderRadius: 12,
          overflow: 'hidden',
          border: '1px solid rgba(255,255,255,.08)',
          background: '#0b0c10',
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width,
            height,
            transform: `scale(${scale})`,
            transformOrigin: '0 0',
          }}
        >
          {children}
        </div>
      </div>
    </figure>
  );
};

import { useEffect, useRef, useState } from 'react';

// Renders a fixed-dimension design at native scale, then uses CSS transform
// to fit the current container width. Preserves the artboard's aspect ratio.
export default function ScaledArtboard({ width, height, children }) {
  const wrapRef = useRef(null);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const measure = () => setScale(el.clientWidth / width);
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [width]);

  return (
    <div ref={wrapRef} style={{ position: 'relative', width: '100%', height: height * scale }}>
      <div style={{ position: 'absolute', top: 0, left: 0, width, height, transform: `scale(${scale})`, transformOrigin: '0 0' }}>
        {children}
      </div>
    </div>
  );
}

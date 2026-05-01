// Camera capture screen
function CameraIcon({ size = 28, color = '#fff' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M3 8a2 2 0 012-2h2.5l1.5-2h6l1.5 2H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"
        stroke={color} strokeWidth="1.8" strokeLinejoin="round"/>
      <circle cx="12" cy="13" r="4" stroke={color} strokeWidth="1.8"/>
    </svg>
  );
}

function CameraScreen({ theme, analyzing = false, onCapture, onClose }) {
  const [scanProgress, setScanProgress] = React.useState(0);
  React.useEffect(() => {
    if (!analyzing) return;
    let raf;
    const start = performance.now();
    const tick = (t) => {
      const p = Math.min(1, (t - start) / 2200);
      setScanProgress(p);
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [analyzing]);

  // Fake "viewfinder" — a stylized food image using gradients + emoji
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: '#000',
      display: 'flex', flexDirection: 'column',
      paddingTop: 54,
    }}>
      {/* Viewfinder — fake food scene */}
      <div style={{
        flex: 1, position: 'relative', overflow: 'hidden',
        background: 'radial-gradient(circle at 50% 45%, #6B4226 0%, #2A1810 70%, #0A0604 100%)',
      }}>
        {/* "Plate" */}
        <div style={{
          position: 'absolute', left: '50%', top: '52%',
          transform: 'translate(-50%, -50%)',
          width: 280, height: 280, borderRadius: '50%',
          background: 'radial-gradient(circle at 35% 30%, #F5EFE6, #D8CFC1 60%, #A89B85)',
          boxShadow: '0 30px 80px rgba(0,0,0,0.6)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 120, lineHeight: 1,
        }}>🥑</div>
        {/* extra props */}
        <div style={{ position: 'absolute', left: '50%', top: '52%', transform: 'translate(-110%, -45%)', fontSize: 60 }}>🍞</div>
        <div style={{ position: 'absolute', left: '50%', top: '52%', transform: 'translate(15%, -10%)', fontSize: 56 }}>🍳</div>

        {/* Reticle / scan frame */}
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          pointerEvents: 'none',
        }}>
          <div style={{ position: 'relative', width: 300, height: 300 }}>
            {[
              { top: 0, left: 0, b: 'tl' },
              { top: 0, right: 0, b: 'tr' },
              { bottom: 0, left: 0, b: 'bl' },
              { bottom: 0, right: 0, b: 'br' },
            ].map((p, i) => {
              const k = p.b;
              const borders = {
                tl: { borderTop: `3px solid ${theme.accent}`, borderLeft: `3px solid ${theme.accent}`, borderTopLeftRadius: 14 },
                tr: { borderTop: `3px solid ${theme.accent}`, borderRight: `3px solid ${theme.accent}`, borderTopRightRadius: 14 },
                bl: { borderBottom: `3px solid ${theme.accent}`, borderLeft: `3px solid ${theme.accent}`, borderBottomLeftRadius: 14 },
                br: { borderBottom: `3px solid ${theme.accent}`, borderRight: `3px solid ${theme.accent}`, borderBottomRightRadius: 14 },
              }[k];
              return <div key={i} style={{ position: 'absolute', width: 36, height: 36, ...p, ...borders }} />;
            })}
            {/* Scan line */}
            {analyzing && (
              <div style={{
                position: 'absolute', left: 8, right: 8,
                top: `${8 + scanProgress * 284}px`,
                height: 2, borderRadius: 2,
                background: theme.accent,
                boxShadow: `0 0 16px ${theme.accent}, 0 0 4px ${theme.accent}`,
                transition: 'top 60ms linear',
              }} />
            )}
          </div>
        </div>

        {/* Top controls */}
        <div style={{
          position: 'absolute', top: 60, left: 0, right: 0,
          display: 'flex', justifyContent: 'space-between', padding: '0 20px',
        }}>
          <button onClick={onClose} style={glassBtn()}>
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M12 4L4 12M4 4l8 8" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </button>
          <button style={glassBtn()}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M12 7v3m0 3v.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" stroke="#fff" strokeWidth="1.6" strokeLinecap="round"/>
            </svg>
          </button>
        </div>

        {/* Hint */}
        <div style={{
          position: 'absolute', top: 120, left: 0, right: 0,
          display: 'flex', justifyContent: 'center',
        }}>
          <div style={{
            padding: '8px 16px', borderRadius: 999,
            background: 'rgba(0,0,0,0.5)',
            backdropFilter: 'blur(20px)',
            color: '#fff', fontSize: 13, fontWeight: 500,
            display: 'flex', alignItems: 'center', gap: 8,
          }}>
            {analyzing ? (
              <>
                <span style={{
                  width: 6, height: 6, borderRadius: 999,
                  background: theme.accent,
                  animation: 'pulse 1s ease-in-out infinite',
                }}/>
                Analyzing food…
              </>
            ) : (
              <>✨ Point at your meal to scan</>
            )}
          </div>
        </div>
      </div>

      {/* Bottom controls */}
      <div style={{
        height: 200, background: '#000',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start',
        paddingTop: 18, paddingBottom: 40,
      }}>
        {/* Mode pills */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 24 }}>
          {['Scan', 'Barcode', 'Label'].map((m, i) => (
            <div key={m} style={{
              padding: '6px 14px', borderRadius: 999,
              fontSize: 12, fontWeight: 600, letterSpacing: 0.3,
              background: i === 0 ? 'rgba(255,255,255,0.16)' : 'transparent',
              color: i === 0 ? '#fff' : 'rgba(255,255,255,0.5)',
            }}>{m}</div>
          ))}
        </div>

        {/* Shutter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 60 }}>
          <button style={smallBtn()}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <rect x="3" y="5" width="18" height="14" rx="2" stroke="#fff" strokeWidth="1.6"/>
              <circle cx="12" cy="12" r="3.5" stroke="#fff" strokeWidth="1.6"/>
            </svg>
          </button>

          <button
            onClick={analyzing ? undefined : onCapture}
            disabled={analyzing}
            style={{
              width: 76, height: 76, borderRadius: 999,
              background: 'transparent',
              border: `4px solid ${analyzing ? theme.accent : '#fff'}`,
              padding: 0, cursor: analyzing ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'all 200ms',
            }}>
            <div style={{
              width: 60, height: 60, borderRadius: 999,
              background: analyzing ? theme.accent : '#fff',
              transition: 'all 300ms',
              transform: analyzing ? 'scale(0.5)' : 'scale(1)',
            }}/>
          </button>

          <button style={smallBtn()}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M4 7h3l2-3h6l2 3h3a1 1 0 011 1v10a1 1 0 01-1 1H4a1 1 0 01-1-1V8a1 1 0 011-1z"
                stroke="#fff" strokeWidth="1.6" strokeLinejoin="round"/>
              <path d="M9 13l2 2 4-4" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>
      </div>

      <style>{`
        @keyframes pulse { 0%,100% { opacity: 1 } 50% { opacity: 0.3 } }
      `}</style>
    </div>
  );
}

function glassBtn() {
  return {
    width: 36, height: 36, borderRadius: 999,
    background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(20px)',
    border: '1px solid rgba(255,255,255,0.1)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer', padding: 0,
  };
}
function smallBtn() {
  return {
    width: 44, height: 44, borderRadius: 12,
    background: 'rgba(255,255,255,0.08)',
    border: 'none', cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
}

Object.assign(window, { CameraScreen });

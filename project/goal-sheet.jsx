// GoalSheet — bottom sheet to set/edit calorie target
function GoalSheet({ theme, currentGoal, onClose, onSave }) {
  const [val, setVal] = React.useState(currentGoal);
  const [open, setOpen] = React.useState(false);
  React.useEffect(() => {
    const t = setTimeout(() => setOpen(true), 10);
    return () => clearTimeout(t);
  }, []);

  const presets = [1500, 1800, 2000, 2200, 2500, 2800];
  const min = 1000, max = 4000;
  const pct = (val - min) / (max - min);

  const adjust = (delta) => setVal(v => Math.max(min, Math.min(max, v + delta)));

  const close = (cb) => {
    setOpen(false);
    setTimeout(cb, 240);
  };

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
    }}>
      {/* Scrim */}
      <div onClick={() => close(onClose)} style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.4)',
        opacity: open ? 1 : 0,
        transition: 'opacity 240ms ease',
      }} />

      {/* Sheet */}
      <div style={{
        position: 'relative',
        background: theme.surface,
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '14px 24px 32px',
        transform: open ? 'translateY(0)' : 'translateY(100%)',
        transition: 'transform 280ms cubic-bezier(.2,.8,.2,1)',
        boxShadow: '0 -20px 60px rgba(0,0,0,0.2)',
      }}>
        {/* Handle */}
        <div style={{
          width: 36, height: 5, borderRadius: 999,
          background: theme.border, margin: '0 auto 18px',
        }} />

        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
          <div style={{ fontSize: 20, fontWeight: 700, color: theme.text, letterSpacing: -0.4 }}>
            Daily calorie goal
          </div>
          <button onClick={() => close(onClose)} style={{
            background: 'transparent', border: 'none', color: theme.textDim,
            fontSize: 14, fontWeight: 500, cursor: 'pointer', padding: 4,
          }}>Cancel</button>
        </div>
        <div style={{ fontSize: 13, color: theme.textDim, marginBottom: 24 }}>
          Set the target you want to hit each day.
        </div>

        {/* Big number */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 18, marginBottom: 22,
        }}>
          <button onClick={() => adjust(-50)} style={stepBtn(theme)}>
            <svg width="18" height="18" viewBox="0 0 16 16"><path d="M3 8h10" stroke={theme.text} strokeWidth="2" strokeLinecap="round"/></svg>
          </button>
          <div style={{ textAlign: 'center', minWidth: 140 }}>
            <div style={{ fontSize: 56, fontWeight: 700, color: theme.text, letterSpacing: -2.4, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>
              {val.toLocaleString()}
            </div>
            <div style={{ fontSize: 12, color: theme.textDim, fontWeight: 500, letterSpacing: 0.6, marginTop: 4 }}>
              KCAL / DAY
            </div>
          </div>
          <button onClick={() => adjust(50)} style={stepBtn(theme)}>
            <svg width="18" height="18" viewBox="0 0 16 16"><path d="M8 3v10M3 8h10" stroke={theme.text} strokeWidth="2" strokeLinecap="round"/></svg>
          </button>
        </div>

        {/* Slider */}
        <div style={{ padding: '0 4px', marginBottom: 22 }}>
          <div style={{ position: 'relative', height: 28 }}>
            <div style={{
              position: 'absolute', top: 12, left: 0, right: 0, height: 4,
              borderRadius: 2, background: theme.ringTrack,
            }} />
            <div style={{
              position: 'absolute', top: 12, left: 0, width: `${pct * 100}%`, height: 4,
              borderRadius: 2, background: theme.accent,
            }} />
            <input
              type="range" min={min} max={max} step={50} value={val}
              onChange={(e) => setVal(parseInt(e.target.value, 10))}
              style={{
                position: 'absolute', inset: 0, width: '100%', opacity: 0, cursor: 'pointer', margin: 0,
              }}
            />
            <div style={{
              position: 'absolute', top: 4, left: `calc(${pct * 100}% - 10px)`,
              width: 20, height: 20, borderRadius: 999,
              background: '#fff', border: `2px solid ${theme.accent}`,
              boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
              pointerEvents: 'none',
            }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4, fontSize: 11, color: theme.textFaint, fontWeight: 500 }}>
            <span>{min.toLocaleString()}</span>
            <span>{max.toLocaleString()}</span>
          </div>
        </div>

        {/* Presets */}
        <div style={{ fontSize: 11, color: theme.textDim, fontWeight: 600, letterSpacing: 0.6, marginBottom: 8 }}>
          QUICK PRESETS
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 24 }}>
          {presets.map(p => (
            <button key={p} onClick={() => setVal(p)} style={{
              padding: '8px 14px', borderRadius: 999,
              background: val === p ? theme.accent : theme.surfaceAlt,
              border: `1px solid ${val === p ? theme.accent : theme.border}`,
              color: val === p ? '#fff' : theme.text,
              fontSize: 13, fontWeight: 600, cursor: 'pointer',
              transition: 'all 150ms', fontFamily: 'inherit',
            }}>
              {p.toLocaleString()}
            </button>
          ))}
        </div>

        {/* Save */}
        <button onClick={() => onSave(val)} style={{
          width: '100%', height: 54, borderRadius: 16,
          background: theme.accent, color: '#fff',
          border: 'none', fontSize: 15, fontWeight: 600, letterSpacing: 0.2,
          cursor: 'pointer', fontFamily: 'inherit',
          boxShadow: `0 8px 24px ${theme.accent}40`,
        }}>Save goal</button>
      </div>
    </div>
  );
}

function stepBtn(theme) {
  return {
    width: 44, height: 44, borderRadius: 999,
    background: theme.surfaceAlt, border: `1px solid ${theme.border}`,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer', padding: 0,
  };
}

Object.assign(window, { GoalSheet });

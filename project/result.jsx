// AI analysis result screen — appears after photo
function ResultScreen({ theme, onClose, onLog }) {
  const [meal, setMeal] = React.useState('Lunch');
  const a = ANALYSIS;

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 120 }}>
      {/* Hero photo */}
      <div style={{
        height: 280, position: 'relative', margin: '0 16px',
        borderRadius: 24, overflow: 'hidden',
        background: 'radial-gradient(circle at 35% 30%, #F5EFE6, #D8CFC1 60%, #A89B85)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ fontSize: 140 }}>🥑</div>
        <div style={{ position: 'absolute', left: '15%', top: '60%', fontSize: 60 }}>🍞</div>
        <div style={{ position: 'absolute', right: '15%', top: '20%', fontSize: 56 }}>🍳</div>

        {/* Close */}
        <button onClick={onClose} style={{
          position: 'absolute', top: 12, right: 12,
          width: 32, height: 32, borderRadius: 999, padding: 0,
          background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(20px)', border: 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
            <path d="M12 4L4 12M4 4l8 8" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
          </svg>
        </button>

        {/* Confidence pill */}
        <div style={{
          position: 'absolute', top: 12, left: 12,
          padding: '5px 10px', borderRadius: 999,
          background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(20px)',
          color: '#fff', fontSize: 11, fontWeight: 600, letterSpacing: 0.3,
          display: 'flex', alignItems: 'center', gap: 5,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: 999, background: '#7CFC00' }}/>
          {a.confidence}% match
        </div>
      </div>

      {/* Title */}
      <div style={{ padding: '20px 24px 6px' }}>
        <div style={{ fontSize: 11, color: theme.textDim, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
          ✨ Detected
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 16, marginTop: 6 }}>
          <div style={{ fontSize: 24, fontWeight: 700, color: theme.text, letterSpacing: -0.6, lineHeight: 1.15 }}>
            {a.name}
          </div>
          <div style={{ textAlign: 'right', flexShrink: 0 }}>
            <div style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8, lineHeight: 1 }}>{a.kcal}</div>
            <div style={{ fontSize: 11, color: theme.textDim, fontWeight: 500, marginTop: 2 }}>kcal</div>
          </div>
        </div>
      </div>

      {/* Macros chips */}
      <div style={{ padding: '14px 24px 20px', display: 'flex', gap: 10 }}>
        {[
          { label: 'Protein', val: a.protein, c: theme.proteinClr },
          { label: 'Carbs',   val: a.carbs,   c: theme.carbsClr },
          { label: 'Fat',     val: a.fat,     c: theme.fatClr },
        ].map(m => (
          <div key={m.label} style={{
            flex: 1, borderRadius: 16, padding: '12px 14px',
            background: theme.surface, border: `1px solid ${theme.border}`,
            display: 'flex', flexDirection: 'column', gap: 4,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: m.c }} />
              <span style={{ fontSize: 11, color: theme.textDim, fontWeight: 500 }}>{m.label}</span>
            </div>
            <div style={{ fontSize: 18, fontWeight: 700, color: theme.text, letterSpacing: -0.4 }}>
              {m.val}<span style={{ fontSize: 11, color: theme.textDim, fontWeight: 500 }}>g</span>
            </div>
          </div>
        ))}
      </div>

      {/* Items breakdown */}
      <div style={{ padding: '0 24px 20px' }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: theme.textDim, letterSpacing: 0.2, marginBottom: 8, padding: '0 4px' }}>
          INGREDIENTS · {a.items.length}
        </div>
        <div style={{
          background: theme.surface, borderRadius: 18,
          border: `1px solid ${theme.border}`, padding: '4px 16px',
        }}>
          {a.items.map((it, i) => (
            <div key={it.name}>
              <div style={{
                padding: '12px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              }}>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{it.name}</div>
                  <div style={{ fontSize: 12, color: theme.textFaint, marginTop: 1 }}>{it.weight}</div>
                </div>
                <div style={{ fontSize: 14, fontWeight: 600, color: theme.text, letterSpacing: -0.2 }}>
                  {it.kcal}<span style={{ fontSize: 11, color: theme.textDim, fontWeight: 500 }}> kcal</span>
                </div>
              </div>
              {i < a.items.length - 1 && <div style={{ height: 1, background: theme.border }} />}
            </div>
          ))}
        </div>
      </div>

      {/* Meal selector */}
      <div style={{ padding: '0 24px 20px' }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: theme.textDim, letterSpacing: 0.2, marginBottom: 8, padding: '0 4px' }}>
          ADD TO
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {['Breakfast', 'Lunch', 'Snack', 'Dinner'].map(m => (
            <button key={m} onClick={() => setMeal(m)} style={{
              flex: 1, padding: '10px 4px', borderRadius: 12,
              background: meal === m ? theme.accent : theme.surface,
              border: `1px solid ${meal === m ? theme.accent : theme.border}`,
              color: meal === m ? '#fff' : theme.text,
              fontSize: 12, fontWeight: 600, letterSpacing: 0.1,
              cursor: 'pointer', transition: 'all 150ms',
            }}>{m}</button>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div style={{
        position: 'absolute', bottom: 24, left: 24, right: 24,
        display: 'flex', gap: 10,
      }}>
        <button onClick={onClose} style={{
          padding: '0 20px', height: 54, borderRadius: 16,
          background: theme.surface, border: `1px solid ${theme.border}`,
          color: theme.text, fontSize: 15, fontWeight: 600, cursor: 'pointer',
        }}>Edit</button>
        <button onClick={onLog} style={{
          flex: 1, height: 54, borderRadius: 16,
          background: theme.accent, color: '#fff',
          border: 'none', fontSize: 15, fontWeight: 600, letterSpacing: 0.2,
          cursor: 'pointer',
          boxShadow: `0 8px 24px ${theme.accent}40`,
        }}>Log to {meal} · {a.kcal} kcal</button>
      </div>
    </div>
  );
}

Object.assign(window, { ResultScreen });

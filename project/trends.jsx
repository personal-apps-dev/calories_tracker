// Trends screen — week/month/year charts + food quality

// Build mock data for 3 ranges. Each entry: { label, consumed, quality (0-100), goal }
const RANGE_DATA = {
  week: [
    { label: 'Thu', consumed: 1980, quality: 72 },
    { label: 'Fri', consumed: 1950, quality: 78 },
    { label: 'Sat', consumed: 2150, quality: 65 },
    { label: 'Sun', consumed: 1890, quality: 82 },
    { label: 'Mon', consumed: 2310, quality: 54 },
    { label: 'Tue', consumed: 2080, quality: 68 },
    { label: 'Wed', consumed: 1420, quality: 81 },
  ],
  month: Array.from({ length: 30 }, (_, i) => ({
    label: `${i + 1}`,
    consumed: 1600 + Math.round(Math.sin(i * 0.6) * 400 + Math.cos(i * 1.3) * 200 + Math.random() * 250),
    quality: Math.max(40, Math.min(95, Math.round(70 + Math.sin(i * 0.4) * 12 + (Math.random() - 0.5) * 18))),
  })),
  year: ['May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar','Apr'].map((m, i) => ({
    label: m,
    consumed: Math.round(1900 + Math.sin(i * 0.7) * 250 + (Math.random() - 0.5) * 120),
    quality: Math.round(65 + Math.sin(i * 0.5) * 10 + Math.random() * 6),
  })),
};

const RANGE_META = {
  week:  { title: 'Apr 24 – Apr 30', barGap: 8 },
  month: { title: 'April 2026',      barGap: 2 },
  year:  { title: 'Last 12 months',  barGap: 4 },
};

function qualityColor(q, theme) {
  if (q >= 80) return '#3DB46D';
  if (q >= 60) return theme.carbsClr;
  if (q >= 45) return '#E8954E';
  return theme.fatClr;
}
function qualityLabel(q) {
  if (q >= 80) return 'Excellent';
  if (q >= 60) return 'Good';
  if (q >= 45) return 'Fair';
  return 'Needs work';
}

function TrendsScreen({ theme, goal }) {
  const [range, setRange] = React.useState('week');
  const [metric, setMetric] = React.useState('calories'); // calories | quality
  const days = RANGE_DATA[range];
  const meta = RANGE_META[range];

  const avg = Math.round(days.reduce((a, d) => a + d.consumed, 0) / days.length);
  const avgQuality = Math.round(days.reduce((a, d) => a + d.quality, 0) / days.length);
  const goalPct = Math.round((days.filter(d => d.consumed <= goal).length / days.length) * 100);
  const onGoalCount = days.filter(d => d.consumed <= goal).length;

  // Compact label sampling for month (every 5th)
  const showLabel = (i) => {
    if (range === 'month') return i === 0 || (i + 1) % 5 === 0 || i === days.length - 1;
    return true;
  };

  const max = metric === 'calories'
    ? Math.max(goal, ...days.map(d => d.consumed)) * 1.05
    : 100;

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 110 }}>
      <div style={{ padding: '8px 24px 18px' }}>
        <div style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8 }}>Trends</div>
        <div style={{ fontSize: 13, color: theme.textDim, marginTop: 2 }}>{meta.title}</div>
      </div>

      {/* Range pills */}
      <div style={{ padding: '0 24px 14px' }}>
        <div style={{
          display: 'flex', gap: 4, padding: 4, borderRadius: 12,
          background: theme.surfaceAlt, border: `1px solid ${theme.border}`,
        }}>
          {[
            { id: 'week',  label: 'Week' },
            { id: 'month', label: 'Month' },
            { id: 'year',  label: 'Year' },
          ].map(r => (
            <button key={r.id} onClick={() => setRange(r.id)} style={{
              flex: 1, padding: '7px 0', borderRadius: 8,
              background: range === r.id ? theme.surface : 'transparent',
              border: 'none', color: range === r.id ? theme.text : theme.textDim,
              fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
              boxShadow: range === r.id ? '0 1px 2px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 150ms',
            }}>{r.label}</button>
          ))}
        </div>
      </div>

      {/* Stat cards */}
      <div style={{ padding: '0 24px 14px', display: 'flex', gap: 10 }}>
        <div style={statCard(theme)}>
          <div style={statLabel(theme)}>Avg / day</div>
          <div style={statValue(theme)}>{avg.toLocaleString()}</div>
          <div style={statSub(theme)}>kcal</div>
        </div>
        <div style={statCard(theme)}>
          <div style={statLabel(theme)}>On goal</div>
          <div style={statValue(theme)}>{goalPct}%</div>
          <div style={statSub(theme)}>{onGoalCount} of {days.length} days</div>
        </div>
      </div>

      {/* Quality card — full width hero */}
      <div style={{ padding: '0 24px 18px' }}>
        <div style={{
          background: theme.surface, borderRadius: 22, padding: '18px 20px',
          border: `1px solid ${theme.border}`,
          display: 'flex', alignItems: 'center', gap: 16,
        }}>
          <QualityRing value={avgQuality} theme={theme} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, color: theme.textDim, fontWeight: 500, letterSpacing: 0.2 }}>
              Avg food quality
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 2 }}>
              <span style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8, fontVariantNumeric: 'tabular-nums' }}>
                {avgQuality}
              </span>
              <span style={{ fontSize: 13, color: theme.textDim, fontWeight: 500 }}>/ 100</span>
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 6,
              padding: '3px 9px', borderRadius: 999,
              background: qualityColor(avgQuality, theme) + '22',
              color: qualityColor(avgQuality, theme),
              fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
            }}>
              <span style={{ width: 5, height: 5, borderRadius: 999, background: qualityColor(avgQuality, theme) }} />
              {qualityLabel(avgQuality)}
            </div>
          </div>
        </div>
      </div>

      {/* Metric toggle for chart */}
      <div style={{ padding: '0 24px 12px', display: 'flex', gap: 6 }}>
        {[
          { id: 'calories', label: 'Calories' },
          { id: 'quality',  label: 'Quality'  },
        ].map(m => (
          <button key={m.id} onClick={() => setMetric(m.id)} style={{
            padding: '6px 14px', borderRadius: 999,
            background: metric === m.id ? theme.text : 'transparent',
            color: metric === m.id ? theme.bg : theme.textDim,
            border: `1px solid ${metric === m.id ? theme.text : theme.border}`,
            fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
          }}>{m.label}</button>
        ))}
      </div>

      {/* Bar chart */}
      <div style={{ padding: '0 24px 22px' }}>
        <div style={{
          background: theme.surface, borderRadius: 22, padding: '18px 16px 14px',
          border: `1px solid ${theme.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: theme.text }}>
              {metric === 'calories' ? 'Daily calories' : 'Daily quality score'}
            </div>
            <div style={{ fontSize: 11, color: theme.textDim, display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 10, height: 2, background: theme.textFaint, borderRadius: 1 }} />
              {metric === 'calories' ? `Goal ${goal.toLocaleString()}` : 'Target 75'}
            </div>
          </div>

          <div style={{ position: 'relative', height: 140, display: 'flex', alignItems: 'flex-end', gap: meta.barGap }}>
            <div style={{
              position: 'absolute', left: 0, right: 0,
              bottom: `${((metric === 'calories' ? goal : 75) / max) * 100}%`,
              height: 0, borderTop: `1px dashed ${theme.border}`,
              pointerEvents: 'none',
            }} />
            {days.map((d, i) => {
              const v = metric === 'calories' ? d.consumed : d.quality;
              const h = (v / max) * 100;
              const over = metric === 'calories' && d.consumed > goal;
              const color = metric === 'calories'
                ? (over ? theme.fatClr : theme.accent)
                : qualityColor(d.quality, theme);
              return (
                <div key={i} style={{
                  flex: 1, height: '100%',
                  display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
                }}>
                  <div title={`${d.label}: ${v}`} style={{
                    width: '100%', height: `${h}%`,
                    background: color,
                    borderRadius: range === 'month' ? 2 : 5,
                    minHeight: 3,
                    opacity: i === days.length - 1 ? 1 : 0.88,
                  }} />
                </div>
              );
            })}
          </div>
          <div style={{ display: 'flex', gap: meta.barGap, marginTop: 8 }}>
            {days.map((d, i) => (
              <div key={i} style={{
                flex: 1, fontSize: 10, color: theme.textDim, textAlign: 'center', fontWeight: 500,
                visibility: showLabel(i) ? 'visible' : 'hidden',
              }}>
                {d.label}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Macro split */}
      <div style={{ padding: '0 24px 24px' }}>
        <div style={{
          background: theme.surface, borderRadius: 22, padding: '20px',
          border: `1px solid ${theme.border}`,
          display: 'flex', alignItems: 'center', gap: 18,
        }}>
          <MacroDonut theme={theme} />
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: theme.text, marginBottom: 2 }}>Macro split</div>
            {[
              { label: 'Protein', pct: 22, c: theme.proteinClr },
              { label: 'Carbs',   pct: 48, c: theme.carbsClr },
              { label: 'Fat',     pct: 30, c: theme.fatClr },
            ].map(m => (
              <div key={m.label} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 8, height: 8, borderRadius: 999, background: m.c }} />
                <span style={{ fontSize: 13, color: theme.text, flex: 1 }}>{m.label}</span>
                <span style={{ fontSize: 13, color: theme.textDim, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{m.pct}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function QualityRing({ value, theme, size = 64, stroke = 7 }) {
  const r = (size - stroke) / 2;
  const C = 2 * Math.PI * r;
  const dash = C * (value / 100);
  const c = qualityColor(value, theme);
  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={theme.ringTrack} strokeWidth={stroke} fill="none" />
        <circle cx={size/2} cy={size/2} r={r}
          stroke={c} strokeWidth={stroke} strokeLinecap="round" fill="none"
          strokeDasharray={`${dash} ${C}`}
        />
      </svg>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 18, fontWeight: 700, color: theme.text, letterSpacing: -0.4,
      }}>{value}</div>
    </div>
  );
}

function MacroDonut({ theme }) {
  const segments = [
    { pct: 0.22, c: theme.proteinClr },
    { pct: 0.48, c: theme.carbsClr },
    { pct: 0.30, c: theme.fatClr },
  ];
  const r = 36, cx = 44, cy = 44, sw = 12;
  const C = 2 * Math.PI * r;
  let off = 0;
  return (
    <svg width="88" height="88" style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={cx} cy={cy} r={r} stroke={theme.ringTrack} strokeWidth={sw} fill="none" />
      {segments.map((s, i) => {
        const dash = C * s.pct - 2;
        const dashoffset = -off * C;
        off += s.pct;
        return (
          <circle key={i} cx={cx} cy={cy} r={r}
            stroke={s.c} strokeWidth={sw} fill="none"
            strokeDasharray={`${dash} ${C - dash}`}
            strokeDashoffset={dashoffset}
          />
        );
      })}
    </svg>
  );
}

function statCard(theme) {
  return {
    flex: 1, padding: '14px 16px', borderRadius: 18,
    background: theme.surface, border: `1px solid ${theme.border}`,
    display: 'flex', flexDirection: 'column',
  };
}
function statLabel(theme) { return { fontSize: 12, color: theme.textDim, fontWeight: 500 }; }
function statValue(theme) { return { fontSize: 26, fontWeight: 700, color: theme.text, letterSpacing: -0.8, marginTop: 2, fontVariantNumeric: 'tabular-nums' }; }
function statSub(theme)   { return { fontSize: 11, color: theme.textFaint, marginTop: 1 }; }

Object.assign(window, { TrendsScreen, qualityColor, qualityLabel, QualityRing });

// HomeScreen — today's stats
const { useState: useStateHome } = React;

function CalorieRing({ consumed, goal, theme, quality, size = 220, stroke = 14 }) {
  const remaining = goal - consumed;
  const over = consumed > goal;
  const pct = over ? 1 : Math.min(1, consumed / goal);
  const overPct = over ? Math.min(1, (consumed - goal) / goal) : 0;
  const overColor = theme.fatClr; // warning red
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = c * pct;
  const overDash = c * overPct;
  const ringColor = over ? overColor : theme.accent;
  const qC = quality != null ? qualityColor(quality, theme) : null;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={theme.ringTrack} strokeWidth={stroke} fill="none" />
        <circle
          cx={size/2} cy={size/2} r={r}
          stroke={ringColor} strokeWidth={stroke} strokeLinecap="round" fill="none"
          strokeDasharray={`${dash} ${c}`}
          style={{ transition: 'stroke-dasharray 800ms cubic-bezier(.2,.7,.2,1), stroke 300ms' }}
        />
        {over && (
          <circle
            cx={size/2} cy={size/2} r={r}
            stroke={overColor} strokeWidth={stroke + 2} strokeLinecap="round" fill="none"
            strokeDasharray={`${overDash} ${c}`}
            opacity={0.55}
            style={{ transition: 'stroke-dasharray 800ms cubic-bezier(.2,.7,.2,1)' }}
          />
        )}
      </svg>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ fontSize: 13, color: over ? overColor : theme.textDim, letterSpacing: 0.2, marginBottom: 2, fontWeight: over ? 600 : 500 }}>
          {over ? 'over by' : 'remaining'}
        </div>
        <div style={{ fontSize: 56, fontWeight: 700, letterSpacing: -2, color: over ? overColor : theme.text, lineHeight: 1, transition: 'color 300ms' }}>
          {Math.abs(remaining).toLocaleString()}
        </div>
        <div style={{ fontSize: 13, color: theme.textDim, marginTop: 6, letterSpacing: 0.4 }}>
          <span style={{ color: theme.text, fontWeight: 600 }}>{consumed.toLocaleString()}</span>
          {' / '}{goal.toLocaleString()} kcal
        </div>
        {quality != null && (
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            marginTop: 8, padding: '3px 9px 3px 4px', borderRadius: 999,
            background: qC + '1F',
          }}>
            <span style={{
              minWidth: 18, height: 18, borderRadius: 999,
              background: qC, color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 10, fontWeight: 700, letterSpacing: -0.2,
              padding: '0 3px',
            }}>{quality}</span>
            <span style={{ fontSize: 11, fontWeight: 600, color: qC, letterSpacing: 0.2 }}>
              calories quality
            </span>
          </div>
        )}
      </div>
    </div>
  );
}

function MacroBar({ label, value, goal, color, theme }) {
  const pct = Math.min(1, value / goal);
  return (
    <div style={{ flex: 1 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
        <span style={{ fontSize: 12, color: theme.textDim, fontWeight: 500 }}>{label}</span>
        <span style={{ fontSize: 11, color: theme.textFaint }}>{goal}g</span>
      </div>
      <div style={{ fontSize: 18, fontWeight: 600, color: theme.text, letterSpacing: -0.4, marginBottom: 6 }}>
        {value}<span style={{ fontSize: 12, color: theme.textDim, fontWeight: 500 }}>g</span>
      </div>
      <div style={{ height: 4, borderRadius: 2, background: theme.ringTrack, overflow: 'hidden' }}>
        <div style={{ width: `${pct*100}%`, height: '100%', background: color, borderRadius: 2,
          transition: 'width 800ms cubic-bezier(.2,.7,.2,1)' }} />
      </div>
    </div>
  );
}

function MetricChip({ icon, value, label, sub, theme }) {
  return (
    <div style={{
      flex: 1, padding: '14px 16px', borderRadius: 18,
      background: theme.surface, border: `1px solid ${theme.border}`,
      display: 'flex', flexDirection: 'column', gap: 2,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: theme.textDim, fontSize: 12, fontWeight: 500 }}>
        <span style={{ fontSize: 14 }}>{icon}</span>{label}
      </div>
      <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.6, color: theme.text }}>{value}</div>
      {sub && <div style={{ fontSize: 11, color: theme.textFaint }}>{sub}</div>}
    </div>
  );
}

function MealRow({ meal, theme }) {
  const qC = meal.quality != null ? qualityColor(meal.quality, theme) : null;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '10px 4px',
    }}>
      <div style={{ position: 'relative', flexShrink: 0 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12,
          background: meal.img,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 22,
        }}>{meal.emoji}</div>
        {meal.quality != null && (
          <div title={`Quality ${meal.quality}/100`} style={{
            position: 'absolute', bottom: -3, right: -3,
            minWidth: 20, height: 20, borderRadius: 999,
            background: qC, color: '#fff',
            border: `2px solid ${theme.surface}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 10, fontWeight: 700, letterSpacing: -0.2,
            padding: '0 4px',
          }}>{meal.quality}</div>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontSize: 11, color: theme.textDim, fontWeight: 500, textTransform: 'uppercase', letterSpacing: 0.6 }}>
            {meal.type}
          </div>
          <div style={{ fontSize: 15, fontWeight: 600, color: theme.text, letterSpacing: -0.2 }}>
            {meal.kcal}<span style={{ fontSize: 11, color: theme.textDim, fontWeight: 500 }}> kcal</span>
          </div>
        </div>
        <div style={{
          fontSize: 14, color: theme.text, fontWeight: 500,
          marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{meal.name}</div>
        <div style={{ fontSize: 11, color: theme.textFaint, marginTop: 1 }}>{meal.time}</div>
      </div>
    </div>
  );
}

function ActivityCard({ theme, burned, activities }) {
  return (
    <div style={{
      background: theme.surface, borderRadius: 22, padding: '16px 20px 14px',
      border: `1px solid ${theme.border}`,
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 12 }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: theme.textDim, fontSize: 12, fontWeight: 500 }}>
            <span style={{ fontSize: 14 }}>🔥</span>
            Calories burned
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8, fontVariantNumeric: 'tabular-nums', lineHeight: 1 }}>
              {burned}
            </span>
            <span style={{ fontSize: 13, color: theme.textDim, fontWeight: 500 }}>kcal · today</span>
          </div>
        </div>
        <div title="Synced from Apple Health" style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          padding: '4px 8px', borderRadius: 999,
          background: theme.surfaceAlt, border: `1px solid ${theme.border}`,
          fontSize: 10, color: theme.textDim, fontWeight: 600, letterSpacing: 0.4,
        }}>
          <svg width="10" height="10" viewBox="0 0 16 16" fill="none">
            <path d="M8 14s-5-3.2-5-7a3 3 0 015.5-1.7A3 3 0 0113 7c0 3.8-5 7-5 7z" fill="#FF375F"/>
          </svg>
          HEALTH
        </div>
      </div>

      <div style={{ display: 'flex', gap: 6 }}>
        {activities.map(a => (
          <div key={a.id} style={{
            flex: 1, padding: '10px 8px', borderRadius: 12,
            background: theme.surfaceAlt, border: `1px solid ${theme.border}`,
            display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 2,
            minWidth: 0,
          }}>
            <div style={{ fontSize: 18, lineHeight: 1 }}>{a.emoji}</div>
            <div style={{ fontSize: 11, color: theme.textDim, fontWeight: 500, marginTop: 2 }}>{a.type}</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: theme.text, letterSpacing: -0.3, fontVariantNumeric: 'tabular-nums' }}>
              {a.kcal}<span style={{ fontSize: 10, color: theme.textFaint, fontWeight: 500 }}> kcal</span>
            </div>
            <div style={{ fontSize: 10, color: theme.textFaint }}>{a.duration}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function FoodQualityCard({ meals, theme }) {
  const avg = Math.round(meals.reduce((a, m) => a + (m.quality || 0), 0) / meals.length);
  const c = qualityColor(avg, theme);
  const sorted = meals.slice().sort((a, b) => b.quality - a.quality);
  const best = sorted[0], worst = sorted[sorted.length - 1];
  return (
    <div style={{
      background: theme.surface, borderRadius: 22, padding: '18px 20px',
      border: `1px solid ${theme.border}`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <QualityRing value={avg} theme={theme} size={68} stroke={7} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12, color: theme.textDim, fontWeight: 500, letterSpacing: 0.2 }}>
            Avg food quality
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 2 }}>
            <span style={{ fontSize: 26, fontWeight: 700, color: theme.text, letterSpacing: -0.8, fontVariantNumeric: 'tabular-nums' }}>{avg}</span>
            <span style={{ fontSize: 12, color: theme.textDim, fontWeight: 500 }}>/ 100</span>
          </div>
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 6,
            padding: '3px 9px', borderRadius: 999,
            background: c + '22', color: c,
            fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
          }}>
            <span style={{ width: 5, height: 5, borderRadius: 999, background: c }} />
            {qualityLabel(avg)}
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 14, paddingTop: 14, borderTop: `1px solid ${theme.border}` }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 10, color: theme.textFaint, fontWeight: 600, letterSpacing: 0.6 }}>BEST</div>
          <div style={{ fontSize: 12, color: theme.text, fontWeight: 500, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {best.emoji} {best.name}
          </div>
        </div>
        <div style={{ width: 1, background: theme.border }} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 10, color: theme.textFaint, fontWeight: 600, letterSpacing: 0.6 }}>NEEDS WORK</div>
          <div style={{ fontSize: 12, color: theme.text, fontWeight: 500, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {worst.emoji} {worst.name}
          </div>
        </div>
      </div>
    </div>
  );
}

function HomeScreen({ theme, userName, goal, onCapture, onEditGoal }) {
  const t = TODAY;
  const date = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
  const avgQuality = Math.round(t.meals.reduce((a, m) => a + (m.quality || 0), 0) / t.meals.length);

  return (
    <div style={{
      height: '100%', overflowY: 'auto',
      paddingBottom: 100, // tab bar space
    }}>
      {/* Header */}
      <div style={{ padding: '8px 24px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: 13, color: theme.textDim, letterSpacing: 0.2, fontWeight: 500 }}>{date}</div>
          <div style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8, marginTop: 2 }}>
            Hey, {userName} 👋
          </div>
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: 999,
          background: `linear-gradient(135deg, ${theme.accent}, ${theme.proteinClr})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#fff', fontWeight: 600, fontSize: 14, letterSpacing: 0.2,
          flexShrink: 0,
        }}>{userName.slice(0,1).toUpperCase()}</div>
      </div>

      {/* Streak pill */}
      <div style={{ padding: '0 24px 18px' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          padding: '5px 12px 5px 10px', borderRadius: 999,
          background: theme.surfaceAlt, border: `1px solid ${theme.border}`,
          fontSize: 12, fontWeight: 600, color: theme.text, letterSpacing: 0.1,
        }}>
          <span style={{ fontSize: 14 }}>🔥</span>
          {t.streak} day streak
        </div>
      </div>

      {/* Calorie Ring */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '8px 0 24px', gap: 14 }}>
        <CalorieRing consumed={t.consumed} goal={goal} theme={theme} quality={avgQuality} />
        <button onClick={onEditGoal} style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          padding: '7px 14px', borderRadius: 999,
          background: theme.surface, border: `1px solid ${theme.border}`,
          fontSize: 12, fontWeight: 600, color: theme.text, letterSpacing: 0.2,
          cursor: 'pointer', fontFamily: 'inherit',
        }}>
          <svg width="12" height="12" viewBox="0 0 16 16" fill="none">
            <path d="M2 11.5V14h2.5L13 5.5 10.5 3 2 11.5z" stroke={theme.text} strokeWidth="1.5" strokeLinejoin="round"/>
          </svg>
          Goal · {goal.toLocaleString()} kcal
        </button>
      </div>

      {/* Macros */}
      <div style={{ padding: '0 24px 20px' }}>
        <div style={{
          background: theme.surface, borderRadius: 22, padding: '18px 20px',
          border: `1px solid ${theme.border}`,
          display: 'flex', gap: 24,
        }}>
          <MacroBar label="Protein" value={t.protein.g} goal={t.protein.goal} color={theme.proteinClr} theme={theme} />
          <MacroBar label="Carbs"   value={t.carbs.g}   goal={t.carbs.goal}   color={theme.carbsClr}   theme={theme} />
          <MacroBar label="Fat"     value={t.fat.g}     goal={t.fat.goal}     color={theme.fatClr}     theme={theme} />
        </div>
      </div>

      {/* Activity row */}
      <div style={{ padding: '0 24px 12px' }}>
        <ActivityCard theme={theme} burned={t.caloriesBurned} activities={t.activities} />
      </div>

      {/* Food quality card */}
      <div style={{ padding: '0 24px 24px' }}>
        <FoodQualityCard meals={TODAY.meals} theme={theme} />
      </div>

      {/* Today's meals */}
      <div style={{ padding: '0 24px' }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8,
        }}>
          <div style={{ fontSize: 18, fontWeight: 700, color: theme.text, letterSpacing: -0.4 }}>Today's meals</div>
          <div style={{ fontSize: 13, color: theme.accent, fontWeight: 600 }}>See all</div>
        </div>
        <div style={{
          background: theme.surface, borderRadius: 22, padding: '4px 16px',
          border: `1px solid ${theme.border}`,
        }}>
          {TODAY.meals.map((m, i) => (
            <div key={m.id}>
              <MealRow meal={m} theme={theme} />
              {i < TODAY.meals.length - 1 && (
                <div style={{ height: 1, background: theme.border, marginLeft: 56 }} />
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { HomeScreen, CalorieRing, FoodQualityCard, ActivityCard });

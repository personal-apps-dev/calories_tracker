// History / Diary tab — list of past days
const TODAY_MEALS_PREVIEW = [
  { emoji: '🥣', type: 'Breakfast', name: 'Greek yogurt & berries', kcal: 320, time: '8:14 AM', img: 'linear-gradient(135deg,#F4E4C1,#E8B4B8)' },
  { emoji: '🥗', type: 'Lunch',     name: 'Chicken caesar wrap',    kcal: 540, time: '12:48 PM', img: 'linear-gradient(135deg,#C8E6C9,#81C784)' },
  { emoji: '🍎', type: 'Snack',     name: 'Apple + almond butter',  kcal: 220, time: '3:22 PM', img: 'linear-gradient(135deg,#FFCCBC,#FF8A65)' },
  { emoji: '🍝', type: 'Dinner',    name: 'Pasta primavera',        kcal: 340, time: '7:05 PM', img: 'linear-gradient(135deg,#FFE0B2,#FFB74D)' },
];

const HISTORY_DAYS = [
  {
    label: 'Today', date: 'Apr 30',
    consumed: 1420, goal: null, meals: 4, // null = use live goal (today is editable)
    items: TODAY_MEALS_PREVIEW,
  },
  {
    label: 'Yesterday', date: 'Apr 29',
    consumed: 2080, goal: 2200, meals: 4,
    items: [
      { emoji: '🥞', type: 'Breakfast', name: 'Pancakes & maple syrup', kcal: 480, time: '8:30 AM', img: 'linear-gradient(135deg,#FFE0B2,#FFB74D)' },
      { emoji: '🍔', type: 'Lunch', name: 'Cheeseburger & fries', kcal: 820, time: '1:15 PM', img: 'linear-gradient(135deg,#FFCCBC,#FF8A65)' },
      { emoji: '🍿', type: 'Snack', name: 'Popcorn', kcal: 180, time: '4:00 PM', img: 'linear-gradient(135deg,#F4E4C1,#E8B4B8)' },
      { emoji: '🍣', type: 'Dinner', name: 'Salmon & rice bowl', kcal: 600, time: '7:30 PM', img: 'linear-gradient(135deg,#C8E6C9,#81C784)' },
    ],
  },
  {
    label: 'Mon', date: 'Apr 28',
    consumed: 2310, goal: 2200, meals: 5,
    items: [
      { emoji: '🥐', type: 'Breakfast', name: 'Croissant & latte', kcal: 420, time: '8:00 AM', img: 'linear-gradient(135deg,#FFE0B2,#FFB74D)' },
      { emoji: '🌯', type: 'Lunch', name: 'Burrito bowl', kcal: 760, time: '12:30 PM', img: 'linear-gradient(135deg,#C8E6C9,#81C784)' },
      { emoji: '🍫', type: 'Snack', name: 'Dark chocolate', kcal: 200, time: '3:30 PM', img: 'linear-gradient(135deg,#FFCCBC,#FF8A65)' },
      { emoji: '🍕', type: 'Dinner', name: 'Margherita pizza (2 slices)', kcal: 720, time: '7:45 PM', img: 'linear-gradient(135deg,#FFE0B2,#FFB74D)' },
      { emoji: '🍷', type: 'Snack', name: 'Glass of red wine', kcal: 210, time: '9:00 PM', img: 'linear-gradient(135deg,#E8B4B8,#C48B9F)' },
    ],
  },
  {
    label: 'Sun', date: 'Apr 27',
    consumed: 1890, goal: 2200, meals: 3,
    items: [
      { emoji: '🥑', type: 'Brunch', name: 'Avocado toast', kcal: 540, time: '10:30 AM', img: 'linear-gradient(135deg,#C8E6C9,#81C784)' },
      { emoji: '🍝', type: 'Lunch', name: 'Pasta carbonara', kcal: 720, time: '2:00 PM', img: 'linear-gradient(135deg,#FFE0B2,#FFB74D)' },
      { emoji: '🥗', type: 'Dinner', name: 'Caesar salad & soup', kcal: 630, time: '7:00 PM', img: 'linear-gradient(135deg,#C8E6C9,#81C784)' },
    ],
  },
  {
    label: 'Sat', date: 'Apr 26',
    consumed: 2150, goal: 2200, meals: 4,
    items: [],
  },
  {
    label: 'Fri', date: 'Apr 25',
    consumed: 1950, goal: 2200, meals: 4,
    items: [],
  },
];

function HistoryScreen({ theme, goal }) {
  const [expanded, setExpanded] = React.useState(1); // yesterday open by default

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 110 }}>
      <div style={{ padding: '8px 24px 18px' }}>
        <div style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8 }}>
          Diary
        </div>
        <div style={{ fontSize: 13, color: theme.textDim, marginTop: 2 }}>
          {HISTORY_DAYS.length} days · 7-day average {Math.round(HISTORY_DAYS.reduce((a, d) => a + d.consumed, 0) / HISTORY_DAYS.length).toLocaleString()} kcal
        </div>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {HISTORY_DAYS.map((d, i) => {
          const over = d.consumed > (d.goal || goal);
          const pct = Math.min(1, d.consumed / (d.goal || goal));
          const isOpen = expanded === i;
          return (
            <div key={i} style={{
              background: theme.surface, borderRadius: 18,
              border: `1px solid ${theme.border}`, overflow: 'hidden',
            }}>
              <button
                onClick={() => setExpanded(isOpen ? -1 : i)}
                style={{
                  width: '100%', padding: '14px 16px',
                  background: 'transparent', border: 'none',
                  display: 'flex', alignItems: 'center', gap: 14,
                  cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
                }}
              >
                {/* Mini ring */}
                <div style={{ position: 'relative', width: 44, height: 44, flexShrink: 0 }}>
                  <svg width="44" height="44" style={{ transform: 'rotate(-90deg)' }}>
                    <circle cx="22" cy="22" r="18" stroke={theme.ringTrack} strokeWidth="4" fill="none" />
                    <circle cx="22" cy="22" r="18"
                      stroke={over ? theme.fatClr : theme.accent}
                      strokeWidth="4" strokeLinecap="round" fill="none"
                      strokeDasharray={`${2 * Math.PI * 18 * pct} ${2 * Math.PI * 18}`}
                    />
                  </svg>
                  <div style={{
                    position: 'absolute', inset: 0,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 11, fontWeight: 700, color: theme.text,
                  }}>{Math.round(pct * 100)}</div>
                </div>

                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                    <span style={{ fontSize: 15, fontWeight: 600, color: theme.text }}>{d.label}</span>
                    <span style={{ fontSize: 12, color: theme.textFaint }}>{d.date}</span>
                  </div>
                  <div style={{ fontSize: 13, color: theme.textDim, marginTop: 2 }}>
                    <span style={{ color: over ? theme.fatClr : theme.text, fontWeight: 600 }}>
                      {d.consumed.toLocaleString()}
                    </span>
                    {' / '}{(d.goal || goal).toLocaleString()} kcal · {d.meals} meals
                  </div>
                </div>

                <svg width="16" height="16" viewBox="0 0 16 16" style={{
                  transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                  transition: 'transform 200ms', flexShrink: 0,
                }}>
                  <path d="M4 6l4 4 4-4" stroke={theme.textDim} strokeWidth="1.6" strokeLinecap="round" fill="none"/>
                </svg>
              </button>

              {isOpen && d.items?.length > 0 && (
                <div style={{ padding: '0 16px 12px', borderTop: `1px solid ${theme.border}` }}>
                  {d.items.map(m => (
                    <div key={m.name} style={{
                      display: 'flex', alignItems: 'center', gap: 12,
                      padding: '10px 0',
                    }}>
                      <div style={{
                        width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                        background: m.img,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 18,
                      }}>{m.emoji}</div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, color: theme.text, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.name}</div>
                        <div style={{ fontSize: 11, color: theme.textFaint, marginTop: 1 }}>{m.type} · {m.time}</div>
                      </div>
                      <div style={{ fontSize: 14, fontWeight: 600, color: theme.text, letterSpacing: -0.2 }}>
                        {m.kcal}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

Object.assign(window, { HistoryScreen, HISTORY_DAYS });

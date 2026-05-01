// Profile screen
function ProfileScreen({ theme, userName, goal, onEditGoal, onToggleDark, dark }) {
  const Row = ({ icon, label, value, onClick, danger, last }) => (
    <button onClick={onClick} style={{
      width: '100%', padding: '14px 16px',
      background: 'transparent', border: 'none',
      borderBottom: last ? 'none' : `1px solid ${theme.border}`,
      display: 'flex', alignItems: 'center', gap: 12,
      cursor: onClick ? 'pointer' : 'default', textAlign: 'left', fontFamily: 'inherit',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 8,
        background: theme.surfaceAlt,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 16, flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1, fontSize: 14, color: danger ? theme.fatClr : theme.text, fontWeight: 500 }}>{label}</div>
      {value && <div style={{ fontSize: 13, color: theme.textDim }}>{value}</div>}
      {onClick && (
        <svg width="14" height="14" viewBox="0 0 16 16">
          <path d="M6 4l4 4-4 4" stroke={theme.textFaint} strokeWidth="1.6" strokeLinecap="round" fill="none"/>
        </svg>
      )}
    </button>
  );

  const Section = ({ label, children }) => (
    <div style={{ marginBottom: 18 }}>
      <div style={{ fontSize: 11, color: theme.textDim, fontWeight: 600, letterSpacing: 0.6, padding: '0 20px 8px' }}>
        {label.toUpperCase()}
      </div>
      <div style={{
        margin: '0 16px', background: theme.surface, borderRadius: 18,
        border: `1px solid ${theme.border}`, overflow: 'hidden',
      }}>{children}</div>
    </div>
  );

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 110 }}>
      {/* Header */}
      <div style={{ padding: '8px 24px 22px' }}>
        <div style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: -0.8 }}>
          Profile
        </div>
      </div>

      {/* Avatar card */}
      <div style={{ padding: '0 16px 22px' }}>
        <div style={{
          background: theme.surface, borderRadius: 22, padding: '22px 20px',
          border: `1px solid ${theme.border}`,
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{
            width: 64, height: 64, borderRadius: 999,
            background: `linear-gradient(135deg, ${theme.accent}, ${theme.proteinClr})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontWeight: 700, fontSize: 26, letterSpacing: 0.2,
            flexShrink: 0,
          }}>{userName.slice(0,1).toUpperCase()}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: theme.text, letterSpacing: -0.4 }}>{userName}</div>
            <div style={{ fontSize: 13, color: theme.textDim, marginTop: 2 }}>Member since Jan 2026</div>
            <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
              <span style={{ fontSize: 12, color: theme.textDim }}>
                <strong style={{ color: theme.text }}>12</strong> day streak
              </span>
              <span style={{ fontSize: 12, color: theme.textDim }}>
                <strong style={{ color: theme.text }}>148</strong> meals logged
              </span>
            </div>
          </div>
        </div>
      </div>

      <Section label="Goals">
        <Row icon="🎯" label="Daily calorie goal" value={`${goal.toLocaleString()} kcal`} onClick={onEditGoal} />
        <Row icon="🥩" label="Protein target" value="140g" onClick={() => {}} />
        <Row icon="⚖️" label="Weight goal" value="−4.5 kg" onClick={() => {}} last />
      </Section>

      <Section label="Preferences">
        <Row icon={dark ? '🌙' : '☀️'} label="Dark mode" value={dark ? 'On' : 'Off'} onClick={onToggleDark} />
        <Row icon="🔔" label="Notifications" value="3 enabled" onClick={() => {}} />
        <Row icon="🔗" label="Apple Health" value="Connected" onClick={() => {}} last />
      </Section>

      <Section label="About">
        <Row icon="❤️" label="Rate the app" onClick={() => {}} />
        <Row icon="📄" label="Privacy" onClick={() => {}} />
        <Row icon="🚪" label="Sign out" onClick={() => {}} danger last />
      </Section>

      <div style={{ textAlign: 'center', fontSize: 11, color: theme.textFaint, padding: '8px 0 4px' }}>
        Version 2.4.1
      </div>
    </div>
  );
}

Object.assign(window, { ProfileScreen });

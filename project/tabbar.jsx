// Bottom tab bar with center camera button
function TabIcon({ name, active, color }) {
  const c = color;
  const sw = 1.7;
  if (name === 'home') return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill={active ? c : 'none'}>
      <path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6h-6v6H4a1 1 0 01-1-1v-9z"
        stroke={c} strokeWidth={sw} strokeLinejoin="round"/>
    </svg>
  );
  if (name === 'chart') return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path d="M4 19V9m6 10V5m6 14v-7m6 7H2" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
  if (name === 'profile') return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill={active ? c : 'none'}>
      <circle cx="12" cy="8" r="4" stroke={c} strokeWidth={sw}/>
      <path d="M4 21c0-4 3.5-7 8-7s8 3 8 7" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
  if (name === 'list') return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01"
        stroke={c} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
}

function TabBar({ theme, active, onCameraTap, onTabTap }) {
  const Tab = ({ id, icon }) => (
    <button onClick={() => onTabTap(id)} style={{
      flex: 1, height: 56, padding: 0, background: 'transparent', border: 'none',
      cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <TabIcon name={icon} active={active === id} color={active === id ? theme.tabIconActive : theme.tabIcon} />
    </button>
  );
  return (
    <div style={{
      position: 'absolute', left: 14, right: 14, bottom: 22,
      height: 64, borderRadius: 32,
      background: theme.tabBarBg,
      backdropFilter: 'blur(30px) saturate(180%)',
      WebkitBackdropFilter: 'blur(30px) saturate(180%)',
      border: `1px solid ${theme.tabBarBorder}`,
      display: 'flex', alignItems: 'center',
      boxShadow: '0 8px 30px rgba(0,0,0,0.08)',
      zIndex: 30,
    }}>
      <Tab id="home"  icon="home" />
      <Tab id="list"  icon="list" />

      {/* Center camera button */}
      <div style={{ flex: 1, display: 'flex', justifyContent: 'center' }}>
        <button onClick={onCameraTap} style={{
          width: 56, height: 56, borderRadius: 999, padding: 0,
          background: theme.accent, border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 8px 22px ${theme.accent}55, 0 2px 4px rgba(0,0,0,0.1)`,
          transform: 'translateY(-12px)',
        }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
            <path d="M3 8a2 2 0 012-2h2.5l1.5-2h6l1.5 2H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"
              stroke="#fff" strokeWidth="1.8" strokeLinejoin="round"/>
            <circle cx="12" cy="13" r="3.5" stroke="#fff" strokeWidth="1.8"/>
          </svg>
        </button>
      </div>

      <Tab id="chart"   icon="chart" />
      <Tab id="profile" icon="profile" />
    </div>
  );
}

Object.assign(window, { TabBar });

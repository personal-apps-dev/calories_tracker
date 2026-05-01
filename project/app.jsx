// Main app — calorie tracker iOS prototype
const { useState, useEffect, useMemo } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "dark": false,
  "accent": "#FF6B35",
  "userName": "Alex"
}/*EDITMODE-END*/;

// Mock data
const TODAY = {
  goal: 2200,
  consumed: 1420,
  protein: { g: 78, goal: 140 },
  carbs:   { g: 165, goal: 240 },
  fat:     { g: 52, goal: 75 },
  steps: 7842,
  stepGoal: 10000,
  streak: 12,
  caloriesBurned: 487,
  activities: [
    { id: 1, type: 'Walk',     emoji: '🚶', kcal: 142, duration: '38 min', time: '7:30 AM' },
    { id: 2, type: 'Strength', emoji: '🏋️', kcal: 215, duration: '45 min', time: '12:15 PM' },
    { id: 3, type: 'Cycling',  emoji: '🚴', kcal: 130, duration: '22 min', time: '6:10 PM' },
  ],
  meals: [
    { id: 1, type: 'Breakfast', emoji: '🥣', name: 'Greek yogurt & berries', kcal: 320, time: '8:14 AM', quality: 88, img: 'linear-gradient(135deg,#F4E4C1,#E8B4B8)' },
    { id: 2, type: 'Lunch',     emoji: '🥗', name: 'Chicken caesar wrap',    kcal: 540, time: '12:48 PM', quality: 64, img: 'linear-gradient(135deg,#C8E6C9,#81C784)' },
    { id: 3, type: 'Snack',     emoji: '🍎', name: 'Apple + almond butter',  kcal: 220, time: '3:22 PM', quality: 92, img: 'linear-gradient(135deg,#FFCCBC,#FF8A65)' },
    { id: 4, type: 'Dinner',    emoji: '🍝', name: 'Pasta primavera',        kcal: 340, time: '7:05 PM', quality: 71, img: 'linear-gradient(135deg,#FFE0B2,#FFB74D)' },
  ],
};

// Analyzed photo result
const ANALYSIS = {
  name: 'Avocado toast w/ poached egg',
  confidence: 94,
  kcal: 385,
  protein: 16,
  carbs: 32,
  fat: 22,
  items: [
    { name: 'Sourdough bread', kcal: 120, weight: '60g' },
    { name: 'Avocado',         kcal: 160, weight: '½ medium' },
    { name: 'Poached egg',     kcal: 78,  weight: '1 large' },
    { name: 'Olive oil & seasoning', kcal: 27, weight: '~5ml' },
  ],
};

function App() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [screen, setScreen] = useState('home'); // home | list | chart | profile | camera | analyzing | result
  const [activeTab, setActiveTab] = useState('home');
  const [goal, setGoal] = useState(2200);
  const [showGoalSheet, setShowGoalSheet] = useState(false);

  const theme = tweaks.dark ? darkTheme(tweaks.accent) : lightTheme(tweaks.accent);

  // Auto-advance camera → analyzing → result
  useEffect(() => {
    if (screen === 'camera') return;
    if (screen === 'analyzing') {
      const t = setTimeout(() => setScreen('result'), 2400);
      return () => clearTimeout(t);
    }
  }, [screen]);

  const goCamera = () => { setScreen('camera'); setActiveTab('camera'); };
  const goHome   = () => { setScreen('home'); setActiveTab('home'); };

  const handleTab = (t) => {
    setActiveTab(t);
    if (t === 'camera') { setScreen('camera'); return; }
    setScreen(t);
  };

  let content;
  if (screen === 'home')           content = <HomeScreen theme={theme} userName={tweaks.userName} goal={goal} onCapture={goCamera} onEditGoal={() => setShowGoalSheet(true)} />;
  else if (screen === 'list')      content = <HistoryScreen theme={theme} goal={goal} />;
  else if (screen === 'chart')     content = <TrendsScreen theme={theme} goal={goal} />;
  else if (screen === 'profile')   content = <ProfileScreen theme={theme} userName={tweaks.userName} goal={goal} dark={tweaks.dark} onEditGoal={() => setShowGoalSheet(true)} onToggleDark={() => setTweak('dark', !tweaks.dark)} />;
  else if (screen === 'camera')    content = <CameraScreen theme={theme} onCapture={() => setScreen('analyzing')} onClose={goHome} />;
  else if (screen === 'analyzing') content = <CameraScreen theme={theme} analyzing onClose={goHome} />;
  else if (screen === 'result')    content = <ResultScreen theme={theme} onClose={goHome} onLog={goHome} />;

  return (
    <div style={{
      minHeight: '100vh',
      background: tweaks.dark ? '#0A0A0A' : '#E8E4DD',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 40,
      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif',
    }}>
      <IOSDevice width={402} height={874} dark={tweaks.dark}>
        <div style={{
          height: '100%', position: 'relative',
          background: theme.bg, color: theme.text,
          paddingTop: 54, // status bar
        }}>
          {content}
          {showGoalSheet && (
            <GoalSheet
              theme={theme}
              currentGoal={goal}
              onClose={() => setShowGoalSheet(false)}
              onSave={(g) => { setGoal(g); setShowGoalSheet(false); }}
            />
          )}
          {screen !== 'camera' && screen !== 'analyzing' && !showGoalSheet && (
            <TabBar
              theme={theme}
              active={activeTab}
              onCameraTap={goCamera}
              onTabTap={handleTab}
            />
          )}
        </div>
      </IOSDevice>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Appearance">
          <TweakToggle label="Dark mode" value={tweaks.dark} onChange={(v) => setTweak('dark', v)} />
          <TweakColor label="Accent" value={tweaks.accent} onChange={(v) => setTweak('accent', v)} />
        </TweakSection>
        <TweakSection label="Profile">
          <TweakText label="Name" value={tweaks.userName} onChange={(v) => setTweak('userName', v)} />
        </TweakSection>
        <TweakSection label="Quick jump">
          <TweakButton label="Home" onClick={() => setScreen('home')} />
          <TweakButton label="Camera" onClick={() => setScreen('camera')} />
          <TweakButton label="Analyzing" onClick={() => setScreen('analyzing')} />
          <TweakButton label="Result" onClick={() => setScreen('result')} />
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);

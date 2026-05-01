// Theme tokens
function lightTheme(accent) {
  return {
    accent,
    bg: '#FAFAF7',
    surface: '#FFFFFF',
    surfaceAlt: '#F4F1EB',
    text: '#0F0F0F',
    textDim: '#6B6660',
    textFaint: '#A8A39C',
    border: 'rgba(15,15,15,0.08)',
    ringTrack: 'rgba(15,15,15,0.06)',
    proteinClr: '#5B8DEF',
    carbsClr:   '#F4B740',
    fatClr:     '#E86A6A',
    tabBarBg: 'rgba(255,255,255,0.78)',
    tabBarBorder: 'rgba(15,15,15,0.06)',
    tabIcon: '#9B9690',
    tabIconActive: '#0F0F0F',
  };
}
function darkTheme(accent) {
  return {
    accent,
    bg: '#0A0A0A',
    surface: '#161616',
    surfaceAlt: '#1F1E1C',
    text: '#F5F2EC',
    textDim: '#A8A39C',
    textFaint: '#6B6660',
    border: 'rgba(255,255,255,0.08)',
    ringTrack: 'rgba(255,255,255,0.06)',
    proteinClr: '#7BA9F5',
    carbsClr:   '#F5C766',
    fatClr:     '#F08585',
    tabBarBg: 'rgba(20,20,20,0.78)',
    tabBarBorder: 'rgba(255,255,255,0.06)',
    tabIcon: '#6B6660',
    tabIconActive: '#F5F2EC',
  };
}

Object.assign(window, { lightTheme, darkTheme });

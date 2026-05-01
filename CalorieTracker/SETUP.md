# CalorieTracker — iOS App Setup

## Requirements
- Mac with Xcode 15 or later
- iPhone running iOS 16.0+
- Free Apple Developer account (for device installation)
- Anthropic API key (for real food photo analysis)

## Build & Install

### 1. Open the project
```
open CalorieTracker.xcodeproj
```

### 2. Set your Development Team
- In Xcode, select the `CalorieTracker` project in the Navigator
- Select the `CalorieTracker` target
- Under **Signing & Capabilities**, set your Team to your personal Apple ID
- Xcode will auto-manage provisioning

### 3. Connect your iPhone
Plug in your iPhone via USB (or use Wi-Fi development if already paired).
Select your device from the scheme selector at the top.

### 4. Build & Run
Press ⌘R. Xcode will install the app on your phone.

On first launch, you may need to trust the developer certificate:
- On iPhone: **Settings → General → VPN & Device Management → Trust**

---

## API Key Setup

For real AI food analysis (instead of mock data):

1. Get your API key from [console.anthropic.com](https://console.anthropic.com)
2. Open the app → **Profile** tab → **AI Analysis** → **Claude API Key**
3. Paste your key (`sk-ant-...`)

The key is stored locally on your device in UserDefaults. Food photos are sent
to the Anthropic API for analysis. No data is stored anywhere else.

---

## App Structure

```
CalorieTracker/
├── CalorieTrackerApp.swift   — App entry, AppState (goal, name, dark mode, API key)
├── Models.swift              — Data models + mock data
├── Theme.swift               — Colors, qualityColor(), cardStyle()
├── ContentView.swift         — Tab navigation + custom tab bar
├── HomeView.swift            — Home screen + all components
│                               (CalorieRingView, MacroBarView, ActivityCardView,
│                                FoodQualityCardView, QualityRingView, MealRowView)
├── SecondaryViews.swift      — Diary, Trends, Profile, GoalSheet
├── CameraFlowView.swift      — Camera capture → Analyzing → Result
└── ClaudeService.swift       — Anthropic API integration
```

## Features
- **Home** — Calorie ring with goal tracking, macros, activity (Apple Health ready), food quality scoring
- **Diary** — Expandable history with per-day calorie rings  
- **Trends** — Week/Month/Year charts, Calories vs Quality toggle, macro donut
- **Profile** — Goal editing, dark mode, API key entry
- **Camera** — Real camera capture → Claude AI analysis → Log meal
- **Goal sheet** — Stepper, slider, quick presets; goal remembered per-day historically
- **Dark mode** — Full light/dark theme support

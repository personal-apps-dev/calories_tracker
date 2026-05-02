import SwiftUI

enum AppTab: Equatable { case home, diary, trends, profile }

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: AppTab = .home
    @State private var showCamera = false
    @State private var showGoalSheet = false
    @State private var showNamePrompt = false
    @State private var nameDraft = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            CustomTabBar(activeTab: $activeTab) {
                showCamera = true
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(isPresented: $showGoalSheet) {
            GoalSheetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraFlowView(onClose: { showCamera = false })
        }
        .onAppear {
            let bare = appState.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if bare && !appState.hasSeenNamePrompt {
                showNamePrompt = true
            }
        }
        .alert("Welcome 👋", isPresented: $showNamePrompt) {
            TextField("Your name", text: $nameDraft)
                .textInputAutocapitalization(.words)
            Button("Continue") {
                let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { appState.userName = trimmed }
                appState.hasSeenNamePrompt = true
            }
        } message: {
            Text("What should we call you?")
        }
    }

    @ViewBuilder
    var tabContent: some View {
        switch activeTab {
        case .home:
            HomeView(
                showGoalSheet: $showGoalSheet,
                onAvatarTap: { activeTab = .profile }
            )
        case .diary:
            DiaryView()
        case .trends:
            TrendsView()
        case .profile:
            ProfileView(showGoalSheet: $showGoalSheet)
        }
    }
}

// MARK: - Custom tab bar

struct CustomTabBar: View {
    @Binding var activeTab: AppTab
    let onCamera: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabBtn(sfName: "house.fill",    isActive: activeTab == .home)  { activeTab = .home }
            TabBtn(sfName: "list.bullet",   isActive: activeTab == .diary) { activeTab = .diary }

            Button(action: onCamera) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 56, height: 56)
                        .shadow(color: accentOrange.opacity(0.4), radius: 12, y: 4)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -14)
            .frame(maxWidth: .infinity)

            TabBtn(sfName: "chart.bar.fill", isActive: activeTab == .trends)  { activeTab = .trends }
            TabBtn(sfName: "person.fill",    isActive: activeTab == .profile) { activeTab = .profile }
        }
        .padding(.horizontal, 14)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 20, y: 4)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 22)
    }
}

struct TabBtn: View {
    let sfName: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: sfName)
                .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .primary : .secondary.opacity(0.5))
                .frame(maxWidth: .infinity, minHeight: 56)
        }
    }
}

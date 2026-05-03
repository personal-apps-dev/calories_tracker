import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

// MARK: - Camera Flow Coordinator

enum CameraPhase { case viewfinder, analyzing, result, error }

struct CameraFlowView: View {
    let onClose: () -> Void

    @EnvironmentObject var appState: AppState
    @StateObject private var camera = CameraManager()
    @State private var phase: CameraPhase = .viewfinder
    @State private var analysis: FoodAnalysis?
    @State private var analysisError: String?
    @State private var showTextEntry = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .viewfinder:
                ViewfinderView(
                    camera: camera,
                    onCapture: { startAnalysis() },
                    onClose: onClose,
                    onDescribe: { showTextEntry = true }
                )
            case .analyzing:
                AnalyzingView(onClose: onClose)
            case .result:
                if let analysis {
                    ResultView(
                        analysis: analysis,
                        onClose: onClose,
                        onLog: { mealType in
                            logMeal(analysis: analysis, mealType: mealType)
                            onClose()
                        }
                    )
                }
            case .error:
                ErrorView(
                    message: analysisError ?? "Unknown error",
                    onClose: onClose,
                    onRetry: { phase = .viewfinder }
                )
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.capturedImage) { image in
            guard let image, phase == .viewfinder else { return }
            phase = .analyzing
            Task { await analyzeWithClaude(image: image) }
        }
        .sheet(isPresented: $showTextEntry) {
            DescribeMealSheet { description in
                showTextEntry = false
                phase = .analyzing
                Task { await analyzeText(description) }
            }
        }
    }

    private func startAnalysis() {
        if camera.isAuthorized {
            camera.capturePhoto()
        } else {
            analysisError = "Camera permission denied. Enable it in Settings → CalorieTracker → Camera."
            phase = .error
        }
    }

    @MainActor
    private func logMeal(analysis: FoodAnalysis, mealType: String) {
        let quality = estimateQuality(
            kcal: analysis.kcal,
            protein: analysis.protein,
            carbs: analysis.carbs,
            fat: analysis.fat
        )
        let meal = LoggedMeal(
            type: mealType,
            emoji: mealEmojiFor(name: analysis.name, type: mealType),
            name: analysis.name,
            kcal: analysis.kcal,
            protein: analysis.protein,
            carbs: analysis.carbs,
            fat: analysis.fat,
            quality: quality,
            items: analysis.items.map {
                LoggedItem(name: $0.name, kcal: $0.kcal, weight: $0.weight)
            }
        )
        appState.logMeal(meal)
    }

    private func analyzeWithClaude(image: UIImage) async {
        guard !appState.claudeApiKey.isEmpty else {
            await MainActor.run {
                analysisError = "No API key set. Add your Anthropic API key in the Profile tab."
                phase = .error
            }
            return
        }

        do {
            let result = try await ClaudeService.shared.analyzeFood(
                image: image,
                apiKey: appState.claudeApiKey,
                language: appState.appLanguage
            )
            await MainActor.run {
                analysis = result
                phase = .result
            }
        } catch {
            await MainActor.run {
                analysisError = error.localizedDescription
                phase = .error
            }
        }
    }

    private func analyzeText(_ description: String) async {
        guard !appState.claudeApiKey.isEmpty else {
            await MainActor.run {
                analysisError = "No API key set. Add your Anthropic API key in the Profile tab."
                phase = .error
            }
            return
        }
        do {
            let result = try await ClaudeService.shared.analyzeFoodText(
                description: description,
                apiKey: appState.claudeApiKey,
                language: appState.appLanguage
            )
            await MainActor.run {
                analysis = result
                phase = .result
            }
        } catch {
            await MainActor.run {
                analysisError = error.localizedDescription
                phase = .error
            }
        }
    }
}

// MARK: - DescribeMealSheet

struct DescribeMealSheet: View {
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var text: String = ""
    @FocusState private var focused: Bool

    private let examples = [
        "Greek yogurt with berries and honey",
        "Chicken caesar salad, large bowl",
        "Two slices of pepperoni pizza",
        "Avocado toast with poached egg",
        "Bowl of borscht with sour cream",
    ]

    private var canSubmit: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Describe what you ate. Be as specific as you can — quantities and prep details help with accuracy.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("e.g. \"Bowl of oatmeal with banana and a tablespoon of peanut butter\"")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .focused($focused)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
                .frame(minHeight: 160)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                )

                Text("Examples")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .padding(.top, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(examples, id: \.self) { ex in
                            Button {
                                text = ex
                            } label: {
                                Text(ex)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(Color(UIColor.tertiarySystemBackground))
                                            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer(minLength: 0)

                Button {
                    onSubmit(text.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Analyze")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canSubmit ? accentOrange : Color.secondary.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: canSubmit ? accentOrange.opacity(0.4) : .clear, radius: 12, y: 4)
                }
                .disabled(!canSubmit)
            }
            .padding(20)
            .navigationTitle("Describe a meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - ViewfinderView

struct ViewfinderView: View {
    @ObservedObject var camera: CameraManager
    let onCapture: () -> Void
    let onClose: () -> Void
    var onDescribe: () -> Void = {}

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            // Camera preview or mock scene
            if camera.isAuthorized {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            } else {
                MockFoodScene()
            }

            // Reticle overlay
            ReticleOverlay()

            // Top controls
            VStack {
                HStack {
                    GlassButton(sfName: "xmark", action: onClose)
                    Spacer()
                    GlassButton(sfName: "questionmark.circle", action: {})
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        HStack(spacing: 8) {
                            Text("✨").font(.system(size: 13))
                            Text("Point at your meal to scan")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                    )
                    .frame(height: 36)
                    .frame(maxWidth: 240)
                    .padding(.top, 16)

                Spacer()
            }

            // Bottom controls
            VStack {
                Spacer()
                VStack(spacing: 24) {
                    HStack(spacing: 4) {
                        ForEach(["Scan", "Barcode", "Label"], id: \.self) { mode in
                            Text(mode)
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.3)
                                .foregroundColor(mode == "Scan" ? .white : .white.opacity(0.5))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(mode == "Scan" ? Color.white.opacity(0.16) : Color.clear)
                                )
                        }
                    }

                    HStack(spacing: 60) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            SmallCameraButton(sfName: "photo.on.rectangle")
                        }
                        ShutterButton(action: onCapture)
                        Button(action: onDescribe) {
                            SmallCameraButton(sfName: "text.bubble")
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onChange(of: pickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { camera.capturedImage = image }
                }
                await MainActor.run { pickerItem = nil }
            }
        }
    }
}

// MARK: - AnalyzingView

struct AnalyzingView: View {
    let onClose: () -> Void
    @State private var scanY: CGFloat = 0

    var body: some View {
        ZStack {
            MockFoodScene()

            ReticleOverlay(isAnalyzing: true, scanY: scanY)

            VStack {
                HStack {
                    GlassButton(sfName: "xmark", action: onClose)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        HStack(spacing: 8) {
                            Circle()
                                .fill(accentOrange)
                                .frame(width: 6, height: 6)
                                .opacity(0.8)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: scanY)
                            Text("Analyzing food…")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                    )
                    .frame(height: 36)
                    .frame(maxWidth: 220)
                    .padding(.top, 16)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.2)) {
                scanY = 292  // end just inside bottom bracket
            }
        }
    }
}

// MARK: - ErrorView

struct ErrorView: View {
    let message: String
    let onClose: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(UIColor.secondarySystemBackground)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(accentOrange)

                    Text("Analysis failed")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(-0.4)

                    ScrollView {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button(action: onRetry) {
                        Text("Try again")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(accentOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button("Close", action: onClose)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }
}

// MARK: - ResultView

struct ResultView: View {
    let analysis: FoodAnalysis
    let onClose: () -> Void
    let onLog: (String) -> Void

    @State private var selectedMeal: String = mealTypeForNow()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image
                ZStack(alignment: .topLeading) {
                    MockFoodScene()
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 16)

                    HStack {
                        confidencePill
                        Spacer()
                        closeButton
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                }
                .padding(.top, 60)

                // Title + kcal
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("✨ DETECTED")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)
                        Text(analysis.name)
                            .font(.system(size: 24, weight: .bold))
                            .tracking(-0.6)
                            .lineSpacing(2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(analysis.kcal)")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.8)
                        Text("kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 6)

                // Macro chips
                HStack(spacing: 10) {
                    MacroChip(label: "Protein", value: analysis.protein, color: Color(hex: "5B8DEF"))
                    MacroChip(label: "Carbs",   value: analysis.carbs,   color: Color(hex: "F4B740"))
                    MacroChip(label: "Fat",     value: analysis.fat,     color: Color(hex: "E86A6A"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 20)

                // Ingredients
                VStack(alignment: .leading, spacing: 8) {
                    Text("INGREDIENTS · \(analysis.items.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(analysis.items.enumerated()), id: \.offset) { i, item in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(item.weight)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                HStack(alignment: .lastTextBaseline, spacing: 1) {
                                    Text("\(item.kcal)")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(" kcal")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)

                            if i < analysis.items.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .cardStyle(radius: 18)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Meal selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD TO")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    HStack(spacing: 6) {
                        ForEach(["Breakfast", "Lunch", "Snack", "Dinner"], id: \.self) { m in
                            Button(m) {
                                withAnimation(.spring(duration: 0.15)) { selectedMeal = m }
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedMeal == m ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMeal == m ? accentOrange : Color(UIColor.secondarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedMeal == m ? accentOrange : Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                Button("Edit") { onClose() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 80, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    )

                Button(action: { onLog(selectedMeal) }) {
                    Text("Log to \(selectedMeal) · \(analysis.kcal) kcal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: accentOrange.opacity(0.4), radius: 12, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .background(
                LinearGradient(
                    colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                .frame(height: 120)
            )
        }
        .background(Color(UIColor.systemBackground))
    }

    var confidencePill: some View {
        HStack(spacing: 5) {
            Circle().fill(Color(hex: "7CFC00")).frame(width: 6, height: 6)
            Text("\(analysis.confidence)% match")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Capsule().fill(Color.black.opacity(0.5)))
    }

    var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
    }
}

struct MacroChip: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.4)
                Text("g")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardStyle(radius: 16)
    }
}

// MARK: - Camera helpers

struct ReticleOverlay: View {
    var isAnalyzing: Bool = false
    var scanY: CGFloat = 8  // starts just inside top bracket

    private let size: CGFloat = 300
    private let len: CGFloat = 36
    private let w: CGFloat = 3

    var body: some View {
        ZStack {
            // Top-Left corner
            Rectangle().fill(accentOrange).frame(width: len, height: w)
                .position(x: len / 2, y: w / 2)
            Rectangle().fill(accentOrange).frame(width: w, height: len)
                .position(x: w / 2, y: len / 2)

            // Top-Right corner
            Rectangle().fill(accentOrange).frame(width: len, height: w)
                .position(x: size - len / 2, y: w / 2)
            Rectangle().fill(accentOrange).frame(width: w, height: len)
                .position(x: size - w / 2, y: len / 2)

            // Bottom-Left corner
            Rectangle().fill(accentOrange).frame(width: len, height: w)
                .position(x: len / 2, y: size - w / 2)
            Rectangle().fill(accentOrange).frame(width: w, height: len)
                .position(x: w / 2, y: size - len / 2)

            // Bottom-Right corner
            Rectangle().fill(accentOrange).frame(width: len, height: w)
                .position(x: size - len / 2, y: size - w / 2)
            Rectangle().fill(accentOrange).frame(width: w, height: len)
                .position(x: size - w / 2, y: size - len / 2)

            // Animated scan line
            if isAnalyzing {
                Rectangle()
                    .fill(accentOrange)
                    .frame(width: size - 16, height: 2)
                    .shadow(color: accentOrange, radius: 6)
                    .shadow(color: accentOrange.opacity(0.4), radius: 12)
                    .position(x: size / 2, y: scanY)
            }
        }
        .frame(width: size, height: size)
    }
}

struct MockFoodScene: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "6B4226"), Color(hex: "2A1810"), Color(hex: "0A0604")],
                center: .init(x: 0.5, y: 0.45), startRadius: 0, endRadius: 280
            )

            // Plate
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "F5EFE6"), Color(hex: "D8CFC1"), Color(hex: "A89B85")],
                    center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: 140
                ))
                .frame(width: 280, height: 280)
                .shadow(color: .black.opacity(0.4), radius: 30, y: 20)
                .overlay(Text("🥑").font(.system(size: 120)))

            Text("🍞")
                .font(.system(size: 60))
                .offset(x: -70, y: 15)
            Text("🍳")
                .font(.system(size: 56))
                .offset(x: 60, y: 30)
        }
    }
}

struct GlassButton: View {
    let sfName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: sfName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
        }
    }
}

struct ShutterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 76, height: 76)
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

struct SmallCameraButton: View {
    let sfName: String

    var body: some View {
        Image(systemName: sfName)
            .font(.system(size: 22, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
    }
}

// MARK: - AVFoundation Camera Manager

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isAuthorized = false
    @Published var capturedImage: UIImage?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    override init() {
        super.init()
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            isAuthorized = false
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
        DispatchQueue.main.async { self.capturedImage = image }
    }
}

// MARK: - Camera preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.frame = uiView.bounds
    }
}

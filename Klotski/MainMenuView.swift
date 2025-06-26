//
//  Untitled.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//
import SwiftUI
import StoreKit
import GameKit

// MARK: - MainMenuView

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showLevelSelection = false
    @State private var showThemeSelection = false
    @State private var showSettings = false
    @State private var navigateToLeaderboardView = false
    
    private var menuButtonStyle: AnyButtonStyle {
        themeManager.currentTheme.viewFactory.menuButtonStyle()
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack() {
                    AnyView(themeManager.currentTheme.viewFactory.gameBackground())
                    
                    VStack(spacing: 20) {
                        Text(settingsManager.localizedString(forKey: "gameTitle"))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .padding(.top, 40)
                            .foregroundColor(themeManager.currentTheme.textColor.color)
                        
                        Spacer()

                        // --- Main menu buttons ---
                        Button(settingsManager.localizedString(forKey: "startGame")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            if let firstLevel = gameManager.levels.first {
                                gameManager.startGame(level: firstLevel, settings: settingsManager, isNewSession: true)
                            }
                        }
                        .buttonStyle(menuButtonStyle)

                        if gameManager.hasSavedGame {
                            Button(settingsManager.localizedString(forKey: "continueGame")) {
                                SoundManager.playImpactHaptic(settings: settingsManager)
                                gameManager.continueGame(settings: settingsManager)
                            }
                            .buttonStyle(menuButtonStyle)
                        }
                        
                        Button(settingsManager.localizedString(forKey: "selectLevel")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            self.showLevelSelection = true
                        }
                        .buttonStyle(menuButtonStyle)

                        Button(settingsManager.localizedString(forKey: "themes")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            self.showThemeSelection = true
                        }
                        .buttonStyle(menuButtonStyle)

                        Button(settingsManager.localizedString(forKey: "leaderboard")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            Task { await gameManager.syncAllLocalBestScoresToGameCenter() }
                            self.navigateToLeaderboardView = true
                        }
                        .buttonStyle(menuButtonStyle)
                        
                        Button(settingsManager.localizedString(forKey: "settings")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            self.showSettings = true
                        }
                        .buttonStyle(menuButtonStyle)
        
                        Spacer()

                        // --- 修改：简化主菜单的iCloud状态显示 ---
                        authStatusFooter().padding(.bottom).background(Color.clear)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .coordinateSpace(name: "MechanismBackground")
                .environment(\.backgroundOffset, geometry.safeAreaInsets.top)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationDestination(isPresented: $gameManager.isGameActive) { GameView() }
            .navigationDestination(isPresented: $navigateToLeaderboardView) { LeaderboardView() }
            .navigationDestination(isPresented: $showLevelSelection) { LevelSelectionView() }
            .navigationDestination(isPresented: $showThemeSelection) { ThemeSelectionView() }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
        }
        .id(themeManager.currentTheme.id)
        .navigationBarTheme(themeManager.currentTheme)
        .tint(themeManager.currentTheme.textColor.color)
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
    }

    // --- 修改：简化主菜单的iCloud状态显示 ---
    @ViewBuilder
    private func authStatusFooter() -> some View {
        HStack(spacing: 8) {
            Image(systemName: authManager.isLoggedIn ? "icloud.fill" : "icloud.slash.fill")
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
            Text(authManager.isLoggedIn ? settingsManager.localizedString(forKey: "iCloudSynced") : settingsManager.localizedString(forKey: "iCloudNotSynced"))
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
        }
        .padding(10)
    }
}


// MARK: - LevelSelectionView
struct LevelSelectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var isPresentedAsPanel: Bool
    var dismissPanelAction: (() -> Void)?
    var onLevelSelected: (() -> Void)?

    init(isPresentedAsPanel: Bool = false, dismissPanelAction: (() -> Void)? = nil, onLevelSelected: (() -> Void)? = nil) {
        self.isPresentedAsPanel = isPresentedAsPanel
        self.dismissPanelAction = dismissPanelAction
        self.onLevelSelected = onLevelSelected
    }
    

    private var levels: [Level] {
        gameManager.levels

    }
    private var classicLevels: [Level] {
        guard !levels.isEmpty else { return [] }
        return [levels[0]]
    }

    private var easyLevels: [Level] {
        guard levels.count >= 12 else { return [] }
        return Array(levels[1..<10])
    }

    private var mediumLevels: [Level] {
        guard levels.count >= 28 else { return [] }
        return Array(levels[10..<28])
    }

    private var hardLevels: [Level] {
        guard levels.count > 28 else { return [] }
        return Array(levels[28...])
    }

    private var moreLevels: [Level] = []

    var body: some View {
        Group {
            if isPresentedAsPanel {
                NavigationView { levelListContent }
                .navigationViewStyle(.stack)
            } else {
                levelListContent
            }
        }
        .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
    }

    private var levelListContent: some View {
        Form {
            if !classicLevels.isEmpty {
                Section(header: Text(settingsManager.localizedString(forKey: "levelCategoryClassic"))
                    .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                    ForEach(classicLevels) { level in
                        levelRow(for: level)
                    }
                }
                .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
            }

            if !easyLevels.isEmpty {
                Section(header: Text(settingsManager.localizedString(forKey: "levelCategoryEasy"))
                    .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                    ForEach(easyLevels) { level in
                        levelRow(for: level)
                    }
                }
                .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
            }
            
            Section(header: Text(settingsManager.localizedString(forKey: "levelCategoryMedium"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                if mediumLevels.isEmpty {
                    Text(settingsManager.localizedString(forKey: "comingSoon"))
                        .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.5))
                } else {
                    ForEach(mediumLevels) { level in
                        levelRow(for: level)
                    }
                }
            }
            .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))

            Section(header: Text(settingsManager.localizedString(forKey: "levelCategoryHard"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                if hardLevels.isEmpty {
                    Text(settingsManager.localizedString(forKey: "comingSoon"))
                        .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.5))
                } else {
                    ForEach(hardLevels) { level in
                        levelRow(for: level)
                    }
                }
            }
            .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
            
            Section(header: Text(settingsManager.localizedString(forKey: "levelCategoryMore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                if moreLevels.isEmpty {
                    Text(settingsManager.localizedString(forKey: "comingSoon"))
                        .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.5))
                } else {
                    ForEach(moreLevels) { level in
                        levelRow(for: level)
                    }
                }
            }
            .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))

            if levels.isEmpty {
                 Text(settingsManager.localizedString(forKey: "noLevels"))
                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                    .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
        }
        .navigationTitle(settingsManager.localizedString(forKey: "selectLevel"))
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .toolbar {
           if isPresentedAsPanel {
               ToolbarItem(placement: .navigationBarTrailing) {
                   Button(settingsManager.localizedString(forKey: "cancel")) {
                       SoundManager.playImpactHaptic(settings: settingsManager)
                       dismissPanelAction?()
                   }
                   .tint(themeManager.currentTheme.textColor.color)
               }
           }
        }
    }

    @ViewBuilder
    private func levelRow(for level: Level) -> some View {
        Button(action: {
            SoundManager.playImpactHaptic(settings: settingsManager)
            gameManager.startGame(level: level, settings: settingsManager, isNewSession: true)
            dismissPanelAction?()
            onLevelSelected?()
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(level.name)
                        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                        .foregroundColor(themeManager.currentTheme.textColor.color)
                    if let moves = level.bestMoves {
                        Text(String(format: settingsManager.localizedString(forKey: "bestScoreFormat"), moves))
                            .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                            .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                    } else {
                        Text(settingsManager.localizedString(forKey: "statusNotCompleted"))
                            .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                            .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.5))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
    }
}


// MARK: - Theme Selection Views
struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var themeForTrialConfirmation: Theme?

    private func storeKitProduct(for theme: Theme) -> Product? {
        guard theme.isPremium, let productID = theme.productID else { return nil }
        return themeManager.storeKitProducts.first(where: { $0.id == productID })
    }

    var body: some View {
        Form {
            Section(header: Text(settingsManager.localizedString(forKey: "themeStore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                
                ForEach(themeManager.themes) { theme in
                    themeRow(for: theme)
                       .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
                }
            }
            
            Section (footer: Text(settingsManager.localizedString(forKey: "restorePurchases_description"))) {
                 Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    guard authManager.isLoggedIn else {
                        themeManager.storeKitError = .userCannotMakePayments
                        return
                    }
                    Task { await themeManager.restoreThemePurchases(authManager:authManager) }
                }) {
                    HStack {
                        Text(settingsManager.localizedString(forKey: "restorePurchases"))

                        Spacer()
                        if themeManager.purchasingThemeID == "restore" {
                            ProgressView()
                        }
                     }
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
               .foregroundColor(authManager.isLoggedIn ? themeManager.currentTheme.textColor.color : .gray)
               .disabled(!authManager.isLoggedIn || themeManager.purchasingThemeID != nil)
            }
        }
        .navigationTitle(settingsManager.localizedString(forKey: "themes"))
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
        .alert(
            settingsManager.localizedString(forKey: "startTrialTitle"),
            isPresented: .constant(themeForTrialConfirmation != nil),
            presenting: themeForTrialConfirmation
        ) { theme in
            Button(settingsManager.localizedString(forKey: "confirm")) {
                themeManager.startTrial(for: theme)
                themeForTrialConfirmation = nil
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {
                themeForTrialConfirmation = nil
            }
        } message: { theme in
            Text(String(format: settingsManager.localizedString(forKey: "startTrialMessage"), theme.name))
        }
    }

    @ViewBuilder
    private func themeRow(for theme: Theme) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsManager.localizedString(forKey: theme.id))
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                HStack {
                    Circle().fill(theme.backgroundColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                    Circle().fill(theme.sliderColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                }
            }
            .foregroundColor(themeManager.currentTheme.textColor.color)
            .frame(maxWidth: .infinity, alignment: .leading)

            if themeManager.currentTheme.id == theme.id {
                if themeManager.isTrialActive {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                        .font(.title2)
                        .transition(.scale)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                        .transition(.scale)
                }
            } else {
                if themeManager.isThemePurchased(theme) {
                    if theme.isPremium{
                        Button(action: {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            themeManager.setCurrentTheme(theme)
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(settingsManager.localizedString(forKey: "applyTheme"))
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(themeManager.currentTheme.textColor.color)
                    }else{
                        Button(action: {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            themeManager.setCurrentTheme(theme)
                        }) {
                            HStack {
                                Text(settingsManager.localizedString(forKey: "applyTheme"))
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(themeManager.currentTheme.textColor.color)
                    }
                                        
                } else if theme.isPremium {
                    let product = storeKitProduct(for: theme)
                    
                    HStack(spacing: 12){
                        Button(action: {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            self.themeForTrialConfirmation = theme
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(settingsManager.localizedString(forKey: "tryTheme"))
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .disabled(!authManager.isLoggedIn || themeManager.isTrialActive || themeManager.purchasingThemeID != nil)

                        Button(action: {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            guard authManager.isLoggedIn else {
                                themeManager.storeKitError = .userCannotMakePayments
                                return
                            }
                            Task {
                                await themeManager.purchaseTheme(theme,authManager:authManager)
                            }
                        }) {
                            ZStack {
                                Text(product?.displayPrice ?? "...")
                                    .opacity(themeManager.purchasingThemeID == theme.id ? 0 : 1)
                                if themeManager.purchasingThemeID == theme.id {
                                    ProgressView()
                                }
                            }
                            .frame(minWidth: 50, minHeight: 22)
                        }
                       .buttonStyle(.borderedProminent)
                       .tint(.pink)
                       .disabled(!authManager.isLoggedIn || themeManager.isTrialActive || themeManager.purchasingThemeID != nil || product == nil)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    
                }
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(), value: themeManager.currentTheme.id)
        .animation(.spring(), value: themeManager.isTrialActive)
        .animation(.default, value: themeManager.purchasingThemeID)
    }
}


// MARK: - LeaderboardView

struct LeaderboardView: View {
    // MARK: - Environment & State
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameCenterManager: GameCenterManager
    
    @State private var isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
    
    @State private var selectedLeaderboardForSheet: LeaderboardInfo? = nil

    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.color.ignoresSafeArea()

            VStack(spacing: 0) {
                if isGameCenterAuthenticated {
                    authenticatedView
                } else {
                    unauthenticatedView
                }
            }
        }
        .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedLeaderboardForSheet) { leaderboardInfo in
            GameCenterLeaderboardPresenterView(
                leaderboardID: leaderboardInfo.id,
                themeManager: themeManager,
                // 传入一个闭包，当 Game Center 关闭时，这个闭包会被执行。
                onDismiss: {
                    // 这个操作会安全地关闭 sheet。
                    selectedLeaderboardForSheet = nil
                }
            )
            .ignoresSafeArea()
        }
        .onAppear {
            self.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
            Task {
                await gameCenterManager.fetchAllLeaderboards()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
            self.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
            Task {
                await gameCenterManager.fetchAllLeaderboards()
            }
        }
    }

    // MARK: - Authenticated View
    @ViewBuilder
    private var authenticatedView: some View {
        VStack {
            headerView
            
            if gameCenterManager.isLoading {
                ProgressView(settingsManager.localizedString(forKey: "loadingLeaderboards"))
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Spacer()
            } else if let error = gameCenterManager.loadingError {
                errorView(error)
            } else if gameCenterManager.leaderboards.isEmpty {
                emptyStateView
            } else {
                leaderboardListView
            }
        }
    }
    
    // MARK: - Subviews for Authenticated State
    
    private var headerView: some View {
        VStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.sliderColor.color)
                .padding(.bottom, 5)
        }
        .padding(.vertical, 20)
    }
    
    // private var leaderboardListView: some View {
    //     List(gameCenterManager.leaderboards) { leaderboardInfo in
    //         Button(action: {
    //             // 点击按钮时，直接设置我们的 item 状态变量来触发弹窗。
    //             self.selectedLeaderboardForSheet = leaderboardInfo
    //         }) {
    //             HStack {
    //                 VStack(alignment: .leading) {
    //                     Text(leaderboardInfo.title)
    //                         .font(.headline)
    //                         .foregroundColor(themeManager.currentTheme.textColor.color)
    //                 }
    //                 Spacer()
    //                 Image(systemName: "chevron.right")
    //                     .foregroundColor(.secondary.opacity(0.5))
    //             }
    //             .padding(.vertical, 8)
    //         }
    //         .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
    //     }
    //     .listStyle(.insetGrouped)
    //     .scrollContentBackground(.hidden)
    // }
    private var leaderboardListView: some View {
        List {
            Section(
                footer: Text(settingsManager.localizedString(forKey: "leaderBoardInfo"))
                    .font(.caption2) // 字体调整为更小的 .caption2
            ) {
                ForEach(gameCenterManager.leaderboards) { leaderboardInfo in
                    Button(action: {
                        // 点击按钮时，直接设置我们的 item 状态变量来触发弹窗。
                        self.selectedLeaderboardForSheet = leaderboardInfo
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(leaderboardInfo.title)
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.textColor.color)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(settingsManager.localizedString(forKey: "loadingFailed"))
                .font(.headline)
                .padding(.top)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "list.star")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(settingsManager.localizedString(forKey: "noLeaderboards"))
                .font(.headline)
                .padding(.top)
            Text(settingsManager.localizedString(forKey: "leaderboardSetupNote"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
            Spacer()
        }
    }

    // MARK: - Unauthenticated View
    @ViewBuilder
    private var unauthenticatedView: some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text(settingsManager.localizedString(forKey: "gameCenterLoginRequired"))
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            Text(settingsManager.localizedString(forKey: "gameCenterLoginPrompt"))
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(settingsManager.localizedString(forKey: "goToSettings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - GameCenterLeaderboardPresenterView (Reverted to Original Embedding Method)
// 恢复到原始的、在您环境中可以正常工作的“嵌入式”方案
struct GameCenterLeaderboardPresenterView: UIViewControllerRepresentable {
    let leaderboardID: String
    @ObservedObject var themeManager: ThemeManager
    // --- 关键修复 ---
    // 增加一个 onDismiss 闭包，用于接收关闭信号。
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let wrapperViewController = UIViewController()
        
        let gameCenterVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        // 将 Coordinator 设为代理
        gameCenterVC.gameCenterDelegate = context.coordinator
        
        wrapperViewController.addChild(gameCenterVC)
        wrapperViewController.view.addSubview(gameCenterVC.view)
        
        gameCenterVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gameCenterVC.view.topAnchor.constraint(equalTo: wrapperViewController.view.topAnchor),
            gameCenterVC.view.bottomAnchor.constraint(equalTo: wrapperViewController.view.bottomAnchor),
            gameCenterVC.view.leadingAnchor.constraint(equalTo: wrapperViewController.view.leadingAnchor),
            gameCenterVC.view.trailingAnchor.constraint(equalTo: wrapperViewController.view.trailingAnchor)
        ])
        
        gameCenterVC.didMove(toParent: wrapperViewController)

        return wrapperViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let newBackgroundColor = UIColor(themeManager.currentTheme.backgroundColor.color)
        if uiViewController.view.backgroundColor != newBackgroundColor {
            uiViewController.view.backgroundColor = newBackgroundColor
        }
    }

    func makeCoordinator() -> Coordinator {
        // 创建 Coordinator 时，把 onDismiss 闭包传递给它。
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        // --- 关键修复 ---
        // Coordinator 持有这个 onDismiss 闭包。
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            // 当用户点击“完成”时，执行这个闭包，
            // 从而触发 LeaderboardView 中的 `selectedLeaderboardForSheet = nil`。
            onDismiss()
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openURL) var openURL

    @State private var showingResetAlert = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            // MARK: - iCloud Status
            iCloudStatusSection()

            // MARK: - General Settings
            Section(header: Text(settingsManager.localizedString(forKey: "settingsGeneral"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                Picker(settingsManager.localizedString(forKey: "language"), selection: $settingsManager.language) {
                    Text(settingsManager.localizedString(forKey: "chinese")).tag("zh")
                    Text(settingsManager.localizedString(forKey: "english")).tag("en")
                }.onChange(of: settingsManager.language) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
           .foregroundColor(themeManager.currentTheme.textColor.color)

            // MARK: - Audio & Haptics
            Section(header: Text(settingsManager.localizedString(forKey: "settingsAudioHaptics"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                // Toggle(settingsManager.localizedString(forKey: "soundEffects"), isOn: $settingsManager.soundEffectsEnabled)
                //         .onChange(of: settingsManager.soundEffectsEnabled) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
                // Toggle(settingsManager.localizedString(forKey: "music"), isOn: $settingsManager.musicEnabled)
                //         .onChange(of: settingsManager.musicEnabled) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
                Toggle(settingsManager.localizedString(forKey: "haptics"), isOn: $settingsManager.hapticsEnabled)
                        .onChange(of: settingsManager.hapticsEnabled) { _, newValue in if newValue { SoundManager.playImpactHaptic(settings: settingsManager) } }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
           .foregroundColor(themeManager.currentTheme.textColor.color)
           .tint(themeManager.currentTheme.sliderColor.color)

            // MARK: - About & Support
            Section(header: Text(settingsManager.localizedString(forKey: "settingsAboutSupport"))
                // --- 修改：应用统一的Header样式 ---
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                
                Link(destination: URL(string: "mailto:zkun325@icloud.com")!) { // <-- 请替换成你的联系邮箱
                    HStack {
                        Text(settingsManager.localizedString(forKey: "settingsContact"))
                        Spacer()
                        Image(systemName: "envelope")
                    }
                }

                Link(destination: URL(string: "https://apps.apple.com/app/id6746719882")!) {
                    HStack {
                       Text(settingsManager.localizedString(forKey: "settingsRateApp"))
                       Spacer()
                       Image(systemName: "star.fill")
                           .foregroundColor(.yellow)
                   }
                }
                
                Link(destination: URL(string: "https://www.privacypolicies.com/live/188121c0-134f-4e9a-bb14-79d5dae73d2b")!) {
                     HStack {
                        Text(settingsManager.localizedString(forKey: "settingsPrivacyPolicy"))
                        Spacer()
                        Image(systemName: "lock.shield")
                    }
                }

                HStack {
                    Text(settingsManager.localizedString(forKey: "settingsVersion"))
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.gray)
                }
            }
            .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
            // --- 修改：为整个Section应用统一的文字颜色 ---
            .foregroundColor(themeManager.currentTheme.textColor.color)

        }
       .navigationTitle(settingsManager.localizedString(forKey: "settings"))
       .navigationBarTitleDisplayMode(.inline)
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
       .alert(settingsManager.localizedString(forKey: "resetProgress"), isPresented: $showingResetAlert) {
            Button(settingsManager.localizedString(forKey: "reset"), role: .destructive) {
                gameManager.levels.indices.forEach { gameManager.levels[$0].bestMoves = nil; gameManager.levels[$0].bestTime = nil }
                gameManager.clearSavedGame()
                debugLog("游戏进度已重置")
                SoundManager.playHapticNotification(type: .success, settings: settingsManager)
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {}
        } message: {Text(settingsManager.localizedString(forKey: "areYouSureReset"))
        }
    }

    // MARK: - iCloud Status Section View
    @ViewBuilder
    private func iCloudStatusSection() -> some View {
        Section(header: Text(settingsManager.localizedString(forKey: "settingsICloudStatus"))
            .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
            .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                
            VStack(alignment: .leading, spacing: 8) {
                if authManager.isLoggedIn {
                    Label {
                        Text(settingsManager.localizedString(forKey: "statusLoggedIn"))
                    } icon: {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .foregroundColor(.green)
                    }
                    .font(.headline)
                } else {
                    Label {
                        Text(settingsManager.localizedString(forKey: "statusNotLoggedIn"))
                    } icon: {
                        Image(systemName: "person.crop.circle.fill.badge.xmark")
                            .foregroundColor(.red)
                    }
                    .font(.headline)
                }

                if authManager.isLoading {
                    ProgressView()
                        .padding(.top, 5)
                    Text(settingsManager.localizedString(forKey: "iCloudCheckingStatus"))
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                } else if authManager.iCloudAccountStatus == .noAccount {
                     Text(settingsManager.localizedString(forKey: "iCloudNoAccountDetailed"))
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if !authManager.isLoggedIn {
                     Text(settingsManager.localizedString(forKey: "iCloudSyncError"))
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text(settingsManager.localizedString(forKey: "iCloudSyncDescription"))
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                }
            }
            .padding(.vertical, 5)
        }
        .listRowBackground(themeManager.currentTheme.backgroundColor.color.adjusted(by: themeManager.currentTheme.swiftUIScheme == .dark ? 0.1 : -0.05))
        .foregroundColor(themeManager.currentTheme.textColor.color)
    }
}




func fetchPlayerScore(leaderboardID: String) {
    guard GKLocalPlayer.local.isAuthenticated else {
        debugLog("Game Center: Player not authenticated. Cannot fetch score.")
        return
    }

    debugLog("Game Center: Attempting to fetch scores for leaderboard ID - \(leaderboardID)")

    Task {
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            
            guard let specificLeaderboard = leaderboards.first else {
                debugLog("Game Center: Leaderboard with ID '\(leaderboardID)' not found or failed to load. Please double-check the ID in App Store Connect.")
                return
            }

            debugLog("Game Center: Successfully loaded leaderboard metadata for '\(specificLeaderboard.title ?? leaderboardID)'.")

            let fetchRange = NSRange(location: 1, length: 50) 
            
            let loadResult = try await specificLeaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: fetchRange
            )

            let fetchedEntriesArray: [GKLeaderboard.Entry] = loadResult.1

            if !fetchedEntriesArray.isEmpty {
                debugLog("Game Center: Successfully fetched \(fetchedEntriesArray.count) entries for leaderboard '\(leaderboardID)':")
                for entry in fetchedEntriesArray {
                    debugLog("  Rank: \(entry.rank), Player: \(entry.player.displayName), Score: \(entry.formattedScore) (Raw: \(entry.score)), Date: \(entry.date)")
                }
            } else {
                debugLog("Game Center: No entries found for leaderboard '\(leaderboardID)'. The leaderboard might be empty or data is still syncing.")
            }

        } catch {
            debugLog("Game Center: Error fetching scores for leaderboard '\(leaderboardID)': \(error.localizedDescription)")
        }
    }
}

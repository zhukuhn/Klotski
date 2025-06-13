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
    
    // --- 新增：用于显示“试用结束”弹窗的状态 ---
    @State private var trialEndedAlertIsPresented = false
    
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
                                //gameManager.clearSavedGame()
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

                        authStatusFooter().padding(.bottom)
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
            .onAppear {
                if settingsManager.useiCloudLogin {
                    // authManager.refreshAuthenticationState()
                }
            }
            // --- 新增：监听 trialEndedAlert 状态来触发弹窗 ---
            .onChange(of: themeManager.showTrialEndedAlert) { _, newValue in
                if newValue {
                    self.trialEndedAlertIsPresented = true
                }
            }
            // --- 新增：试用结束后的购买弹窗 ---
            .alert(
                settingsManager.localizedString(forKey: "trialEnded"),
                isPresented: $trialEndedAlertIsPresented,
                presenting: themeManager.trialThemeForPurchase
            ) { theme in
                Button(settingsManager.localizedString(forKey: "purchase")) {
                    Task {
                        await themeManager.purchaseTheme(theme)
                    }
                }
                Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {}
            } message: { theme in
                Text(String(format: settingsManager.localizedString(forKey: "trialEndedMessage"), theme.name))
            }
        }
        .id(themeManager.currentTheme.id)
        .navigationBarTheme(themeManager.currentTheme)
        .tint(themeManager.currentTheme.textColor.color)
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
        
    }

    @ViewBuilder
    private func authStatusFooter() -> some View {
        // ... 此处代码与之前版本相同，保持不变 ...
        VStack {
            if settingsManager.useiCloudLogin {
                if authManager.isLoading {
                    ProgressView()
                       .padding(.bottom, 5)
                    Text(settingsManager.localizedString(forKey: "iCloudCheckingStatus"))
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                } else if authManager.isLoggedIn, let user = authManager.currentUser {
                    Text("\(settingsManager.localizedString(forKey: "loggedInAs")) \(user.displayName ?? settingsManager.localizedString(forKey: "iCloudUser"))")
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.textColor.color)
                       .padding(.bottom, 5)
                } else if authManager.iCloudAccountStatus == .noAccount {
                     Text(settingsManager.localizedString(forKey: "iCloudNoAccountDetailed"))
                       .font(.caption)
                       .foregroundColor(.orange)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)
                } else {
                     Text(settingsManager.localizedString(forKey: "iCloudSyncError"))
                       .font(.caption)
                       .foregroundColor(.orange)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)
                }
            } else {
                Text(settingsManager.localizedString(forKey: "iCloudDisabledInSettings"))
                   .font(.caption)
                   .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                   .multilineTextAlignment(.center)
                   .padding(.horizontal)
            }
        }
        .frame(minHeight: 50)
    }
}




// MARK: 关卡选择视图
struct LevelSelectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var isPresentedAsPanel: Bool = false
    var dismissPanelAction: (() -> Void)? = nil
    var onLevelSelected: (() -> Void)? = nil

    var body: some View {
        Group {
            if isPresentedAsPanel {
                NavigationView { levelListContent }
                .navigationViewStyle(.stack)
            } else {
                levelListContent
            }
        }
    }

    var levelListContent: some View {
        List {
            ForEach(gameManager.levels.filter { $0.isUnlocked }) { level in
                Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    gameManager.startGame(level: level, settings: settingsManager, isNewSession: true)
                    dismissPanelAction?()
                    onLevelSelected?()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            // --- 修改：使用新的 textColor ---
                            Text(level.name)
                                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                                .foregroundColor(themeManager.currentTheme.textColor.color)
                            if let moves = level.bestMoves {
                                Text("最佳: \(moves) \(settingsManager.localizedString(forKey: "moves"))")
                                    .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                            } else {
                                Text("未完成")
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
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
            if gameManager.levels.filter({ $0.isUnlocked }).isEmpty {
                Text(settingsManager.localizedString(forKey: "noLevels"))
                   .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7))
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "selectLevel"))
       //.navigationBarTitleDisplayMode(isPresentedAsPanel ? .inline : .automatic)
       .navigationBarTitleDisplayMode(.inline)
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
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
    }
}

// MARK: - 主题选择视图
struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager

    @State private var showStoreErrorAlert = false
    @State private var storeActionError: StoreKitError? = nil {
        didSet { if storeActionError != nil { showStoreErrorAlert = true } }
    }
    
    // --- 新增：用于在开始试用前进行确认 ---
    @State private var themeForTrialConfirmation: Theme?

    private func storeKitProduct(for theme: Theme) -> Product? {
        guard theme.isPremium, let productID = theme.productID else { return nil }
        return themeManager.storeKitProducts.first(where: { $0.id == productID })
    }

    var body: some View {
        List {
            Section(header: Text(settingsManager.localizedString(forKey: "themeStore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) {
                
                ForEach(themeManager.themes) { theme in
                    themeRow(for: theme)
                       .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
            
            Section {
                 // ... 恢复购买按钮逻辑保持不变 ...
                 Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    guard settingsManager.useiCloudLogin && authManager.isLoggedIn else {
                        self.storeActionError = .userCannotMakePayments
                        return
                    }
                    Task { await themeManager.restoreThemePurchases() }
                }) {
                    HStack {
                        Text(settingsManager.localizedString(forKey: "restorePurchases"))
                        Spacer()
                        if themeManager.isStoreLoading && storeKitProduct(for: themeManager.currentTheme) == nil {
                            ProgressView()
                        }
                     }
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
               .foregroundColor(settingsManager.useiCloudLogin && authManager.isLoggedIn ? themeManager.currentTheme.textColor.color : .gray)
               .disabled(!settingsManager.useiCloudLogin || !authManager.isLoggedIn || themeManager.isStoreLoading)
            }
        }
        .navigationTitle(settingsManager.localizedString(forKey: "themes"))
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
        .onAppear {
           if settingsManager.useiCloudLogin && authManager.isLoggedIn {
               Task {
                   await themeManager.fetchSKProducts()
                   await StoreKitManager.shared.checkForCurrentEntitlements()
               }
           }
           themeManager.storeKitError = nil
        }
        .onChange(of: themeManager.storeKitError) { _, newValue in
           if let newError = newValue { self.storeActionError = newError }
        }
        .alert(isPresented: $showStoreErrorAlert, error: storeActionError) { _ in
           Button("OK") {
               themeManager.storeKitError = nil
               storeActionError = nil
           }
        } message: { error in
           Text(error.errorDescription ?? "An unknown error occurred.")
        }
        // --- 新增：开始试用前的确认弹窗 ---
        .alert(
            settingsManager.localizedString(forKey: "startTrialTitle"),
            isPresented: .constant(themeForTrialConfirmation != nil),
            presenting: themeForTrialConfirmation
        ) { theme in
            Button(settingsManager.localizedString(forKey: "confirm")) {
                themeManager.startTrial(for: theme)
                themeForTrialConfirmation = nil // 关闭弹窗
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {
                themeForTrialConfirmation = nil // 关闭弹窗
            }
        } message: { theme in
            Text(String(format: settingsManager.localizedString(forKey: "startTrialMessage"), theme.name))
        }
    }

    @ViewBuilder
    private func themeRow(for theme: Theme) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                HStack {
                    Circle().fill(theme.backgroundColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                    Circle().fill(theme.sliderColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                    //if let font = theme.fontName { Text(font).font(.caption2).italic() }
                }
            }
            .foregroundColor(themeManager.currentTheme.textColor.color)

            Spacer()

            if themeManager.currentTheme.id == theme.id {
                // 如果当前主题正在试用，显示一个计时器图标
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
                        .tint(.orange)
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
                    HStack{
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
                        // 如果正在试用其他主题，则禁用此按钮
                        .disabled(themeManager.isTrialActive)

                        Button(action: {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            guard settingsManager.useiCloudLogin && authManager.isLoggedIn else {
                                print("Purchase blocked: iCloud not enabled or user not logged in.")
                                self.storeActionError = .userCannotMakePayments
                                return
                            }
                            Task {
                                await themeManager.purchaseTheme(theme)
                                // 错误会通过 themeManager.storeKitError 更新
                            }
                        }) {
                            if themeManager.isStoreLoading && storeKitProduct(for: theme)?.id == product?.id {
                                ProgressView().frame(height: 20)
                            } else {
                                Text(product?.displayPrice ?? (theme.price != nil ? String(format: "¥%.2f", theme.price!) : settingsManager.localizedString(forKey: "purchase")))
                            }
                        }
                       .buttonStyle(.borderedProminent)
                       .tint(.pink)
                       .disabled(!settingsManager.useiCloudLogin || !authManager.isLoggedIn || themeManager.isStoreLoading || product == nil) // 如果 product 未加载也禁用
                    }
                    
                }
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(), value: themeManager.currentTheme.id)
        .animation(.spring(), value: themeManager.isTrialActive)
    }
}

// MARK: 排行榜视图
enum ScoreType: String, CaseIterable, Identifiable {
    case moves = "最少步数"
    case time = "最短时间"
    var id: String { self.rawValue }
}

struct LeaderboardView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager

    @State private var isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
    @State private var showingGameCenterSheet = false
    @State private var selectedLeaderboardIDForSheet: String? = nil

    @State private var selectedLevelID: String? = nil
    @State private var selectedScoreType: ScoreType = .moves

    var unlockedLevels: [Level] {
        gameManager.levels.filter { $0.isUnlocked }
    }

    var body: some View {
        VStack(spacing: 20) {
            if !isGameCenterAuthenticated {
                Spacer()
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text("需要登录 Game Center 才能查看排行榜。")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                Text("请前往 设置App -> Game Center 打开")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                Picker(settingsManager.localizedString(forKey: "selectLevel"), selection: $selectedLevelID) {
                    Text("请选择关卡").tag(String?.none)
                    ForEach(unlockedLevels) { level in
                        Text(level.name).tag(String?(level.id))
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .disabled(unlockedLevels.isEmpty)

                if unlockedLevels.isEmpty {
                    Text("暂无可查看排行榜的关卡。")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Picker("排行榜类型", selection: $selectedScoreType) {
                    ForEach(ScoreType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button {
                    if let levelID = selectedLevelID {
                        let baseID = levelID
                        let suffix = selectedScoreType == .moves ? "_moves" : "_time"
                        self.selectedLeaderboardIDForSheet = baseID + suffix
                        self.showingGameCenterSheet = true
                    }
                } label: {
                    Label("查看排行榜", systemImage: "list.star")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedLevelID == nil || selectedLeaderboardIDForSheet == nil)
                .padding()
                
                Spacer()
                
                Text("排行榜数据由 Game Center 提供。")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.7)) // Use textColor
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingGameCenterSheet) {
            if let leaderboardID = selectedLeaderboardIDForSheet {
                GameCenterLeaderboardPresenterView(
                    leaderboardID: leaderboardID,
                    isPresented: $showingGameCenterSheet,
                    themeManager: themeManager
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            self.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
            if selectedLevelID == nil, let firstUnlockedLevel = unlockedLevels.first {
                selectedLevelID = firstUnlockedLevel.id
            }
            updateSelectedLeaderboardID()
        }
        .onChange(of: selectedLevelID) { _, _ in updateSelectedLeaderboardID() }
        .onChange(of: selectedScoreType) { _, _ in updateSelectedLeaderboardID() }
        .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
            self.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
        }
    }

    private func updateSelectedLeaderboardID() {
        if let levelID = selectedLevelID {
            let baseID = levelID
            let suffix = selectedScoreType == .moves ? "_moves" : "_time"
            self.selectedLeaderboardIDForSheet = baseID + suffix
        } else {
            self.selectedLeaderboardIDForSheet = nil
        }
    }
}

struct GameCenterLeaderboardPresenterView: UIViewControllerRepresentable {
    let leaderboardID: String
    @Binding var isPresented: Bool
    @ObservedObject var themeManager: ThemeManager

    func makeUIViewController(context: Context) -> UIViewController {
        let wrapperViewController = UIViewController()
        wrapperViewController.view.backgroundColor = UIColor.clear

        let gameCenterViewController = GKGameCenterViewController(leaderboardID: leaderboardID,playerScope: .global,timeScope: .allTime)
        gameCenterViewController.gameCenterDelegate = context.coordinator

        wrapperViewController.addChild(gameCenterViewController)
        wrapperViewController.view.addSubview(gameCenterViewController.view)
        
        gameCenterViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gameCenterViewController.view.topAnchor.constraint(equalTo: wrapperViewController.view.topAnchor),
            gameCenterViewController.view.bottomAnchor.constraint(equalTo: wrapperViewController.view.bottomAnchor),
            gameCenterViewController.view.leadingAnchor.constraint(equalTo: wrapperViewController.view.leadingAnchor),
            gameCenterViewController.view.trailingAnchor.constraint(equalTo: wrapperViewController.view.trailingAnchor)
        ])
        gameCenterViewController.didMove(toParent: wrapperViewController)

        return wrapperViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let newBackgroundColor = UIColor(themeManager.currentTheme.backgroundColor.color)
        if uiViewController.view.backgroundColor != newBackgroundColor {
            uiViewController.view.backgroundColor = newBackgroundColor
         }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        var parent: GameCenterLeaderboardPresenterView

        init(_ parent: GameCenterLeaderboardPresenterView) {
            self.parent = parent
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            self.parent.isPresented = false
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openURL) var openURL

    @State private var showingResetAlert = false
    @State private var showingiCloudInstructionAlert = false

    var body: some View {
        Form {
            Section(header: Text(settingsManager.localizedString(forKey: "iCloudSectionTitle"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) { // Use textColor
                Toggle(settingsManager.localizedString(forKey: "useiCloudLogin"), isOn: $settingsManager.useiCloudLogin)
                    .onChange(of: settingsManager.useiCloudLogin) { oldValue, newValue in
                        SoundManager.playImpactHaptic(settings: settingsManager)
                        authManager.handleiCloudPreferenceChange(useiCloud: newValue)
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if authManager.iCloudAccountStatus != .available {
                                    settingsManager.useiCloudLogin = false
                                    authManager.handleiCloudPreferenceChange(useiCloud: false)
                                    self.showingiCloudInstructionAlert = true
                                }
                            }
                        }
                    }
                Text(settingsManager.localizedString(forKey: "iCloudLoginDescription"))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.6)) // Use textColor
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.textColor.color) // Use textColor
           .tint(themeManager.currentTheme.sliderColor.color) // Tint for toggle remains slider color for accent

            Section(header: Text("通用设置")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) { // Use textColor
                Picker(settingsManager.localizedString(forKey: "language"), selection: $settingsManager.language) {
                    Text(settingsManager.localizedString(forKey: "chinese")).tag("zh")
                    Text(settingsManager.localizedString(forKey: "english")).tag("en")
                }.onChange(of: settingsManager.language) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.textColor.color) // Use textColor

            Section(header: Text("音频与触感")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) { // Use textColor
                Toggle(settingsManager.localizedString(forKey: "soundEffects"), isOn: $settingsManager.soundEffectsEnabled)
                        .onChange(of: settingsManager.soundEffectsEnabled) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
                Toggle(settingsManager.localizedString(forKey: "music"), isOn: $settingsManager.musicEnabled)
                        .onChange(of: settingsManager.musicEnabled) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
                Toggle(settingsManager.localizedString(forKey: "haptics"), isOn: $settingsManager.hapticsEnabled)
                        .onChange(of: settingsManager.hapticsEnabled) { _, newValue in if newValue { SoundManager.playImpactHaptic(settings: settingsManager) } }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.textColor.color) // Use textColor
           .tint(themeManager.currentTheme.sliderColor.color) // Tint for toggles

            Section(header: Text("游戏数据")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.textColor.color.opacity(0.8))) { // Use textColor
                Button(settingsManager.localizedString(forKey: "resetProgress"), role: .destructive) {
                    showingResetAlert = true
                    SoundManager.playHapticNotification(type: .warning, settings: settingsManager)
                }
               .foregroundColor(.red)
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
            
            Section(header: Text("开发者选项")) {
                Button("重置 iCloud 已购主题", role: .destructive) {
                    authManager.resetPurchasedThemesInCloud()
                }
                .foregroundColor(.red)
                .disabled(!authManager.isLoggedIn)
            }
            .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
        }
       .navigationTitle(settingsManager.localizedString(forKey: "settings"))
       .navigationBarTitleDisplayMode(.inline)
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
       .alert(settingsManager.localizedString(forKey: "resetProgress"), isPresented: $showingResetAlert) {
            Button(settingsManager.localizedString(forKey: "reset"), role: .destructive) {
                gameManager.levels.indices.forEach { gameManager.levels[$0].bestMoves = nil; gameManager.levels[$0].bestTime = nil }
                gameManager.clearSavedGame()
                print("游戏进度已重置")
                SoundManager.playHapticNotification(type: .success, settings: settingsManager)
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {}
        } message: {Text(settingsManager.localizedString(forKey: "areYouSureReset"))
        }
        .alert(settingsManager.localizedString(forKey: "iCloudEnableInstructionTitle"), isPresented: $showingiCloudInstructionAlert) {
            Button(settingsManager.localizedString(forKey: "confirm"), role: .cancel) {}
        } message: {
            Text(settingsManager.localizedString(forKey: "iCloudEnableInstructionMessage"))
        }
    }
}

func fetchPlayerScore(leaderboardID: String) {
    guard GKLocalPlayer.local.isAuthenticated else {
        print("Game Center: Player not authenticated. Cannot fetch score.")
        return
    }

    print("Game Center: Attempting to fetch scores for leaderboard ID - \(leaderboardID)")

    Task {
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            
            guard let specificLeaderboard = leaderboards.first else {
                print("Game Center: Leaderboard with ID '\(leaderboardID)' not found or failed to load. Please double-check the ID in App Store Connect.")
                return
            }

            print("Game Center: Successfully loaded leaderboard metadata for '\(specificLeaderboard.title ?? leaderboardID)'.")

            let fetchRange = NSRange(location: 1, length: 50) 
            
            let loadResult = try await specificLeaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: fetchRange
            )

            let fetchedEntriesArray: [GKLeaderboard.Entry] = loadResult.1

            if !fetchedEntriesArray.isEmpty {
                print("Game Center: Successfully fetched \(fetchedEntriesArray.count) entries for leaderboard '\(leaderboardID)':")
                for entry in fetchedEntriesArray {
                    print("  Rank: \(entry.rank), Player: \(entry.player.displayName), Score: \(entry.formattedScore) (Raw: \(entry.score)), Date: \(entry.date)")
                }
            } else {
                print("Game Center: No entries found for leaderboard '\(leaderboardID)'. The leaderboard might be empty or data is still syncing.")
            }

        } catch {
            print("Game Center: Error fetching scores for leaderboard '\(leaderboardID)': \(error.localizedDescription)")
        }
    }
}

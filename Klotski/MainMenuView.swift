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
    // MARK: Environment Objects
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var navigateToLeaderboardView = false
    
    // 获取当前主题的按钮样式
    private var menuButtonStyle: AnyButtonStyle {
        themeManager.currentTheme.viewFactory.menuButtonStyle()
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            // --- 已修正：使用 ZStack 来承载背景和内容 ---
            ZStack {
                // 第 1 层：由主题工厂提供背景
                AnyView(themeManager.currentTheme.viewFactory.gameBackground())

                // 第 2 层：页面内容
                VStack(spacing: 20) {
                    Text(settingsManager.localizedString(forKey: "gameTitle"))
                       .font(.system(size: 36, weight: .bold, design: .rounded))
                       .padding(.top, 40)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color)
                    
                    Spacer()

                    Button(settingsManager.localizedString(forKey: "startGame")) {
                        SoundManager.playImpactHaptic(settings: settingsManager)
                        if let firstLevel = gameManager.levels.first {
                            gameManager.clearSavedGame()
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
                    
                    NavigationLink(destination: LevelSelectionView()) {
                         Text(settingsManager.localizedString(forKey: "selectLevel"))
                    }
                    .buttonStyle(menuButtonStyle)
                    .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })

                    NavigationLink(destination: ThemeSelectionView()) {
                        Text(settingsManager.localizedString(forKey: "themes"))
                    }
                    .buttonStyle(menuButtonStyle)
                    .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })

                    Button(settingsManager.localizedString(forKey: "leaderboard")) {
                        SoundManager.playImpactHaptic(settings: settingsManager)
                        Task {
                            await gameManager.syncAllLocalBestScoresToGameCenter()
                        }
                        self.navigateToLeaderboardView = true
                    }
                    .buttonStyle(menuButtonStyle)

                    NavigationLink(destination: SettingsView()) {
                        Text(settingsManager.localizedString(forKey: "settings"))
                    }
                    .buttonStyle(menuButtonStyle)
                    .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })
                    
                    Button("查询"){
                        fetchPlayerScore(leaderboardID: "classic_hdml_moves")
                    }
        
                    Spacer()

                    authStatusFooter().padding(.bottom)
                }
               .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
           .navigationDestination(isPresented: $gameManager.isGameActive) { GameView() }
           .navigationDestination(isPresented: $navigateToLeaderboardView) { LeaderboardView() }
           .onAppear {
                if settingsManager.useiCloudLogin {
                    // authManager.refreshAuthenticationState()
                }
           }
        }
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
    }
    
    // ... 其余 MainMenuView 代码 (authStatusFooter, etc.) 保持不变 ...
    // --- (篇幅原因，此处省略未改变的代码) ---
    @ViewBuilder
    private func authStatusFooter() -> some View {
        VStack {
            if settingsManager.useiCloudLogin {
                if authManager.isLoading {
                    ProgressView()
                       .padding(.bottom, 5)
                    Text(settingsManager.localizedString(forKey: "iCloudCheckingStatus"))
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                } else if authManager.isLoggedIn, let user = authManager.currentUser {
                    Text("\(settingsManager.localizedString(forKey: "loggedInAs")) \(user.displayName ?? settingsManager.localizedString(forKey: "iCloudUser"))")
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color)
                       .padding(.bottom, 5)
                } else if authManager.iCloudAccountStatus == .noAccount {
                     Text(settingsManager.localizedString(forKey: "iCloudNoAccountDetailed"))
                       .font(.caption)
                       .foregroundColor(.orange)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)
                } else if authManager.iCloudAccountStatus != .available && authManager.errorMessage != nil {
                    Text(authManager.errorMessage ?? settingsManager.localizedString(forKey: "iCloudConnectionError"))
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if authManager.iCloudAccountStatus == .available && !authManager.isLoggedIn && !authManager.isLoading {
                     Text(settingsManager.localizedString(forKey: "iCloudSyncError"))
                       .font(.caption)
                       .foregroundColor(.orange)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)
                } else if !authManager.isLoggedIn && !authManager.isLoading {
                    Text(settingsManager.localizedString(forKey: "iCloudLoginPrompt"))
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                }
            } else {
                Text(settingsManager.localizedString(forKey: "iCloudDisabledInSettings"))
                   .font(.caption)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
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
                    gameManager.clearSavedGame()
                    gameManager.startGame(level: level, settings: settingsManager, isNewSession: true)
                    dismissPanelAction?()
                    onLevelSelected?()
                }) {
                    HStack {
                        VStack(alignment: .leading) { Text(level.name).font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline).foregroundColor(themeManager.currentTheme.sliderColor.color); if let moves = level.bestMoves { Text("最佳: \(moves) \(settingsManager.localizedString(forKey: "moves"))").font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption).foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7)) } else { Text("未完成").font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption).foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.5)) } }; Spacer(); Image(systemName: "chevron.right").foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.5))
                    }.padding(.vertical, 8)
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
            if gameManager.levels.filter({ $0.isUnlocked }).isEmpty {
                Text(settingsManager.localizedString(forKey: "noLevels"))
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "selectLevel"))
       .navigationBarTitleDisplayMode(isPresentedAsPanel ? .inline : .automatic)
       .toolbar {
           if isPresentedAsPanel {
               ToolbarItem(placement: .navigationBarTrailing) {
                   Button(settingsManager.localizedString(forKey: "cancel")) {
                       SoundManager.playImpactHaptic(settings: settingsManager)
                       dismissPanelAction?()
                   }
                   .tint(themeManager.currentTheme.sliderColor.color)
               }
           }
       }
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
    }
}

// MARK: 主题选择视图
struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager

    @State private var showStoreErrorAlert = false
    @State private var storeActionError: StoreKitError? = nil {
        didSet {
            if storeActionError != nil {
                showStoreErrorAlert = true
            }
        }
    }
    
    // Helper to get SKProduct equivalent for a theme
    private func storeKitProduct(for theme: Theme) -> Product? {
        guard theme.isPremium, let productID = theme.productID else { return nil }
        return themeManager.storeKitProducts.first(where: { $0.id == productID })
    }

    var body: some View {
        List {
            Section(header: Text(settingsManager.localizedString(forKey: "themeStore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                
                ForEach(themeManager.themes) { theme in
                    themeRow(for: theme)
                       .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
            
            Section {
                 Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    guard settingsManager.useiCloudLogin && authManager.isLoggedIn else {
                        print("Restore purchases requires iCloud login and user to be logged in.")
                        self.storeActionError = .userCannotMakePayments // 或更合适的错误
                        return
                    }
                    Task {
                        await themeManager.restoreThemePurchases()
                        // 错误会通过 themeManager.storeKitError 更新，并触发 alert
                    }
                }) {
                    HStack {
                        Text(settingsManager.localizedString(forKey: "restorePurchases"))
                        Spacer()
                        if themeManager.isStoreLoading && storeKitProduct(for: themeManager.currentTheme) == nil { // 粗略判断是否是全局恢复
                            ProgressView()
                        }
                     }
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
               .foregroundColor(settingsManager.useiCloudLogin && authManager.isLoggedIn ? themeManager.currentTheme.sliderColor.color : .gray)
               .disabled(!settingsManager.useiCloudLogin || !authManager.isLoggedIn || themeManager.isStoreLoading)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "themes"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
       .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
       .onAppear {
           print("ThemeSelectionView onAppear: useiCloudLogin = \(settingsManager.useiCloudLogin)")
           if settingsManager.useiCloudLogin && authManager.isLoggedIn { // && themeManager.storeKitProducts.isEmpty { // 每次出现都获取一下，确保最新
               Task {
                   await themeManager.fetchSKProducts()
                   // 视图出现时也检查一下当前购买情况
                   await StoreKitManager.shared.checkForCurrentEntitlements()
               }
           }
           themeManager.storeKitError = nil // 进入视图时清除旧错误
       }
       .onChange(of: themeManager.storeKitError) { oldValue, newValue in // 监听错误变化
           if let newError = newValue {
               self.storeActionError = newError
           }
       }
       .alert(isPresented: $showStoreErrorAlert, error: storeActionError) { error in
           // SwiftUI 会自动使用 error.localizedDescription
           Button("OK") {
               themeManager.storeKitError = nil // 清除错误，以便下次可以再次触发 alert
               storeActionError = nil
           }
       } message: { error in
           Text(error.errorDescription ?? "An unknown error occurred.") // 使用我们自定义的描述
       }
    }

    @ViewBuilder
    private func themeRow(for theme: Theme) -> some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                       .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                    HStack { /* ... 颜色圆点 ... */ 
                        Circle().fill(theme.backgroundColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                        Circle().fill(theme.sliderColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                        if let font = theme.fontName { Text(font).font(.caption2).italic() }
                    }
                }
               .foregroundColor(themeManager.currentTheme.sliderColor.color)

                Spacer()

                if themeManager.currentTheme.id == theme.id {
                    Image(systemName: "checkmark.circle.fill")
                       .foregroundColor(.green)
                       .font(.title2)
                } else {
                    if themeManager.isThemePurchased(theme) {
                        Button(settingsManager.localizedString(forKey: "applyTheme")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            themeManager.setCurrentTheme(theme)
                        }
                       .buttonStyle(.bordered)
                       .tint(themeManager.currentTheme.sliderColor.color)
                    } else if theme.isPremium {
                        let product = storeKitProduct(for: theme)
                        
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
                    // 免费且未应用的主题会落入 isThemePurchased -> applyTheme
                }
            }
            
            if theme.isPremium {
                if !themeManager.isThemePurchased(theme) && (!settingsManager.useiCloudLogin || !authManager.isLoggedIn) {
                    Text(settingsManager.localizedString(forKey: "purchaseRequiresiCloud"))
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
            }
        }
       .padding(.vertical, 8)
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
                    .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
        .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingGameCenterSheet) {
            // 使用我们优化后的 Representable
            if let leaderboardID = selectedLeaderboardIDForSheet {
                // 将 themeManager 传递给 Representable，以便它可以访问主题颜色
                GameCenterLeaderboardPresenterView(
                    leaderboardID: leaderboardID,
                    isPresented: $showingGameCenterSheet,
                    themeManager: themeManager // 传递 themeManager
                )
                .ignoresSafeArea() // 确保 Game Center UI 充满整个 sheet
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

// 新的包装视图，用于承载 GKGameCenterViewController 并处理背景
struct GameCenterLeaderboardPresenterView: UIViewControllerRepresentable {
    let leaderboardID: String
    @Binding var isPresented: Bool
    @ObservedObject var themeManager: ThemeManager // 接收 ThemeManager

    func makeUIViewController(context: Context) -> UIViewController {
        // 1. 创建一个包装的 UIViewController
        let wrapperViewController = UIViewController()
        
        // 2. 设置包装 ViewController 的背景色
        // 您可以根据 App 的主题来设置，或者使用一个与 Game Center 较协调的颜色
        // 例如，使用当前主题的背景色
        //wrapperViewController.view.backgroundColor = UIColor(themeManager.currentTheme.backgroundColor.color)
        // 或者使用一个标准的系统灰色，这通常与 Game Center 的 UI 比较协调
        // wrapperViewController.view.backgroundColor = UIColor.systemGroupedBackground
        wrapperViewController.view.backgroundColor = UIColor.clear

        // 3. 创建 GameCenterViewController
        let gameCenterViewController = GKGameCenterViewController(leaderboardID: leaderboardID,
                                                                playerScope: .global,
                                                                timeScope: .allTime)
        gameCenterViewController.gameCenterDelegate = context.coordinator

        // 4. 将 GameCenterViewController 作为子视图控制器添加到包装器中
        wrapperViewController.addChild(gameCenterViewController)
        wrapperViewController.view.addSubview(gameCenterViewController.view)
        
        // 5. 设置 GameCenterViewController 的 view 约束，使其填满包装器
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
        // 当 SwiftUI 状态变化时，如果需要更新 UIKit 视图，可以在这里处理
        // 对于当前场景，主要是在创建时设置好，通常不需要太多更新逻辑
        // 但如果主题颜色动态改变且希望 sheet 背景也立即响应，则可能需要在这里更新 wrapperViewController.view.backgroundColor
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

// MARK: 设置视图
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openURL) var openURL // For opening settings URL

    @State private var showingResetAlert = false
    @State private var showingiCloudInstructionAlert = false // New state for iCloud instruction

    var body: some View {
        Form {
            Section(header: Text(settingsManager.localizedString(forKey: "iCloudSectionTitle"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
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
                    .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.6))
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.sliderColor.color)
           .tint(themeManager.currentTheme.sliderColor.color)

            Section(header: Text("通用设置")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Picker(settingsManager.localizedString(forKey: "language"), selection: $settingsManager.language) {
                    Text(settingsManager.localizedString(forKey: "chinese")).tag("zh")
                    Text(settingsManager.localizedString(forKey: "english")).tag("en")
                }.onChange(of: settingsManager.language) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.sliderColor.color)


            Section(header: Text("音频与触感")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Toggle(settingsManager.localizedString(forKey: "soundEffects"), isOn: $settingsManager.soundEffectsEnabled)
                        .onChange(of: settingsManager.soundEffectsEnabled) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
                Toggle(settingsManager.localizedString(forKey: "music"), isOn: $settingsManager.musicEnabled)
                        .onChange(of: settingsManager.musicEnabled) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
                Toggle(settingsManager.localizedString(forKey: "haptics"), isOn: $settingsManager.hapticsEnabled)
                        .onChange(of: settingsManager.hapticsEnabled) { _, newValue in if newValue { SoundManager.playImpactHaptic(settings: settingsManager) } }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.sliderColor.color)
           .tint(themeManager.currentTheme.sliderColor.color)

            Section(header: Text("游戏数据")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Button(settingsManager.localizedString(forKey: "resetProgress"), role: .destructive) {
                    showingResetAlert = true
                    SoundManager.playHapticNotification(type: .warning, settings: settingsManager)
                }
               .foregroundColor(.red)
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
            
            //开发者按钮
            // --- 开始添加 ---
            Section(header: Text("开发者选项")) {
                Button("重置 iCloud 已购主题", role: .destructive) {
                    // 调用我们刚刚在 AuthManager 中添加的函数
                    authManager.resetPurchasedThemesInCloud()
                }
                .foregroundColor(.red)
                .disabled(!authManager.isLoggedIn) // 只有在登录时才可用
            }
            .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
            // --- 结束添加 ---

        }
       .navigationTitle(settingsManager.localizedString(forKey: "settings"))
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
        // 在实际应用中，您可能想在这里更新UI，提示用户需要登录
        return
    }

    print("Game Center: Attempting to fetch scores for leaderboard ID - \(leaderboardID)")

    Task {
        do {
            // 1. 加载特定的排行榜实例
            // loadLeaderboards 是一个类型方法，返回一个包含 GKLeaderboard 实例的数组
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            
            // 确保我们获取到了排行榜实例
            guard let specificLeaderboard = leaderboards.first else {
                print("Game Center: Leaderboard with ID '\(leaderboardID)' not found or failed to load. Please double-check the ID in App Store Connect.")
                // 在实际应用中，您可能想在这里更新UI，提示排行榜加载失败
                return
            }

            print("Game Center: Successfully loaded leaderboard metadata for '\(specificLeaderboard.title ?? leaderboardID)'.")

            // 2. 加载排行榜的条目 (entries)
            // loadEntries 是一个实例方法
            // 它返回一个元组，根据编译器错误，其结构为: (GKLeaderboard.Entry?, [GKLeaderboard.Entry], Int)
            // 对应于 (localPlayerEntry, entries, totalPlayerCount)
            
            // 设置要加载的条目范围，例如前50名
            let fetchRange = NSRange(location: 1, length: 50) 
            
            let loadResult = try await specificLeaderboard.loadEntries(
                for: .global,       // 获取全局排行榜
                timeScope: .allTime, // 获取所有时间的成绩
                range: fetchRange    // 指定加载范围
            )

            // 通过索引访问元组的元素
            // loadResult.0 对应 localPlayerEntry: GKLeaderboard.Entry?
            // loadResult.1 对应 entries: [GKLeaderboard.Entry]? (注意：API可能返回[GKLeaderboard.Entry]或[GKLeaderboard.Entry]?)
            // loadResult.2 对应 totalPlayerCount: Int
            
            // 确保类型匹配，GKLeaderboard.loadEntries 返回的 entries 是 [GKLeaderboard.Entry] (非可选数组，但数组本身可能为空)
            // 而元组的第二个元素根据错误提示是 [GKLeaderboard.Entry]
            // 但为了安全，我们还是用可选绑定，因为API有时返回的是可选数组
            let fetchedEntriesArray: [GKLeaderboard.Entry] = loadResult.1 // 根据错误提示，这里应该是 [GKLeaderboard.Entry]
                                                                      // 如果 loadResult.1 本身是可选的 ([GKLeaderboard.Entry]?)，则需要可选绑定
                                                                      // 但错误提示是 '(GKLeaderboard.Entry?, [GKLeaderboard.Entry], Int)'，表明第二个元素是非可选数组

            // let localPlayerSpecificEntry: GKLeaderboard.Entry? = loadResult.0 
            // let totalPlayers: Int = loadResult.2

            if !fetchedEntriesArray.isEmpty { // 直接检查数组是否为空
                print("Game Center: Successfully fetched \(fetchedEntriesArray.count) entries for leaderboard '\(leaderboardID)':")
                for entry in fetchedEntriesArray {
                    print("  Rank: \(entry.rank), Player: \(entry.player.displayName), Score: \(entry.formattedScore) (Raw: \(entry.score)), Date: \(entry.date)")
                    // 如果需要，可以进一步获取 entry.player.alias, entry.player.gamePlayerID 等
                }
                // 在实际应用中，您会在这里用这些 'entries' 更新您的UI
            } else {
                print("Game Center: No entries found for leaderboard '\(leaderboardID)'. The leaderboard might be empty or data is still syncing.")
                // 在实际应用中，您会在这里更新UI，提示没有数据
            }

        } catch {
            print("Game Center: Error fetching scores for leaderboard '\(leaderboardID)': \(error.localizedDescription)")
            // 在实际应用中，您可能想在这里更新UI，提示加载错误
        }
    }
}

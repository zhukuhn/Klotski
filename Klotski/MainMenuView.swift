//
//  Untitled.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//
import SwiftUI

// MARK: - MainMenuView
struct MainMenuView: View {
    // MARK: Environment Objects
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: State Variables
    @State private var showingLoginSheet = false    // 控制登录表单是否显示
    @State private var showingRegisterSheet = false // 控制注册表单是否显示

    // MARK: Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) { // 主垂直堆栈，用于排列菜单项
                // 游戏标题
                Text(settingsManager.localizedString(forKey: "gameTitle"))
                   .font(.system(size: 36, weight: .bold, design: .rounded))
                   .padding(.top, 40) // 顶部留白
                   .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用主题颜色
                
                // 调试信息：显示 hasSavedGame 状态
                // Text("调试信息: hasSavedGame = \(gameManager.hasSavedGame.description)")
                //     .font(.caption)
                //     .foregroundColor(.gray)
                //     .padding(.top, 5)

                Spacer() // 弹性空间，将按钮推向中心

                // "开始游戏" 按钮
                Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    if let firstLevel = gameManager.levels.first {
                        gameManager.clearSavedGame()
                        gameManager.startGame(level: firstLevel, settings: settingsManager, isNewSession: true)
                    } else {
                        print("错误：关卡列表为空，无法开始游戏！")
                    }
                }) {
                    MenuButton(title: settingsManager.localizedString(forKey: "startGame"))
                }

                // "继续游戏" 按钮
                if gameManager.hasSavedGame {
                    Button(action: {
                        SoundManager.playImpactHaptic(settings: settingsManager)
                        gameManager.continueGame(settings: settingsManager)
                    }) {
                        MenuButton(title: settingsManager.localizedString(forKey: "continueGame"))
                    }
                }
                
                // "选择关卡" 导航链接
                NavigationLink(destination: LevelSelectionView()) {
                     MenuButton(title: settingsManager.localizedString(forKey: "selectLevel"))
                }
                .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })

                // "主题" 导航链接
                NavigationLink(destination: ThemeSelectionView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "themes"))
                }
                .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })

                // "排行榜" 导航链接
                NavigationLink(destination: LeaderboardView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "leaderboard"))
                }
                .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })

                // "设置" 导航链接
                NavigationLink(destination: SettingsView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "settings"))
                }
                .simultaneousGesture(TapGesture().onEnded { SoundManager.playImpactHaptic(settings: settingsManager) })
                
                Spacer() 

                // 认证状态视图 (登录/注册/注销按钮)
                //authStatusView().padding(.bottom)

            }
           .frame(maxWidth: .infinity, maxHeight: .infinity) 
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea()) 
//           .sheet(isPresented: $showingLoginSheet) { LoginView() }
//           .sheet(isPresented: $showingRegisterSheet) { RegisterView() }
           .navigationDestination(isPresented: $gameManager.isGameActive) { GameView() }
//           .onAppear {
//               print("MainMenuView onAppear: gameManager.hasSavedGame = \(gameManager.hasSavedGame)")
//               print("MainMenuView onAppear: authManager.isLoggedIn = \(authManager.isLoggedIn), isLoading = \(authManager.isLoading)")
//           }
        }
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
    }
    
//    @ViewBuilder
//    private func authStatusView() -> some View {
//        VStack {
//            if authManager.isLoading && !authManager.isLoggedIn { // 正在加载认证状态且尚未登录
//                ProgressView()
//                    .padding(.bottom, 10)
//            } else if authManager.isLoggedIn, let user = authManager.currentUser {
//                Text("\(settingsManager.localizedString(forKey: "loggedInAs")) \(user.displayName ?? user.email ?? "User")")
//                   .font(.caption)
//                   .foregroundColor(themeManager.currentTheme.sliderColor.color)
//                   .padding(.bottom, 5)
//                Button(settingsManager.localizedString(forKey: "logout")) {
//                    SoundManager.playImpactHaptic(settings: settingsManager)
//                    //authManager.logout()
//                }
//               .buttonStyle(.bordered) 
//               .tint(themeManager.currentTheme.sliderColor.color)
//            } else {
//                HStack(spacing: 15) {
//                    Button(settingsManager.localizedString(forKey: "login")) {
//                        SoundManager.playImpactHaptic(settings: settingsManager)
//                        showingLoginSheet = true 
//                    }
//                   .buttonStyle(.borderedProminent) 
//                   .tint(themeManager.currentTheme.sliderColor.color)
//                    
//                    Button(settingsManager.localizedString(forKey: "register")) {
//                        SoundManager.playImpactHaptic(settings: settingsManager)
//                        showingRegisterSheet = true 
//                    }
//                   .buttonStyle(.bordered) 
//                   .tint(themeManager.currentTheme.sliderColor.color)
//                }
//            }
//        }
//    }
}

// MARK: 菜单按钮
// Reusable MenuButton Style for consistency (used in VictoryOverlay too)
struct MenuButtonStyle: ButtonStyle {
    @ObservedObject var themeManager: ThemeManager // Use ObservedObject if passed directly

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
            .fontWeight(.medium)
            .padding()
            .frame(maxWidth: 280, minHeight: 50)
            .background(themeManager.currentTheme.sliderColor.color.opacity(configuration.isPressed ? 0.7 : 0.9))
            .foregroundColor(themeManager.currentTheme.backgroundColor.color)
            .cornerRadius(12)
            .shadow(color: themeManager.currentTheme.sliderColor.color.opacity(0.3), radius: configuration.isPressed ? 3 : 5, x: 0, y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
struct MenuButton: View { // MenuButton now uses the reusable style
    let title: String
    @EnvironmentObject var themeManager: ThemeManager // Keep this for easy use in MainMenu

    var body: some View {
        Text(title) // The style is applied by the ButtonStyle
           .modifier(MenuButtonViewModifier(themeManager: themeManager)) // Apply common styling here
    }
}
// Modifier for MenuButton content if not using ButtonStyle directly on Text
struct MenuButtonViewModifier: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    func body(content: Content) -> some View {
        content
            .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
            .fontWeight(.medium)
            .padding()
            .frame(maxWidth: 280, minHeight: 50)
            .background(themeManager.currentTheme.sliderColor.color.opacity(0.9))
            .foregroundColor(themeManager.currentTheme.backgroundColor.color)
            .cornerRadius(12)
            .shadow(color: themeManager.currentTheme.sliderColor.color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// MARK: 关卡选择视图
struct LevelSelectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var isPresentedAsPanel: Bool = false // 标记是否作为面板显示
    var dismissPanelAction: (() -> Void)? = nil // 关闭面板的回调
    var onLevelSelected: (() -> Void)? = nil // 

    var body: some View {
        // 根据是否作为面板显示，决定是否包裹 NavigationView
        Group {
            if isPresentedAsPanel {
                NavigationView { levelListContent }
                .navigationViewStyle(.stack) // 确保在面板模式下有正确的导航栏行为
            } else {
                levelListContent // 直接显示列表内容（例如从主菜单通过 NavigationLink 进入时）
            }
        }
    }

    var levelListContent: some View {
        List {
            ForEach(gameManager.levels.filter { $0.isUnlocked }) { level in
                Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    gameManager.clearSavedGame() // 开始新选择的关卡前清除旧存档
                    gameManager.startGame(level: level, settings: settingsManager, isNewSession: true)
                    dismissPanelAction?() // 如果是面板，则关闭面板
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
       .navigationBarTitleDisplayMode(isPresentedAsPanel ? .inline : .automatic) // 面板模式下使用 inline
       .toolbar {
           if isPresentedAsPanel { // 仅在面板模式下显示关闭按钮
               ToolbarItem(placement: .navigationBarTrailing) { // 或者 .navigationBarLeading
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
    // Inject AuthManager to pass to themeManager.themePurchased or themeManager.themesRestored
    @EnvironmentObject var authManager: AuthManager


    var body: some View {
        List {
            Section(header: Text(settingsManager.localizedString(forKey: "themeStore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                
                ForEach(themeManager.themes) { theme in
                    // Call the new helper function for the row content
                    themeRow(for: theme)
                       .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
            
            Section {
                 Button(settingsManager.localizedString(forKey: "restorePurchases")) {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    // In a real app, this would trigger StoreKit's restoreCompletedTransactions
                    // For now, it calls a simulated method in ThemeManager
                    // themeManager.restorePurchases() // Old simulated method
                    // With StoreKit, you'd have an IAPManager or similar to call:
                    // iapManager.restorePurchases { restoredIDs in
                    //    themeManager.themesRestored(restoredThemeIDs: restoredIDs, authManager: authManager)
                    // }
                    print("恢复购买按钮被点击 (功能待StoreKit集成)")
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
               .foregroundColor(themeManager.currentTheme.sliderColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "themes"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
       .preferredColorScheme(themeManager.currentTheme.swiftUIScheme) 
    }

    // Helper function to build each theme row, reducing complexity in the ForEach
    @ViewBuilder
    private func themeRow(for theme: Theme) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                
                HStack {
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
            } else if themeManager.isThemePurchased(theme) {
                Button(settingsManager.localizedString(forKey: "applyTheme")) {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    themeManager.setCurrentTheme(theme)
                }
               .buttonStyle(.bordered)
               .tint(themeManager.currentTheme.sliderColor.color)
            } else {
                Button {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    // In a real app, this would trigger StoreKit's purchase flow
                    // For now, it calls a simulated method in ThemeManager
                    // themeManager.purchaseTheme(theme) // Old simulated method
                    // With StoreKit, you'd have an IAPManager or similar to call:
                    // iapManager.purchase(productID: theme.id) { success, purchasedID in
                    //    if success, let id = purchasedID {
                    //        themeManager.themePurchased(themeID: id, authManager: authManager)
                    //    }
                    // }
                    themeManager.themeDidGetPurchased(themeID: theme.id, authManager: authManager)
                    print("购买主题 '\(theme.name)' 按钮被点击 (功能待StoreKit集成)")
                    // Simulate purchase for testing UI, if needed, directly calling themePurchased
                    // themeManager.themePurchased(themeID: theme.id, authManager: authManager) // Uncomment for UI testing of purchase flow
                } label: {
                    Text("\(settingsManager.localizedString(forKey: "purchase")) \(theme.price != nil ? String(format: "¥%.2f", theme.price!) : "")")
                }
               .buttonStyle(.borderedProminent)
               .tint(theme.isPremium ? .pink : themeManager.currentTheme.sliderColor.color) 
            }
        }
       .padding(.vertical, 8) // Apply padding to the HStack content
    }
}

// MARK: 排行榜视图
struct LeaderboardView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager // To get level names for picker
    // TODO: Inject Game Center manager or data source

    // Sample data, replace with actual Game Center data
    @State private var leaderboardData: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, playerName: "高手玩家", moves: 25, levelID: "easy-1"),
        LeaderboardEntry(rank: 2, playerName: "新手上路", moves: 30, levelID: "easy-1"),
        LeaderboardEntry(rank: 1, playerName: "解谜大师", moves: 120, levelID: "medium-1"),
    ]
    @State private var selectedLevelFilter: String = "all" // "all" or a levelID

    var body: some View {
        VStack {
            // TODO: Implement actual Game Center leaderboard view
            // (e.g., using GKGameCenterViewController as a sheet)
            // Or a custom UI that fetches data from Game Center.
            
            Picker(settingsManager.localizedString(forKey: "selectLevel"), selection: $selectedLevelFilter) {
                Text("所有关卡").tag("all")
                ForEach(gameManager.levels) { level in
                    Text(level.name).tag(level.id)
                }
            }
           .pickerStyle(.segmented) // Or .menu for more items
           .padding()
           .tint(themeManager.currentTheme.sliderColor.color)


            List {
                ForEach(filteredLeaderboardData()) { entry in
                    HStack {
                        Text("\(entry.rank).")
                           .fontWeight(.bold)
                        Text(entry.playerName)
                        Spacer()
                        Text("\(entry.moves) \(settingsManager.localizedString(forKey: "moves"))")
                           .fontWeight(.semibold)
                    }
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .body)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
                if filteredLeaderboardData().isEmpty {
                    Text("此关卡暂无排行数据。")
                        .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                        .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
           .scrollContentBackground(.hidden)
            
            Text("排行榜功能待 Game Center 集成")
               .font(.caption)
               .padding()
               .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
        }
       .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
    }

    func filteredLeaderboardData() -> [LeaderboardEntry] {
        if selectedLevelFilter == "all" {
            return leaderboardData.sorted { $0.moves < $1.moves } // Example sorting
        }
        return leaderboardData.filter { $0.levelID == selectedLevelFilter }.sorted { $0.moves < $1.moves }
    }
}

// MARK: 设置视图
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager // For reset progress

    @State private var showingResetAlert = false

    var body: some View {
        Form { // Form provides a standard iOS settings look
            Section(header: Text("通用设置")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Picker(settingsManager.localizedString(forKey: "language"), selection: $settingsManager.language) {
                    Text(settingsManager.localizedString(forKey: "chinese")).tag("zh")
                    Text(settingsManager.localizedString(forKey: "english")).tag("en")
                }.onChange(of: settingsManager.language) { _, _ in SoundManager.playImpactHaptic(settings: settingsManager) }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5)) // Slightly different for Form
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
           .tint(themeManager.currentTheme.sliderColor.color) // Tint for Toggles

            Section(header: Text("游戏数据")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Button(settingsManager.localizedString(forKey: "resetProgress"), role: .destructive) {
                    showingResetAlert = true
                    SoundManager.playHapticNotification(type: .warning, settings: settingsManager)
                }
               .foregroundColor(.red) // Standard destructive color
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
            
            // TODO: Add links to Privacy Policy, About, etc.
            // Section("About") { Link("Privacy Policy", destination: URL(string: "...")!) }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "settings"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea()) // Background for the whole view
       .scrollContentBackground(.hidden) // Makes Form background transparent
       .alert(settingsManager.localizedString(forKey: "resetProgress"), isPresented: $showingResetAlert) {
            Button(settingsManager.localizedString(forKey: "reset"), role: .destructive) {
                // Reset best scores in levels
                gameManager.levels.indices.forEach { gameManager.levels[$0].bestMoves = nil; gameManager.levels[$0].bestTime = nil }
                // Clear any currently saved game progress
                gameManager.clearSavedGame()
                // TODO: Potentially reset other game-specific stats if any
                print("游戏进度已重置")
                SoundManager.playHapticNotification(type: .success, settings: settingsManager)
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {}
        } message: {Text(settingsManager.localizedString(forKey: "areYouSureReset"))
        }
    }
}

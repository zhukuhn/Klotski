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
    // @State private var showingLoginSheet = false    // 控制登录表单是否显示 (Currently unused due to iCloud focus)
    // @State private var showingRegisterSheet = false // 控制注册表单是否显示 (Currently unused)

    // MARK: Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) { // 主垂直堆栈，用于排列菜单项
                // 游戏标题
                Text(settingsManager.localizedString(forKey: "gameTitle"))
                   .font(.system(size: 36, weight: .bold, design: .rounded))
                   .padding(.top, 40) // 顶部留白
                   .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用主题颜色
                
                //Spacer() // 弹性空间，将按钮推向中心

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

                // Auth Status Display (Simplified for iCloud)
                authStatusFooter().padding(.bottom)

            }
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           // .sheet(isPresented: $showingLoginSheet) { LoginView() } // Not used
           // .sheet(isPresented: $showingRegisterSheet) { RegisterView() } // Not used
           .navigationDestination(isPresented: $gameManager.isGameActive) { GameView() }
           .onAppear {
                if settingsManager.useiCloudLogin {
                    // authManager.refreshAuthenticationState()
                }
                print("MainMenuView onAppear: useiCloudLogin = \(settingsManager.useiCloudLogin), isLoggedIn = \(authManager.isLoggedIn)")
           }
        }
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
    }
    
    @ViewBuilder
    private func authStatusFooter() -> some View {
        VStack {
            if settingsManager.useiCloudLogin {
                if authManager.isLoading {
                    ProgressView()
                       .padding(.bottom, 5)
                    Text(settingsManager.localizedString(forKey: "iCloudCheckingStatus")) // "正在检查iCloud状态..."
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                } else if authManager.isLoggedIn, let user = authManager.currentUser {
                    Text("\(settingsManager.localizedString(forKey: "loggedInAs")) \(user.displayName ?? settingsManager.localizedString(forKey: "iCloudUser"))")
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color)
                       .padding(.bottom, 5)
                } else if authManager.iCloudAccountStatus == .noAccount {
                     Text(settingsManager.localizedString(forKey: "iCloudNoAccountDetailed")) // "未登录iCloud账户。请前往设备设置登录以使用云功能。"
                       .font(.caption)
                       .foregroundColor(.orange)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)
                } else if authManager.iCloudAccountStatus != .available && authManager.errorMessage != nil {
                     // Use specific localized messages from AuthManager if available, or a generic one
                    Text(authManager.errorMessage ?? settingsManager.localizedString(forKey: "iCloudConnectionError"))
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if authManager.iCloudAccountStatus == .available && !authManager.isLoggedIn && !authManager.isLoading { // Added !authManager.isLoading
                     Text(settingsManager.localizedString(forKey: "iCloudSyncError")) // "iCloud可用，但应用未能同步用户数据。"
                       .font(.caption)
                       .foregroundColor(.orange)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)
                } else if !authManager.isLoggedIn && !authManager.isLoading { // Generic message if not loading and not logged in
                    Text(settingsManager.localizedString(forKey: "iCloudLoginPrompt")) // "iCloud功能需要登录。请检查设置。"
                       .font(.caption)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                }
            } else {
                Text(settingsManager.localizedString(forKey: "iCloudDisabledInSettings")) // "iCloud登录已禁用。云同步功能不可用。"
                   .font(.caption)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                   .multilineTextAlignment(.center)
                   .padding(.horizontal)
            }
        }
        .frame(minHeight: 50)
    }
}

// MARK: 菜单按钮
struct MenuButtonStyle: ButtonStyle {
    @ObservedObject var themeManager: ThemeManager

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
struct MenuButton: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text(title)
           .modifier(MenuButtonViewModifier(themeManager: themeManager))
    }
}
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
                 Button(settingsManager.localizedString(forKey: "restorePurchases")) {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    if settingsManager.useiCloudLogin && authManager.isLoggedIn {
                        // Placeholder for actual StoreKit restore call
                        // For now, simulate by calling themesDidGetRestored with an empty set or known test IDs
                        // let testRestoredIDs: Set<String> = ["forest", "ocean"] // Example
                        themeManager.themesDidGetRestored(restoredThemeIDsFromStoreKit: [], authManager: authManager)
                        print("恢复购买按钮被点击 (功能待StoreKit集成)")
                    } else {
                        print("恢复购买需要iCloud登录。")
                    }
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
               .foregroundColor(settingsManager.useiCloudLogin && authManager.isLoggedIn ? themeManager.currentTheme.sliderColor.color : .gray)
               .disabled(!settingsManager.useiCloudLogin || !authManager.isLoggedIn) // Corrected: disable if not using iCloud OR not logged in
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "themes"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
       .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
       .onAppear {
           print("ThemeSelectionView onAppear: useiCloudLogin = \(settingsManager.useiCloudLogin)")
       }
    }

    @ViewBuilder
    private func themeRow(for theme: Theme) -> some View {
        VStack(alignment: .leading) {
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
                } else {
                    let isConsideredPurchased = themeManager.isThemePurchased(theme)

                    if isConsideredPurchased {
                        // Theme is free, or it's paid and considered purchased (either via local cache or iCloud sync)
                        // To apply a paid theme, iCloud login must be enabled (even if known locally)
                        let canApplyThisTheme = !theme.isPremium || settingsManager.useiCloudLogin
                        Button(settingsManager.localizedString(forKey: "applyTheme")) {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            themeManager.setCurrentTheme(theme)
                        }
                       .buttonStyle(.bordered)
                       .tint(themeManager.currentTheme.sliderColor.color)
                       .disabled(!canApplyThisTheme)
                    } else { // Theme is premium and NOT considered purchased
                        Button {
                            SoundManager.playImpactHaptic(settings: settingsManager)
                            themeManager.themeDidGetPurchased(themeID: theme.id, authManager: authManager)
                            print("购买主题 '\(theme.name)' 按钮被点击 (功能待StoreKit集成)")
                        } label: {
                            Text("\(settingsManager.localizedString(forKey: "purchase")) \(theme.price != nil ? String(format: "¥%.2f", theme.price!) : "")")
                        }
                       .buttonStyle(.borderedProminent)
                       .tint(theme.isPremium ? .pink : themeManager.currentTheme.sliderColor.color)
                       .disabled(!settingsManager.useiCloudLogin) // Can only purchase if iCloud login is enabled
                    }
                }
            }
            
            if theme.isPremium {
                if !themeManager.isThemePurchased(theme) && !settingsManager.useiCloudLogin {
                    Text(settingsManager.localizedString(forKey: "purchaseRequiresiCloud"))
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                } else if themeManager.isThemePurchased(theme) && !settingsManager.useiCloudLogin && themeManager.currentTheme.id != theme.id {
                    Text(settingsManager.localizedString(forKey: "applyPaidThemeRequiresiCloud"))
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
struct LeaderboardView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager

    @State private var leaderboardData: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, playerName: "高手玩家", moves: 25, levelID: "classic_hdml"),
        LeaderboardEntry(rank: 2, playerName: "新手上路", moves: 30, levelID: "classic_hdml"),
        LeaderboardEntry(rank: 1, playerName: "解谜大师", moves: 120, levelID: "easy_exit"),
    ]
    @State private var selectedLevelFilter: String = "all"

    var body: some View {
        VStack {
            if !settingsManager.useiCloudLogin { // Simplified check: just if the setting is off
                Spacer()
                Image(systemName: "lock.icloud.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                    .padding(.bottom)
                Text(settingsManager.localizedString(forKey: "leaderboardRequiresiCloud"))
                   .font(.headline)
                   .multilineTextAlignment(.center)
                   .padding()
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))
                Spacer()
            } else {
                Picker(settingsManager.localizedString(forKey: "selectLevel"), selection: $selectedLevelFilter) {
                    Text("所有关卡").tag("all")
                    ForEach(gameManager.levels.filter{$0.isUnlocked}) { level in
                        Text(level.name).tag(level.id)
                    }
                }
               .pickerStyle(.segmented)
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
                
                Text("排行榜功能待 Game Center 集成。提交记录功能将受iCloud登录状态限制。")
                   .font(.caption)
                   .padding()
                   .multilineTextAlignment(.center)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
    }

    func filteredLeaderboardData() -> [LeaderboardEntry] {
        if selectedLevelFilter == "all" {
            return leaderboardData.sorted { $0.moves < $1.moves }
        }
        return leaderboardData.filter { $0.levelID == selectedLevelFilter }.sorted { $0.moves < $1.moves }
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
//            Button(settingsManager.localizedString(forKey: "openSettings")) {
//                if let url = URL(string: UIApplication.openSettingsURLString) {
//                    openURL(url)
//                }
//            }
            Button(settingsManager.localizedString(forKey: "confirm"), role: .cancel) {}
        } message: {
            Text(settingsManager.localizedString(forKey: "iCloudEnableInstructionMessage"))
        }
    }
}

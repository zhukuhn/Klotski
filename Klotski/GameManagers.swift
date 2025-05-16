//
//  GameManeger.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI

class GameManager: ObservableObject {
    @Published var currentLevel: Level?
    @Published var levels: [Level] = [ // Sample levels
        Level(id: "easy-1", name: "入门第一关", layout: [[1,1,2,0],[1,1,3,0],[4,5,0,0]], bestMoves: nil, bestTime: nil, isUnlocked: true),
        Level(id: "easy-2", name: "入门第二关", layout: [[1,2,2,0],[1,3,3,0],[4,5,0,0]], bestMoves: nil, bestTime: nil, isUnlocked: true),
        Level(id: "medium-1", name: "中等第一关", layout: [[1,1,2,3],[1,1,4,5],[6,7,0,8],[9,10,11,12],[13,14,15,0]], isUnlocked: true)
        // TODO: Add more diverse and representative Klotski layouts, especially for a 4x5 board.
        // The layouts above are just placeholders. A typical Klotski (Huarong Dao) has specific piece sizes.
        // e.g., CaoCao (2x2), GuanYu (2x1 horizontal), ZhangFei/MaChao/ZhaoYun/HuangZhong (1x2 vertical), Soldiers (1x1).
        // The [[Int]] layout would need a mapping from these Ints to piece types/dimensions for rendering.
    ]
    @Published var moves: Int = 0
    @Published var timeElapsed: TimeInterval = 0
    @Published var isGameActive: Bool = false
    @Published var hasSavedGame: Bool = false

    init() {
        // Check if a game was previously saved
        if UserDefaults.standard.string(forKey: "savedLevelID") != nil {
            hasSavedGame = true
        }
    }

    func startGame(level: Level) {
        currentLevel = level
        moves = 0
        timeElapsed = 0
        isGameActive = true // This will trigger navigation if GameView is observing it
        // TODO: Initialize game board based on level.layout
        print("游戏开始: \(level.name)")
        // After starting, this becomes the new "saved game" implicitly until cleared or level completed
        saveGame() // Save immediately when a new game starts or a level is selected
        hasSavedGame = true
    }

    func continueGame() {
        if let savedLevelID = UserDefaults.standard.string(forKey: "savedLevelID") {
             if let levelToContinue = levels.first(where: { $0.id == savedLevelID }) {
                 // TODO: Load actual saved board configuration from UserDefaults or a file
                 currentLevel = levelToContinue
                 moves = UserDefaults.standard.integer(forKey: "savedMoves")
                 timeElapsed = UserDefaults.standard.double(forKey: "savedTime")
                 isGameActive = true // This will trigger navigation
                 print("继续游戏: \(levelToContinue.name)")
                 return
             }
        }
        // Fallback if no valid saved game found, clear flag and potentially start a new game
        print("未找到有效存档，或存档已损坏。")
        clearSavedGame() // Clear potentially corrupted save data
        // Optionally, start the first level or do nothing, letting the user choose.
        // if let firstLevel = levels.first { startGame(level: firstLevel) }
    }

    func saveGame() {
        guard let currentLevel = currentLevel, isGameActive else { return }
        UserDefaults.standard.set(currentLevel.id, forKey: "savedLevelID")
        UserDefaults.standard.set(moves, forKey: "savedMoves")
        UserDefaults.standard.set(timeElapsed, forKey: "savedTime")
        // TODO: Save current board configuration (e.g., serialize the state of the game board)
        hasSavedGame = true // Ensure this is set
        print("游戏已保存: \(currentLevel.name), 步数: \(moves)")
    }
    
    func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: "savedLevelID")
        UserDefaults.standard.removeObject(forKey: "savedMoves")
        UserDefaults.standard.removeObject(forKey: "savedTime")
        // TODO: Clear saved board configuration
        hasSavedGame = false
        print("已清除已保存的游戏")
    }

    func completeLevel(moves: Int, time: TimeInterval) {
        print("关卡 \(currentLevel?.name ?? "N/A") 完成！步数: \(moves), 时间: \(String(format: "%.2f", time))s")
        // TODO: Update level stats (bestMoves, bestTime) in the `levels` array and persist them.
        // TODO: Submit to Game Center leaderboard.
        
        // Clear the saved game for this completed level
        clearSavedGame()
        isGameActive = false // This will allow programmatic dismissal of GameView
    }

    func moveBlock() {
        // TODO: Implement block moving logic on the game board.
        // This involves:
        // 1. Identifying the selected block.
        // 2. Determining valid move directions.
        // 3. Updating the block's position in the internal game board representation.
        // 4. Checking for win condition.
        moves += 1
    }
}

class ThemeManager: ObservableObject {
    @Published var themes: [Theme] = [
        Theme(id: "default", name: "默认浅色", isPremium: false, backgroundColor: CodableColor(color: .white), sliderColor: CodableColor(color: .blue), fontName: nil, colorScheme: .light),
        Theme(id: "dark", name: "深邃夜空", isPremium: false, backgroundColor: CodableColor(color: .black), sliderColor: CodableColor(color: .orange), fontName: nil, colorScheme: .dark),
        Theme(id: "forest", name: "森林绿意", isPremium: true, price: 6.00,
              backgroundColor: CodableColor(color: Color(hex: "A1C181")),
              sliderColor: CodableColor(color: Color(hex: "679436")),
              fontName: "Georgia", colorScheme: .light),
        Theme(id: "ocean", name: "蔚蓝海洋", isPremium: true, price: 6.00,
              backgroundColor: CodableColor(color: Color(red: 86/255, green: 207/255, blue: 225/255)),
              sliderColor: CodableColor(color: Color(red: 78/255, green: 168/255, blue: 222/255)),
              fontName: "HelveticaNeue-Light", colorScheme: .light)
    ]
    @Published var currentTheme: Theme
    @Published var purchasedThemeIDs: Set<String> = ["default", "dark"] // User initially owns free themes

    init() {
        // `themes` 和 `purchasedThemeIDs` 属性已通过其声明进行了初始化。
        // 现在需要初始化 `currentTheme`。

        // 步骤 1: 为 `currentTheme` 提供一个明确的初始值。
        // 我们直接使用“默认浅色”主题的定义来初始化 currentTheme。
        // 这确保了在 self 完全初始化之前，currentTheme 就被赋值，
        // 并且这个赋值不依赖于通过 `self` 访问 `themes` 数组。
        let initialDefaultTheme = Theme(id: "default", name: "默认浅色", isPremium: false,
                                        backgroundColor: CodableColor(color: .white),
                                        sliderColor: CodableColor(color: .blue), fontName: nil, colorScheme: .light)
        self.currentTheme = initialDefaultTheme // 至此，所有存储属性都已初始化。

        // 步骤 2: 现在 `self` 已经完全初始化，可以安全地访问 `self.themes` (或简写为 `themes`)
        // 来加载用户偏好设置并更新 `currentTheme`。
        let savedThemeID = UserDefaults.standard.string(forKey: "currentThemeID") ?? "default" // 使用 "default" 作为备用ID

        // 尝试从 `self.themes` 数组中找到保存的主题。
        // 如果找到，则更新 `self.currentTheme`。否则，它将保持为 `initialDefaultTheme`。
        if let themeFromUserDefaults = self.themes.first(where: { $0.id == savedThemeID }) {
            self.currentTheme = themeFromUserDefaults
        }
        // 如果 `savedThemeID` 是 "default"，并且它与 `initialDefaultTheme` 相同，则不会发生变化。
        // 如果 `savedThemeID` 是 `themes` 中存在的其他ID，则 `currentTheme` 会被更新。
        // 如果 `savedThemeID` 在 `themes` 中不存在，则 `currentTheme` 保持为 `initialDefaultTheme`。
        loadPurchasedThemes()
    }

    func setCurrentTheme(_ theme: Theme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: "currentThemeID")
        print("主题已更改为: \(theme.name)")
    }

    func purchaseTheme(_ theme: Theme) {
        // TODO: Implement IAP logic with StoreKit. This is a placeholder.
        // In a real app, this would involve calls to StoreKit to process the purchase.
        print("模拟购买主题: \(theme.name)")
        // If purchase is successful (simulated):
        if theme.isPremium {
            purchasedThemeIDs.insert(theme.id)
            savePurchasedThemes()
            print("主题 \(theme.name) 已购买 (模拟)")
        }
    }
    
    func restorePurchases() {
        // TODO: Implement IAP restore logic using StoreKit.
        print("正在恢复已购买项目... (模拟)")
        // Example: Simulate finding a previously purchased premium theme.
        // self.purchasedThemeIDs.insert("forest")
        // self.purchasedThemeIDs.insert("ocean")
        // savePurchasedThemes()
        // print("已恢复购买项目 (模拟)")
    }

    private func savePurchasedThemes() {
        let idsArray = Array(purchasedThemeIDs)
        UserDefaults.standard.set(idsArray, forKey: "purchasedThemeIDs")
    }

    private func loadPurchasedThemes() {
        if let idsArray = UserDefaults.standard.array(forKey: "purchasedThemeIDs") as? [String] {
            self.purchasedThemeIDs = Set(idsArray)
        }
    }

    func isThemePurchased(_ theme: Theme) -> Bool {
        return !theme.isPremium || purchasedThemeIDs.contains(theme.id)
    }
}

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoggedIn: Bool = false

    init() {
        // TODO: Check for saved login state (e.g., Keychain for tokens, UserDefaults for user profile data)
        // For now, simulate logged out state.
        // Example of loading a saved user:
        // if let userData = UserDefaults.standard.data(forKey: "currentUserProfile"),
        //    let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
        //     self.currentUser = user
        //     self.isLoggedIn = true
        //     // Also load purchased themes associated with this user if stored server-side
        // }
    }

    func login(email: String, pass: String) {
        // TODO: Implement actual login logic (e.g., Firebase, custom backend API call)
        print("尝试登录: \(email)")
        // Simulate successful login for demonstration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Simulate network delay
            self.currentUser = UserProfile(uid: "demo-uid-\(UUID().uuidString)", displayName: "测试用户", email: email, purchasedThemeIDs: ["default", "dark"]) // Initialize with default themes
            self.isLoggedIn = true
            // self.saveCurrentUserProfile() // Persist user profile
            print("登录成功")
        }
    }

    func register(email: String, pass: String, displayName: String) {
        // TODO: Implement actual registration logic
        print("尝试注册: \(email)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentUser = UserProfile(uid: "new-uid-\(UUID().uuidString)", displayName: displayName, email: email, purchasedThemeIDs: ["default", "dark"])
            self.isLoggedIn = true
            // self.saveCurrentUserProfile()
            print("注册成功")
        }
    }
    
    func signInWithApple() {
        // TODO: Implement Sign in with Apple using AuthenticationServices framework.
        // This involves handling ASAuthorizationControllerDelegate methods.
        print("尝试通过Apple登录...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentUser = UserProfile(uid: "apple-uid-\(UUID().uuidString)", displayName: "Apple 用户", email: "apple.user@example.com", purchasedThemeIDs: ["default", "dark"])
            self.isLoggedIn = true
            // self.saveCurrentUserProfile()
            print("通过Apple登录成功 (模拟)")
        }
    }

    func logout() {
        // TODO: Clear session, tokens from Keychain, etc.
        currentUser = nil
        isLoggedIn = false
        // UserDefaults.standard.removeObject(forKey: "currentUserProfile")
        print("已注销")
    }

    // private func saveCurrentUserProfile() {
    //     if let user = currentUser, let userData = try? JSONEncoder().encode(user) {
    //         UserDefaults.standard.set(userData, forKey: "currentUserProfile")
    //     }
    // }
}

class SettingsManager: ObservableObject {
    // Using @AppStorage for persistence of simple settings
    @AppStorage("selectedLanguage") var language: String = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "en" // Default to system's preferred language or English
    @AppStorage("isSoundEffectsEnabled") var soundEffectsEnabled: Bool = true
    @AppStorage("isMusicEnabled") var musicEnabled: Bool = true
    @AppStorage("isHapticsEnabled") var hapticsEnabled: Bool = true
    // Add other settings as needed

    // Basic localization dictionary. For a real app, use .strings files and Bundle.main.localizedString.
    private let translations: [String: [String: String]] = [
        "en": [
            "gameTitle": "Klotski Challenge",
            "startGame": "Start Game",
            "continueGame": "Continue Game",
            "selectLevel": "Select Level",
            "themes": "Themes",
            "leaderboard": "Leaderboard",
            "settings": "Settings",
            "login": "Login",
            "register": "Register",
            "logout": "Logout",
            "loggedInAs": "Logged in as:",
            "email": "Email",
            "password": "Password",
            "displayName": "Display Name",
            "forgotPassword": "Forgot Password?",
            "signInWithApple": "Sign in with Apple",
            "cancel": "Cancel",
            "level": "Level",
            "moves": "Moves",
            "time": "Time",
            "noLevels": "No levels available.",
            "themeStore": "Theme Store",
            "applyTheme": "Apply",
            "purchase": "Purchase",
            "restorePurchases": "Restore Purchases",
            "language": "Language",
            "chinese": "简体中文 (Chinese)",
            "english": "English",
            "soundEffects": "Sound Effects",
            "music": "Music",
            "haptics": "Haptics",
            "resetProgress": "Reset Progress",
            "areYouSureReset": "Are you sure you want to reset all game progress? This cannot be undone.",
            "reset": "Reset",
        ],
        "zh": [
            "gameTitle": "华容道挑战",
            "startGame": "开始游戏",
            "continueGame": "继续游戏",
            "selectLevel": "选择关卡",
            "themes": "主题",
            "leaderboard": "排行榜",
            "settings": "设置",
            "login": "登录",
            "register": "注册",
            "logout": "注销",
            "loggedInAs": "已登录:",
            "email": "邮箱",
            "password": "密码",
            "displayName": "昵称",
            "forgotPassword": "忘记密码?",
            "signInWithApple": "通过Apple登录",
            "cancel": "取消",
            "level": "关卡",
            "moves": "步数",
            "time": "时间",
            "noLevels": "暂无可用关卡。",
            "themeStore": "主题商店",
            "applyTheme": "应用",
            "purchase": "购买",
            "restorePurchases": "恢复购买",
            "language": "语言",
            "chinese": "简体中文",
            "english": "English (英文)",
            "soundEffects": "音效",
            "music": "音乐",
            "haptics": "触感反馈",
            "resetProgress": "重置进度",
            "areYouSureReset": "您确定要重置所有游戏进度吗？此操作无法撤销。",
            "reset": "重置",
        ]
    ]

    func localizedString(forKey key: String) -> String {
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }
}

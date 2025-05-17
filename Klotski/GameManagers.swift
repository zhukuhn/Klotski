//
//  GameManeger.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI

class GameManager: ObservableObject {
    @Published var currentLevel: Level?
    @Published var pieces: [Piece] = [] // 当前关卡的棋子实例
    @Published var gameBoard: [[Int?]] = [] // 棋盘网格，存储占据该格子的棋子ID，nil表示空格。Int? 而非 Int 是因为 0 可能是一个有效的棋子ID
    
    static let classicLevel = Level(
        id: "classic_hdml", name: "横刀立马",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0),      // 曹操
            PiecePlacement(id: 2, type: .guanYuH, initialX: 1, initialY: 2),     // 关羽 (横)
            PiecePlacement(id: 3, type: .zhangFeiV, initialX: 0, initialY: 0),   // 张飞 (竖)
            PiecePlacement(id: 4, type: .zhaoYunV, initialX: 3, initialY: 0),    // 赵云 (竖)
            PiecePlacement(id: 5, type: .maChaoV, initialX: 0, initialY: 2),     // 马超 (竖)
            PiecePlacement(id: 6, type: .huangZhongV, initialX: 3, initialY: 2),  // 黄忠 (竖)
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3),     // 兵1
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),     // 兵2
            PiecePlacement(id: 9, type: .soldier, initialX: 0, initialY: 4),     // 兵3
            PiecePlacement(id: 10, type: .soldier, initialX: 3, initialY: 4)     // 兵4
        ],
        targetPieceId: 1, targetX: 1, targetY: 3, // 曹操的目标位置 (出口在下方中间)
        isUnlocked: true
    )

    @Published var levels: [Level] = [classicLevel] // 更多关卡可以后续添加

    @Published var moves: Int = 0
    @Published var timeElapsed: TimeInterval = 0
    @Published var isGameActive: Bool = false
    @Published var hasSavedGame: Bool = false
    @Published var isGameWon: Bool = false


    init() {
        if UserDefaults.standard.string(forKey: "savedLevelID") != nil {
            // TODO: 完善存档加载逻辑，目前仅设置标志
            // hasSavedGame = true
        }
    }

    func startGame(level: Level) {
        currentLevel = level
        moves = 0
        timeElapsed = 0
        isGameActive = true
        isGameWon = false
        
        // 1. 初始化棋子实例
        pieces = level.piecePlacements.map { placement in
            Piece(id: placement.id, type: placement.type, x: placement.initialX, y: placement.initialY)
        }

        // 2. 初始化棋盘网格
        gameBoard = Array(repeating: Array(repeating: nil, count: level.boardWidth), count: level.boardHeight)
        for piece in pieces {
            for r in 0..<piece.height {
                for c in 0..<piece.width {
                    let boardY = piece.y + r
                    let boardX = piece.x + c
                    if boardY < level.boardHeight && boardX < level.boardWidth {
                        gameBoard[boardY][boardX] = piece.id
                    } else {
                        // 棋子超出边界，这是一个关卡设计错误
                        print("错误：棋子 \(piece.id) 在初始布局时超出边界。")
                    }
                }
            }
        }
        
        print("游戏开始: \(level.name)")
        // saveGame() // 可以在开始时就保存，或首次移动后保存
        // hasSavedGame = true
    }

    // 尝试移动棋子 (由拖动手势结束时调用)
    // dx, dy 是格子单位的位移
    func attemptMove(pieceId: Int, dx: Int, dy: Int) {
        guard let level = currentLevel, var pieceToMove = pieces.first(where: { $0.id == pieceId }),
              (dx != 0 || dy != 0) else { // 如果没有位移，则不执行任何操作
            return
        }

        let originalX = pieceToMove.x
        let originalY = pieceToMove.y
        let newX = originalX + dx
        let newY = originalY + dy

        // 1. 边界检查
        guard newX >= 0, newX + pieceToMove.width <= level.boardWidth,
              newY >= 0, newY + pieceToMove.height <= level.boardHeight else {
            print("移动无效：棋子 \(pieceId) 移出边界。")
            return
        }

        // 2. 碰撞检查 (与目标位置的其他棋子)
        for r in 0..<pieceToMove.height {
            for c in 0..<pieceToMove.width {
                let targetBoardY = newY + r
                let targetBoardX = newX + c
                if let occupyingPieceId = gameBoard[targetBoardY][targetBoardX], occupyingPieceId != pieceId {
                    print("移动无效：棋子 \(pieceId) 与棋子 \(occupyingPieceId) 在 (\(targetBoardX), \(targetBoardY)) 发生碰撞。")
                    return // 目标位置已被其他棋子占据
                }
            }
        }
        
        // --- 如果移动有效 ---
        // 3. 更新 gameBoard: 清除旧位置，填充新位置
        for r in 0..<pieceToMove.height {
            for c in 0..<pieceToMove.width {
                gameBoard[originalY + r][originalX + c] = nil // 清除旧位置
            }
        }
        for r in 0..<pieceToMove.height {
            for c in 0..<pieceToMove.width {
                gameBoard[newY + r][newX + c] = pieceId // 填充新位置
            }
        }

        // 4. 更新 pieces 数组中棋子的位置
        if let index = pieces.firstIndex(where: { $0.id == pieceId }) {
            pieces[index].x = newX
            pieces[index].y = newY
            pieceToMove = pieces[index] // 更新 pieceToMove 的本地副本
        }

        // 5. 更新步数 (移动一格算一步，所以总步数是水平和垂直移动格数的总和)
        moves += abs(dx) + abs(dy)
        print("棋子 \(pieceId) 移动到 (\(newX), \(newY))，当前步数: \(moves)")
        
        // 6. 检查胜利条件
        checkWinCondition(movedPiece: pieceToMove)
        
        // saveGame() // 每次有效移动后保存游戏
    }

    // 检查棋子是否可以移动到指定方向的指定格数 (用于拖动过程中的实时校验)
    // pieceId: 要移动的棋子ID
    // dx, dy: 尝试移动的格子数 (通常每次为 1 或 -1)
    // returns: Bool - 是否可以移动
    func canMove(pieceId: Int, dx: Int, dy: Int) -> Bool {
        guard let level = currentLevel, let pieceToMove = pieces.first(where: { $0.id == pieceId }) else {
            return false
        }

        let newX = pieceToMove.x + dx
        let newY = pieceToMove.y + dy

        // 1. 边界检查
        guard newX >= 0, newX + pieceToMove.width <= level.boardWidth,
              newY >= 0, newY + pieceToMove.height <= level.boardHeight else {
            return false // 超出边界
        }

        // 2. 碰撞检查
        // 检查目标位置的每一个格子是否为空，或者是否被当前正在移动的棋子自身占据 (这在单步检查中不应发生，但在多步检查中可能需要)
        for r_offset in 0..<pieceToMove.height {
            for c_offset in 0..<pieceToMove.width {
                let targetBoardY = newY + r_offset
                let targetBoardX = newX + c_offset
                
                // 获取目标格子上的棋子ID
                let occupyingPieceId = gameBoard[targetBoardY][targetBoardX]
                
                // 如果目标格子上存在棋子，并且这个棋子不是当前正在移动的棋子，则发生碰撞
                if let occupyingPieceId = occupyingPieceId, occupyingPieceId != pieceId {
                    return false // 碰撞
                }
            }
        }
        return true // 可以移动
    }


    func checkWinCondition(movedPiece: Piece) {
        guard let level = currentLevel else { return }
        if movedPiece.id == level.targetPieceId && movedPiece.x == level.targetX && movedPiece.y == level.targetY {
            isGameWon = true
            isGameActive = false // 可以选择在胜利时停止游戏活动状态
            // clearSavedGame() // 胜利后清除存档
            print("恭喜！关卡 \(level.name) 完成！总步数: \(moves)")
            // 后续可以触发更复杂的完成逻辑，如显示胜利界面、解锁下一关等
        }
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
}

class ThemeManager: ObservableObject {
    @Published var themes: [Theme] = [
        Theme(id: "default", name: "默认浅色", isPremium: false,
              backgroundColor: CodableColor(color: .white),
              sliderColor: CodableColor(color: .blue), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(white: 0.9)), boardGridLineColor: CodableColor(color: Color(white: 0.7)),
              fontName: nil, colorScheme: .light),
        Theme(id: "dark", name: "深邃夜空", isPremium: false,
              backgroundColor: CodableColor(color: .black),
              sliderColor: CodableColor(color: .orange), sliderTextColor: CodableColor(color: .black),
              boardBackgroundColor: CodableColor(color: Color(white: 0.2)), boardGridLineColor: CodableColor(color: Color(white: 0.4)),
              fontName: nil, colorScheme: .dark),
        Theme(id: "forest", name: "森林绿意", isPremium: true, price: 6.00,
              backgroundColor: CodableColor(color: Color(red: 161/255, green: 193/255, blue: 129/255)),
              sliderColor: CodableColor(color: Color(red: 103/255, green: 148/255, blue: 54/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 200/255, green: 220/255, blue: 180/255)), boardGridLineColor: CodableColor(color: Color(red: 120/255, green: 150/255, blue: 100/255)),
              fontName: "Georgia", colorScheme: .light),
        Theme(id: "ocean", name: "蔚蓝海洋", isPremium: true, price: 6.00,
              backgroundColor: CodableColor(color: Color(red: 86/255, green: 207/255, blue: 225/255)),
              sliderColor: CodableColor(color: Color(red: 78/255, green: 168/255, blue: 222/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 180/255, green: 225/255, blue: 235/255)), boardGridLineColor: CodableColor(color: Color(red: 100/255, green: 150/255, blue: 180/255)),
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
                                        backgroundColor: CodableColor(color: .white),sliderColor: CodableColor(color: .blue),
                                        sliderTextColor: CodableColor(color: .white),boardBackgroundColor: CodableColor(color: Color(white: 0.9)),
                                        boardGridLineColor: CodableColor(color: Color(white: 0.7)),fontName: nil, colorScheme: .light)
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

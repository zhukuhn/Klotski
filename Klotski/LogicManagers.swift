//
//  GameManeger.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI
import AVFoundation // For future sound implementation
import UIKit // For Haptics

class GameManager: ObservableObject {
    @Published var currentLevel: Level?
    @Published var pieces: [Piece] = [] // 当前关卡的棋子实例
    @Published var gameBoard: [[Int?]] = [] // 棋盘网格，存储占据该格子的棋子ID，nil表示空格。Int? 而非 Int 是因为 0 可能是一个有效的棋子ID
    
    static let classicLevel = Level(
        id: "classic_hdml", name: "横刀立马", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0), PiecePlacement(id: 2, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 3, type: .zhangFeiV, initialX: 0, initialY: 0), PiecePlacement(id: 4, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 5, type: .maChaoV, initialX: 0, initialY: 2), PiecePlacement(id: 6, type: .huangZhongV, initialX: 3, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3), PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 0, initialY: 4), PiecePlacement(id: 10, type: .soldier, initialX: 3, initialY: 4)
        ], targetPieceId: 1, targetX: 1, targetY: 3, isUnlocked: true
    )
    static let easyExitLevel = Level(
        id: "easy_exit", name: "兵临城下", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 2, type: .soldier, initialX: 0, initialY: 0), PiecePlacement(id: 3, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .soldier, initialX: 1, initialY: 2), PiecePlacement(id: 5, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .guanYuH, initialX: 1, initialY: 3) // Blocks exit initially
        ], targetPieceId: 1, targetX: 1, targetY: 3, isUnlocked: true
    )
    static let verticalChallengeLevel = Level(
        id: "vertical_challenge", name: "层峦叠嶂", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0), PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2), PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 2), PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 3), PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 3),
        ], targetPieceId: 1, targetX: 1, targetY: 3, isUnlocked: true
    )
    
    @Published var levels: [Level] = [classicLevel] // 更多关卡可以后续添加
    
    @Published var moves: Int = 0
    @Published var timeElapsed: TimeInterval = 0
    @Published var isGameActive: Bool = false
    @Published var hasSavedGame: Bool = false
    @Published var isGameWon: Bool = false
    
    // --- P1: Keys for UserDefaults ---
    private let savedLevelIDKey = "savedKlotskiLevelID"
    private let savedMovesKey = "savedKlotskiMoves"
    private let savedTimeKey = "savedKlotskiTime"
    private let savedPiecesKey = "savedKlotskiPieces"
    
    
    init() {
        let levelID = UserDefaults.standard.string(forKey: savedLevelIDKey)
        let piecesData = UserDefaults.standard.data(forKey: savedPiecesKey)
        let movesData = UserDefaults.standard.object(forKey: savedMovesKey) // 检查键是否存在
        let timeData = UserDefaults.standard.object(forKey: savedTimeKey)   // 检查键是否存在

        print("GameManager init: 正在检查已保存的数据...")
        print("  - 关卡 ID: \(levelID ?? "无")")
        print("  - 棋子数据: \(piecesData != nil ? "\(piecesData!.count) 字节" : "无")")
        print("  - 步数: \(movesData != nil ? String(describing: UserDefaults.standard.integer(forKey: savedMovesKey)) : "无")")
        print("  - 时间: \(timeData != nil ? String(describing: UserDefaults.standard.double(forKey: savedTimeKey)) : "无")")

        // 严格检查：所有存档部分都必须存在才认为存档有效
        if let id = levelID, piecesData != nil, movesData != nil, timeData != nil {
            print("GameManager init: 发现有效的存档，关卡 ID \(id)。设置 hasSavedGame = true")
            hasSavedGame = true
        } else {
            print("GameManager init: 未找到有效的完整存档或存档部分缺失。设置 hasSavedGame = false。")
            hasSavedGame = false
            // 如果任何存档部分存在，说明存档不完整或已损坏，进行清理
            if levelID != nil || piecesData != nil || movesData != nil || timeData != nil {
                print("GameManager init: 正在清除部分或损坏的存档数据。")
                UserDefaults.standard.removeObject(forKey: savedLevelIDKey)
                UserDefaults.standard.removeObject(forKey: savedMovesKey)
                UserDefaults.standard.removeObject(forKey: savedTimeKey)
                UserDefaults.standard.removeObject(forKey: savedPiecesKey)
            }
        }
    }
    
    func startGame(level: Level, settings: SettingsManager) {
        currentLevel = level
        moves = 0
        timeElapsed = 0 // Reset time for new game
        isGameActive = true
        isGameWon = false
        
        pieces = level.piecePlacements.map { Piece(id: $0.id, type: $0.type, x: $0.initialX, y: $0.initialY) }
        rebuildGameBoard()
        
        print("游戏开始: \(level.name)")
        SoundManager.playImpactHaptic(settings: settings) // Haptic for game start
        // saveGame(settings: settings) // Optionally save at the very start
        // hasSavedGame = true // Set by saveGame if it runs
    }
    
    // 尝试移动棋子 (由拖动手势结束时调用)
    // dx, dy 是格子单位的位移
    func attemptMove(pieceId: Int, dx: Int, dy: Int, settings: SettingsManager) -> Bool {
        guard let level = currentLevel, var pieceToMove = pieces.first(where: { $0.id == pieceId }),
              (dx != 0 || dy != 0) else {
            return false // No actual displacement
        }
        
        let originalX = pieceToMove.x
        let originalY = pieceToMove.y
        let newX = originalX + dx
        let newY = originalY + dy
        
        guard newX >= 0, newX + pieceToMove.width <= level.boardWidth,
              newY >= 0, newY + pieceToMove.height <= level.boardHeight else {
            print("移动无效：棋子 \(pieceId) 移出边界。")
            // SoundManager.playHapticNotification(type: .error, settings: settings) // Handled in GameView
            return false
        }
        
        for r in 0..<pieceToMove.height {
            for c in 0..<pieceToMove.width {
                let targetBoardY = newY + r
                let targetBoardX = newX + c
                if let occupyingPieceId = gameBoard[targetBoardY][targetBoardX], occupyingPieceId != pieceId {
                    print("移动无效：棋子 \(pieceId) 与棋子 \(occupyingPieceId) 在 (\(targetBoardX), \(targetBoardY)) 发生碰撞。")
                    // SoundManager.playHapticNotification(type: .error, settings: settings) // Handled in GameView
                    return false
                }
            }
        }
        
        // Update gameBoard
        for r in 0..<pieceToMove.height { for c in 0..<pieceToMove.width { gameBoard[originalY + r][originalX + c] = nil } }
        for r in 0..<pieceToMove.height { for c in 0..<pieceToMove.width { gameBoard[newY + r][newX + c] = pieceId } }
        
        if let index = pieces.firstIndex(where: { $0.id == pieceId }) {
            pieces[index].x = newX
            pieces[index].y = newY
            pieceToMove = pieces[index]
        }
        
        moves += abs(dx) + abs(dy)
        print("棋子 \(pieceId) 移动到 (\(newX), \(newY))，当前步数: \(moves)")
        // SoundManager.playImpactHaptic(settings: settings) // Handled in GameView after successful call
        
        checkWinCondition(movedPiece: pieceToMove, settings: settings)
        
        // --- P1: Auto-save after successful move ---
        if isGameActive && !isGameWon {
            saveGame(settings: settings)
        }
        return true
    }
    
    func canMove(pieceId: Int, currentGridX: Int, currentGridY: Int, deltaX: Int, deltaY: Int) -> Bool {
        guard let level = currentLevel, let pieceToMove = pieces.first(where: { $0.id == pieceId }) else {
            return false
        }
        // 如果没有位移，则认为可以“移动”（停在原地）
        if deltaX == 0 && deltaY == 0 { return true }
        
        let newX = currentGridX + deltaX
        let newY = currentGridY + deltaY
        
        guard newX >= 0, newX + pieceToMove.width <= level.boardWidth,
              newY >= 0, newY + pieceToMove.height <= level.boardHeight else {
            return false // 超出边界
        }
        
        for r_offset in 0..<pieceToMove.height {
            for c_offset in 0..<pieceToMove.width {
                let targetBoardY = newY + r_offset
                let targetBoardX = newX + c_offset
                if let occupyingPieceId = gameBoard[targetBoardY][targetBoardX], occupyingPieceId != pieceId {
                    return false // 碰撞
                }
            }
        }
        return true
    }
    
    
    func checkWinCondition(movedPiece: Piece, settings: SettingsManager) {
        guard let level = currentLevel, !isGameWon else { return } // 防止重复触发胜利
        if movedPiece.id == level.targetPieceId && movedPiece.x == level.targetX && movedPiece.y == level.targetY {
            isGameWon = true
            // isGameActive = false; // 不在这里设置 isGameActive = false，交由 GameView 的胜利界面处理
            print("恭喜！关卡 \(level.name) 完成！总步数: \(moves)")
            SoundManager.playSound(named: "victory_fanfare", settings: settings) // 立即播放胜利音效
            SoundManager.playHapticNotification(type: .success, settings: settings) // 立即播放胜利触感
            clearSavedGame() // 清除已完成关卡的存档
        }
    }
    
    
    func continueGame(settings: SettingsManager) {
        guard let savedLevelID = UserDefaults.standard.string(forKey: savedLevelIDKey),
              let levelToContinue = levels.first(where: { $0.id == savedLevelID }) else {
            print("未找到有效存档ID或对应关卡。")
            clearSavedGame() // Clear any partial/corrupt save
            hasSavedGame = false
            return
        }
        
        self.currentLevel = levelToContinue
        self.moves = UserDefaults.standard.integer(forKey: savedMovesKey)
        self.timeElapsed = UserDefaults.standard.double(forKey: savedTimeKey)
        
        if let savedPiecesData = UserDefaults.standard.data(forKey: savedPiecesKey) {
            do {
                let decoder = JSONDecoder()
                let decodedPieces = try decoder.decode([Piece].self, from: savedPiecesData)
                self.pieces = decodedPieces
                rebuildGameBoard()
                self.isGameActive = true
                self.isGameWon = false // Ensure win state is reset
                print("继续游戏: \(levelToContinue.name), 棋子状态已加载。")
                SoundManager.playImpactHaptic(settings: settings)
                // Check win condition in case the saved state was already a win (unlikely for Klotski mid-game)
                if let targetPiece = pieces.first(where: {$0.id == levelToContinue.targetPieceId}) {
                    checkWinCondition(movedPiece: targetPiece, settings: settings) // Re-check, might clear save if won
                }
            } catch {
                print("错误：无法解码已保存的棋子状态: \(error)。将清除存档并尝试重新开始关卡。")
                clearSavedGame()
                hasSavedGame = false
                isGameActive = false // Prevent navigation to broken state
                // Optionally, you could offer to start the level fresh:
                // startGame(level: levelToContinue, settings: settings)
            }
        } else {
            print("未找到已保存的棋子数据。存档不完整。将清除存档。")
            clearSavedGame()
            hasSavedGame = false
            isGameActive = false
        }
    }
    
    func saveGame(settings: SettingsManager) {
        guard let currentLevel = currentLevel else {
            print("SaveGame: 无当前关卡，无法保存。")
            return
        }
        // 仅当游戏活跃且未胜利时才保存，以支持“继续游戏”功能
        guard isGameActive && !isGameWon else {
            print("SaveGame: 游戏非活跃或已胜利，跳过保存。isGameActive=\(isGameActive), isGameWon=\(isGameWon)")
            return
        }
        UserDefaults.standard.set(currentLevel.id, forKey: savedLevelIDKey)
        UserDefaults.standard.set(moves, forKey: savedMovesKey)
        UserDefaults.standard.set(timeElapsed, forKey: savedTimeKey)
        do {
            let encodedPieces = try JSONEncoder().encode(pieces)
            UserDefaults.standard.set(encodedPieces, forKey: savedPiecesKey)
            hasSavedGame = true // 关键：这会使“继续游戏”按钮出现
            print("游戏已保存: \(currentLevel.name), 步数: \(moves)。hasSavedGame = \(hasSavedGame)")
        } catch {
            print("错误：无法编码并保存棋子状态: \(error)")
            hasSavedGame = false // 如果棋子无法保存，则存档不完整
        }
    }
    
    func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: savedLevelIDKey)
        UserDefaults.standard.removeObject(forKey: savedMovesKey)
        UserDefaults.standard.removeObject(forKey: savedTimeKey)
        UserDefaults.standard.removeObject(forKey: savedPiecesKey) // Clear saved pieces
        hasSavedGame = false
        print("已清除已保存的游戏及棋子状态")
    }
    
    func rebuildGameBoard() {
        guard let level = currentLevel else { return }
        gameBoard = Array(repeating: Array(repeating: nil, count: level.boardWidth), count: level.boardHeight)
        for piece in pieces {
            for r in 0..<piece.height {
                for c in 0..<piece.width {
                    let boardY = piece.y + r
                    let boardX = piece.x + c
                    if boardY < level.boardHeight && boardX < level.boardWidth {
                        gameBoard[boardY][boardX] = piece.id
                    }
                }
            }
        }
    }
    
    func completeLevel(moves: Int, time: TimeInterval, settings: SettingsManager) { // Pass settings
        print("关卡 \(currentLevel?.name ?? "N/A") 完成！步数: \(moves), 时间: \(String(format: "%.2f", time))s")
        // TODO P2: Update level stats (bestMoves, bestTime) in the `levels` array and persist them.
        // TODO P2: Submit to Game Center leaderboard.
        clearSavedGame()
        isGameActive = false
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
            "gameTitle": "Klotski",
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
            "pause": "Pause", 
            "resume": "Resume",
            "backToMenu": "Back to Menu",
            "victoryTitle": "Congratulations!",
            "victoryMessage": "Level Cleared!"
        ],
        "zh": [
            "gameTitle": "华容道",
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
            "pause": "暂停",
            "resume": "继续",
            "backToMenu": "返回主菜单",
            "victoryTitle": "恭喜获胜!",
            "victoryMessage": "成功过关!",
        ]
    ]

    func localizedString(forKey key: String) -> String {
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }
}

// Simple manager to handle sounds and haptics, respecting user settings.
struct SoundManager {
    // Using static methods for simplicity in P1.
    // For more complex audio, a dedicated class/ObservableObject might be better.
    private static var audioPlayer: AVAudioPlayer?
    private static let hapticNotificationGenerator = UINotificationFeedbackGenerator()
    private static let hapticImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    // Placeholder for playing sounds. Actual implementation would load and play sound files.
    static func playSound(named soundName: String, type: String = "mp3", settings: SettingsManager) {
        guard settings.soundEffectsEnabled else { return }
        // In a real app, you would use AVAudioPlayer here:
        // guard let path = Bundle.main.path(forResource: soundName, ofType: type) else {
        //     print("Sound file not found: \(soundName).\(type)")
        //     return
        // }
        // do {
        //     audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        //     audioPlayer?.play()
        //     print("SoundManager: Playing sound \(soundName)")
        // } catch {
        //     print("SoundManager: Could not load/play sound file: \(error)")
        // }
        print("SoundManager: Playing sound '\(soundName)' (if enabled and sound file exists)")
    }

    static func playHapticNotification(type: UINotificationFeedbackGenerator.FeedbackType, settings: SettingsManager) {
        guard settings.hapticsEnabled else { return }
        hapticNotificationGenerator.prepare()
        hapticNotificationGenerator.notificationOccurred(type)
        print("SoundManager: Playing haptic notification \(type) (if enabled)")
    }

    static func playImpactHaptic(settings: SettingsManager) {
        guard settings.hapticsEnabled else { return }
        hapticImpactGenerator.prepare()
        hapticImpactGenerator.impactOccurred()
        print("SoundManager: Playing impact haptic (if enabled)")
    }
}

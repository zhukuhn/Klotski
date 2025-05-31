//
//  GameManeger.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI
import AVFoundation // For future sound implementation
import UIKit // For Haptics
import Combine
import CloudKit

class GameManager: ObservableObject {
    @Published var currentLevel: Level?
    @Published var currentLevelIndex: Int? 
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
        ], targetPieceId: 1, targetX: 1, targetY: 3, bestMoves: 200, bestTime: 200
    )
    static let easyExitLevel = Level(
        id: "easy_exit", name: "兵临城下", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 2, type: .soldier, initialX: 0, initialY: 0), PiecePlacement(id: 3, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .soldier, initialX: 1, initialY: 2), PiecePlacement(id: 5, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .guanYuH, initialX: 1, initialY: 3) // Blocks exit initially
        ], targetPieceId: 1, targetX: 1, targetY: 3, bestMoves: 100, bestTime: 200
    )
    static let verticalChallengeLevel = Level(
        id: "vertical_challenge", name: "层峦叠嶂", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0), PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2), PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 2), PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 3), PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 3),
        ], targetPieceId: 1, targetX: 1, targetY: 3
    )
    
    @Published var levels: [Level] = [classicLevel, easyExitLevel, verticalChallengeLevel] // 更多关卡可以后续添加
    
    @Published var moves: Int = 0
    @Published var timeElapsed: TimeInterval = 0
    @Published var isGameActive: Bool = false
    @Published var hasSavedGame: Bool = false
    @Published var isGameWon: Bool = false
    @Published var isPaused: Bool = false // 游戏暂停状态

    private var timerSubscription: Cancellable? // 用于管理计时器
    
    private let savedLevelIDKey = "savedKlotskiLevelID"
    private let savedMovesKey = "savedKlotskiMoves"
    private let savedTimeKey = "savedKlotskiTime"
    private let savedPiecesKey = "savedKlotskiPieces"
    private let savedLevelIndexKey = "savedKlotskiLevelIndex"
    private let savedIsPausedKey = "savedKlotskiIsPaused" // 保存暂停状态的键

    init() {
        let levelID = UserDefaults.standard.string(forKey: savedLevelIDKey)
        let piecesData = UserDefaults.standard.data(forKey: savedPiecesKey)
        let movesDataExists = UserDefaults.standard.object(forKey: savedMovesKey) != nil
        let timeDataExists = UserDefaults.standard.object(forKey: savedTimeKey) != nil
        let levelIndexExists = UserDefaults.standard.object(forKey: savedLevelIndexKey) != nil
        let isPausedDataExists = UserDefaults.standard.object(forKey: savedIsPausedKey) != nil

        print("GameManager init: 正在检查已保存的数据...")
        print("  - 关卡 ID: \(levelID ?? "无")")
        print("  - 棋子数据: \(piecesData != nil ? "\(piecesData!.count) 字节" : "无")")
        print("  - 步数: \(movesDataExists ? String(describing: UserDefaults.standard.integer(forKey: savedMovesKey)) : "无")")
        print("  - 时间: \(timeDataExists ? String(describing: UserDefaults.standard.double(forKey: savedTimeKey)) : "无")")
        print("  - 关卡索引: \(levelIndexExists ? String(describing: UserDefaults.standard.integer(forKey: savedLevelIndexKey)) : "无")")

        // 严格检查：所有存档部分都必须存在才认为存档有效
        if let id = levelID, piecesData != nil, movesDataExists, timeDataExists, levelIndexExists, isPausedDataExists {
            print("GameManager init: 发现有效的存档，关卡 ID \(id)。设置 hasSavedGame = true")
            hasSavedGame = true
        } else {
            print("GameManager init: 未找到有效的完整存档或存档部分缺失。设置 hasSavedGame = false。")
            hasSavedGame = false
            // 如果任何存档部分存在，说明存档不完整或已损坏，进行清理
            if levelID != nil || piecesData != nil || movesDataExists || timeDataExists || levelIndexExists || isPausedDataExists {
                print("GameManager init: 正在清除部分或损坏的存档数据。")
                UserDefaults.standard.removeObject(forKey: savedLevelIDKey)
                UserDefaults.standard.removeObject(forKey: savedMovesKey)
                UserDefaults.standard.removeObject(forKey: savedTimeKey)
                UserDefaults.standard.removeObject(forKey: savedPiecesKey)
                UserDefaults.standard.removeObject(forKey: savedLevelIndexKey)
                UserDefaults.standard.removeObject(forKey: savedIsPausedKey)
            }
        }
    }
    
    // 开始指定关卡
    func startGame(level: Level, settings: SettingsManager, isNewSession: Bool = true) {
        currentLevel = level
        if let index = levels.firstIndex(where: { $0.id == level.id }) {
            currentLevelIndex = index
        } else {
            currentLevelIndex = nil; print("警告：开始的关卡 \(level.name) 在 levels 数组中未找到！")
        }

        if isNewSession { // 只有全新的会话才重置所有状态
            moves = 0
            timeElapsed = 0
            isPaused = true // 新游戏默认暂停
        }
        // 对于切换关卡 (isNewSession = false)，moves, timeElapsed, isPaused 会在 switchToLevel 中处理

        isGameActive = true
        isGameWon = false
        
        pieces = level.piecePlacements.map { Piece(id: $0.id, type: $0.type, x: $0.initialX, y: $0.initialY) }
        rebuildGameBoard()
        print("游戏开始/切换到: \(level.name) (索引: \(currentLevelIndex ?? -1)), isPaused: \(isPaused)")
        SoundManager.playImpactHaptic(settings: settings)
        
        if !isPaused && !isGameWon { // 如果不是暂停状态且未胜利，则启动计时器
            startTimer()
        } else {
            stopTimer() // 其他情况确保计时器停止
        }
    }

    // 切换到指定索引的关卡
    func switchToLevel(at index: Int, settings: SettingsManager) {
        guard index >= 0 && index < levels.count else { print("切换关卡失败：索引 \(index) 超出范围。"); return }
        let newLevel = levels[index]
        
        // 切换关卡时，重置这些状态
        moves = 0
        timeElapsed = 0
        isPaused = false // 新关卡默认不暂停
        isGameWon = false
        // isGameActive 保持 true
        
        stopTimer() // 先停止旧关卡的计时器
        startGame(level: newLevel, settings: settings, isNewSession: false) // isNewSession false 表示是切换
        clearSavedGameForCurrentLevelOnly() // 清除对这个新关卡尝试的任何旧存档
    }

    // 仅清除当前关卡的存档标记，但不清除关卡本身的最佳记录
    private func clearSavedGameForCurrentLevelOnly() {
        UserDefaults.standard.removeObject(forKey: savedLevelIDKey)
        UserDefaults.standard.removeObject(forKey: savedMovesKey)
        UserDefaults.standard.removeObject(forKey: savedTimeKey)
        UserDefaults.standard.removeObject(forKey: savedPiecesKey)
        UserDefaults.standard.removeObject(forKey: savedLevelIndexKey)
        hasSavedGame = false // 因为当前尝试的存档被清除了
        print("已清除当前尝试的关卡存档。hasSavedGame = \(hasSavedGame)")
    }

    // 暂停游戏
    func pauseGame() {
        guard isGameActive && !isGameWon else { return } // 游戏结束或未开始不能暂停
        if !isPaused {
            isPaused = true
            stopTimer()
            print("游戏已暂停。时间: \(formattedTime(timeElapsed))")
        }
    }

    // 继续游戏
    func resumeGame(settings: SettingsManager) {
        guard isGameActive && !isGameWon else { return } // 游戏结束或未开始不能继续
        if isPaused {
            isPaused = false
            startTimer()
            SoundManager.playImpactHaptic(settings: settings)
            print("游戏已继续。")
        }
    }

    // 启动计时器
    func startTimer() {
        stopTimer() // 先确保之前的计时器已停止
        guard isGameActive && !isPaused && !isGameWon else { return } // 满足条件才启动
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.timeElapsed += 1
            }
        print("计时器已启动。isGameActive=\(isGameActive), isPaused=\(isPaused), isGameWon=\(isGameWon)")
    }

    // 停止计时器
    func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
        print("计时器已停止。")
    }
    
    // 尝试移动棋子 (由拖动手势结束时调用)
    // dx, dy 是格子单位的位移
    func attemptMove(pieceId: Int, dx: Int, dy: Int, settings: SettingsManager) -> Bool {
        guard isGameActive && !isPaused && !isGameWon else { 
            print("尝试移动失败：游戏非活动、已暂停或已胜利。")
            return false 
        } // 增加检查
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
            stopTimer() // 胜利时停止计时器
            print("恭喜！关卡 \(level.name) 完成！总步数: \(moves)")
            SoundManager.playSound(named: "victory_fanfare", settings: settings) // 立即播放胜利音效
            SoundManager.playHapticNotification(type: .success, settings: settings) // 立即播放胜利触感
            
            if let currentIndex = currentLevelIndex {
                var completedLevel = levels[currentIndex]
                var recordUpdated = false
                if completedLevel.bestMoves == nil || moves < completedLevel.bestMoves! {
                    completedLevel.bestMoves = moves
                    recordUpdated = true
                    print("新纪录：最少步数 \(moves) 步！")
                }
                if completedLevel.bestTime == nil || timeElapsed < completedLevel.bestTime! {
                    completedLevel.bestTime = timeElapsed
                    recordUpdated = true
                    print("新纪录：最短时间 \(formattedTime(timeElapsed))！")
                }
                if recordUpdated {
                    levels[currentIndex] = completedLevel
                    // TODO P2: 在这里持久化整个 levels 数组 (例如保存到 UserDefaults)
                    // persistLevelsArray()
                }
            }
            clearSavedGameForCurrentLevelOnly() // 清除当前尝试的存档，因为关卡已完成
        }
    }
    
    
    func continueGame(settings: SettingsManager) {
        guard let savedLevelID = UserDefaults.standard.string(forKey: savedLevelIDKey),
              let savedLevelIndex = UserDefaults.standard.object(forKey: savedLevelIndexKey) as? Int, // 加载索引
              savedLevelIndex >= 0 && savedLevelIndex < levels.count, // 确保索引有效
              let levelToContinue = levels.first(where: { $0.id == savedLevelID }), // 确保关卡ID匹配
              UserDefaults.standard.object(forKey: savedPiecesKey) != nil,
              UserDefaults.standard.object(forKey: savedMovesKey) != nil,
              UserDefaults.standard.object(forKey: savedTimeKey) != nil
        else {
            print("继续游戏失败：未找到有效或完整的存档。将清除任何部分存档。")
            clearSavedGame(); hasSavedGame = false; return
        }
        
        self.currentLevel = levelToContinue
        self.currentLevelIndex = savedLevelIndex // 设置当前关卡索引
        self.moves = UserDefaults.standard.integer(forKey: savedMovesKey)
        self.timeElapsed = UserDefaults.standard.double(forKey: savedTimeKey)
        // Load pause state
        self.isPaused = UserDefaults.standard.bool(forKey: savedIsPausedKey)


        if let savedPiecesData = UserDefaults.standard.data(forKey: savedPiecesKey) {
            do {
                self.pieces = try JSONDecoder().decode([Piece].self, from: savedPiecesData)
                rebuildGameBoard()
                self.isGameActive = true; self.isGameWon = false
                print("继续游戏: \(levelToContinue.name) (索引: \(savedLevelIndex)), 棋子状态已加载, isPaused: \(self.isPaused)")
                SoundManager.playImpactHaptic(settings: settings)
                if !self.isPaused && !self.isGameWon { startTimer() } // 如果不是暂停状态且未胜利，则启动计时器
                else { stopTimer() } // Ensure timer is stopped if paused or won
                
                if let targetPiece = pieces.first(where: {$0.id == levelToContinue.targetPieceId}) {
                     checkWinCondition(movedPiece: targetPiece, settings: settings)
                 }
            } catch {
                print("错误：无法解码已保存的棋子状态: \(error)。将清除存档。")
                clearSavedGame()
                hasSavedGame = false
                isGameActive = false
            }
        }
    }
    
    func saveGame(settings: SettingsManager) {
        guard let currentLevel = currentLevel, let currentIndex = currentLevelIndex else {
            print("SaveGame: 无当前关卡，无法保存。")
            return
        }
        // 仅当游戏活跃且未胜利时才保存，以支持“继续游戏”功能
        guard isGameActive && !isGameWon else {
            print("SaveGame: 游戏非活跃或已胜利，跳过保存。isGameActive=\(isGameActive), isGameWon=\(isGameWon)")
            return
        }
        UserDefaults.standard.set(currentLevel.id, forKey: savedLevelIDKey)
        UserDefaults.standard.set(currentIndex, forKey: savedLevelIndexKey)
        UserDefaults.standard.set(moves, forKey: savedMovesKey)
        UserDefaults.standard.set(timeElapsed, forKey: savedTimeKey)
        UserDefaults.standard.set(isPaused, forKey: savedIsPausedKey) // Save pause state
        do {
            let encodedPieces = try JSONEncoder().encode(pieces)
            UserDefaults.standard.set(encodedPieces, forKey: savedPiecesKey)
            hasSavedGame = true // 关键：这会使“继续游戏”按钮出现
            print("游戏已保存: \(currentLevel.name), 步数: \(moves), isPaused: \(isPaused)。hasSavedGame = \(hasSavedGame)")
        } catch {
            print("错误：无法编码并保存棋子状态: \(error)")
            hasSavedGame = false // 如果棋子无法保存，则存档不完整
        }
    }
    
    func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: savedLevelIDKey)
        UserDefaults.standard.removeObject(forKey: savedLevelIndexKey)
        UserDefaults.standard.removeObject(forKey: savedMovesKey)
        UserDefaults.standard.removeObject(forKey: savedTimeKey)
        UserDefaults.standard.removeObject(forKey: savedPiecesKey) // Clear saved pieces
        UserDefaults.standard.removeObject(forKey: savedIsPausedKey) // Clear saved pause state
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

    // 辅助函数：格式化时间显示
    func formattedTime(_ time: TimeInterval?) -> String {
        guard let time = time else { return "--:--" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class ThemeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var themes: [Theme]
    @Published var currentTheme: Theme
    @Published private(set) var purchasedThemeIDs: Set<String>

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let currentThemeIDKey = "currentThemeID"
    private let locallyKnownPaidThemeIDsKey = "locallyKnownPaidThemeIDs"
    private let settingsManagerInstance: SettingsManager 
    private var initialAuthCheckCompleted = false // Flag to manage initial auth sync

    // MARK: - Initialization
    init(authManager: AuthManager, settingsManager: SettingsManager, availableThemes: [Theme] = AppThemeRepository.allThemes) {
        self.settingsManagerInstance = settingsManager
        self.themes = availableThemes
        
        let fallbackTheme = Theme(id: "fallback", name: "备用", isPremium: false, backgroundColor: CodableColor(color: .gray), sliderColor: CodableColor(color: .secondary), sliderTextColor: CodableColor(color: .black), boardBackgroundColor: CodableColor(color: .white), boardGridLineColor: CodableColor(color: Color(.systemGray)))
        let defaultTheme = availableThemes.first(where: { $0.id == "default" }) ?? fallbackTheme
        self._currentTheme = Published(initialValue: defaultTheme) // Start with a sensible default
        
        var tempPurchasedIDs = Set(availableThemes.filter { !$0.isPremium }.map { $0.id })
        let localPaidIDsArray = UserDefaults.standard.array(forKey: locallyKnownPaidThemeIDsKey) as? [String] ?? []
        tempPurchasedIDs.formUnion(Set(localPaidIDsArray))
        self._purchasedThemeIDs = Published(initialValue: tempPurchasedIDs)

        print("ThemeManager init: Initial purchasedThemeIDs (free + local): \(self.purchasedThemeIDs)")
        
        // Attempt to set current theme based on saved ID and current knowledge of purchases
        // This will be re-evaluated if auth state changes.
        trySetInitialCurrentTheme(authManager: authManager)

        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                print("ThemeManager: AuthManager.currentUser changed (is now \(userProfile == nil ? "nil" : "available")).")
                self.initialAuthCheckCompleted = true 
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
            }
            .store(in: &cancellables)
        
        settingsManagerInstance.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let iCloudSettingChanged = self.settingsManagerInstance.useiCloudLogin // Get current value
                print("ThemeManager: SettingsManager's useiCloudLogin might have changed to \(iCloudSettingChanged).")
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
            }
            .store(in: &cancellables)

        // If authManager.currentUser is already available at the end of init,
        // ensure the theme state is fully up-to-date.
        if authManager.currentUser != nil && !self.initialAuthCheckCompleted {
            print("ThemeManager init: currentUser available immediately. Triggering initial full rebuild and theme refresh.")
            self.initialAuthCheckCompleted = true
            self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
        } else if authManager.currentUser == nil {
             self.initialAuthCheckCompleted = false // Ensure sink will run fully first time
        }
        print("ThemeManager init: Fully initialized. Current theme: \(self.currentTheme.name)")
    }

    private func trySetInitialCurrentTheme(authManager: AuthManager) {
        let savedThemeID = UserDefaults.standard.string(forKey: currentThemeIDKey)
        var themeToSet: Theme? = nil

        if let themeID = savedThemeID, let candidate = themes.first(where: { $0.id == themeID }) {
            // Build a temporary complete set of purchased IDs for this initial check
            var currentKnownPurchases = self.purchasedThemeIDs // (free + local)
            if settingsManagerInstance.useiCloudLogin, let user = authManager.currentUser {
                currentKnownPurchases.formUnion(user.purchasedThemeIDs)
            }

            if !candidate.isPremium || currentKnownPurchases.contains(candidate.id) {
                themeToSet = candidate
                print("ThemeManager trySetInitialCurrentTheme: Setting to saved theme '\(candidate.name)' based on current knowledge.")
            } else {
                print("ThemeManager trySetInitialCurrentTheme: Saved theme '\(candidate.name)' not considered purchased with current knowledge. Will use default.")
            }
        } else {
            print("ThemeManager trySetInitialCurrentTheme: No valid saved theme ID. Will use default.")
        }
        
        let defaultTheme = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
        self.currentTheme = themeToSet ?? defaultTheme

        // Ensure UserDefaults reflects the chosen theme, even if it's the default.
        // This is important if savedThemeID was invalid and we fell back to default.
        if UserDefaults.standard.string(forKey: currentThemeIDKey) != self.currentTheme.id {
             UserDefaults.standard.set(self.currentTheme.id, forKey: currentThemeIDKey)
             print("ThemeManager trySetInitialCurrentTheme: Updated UserDefaults for currentThemeID to '\(self.currentTheme.id)'")
        }
        print("ThemeManager trySetInitialCurrentTheme: Final initial current theme: \(self.currentTheme.name)")
    }

    private func rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: AuthManager) {
        var newPurchased = Set(self.themes.filter { !$0.isPremium }.map { $0.id })
        let localPaidIDsArray = UserDefaults.standard.array(forKey: locallyKnownPaidThemeIDsKey) as? [String] ?? []
        newPurchased.formUnion(Set(localPaidIDsArray))

        if self.settingsManagerInstance.useiCloudLogin, let userProfile = authManager.currentUser {
            newPurchased.formUnion(userProfile.purchasedThemeIDs)
            let newCloudThemes = userProfile.purchasedThemeIDs.subtracting(Set(localPaidIDsArray))
            if !newCloudThemes.isEmpty {
                var updatedLocalPaidIDs = Set(localPaidIDsArray)
                updatedLocalPaidIDs.formUnion(newCloudThemes)
                UserDefaults.standard.set(Array(updatedLocalPaidIDs), forKey: locallyKnownPaidThemeIDsKey)
                print("ThemeManager rebuild: Synced new paid themes from CloudKit to local cache: \(newCloudThemes)")
            }
        }
        
        if self.purchasedThemeIDs != newPurchased {
            self.purchasedThemeIDs = newPurchased
            print("ThemeManager: purchasedThemeIDs rebuilt. New set: \(self.purchasedThemeIDs)")
        }

        // After purchased IDs are updated, try to apply the saved theme preference or default
        let savedThemeID = UserDefaults.standard.string(forKey: currentThemeIDKey)
        var themeToRestore: Theme? = nil

        if let themeID = savedThemeID, let candidate = themes.first(where: { $0.id == themeID }) {
            if self.isThemePurchased(candidate) { // Check with NEWLY built purchasedThemeIDs
                themeToRestore = candidate
            }
        }

        let themeToActuallySet: Theme
        if let validRestoredTheme = themeToRestore {
            themeToActuallySet = validRestoredTheme
            if self.currentTheme.id != themeToActuallySet.id {
                 print("ThemeManager rebuild: Restoring saved theme '\(themeToActuallySet.name)' as it's now purchased.")
            } else {
                 print("ThemeManager rebuild: Saved theme '\(themeToActuallySet.name)' is already current and purchased.")
            }
        } else {
            let defaultThemeToSet = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
            themeToActuallySet = defaultThemeToSet
            if self.currentTheme.id != themeToActuallySet.id {
                 print("ThemeManager rebuild: Saved theme not restorable or current theme '\(self.currentTheme.name)' no longer purchased. Reverting to default '\(themeToActuallySet.name)'.")
            } else if let unwrappedSavedThemeID = savedThemeID, unwrappedSavedThemeID != defaultThemeToSet.id { // If a different theme was saved but is no longer valid
                 print("ThemeManager rebuild: Previously saved theme '\(savedThemeID!)' is no longer valid. Reverting to default '\(defaultThemeToSet.name)'.")
            }
        }
        
        // Crucially, call setCurrentTheme to update the @Published currentTheme and persist to UserDefaults
        self.setCurrentTheme(themeToActuallySet)
    }


    // MARK: - Public Methods
    func setCurrentTheme(_ theme: Theme) {
        guard themes.contains(where: { $0.id == theme.id }) else {
            print("ThemeManager: Attempted to set an unknown theme ('\(theme.name)'). Ignoring.")
            return
        }

        // Check if the theme can be applied based on purchase status and iCloud setting for paid themes
        let canApply: Bool
        if theme.isPremium {
            // Paid themes can only be applied if they are in purchasedThemeIDs AND (if iCloud is the mechanism for purchase) iCloud is enabled.
            // The isThemePurchased() already covers the "is it in purchasedThemeIDs" part.
            // The additional constraint from the user was: "不使用icloud登录则无法购买和应用付费主题"
            // So, for paid themes, settingsManagerInstance.useiCloudLogin must be true to apply.
            // However, our current isThemePurchased already reflects a combination of local and cloud.
            // The critical part is that `purchasedThemeIDs` is built correctly.
            // If iCloud is off, `purchasedThemeIDs` won't have cloud-only themes.
            // If a theme is in `purchasedThemeIDs` (meaning it's free, or local_paid, or cloud_paid_and_icloud_on), it should be settable.
            canApply = self.isThemePurchased(theme)
        } else {
            canApply = true // Free themes can always be applied
        }

        guard canApply else {
            print("ThemeManager setCurrentTheme: Cannot apply theme '\(theme.name)'. It's premium and not considered purchased/accessible under current settings. (iCloud: \(settingsManagerInstance.useiCloudLogin), Purchased: \(purchasedThemeIDs.contains(theme.id)))")
            // If an invalid theme was attempted, and it's not already the default, revert to default.
            let defaultTheme = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
            if self.currentTheme.id != defaultTheme.id {
                self.currentTheme = defaultTheme // Update @Published property
                UserDefaults.standard.set(defaultTheme.id, forKey: currentThemeIDKey) // Persist
                print("ThemeManager setCurrentTheme: Reverted to default theme '\(defaultTheme.name)'.")
            }
            return
        }

        if currentTheme.id != theme.id {
            currentTheme = theme // Update @Published property
            UserDefaults.standard.set(theme.id, forKey: currentThemeIDKey) // Persist
            print("ThemeManager: Current theme changed to '\(theme.name)' and saved to UserDefaults.")
        }
    }

    func isThemePurchased(_ theme: Theme) -> Bool {
        return !theme.isPremium || purchasedThemeIDs.contains(theme.id)
    }

    func themeDidGetPurchased(themeID: String, authManager: AuthManager) {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager: Purchase attempt for '\(themeID)' while iCloud login is disabled. Purchase flow should be blocked by UI.")
            // Potentially show an alert to the user here if this is somehow reached.
            return
        }
        guard let purchasedThemeObject = themes.first(where: { $0.id == themeID && $0.isPremium }) else {
            print("ThemeManager: Attempted to mark non-existent or free theme ID '\(themeID)' as purchased. Ignoring.")
            return
        }

        var localPaidIDs = Set(UserDefaults.standard.array(forKey: locallyKnownPaidThemeIDsKey) as? [String] ?? [])
        if localPaidIDs.insert(themeID).inserted {
            UserDefaults.standard.set(Array(localPaidIDs), forKey: locallyKnownPaidThemeIDsKey)
            print("ThemeManager: Theme ID '\(themeID)' added to local paid cache.")
        }

        if self.purchasedThemeIDs.insert(themeID).inserted {
             print("ThemeManager: Theme ID '\(themeID)' added to published purchasedThemeIDs.")
        }
        
        // Sync with CloudKit since iCloud login is enabled for purchase
        authManager.updateUserPurchasedThemes(themeIDs: self.purchasedThemeIDs) 
        
        setCurrentTheme(purchasedThemeObject)
    }
    
    func themesDidGetRestored(restoredThemeIDsFromStoreKit: Set<String>, authManager: AuthManager) {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager: Restore attempt while iCloud login is disabled. Restore flow should be blocked by UI.")
            return
        }

        var localPaidIDs = Set(UserDefaults.standard.array(forKey: locallyKnownPaidThemeIDsKey) as? [String] ?? [])
        var didUpdateAnySet = false

        for themeID in restoredThemeIDsFromStoreKit {
            if let theme = themes.first(where: { $0.id == themeID && $0.isPremium }) {
                if localPaidIDs.insert(theme.id).inserted {
                    print("ThemeManager: Restored theme ID '\(theme.id)' added to local paid cache.")
                    didUpdateAnySet = true
                }
                if self.purchasedThemeIDs.insert(theme.id).inserted {
                    print("ThemeManager: Restored theme ID '\(theme.id)' added to published purchasedThemeIDs.")
                    didUpdateAnySet = true 
                }
            }
        }

        if didUpdateAnySet {
            UserDefaults.standard.set(Array(localPaidIDs), forKey: locallyKnownPaidThemeIDsKey) // Save updated local cache
            print("ThemeManager: Syncing updated purchased themes to CloudKit after restoration.")
            authManager.updateUserPurchasedThemes(themeIDs: self.purchasedThemeIDs) // Sync all known
        } else {
            print("ThemeManager: No new themes were added from restoration, or restored IDs were not valid premium themes.")
        }
    }
}

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine

    private let container: CKContainer
    private let privateDB: CKDatabase
    
    private var iCloudUserActualRecordID: CKRecord.ID?

    private var cancellables = Set<AnyCancellable>()

    static let userProfileRecordType = "UserProfiles"
    static let useiCloudLoginKey = "useiCloudLogin" 

    init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        print("AuthManager (CloudKit v2): 初始化完成。")

        let useiCloudInitial = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
        if UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) == nil {
            UserDefaults.standard.set(useiCloudInitial, forKey: AuthManager.useiCloudLoginKey)
        }


        if useiCloudInitial {
            print("AuthManager init: iCloud login is enabled by preference. Checking status.")
            checkiCloudAccountStatusAndFetchProfile()
        } else {
            print("AuthManager init: iCloud login is disabled by preference (default or user set).")
            DispatchQueue.main.async { 
                self.clearLocalSessionForDisablediCloud(reason: "Initial setting is off.")
                self.errorMessage = self.localizedErrorMessageForDisablediCloud() 
            }
        }

        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("AuthManager: Received CKAccountChanged notification.")
                self.iCloudUserActualRecordID = nil 
                
                let useiCloudCurrent = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                if useiCloudCurrent {
                    print("AuthManager: iCloud account changed, and preference is ON. Re-checking account status and profile.")
                    self.checkiCloudAccountStatusAndFetchProfile()
                } else {
                    print("AuthManager: iCloud account changed, but preference is OFF. Ensuring local session is cleared.")
                    self.clearLocalSessionForDisablediCloud(reason: "Account changed while preference is off.")
                    self.errorMessage = self.localizedErrorMessageForDisablediCloud()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        print("AuthManager (CloudKit v2): Deinitialized.")
    }
    
    private func localizedErrorMessageForDisablediCloud() -> String {
        let sm = SettingsManager() 
        return sm.localizedString(forKey: "iCloudLoginDisabledMessage")
    }

    private func clearLocalSessionForDisablediCloud(reason: String) {
        DispatchQueue.main.async {
            if self.currentUser != nil || self.isLoggedIn || self.isLoading { 
                print("AuthManager: Clearing local session. Reason: \(reason)")
                self.currentUser = nil
                self.isLoggedIn = false
                self.iCloudUserActualRecordID = nil 
                self.isLoading = false 
                
                if self.iCloudAccountStatus == .available {
                   self.iCloudAccountStatus = .couldNotDetermine 
                }
                self.objectWillChange.send() 
            }
        }
    }

    public func handleiCloudPreferenceChange(useiCloud: Bool) {
        print("AuthManager: iCloud preference changed to \(useiCloud).")
        UserDefaults.standard.set(useiCloud, forKey: AuthManager.useiCloudLoginKey) 

        if useiCloud {
            self.errorMessage = nil 
            self.isLoading = true 
            if self.iCloudAccountStatus == .couldNotDetermine && self.currentUser == nil { 
                 self.iCloudAccountStatus = .couldNotDetermine 
            }
            print("AuthManager: Preference ON. Attempting to check iCloud status and fetch profile.")
            checkiCloudAccountStatusAndFetchProfile()
        } else {
            clearLocalSessionForDisablediCloud(reason: "User toggled preference to OFF.")
            self.errorMessage = localizedErrorMessageForDisablediCloud()
        }
    }

    func checkiCloudAccountStatusAndFetchProfile() {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager checkiCloudAccountStatusAndFetchProfile: iCloud login preference is OFF. Aborting check.")
            clearLocalSessionForDisablediCloud(reason: "Check called while preference is off.")
            if self.errorMessage == nil { 
                 self.errorMessage = localizedErrorMessageForDisablediCloud()
            }
            return
        }

        self.isLoading = true 
        print("AuthManager: Checking iCloud account status (preference is ON)...")

        container.accountStatus { [weak self] (status, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager accountStatus callback: iCloud login preference turned OFF during async. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during account status check.")
                    return
                }

                if let error = error {
                    print("AuthManager: Error checking iCloud account status: \(error.localizedDescription)")
                    self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
                    self.iCloudAccountStatus = .couldNotDetermine
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                    return
                }

                self.iCloudAccountStatus = status
                print("AuthManager: iCloud Account Status: \(status.description)")
                let sm = SettingsManager() 

                switch status {
                case .available:
                    self.errorMessage = nil 
                    self.fetchICloudUserRecordID()
                case .noAccount:
                    self.errorMessage = sm.localizedString(forKey: "iCloudNoAccount") 
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .restricted:
                    self.errorMessage = sm.localizedString(forKey: "iCloudRestricted") 
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .couldNotDetermine:
                    self.errorMessage = sm.localizedString(forKey: "iCloudCouldNotDetermine") 
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .temporarilyUnavailable:
                    self.errorMessage = sm.localizedString(forKey: "iCloudTempUnavailable") 
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                @unknown default:
                    self.errorMessage = sm.localizedString(forKey: "iCloudUnknownStatus") 
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                }
            }
        }
    }

    private func fetchICloudUserRecordID() {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager fetchICloudUserRecordID: iCloud login preference is OFF. Aborting fetch.")
            clearLocalSessionForDisablediCloud(reason: "User Record ID fetch called while preference is off.")
            return
        }

        print("AuthManager: Attempting to fetch iCloud User Record ID (preference is ON)...")

        container.fetchUserRecordID { [weak self] (recordID, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager fetchUserRecordID callback: iCloud login preference turned OFF during async. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during user ID fetch.")
                    return
                }
                let sm = SettingsManager() 
                if let error = error {
                    print("AuthManager: Error fetching iCloud User Record ID: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudFetchUserFailed")): \(error.localizedDescription)" 
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                    return
                }

                if let recordID = recordID {
                    print("AuthManager: Successfully fetched iCloud User Record ID: \(recordID.recordName)")
                    self.iCloudUserActualRecordID = recordID
                    self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: recordID.recordName)
                } else {
                    print("AuthManager: No iCloud User Record ID fetched.")
                    self.errorMessage = sm.localizedString(forKey: "iCloudNoUserIdentity") 
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func fetchOrCreateUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager fetchOrCreateUserProfile: iCloud login preference is OFF. Aborting.")
            clearLocalSessionForDisablediCloud(reason: "Profile fetch/create called while preference is off.")
            return
        }
        print("AuthManager: Fetching or creating UserProfile for iCloud User \(iCloudRecordName) (preference is ON)...")
        let sm = SettingsManager() 

        let predicate = NSPredicate(format: "iCloudUserRecordName == %@", iCloudRecordName)
        let query = CKQuery(recordType: AuthManager.userProfileRecordType, predicate: predicate)
        
        privateDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager fetchOrCreateUserProfile callback: iCloud login preference turned OFF. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during profile fetch/create.")
                    return
                }

                switch result {
                case .success(let data):
                    if let firstMatch = data.matchResults.first {
                        let matchedRecordID = firstMatch.0
                        switch firstMatch.1 {
                        case .success(let existingUserProfileRecord):
                            print("AuthManager: Found existing UserProfile record: \(existingUserProfileRecord.recordID.recordName)")
                            if let userProfile = UserProfile(from: existingUserProfileRecord) {
                                self.currentUser = userProfile
                                self.isLoggedIn = true
                                print("AuthManager: UserProfile loaded: \(userProfile.displayName ?? userProfile.id)")
                            } else {
                                print("AuthManager: Failed to parse UserProfile from fetched record (ID: \(matchedRecordID.recordName)).")
                                self.errorMessage = sm.localizedString(forKey: "iCloudParseProfileErrorExisting") 
                                self.currentUser = nil; self.isLoggedIn = false
                            }
                            self.isLoading = false
                        case .failure(let recordFetchError):
                            print("AuthManager: Matched UserProfile ID \(matchedRecordID.recordName), but failed to fetch record: \(recordFetchError.localizedDescription)")
                            self.errorMessage = "\(sm.localizedString(forKey: "iCloudLoadProfileErrorFetch")): \(recordFetchError.localizedDescription)" 
                            self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                        }
                    } else {
                        print("AuthManager: No UserProfile found for iCloud User \(iCloudRecordName). Creating new UserProfile.")
                        self.createUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                    }
                case .failure(let queryError):
                    print("AuthManager: Error querying UserProfile: \(queryError.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudLoadProfileErrorQuery")): \(queryError.localizedDescription)" 
                    self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func createUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager createUserProfile: iCloud login preference is OFF. Aborting.")
            clearLocalSessionForDisablediCloud(reason: "Profile create called while preference is off.")
            return
        }
        print("AuthManager: Creating new UserProfile linked to iCloud User \(iCloudRecordName) (preference is ON)...")
        let sm = SettingsManager() 

        let newUserProfile = UserProfile(
            iCloudUserRecordName: iCloudRecordName,
            displayName: sm.localizedString(forKey: "defaultPlayerName"), 
            purchasedThemeIDs: Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        )
        
        let newUserProfileCKRecord = newUserProfile.toCKRecord()

        privateDB.save(newUserProfileCKRecord) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager createUserProfile callback: iCloud login preference turned OFF. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during profile creation.")
                    return
                }

                if let error = error {
                    print("AuthManager: Error saving new UserProfile record: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudCreateProfileErrorSave")): \(error.localizedDescription)" 
                    self.currentUser = nil; self.isLoggedIn = false
                    
                    if let ckError = error as? CKError, ckError.code == .constraintViolation {
                        print("AuthManager: Constraint violation while creating UserProfile. Attempting to re-fetch.")
                        self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                        return 
                    }
                    self.isLoading = false
                    return
                }

                if let record = savedRecord, let finalProfile = UserProfile(from: record) {
                    self.currentUser = finalProfile
                    self.isLoggedIn = true
                    print("AuthManager: New UserProfile successfully created and loaded: \(finalProfile.displayName ?? finalProfile.id)")
                } else {
                    print("AuthManager: Failed to create UserProfile from newly saved record, or save did not return a record.")
                    self.errorMessage = sm.localizedString(forKey: "iCloudParseProfileErrorNew") 
                    self.currentUser = nil; self.isLoggedIn = false
                }
                self.isLoading = false
            }
        }
    }
    
    func saveCurrentUserProfile() {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager saveCurrentUserProfile: iCloud login preference is OFF. Cannot save profile.")
            self.errorMessage = localizedErrorMessageForDisablediCloud()
            return
        }

        guard let currentUserProfile = self.currentUser else {
            print("AuthManager: Cannot save profile. No current user.")
            return
        }
        guard iCloudAccountStatus == .available else {
            print("AuthManager: iCloud account not available. Cannot save profile to CloudKit.")
            let sm = SettingsManager()
            self.errorMessage = sm.localizedString(forKey: "iCloudUnavailableCannotSave") 
            return
        }
        guard self.iCloudUserActualRecordID != nil else {
            print("AuthManager: Cannot save profile. iCloudUserActualRecordID is unknown.")
            let sm = SettingsManager()
            self.errorMessage = sm.localizedString(forKey: "iCloudUserIdentityIncomplete") 
            return
        }

        print("AuthManager: Saving current UserProfile (ID: \(currentUserProfile.id)) to CloudKit (preference is ON)...")
        self.isLoading = true
        let sm = SettingsManager() 
        
        let userProfileRecordIDToFetch = CKRecord.ID(recordName: currentUserProfile.id)

        privateDB.fetch(withRecordID: userProfileRecordIDToFetch) { [weak self] (existingRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager saveCurrentUserProfile callback: iCloud login preference turned OFF. Aborting save.")
                    self.isLoading = false 
                    return
                }

                var recordToSave: CKRecord
                if let fetchError = error as? CKError, fetchError.code == .unknownItem {
                    print("AuthManager: UserProfile record (ID: \(currentUserProfile.id)) not found during save. Creating new.")
                    recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                } else if let error = error {
                    print("AuthManager: Error fetching existing record before save: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudSaveProfileErrorFetch")): \(error.localizedDescription)" 
                    self.isLoading = false
                    return
                } else if let fetchedRecord = existingRecord {
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: fetchedRecord)
                } else {
                     print("AuthManager: Unexpected state: no error but no existing record found for ID \(currentUserProfile.id) during save. Creating new.")
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                }

                self.privateDB.save(recordToSave) { (savedRecord, saveError) in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let saveError = saveError {
                            print("AuthManager: Error saving UserProfile to CloudKit: \(saveError.localizedDescription)")
                            self.errorMessage = "\(sm.localizedString(forKey: "iCloudSaveProfileErrorWrite")): \(saveError.localizedDescription)" 
                        } else {
                            print("AuthManager: UserProfile successfully saved to CloudKit.")
                            if let sr = savedRecord, let updatedProfile = UserProfile(from: sr) {
                                if self.currentUser?.recordChangeTag != updatedProfile.recordChangeTag || self.currentUser?.purchasedThemeIDs != updatedProfile.purchasedThemeIDs {
                                    self.currentUser = updatedProfile
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public func refreshAuthenticationState() {
        print("AuthManager: Manually refreshing authentication state...")
        self.iCloudUserActualRecordID = nil 
        checkiCloudAccountStatusAndFetchProfile()
    }

    public func pseudoLogout() { 
        print("AuthManager: Performing pseudo-logout (clearing local app session)...")
        clearLocalSessionForDisablediCloud(reason: "Pseudo-logout called.")
        let sm = SettingsManager()
        self.errorMessage = sm.localizedString(forKey: "loggedOutMessage") 
    }

    func updateUserPurchasedThemes(themeIDs: Set<String>) {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager updateUserPurchasedThemes: iCloud login preference is OFF. Cannot update themes on CloudKit.")
            return
        }

        guard var profileToUpdate = self.currentUser else {
            print("AuthManager: Cannot update purchased themes. No current user (or iCloud disabled).")
            return
        }
        
        if profileToUpdate.purchasedThemeIDs != themeIDs {
            profileToUpdate.purchasedThemeIDs = themeIDs
            self.currentUser = profileToUpdate 
            print("AuthManager: User's purchased themes updated locally. Attempting to save to CloudKit.")
            saveCurrentUserProfile() 
        } else {
            print("AuthManager: No change in purchased themes. Skipping save.")
        }
    }
}

extension CKAccountStatus {
    var description: String { 
        switch self {
        case .couldNotDetermine: return "无法确定 (Could Not Determine)"
        case .available: return "可用 (Available)"
        case .restricted: return "受限 (Restricted)"
        case .noAccount: return "无账户 (No Account)"
        case .temporarilyUnavailable: return "暂时不可用 (Temporarily Unavailable)"
        @unknown default: return "未知状态 (Unknown)"
        }
    }
}


class SettingsManager: ObservableObject {
    @AppStorage("selectedLanguage") var language: String = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "en"
    @AppStorage("isSoundEffectsEnabled") var soundEffectsEnabled: Bool = true
    @AppStorage("isMusicEnabled") var musicEnabled: Bool = true
    @AppStorage("isHapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage(AuthManager.useiCloudLoginKey) var useiCloudLogin: Bool = false // DEFAULT TO FALSE

    private let translations: [String: [String: String]] = [
        "en": [
            "gameTitle": "Klotski", "startGame": "Start Game", "continueGame": "Continue Game",
            "selectLevel": "Select Level", "themes": "Themes", "leaderboard": "Leaderboard",
            "settings": "Settings", "login": "Login", "register": "Register", "logout": "Logout", "confirm": "Confirm",
            "loggedInAs": "Logged in as:", "email": "Email", "password": "Password",
            "displayName": "Display Name", "forgotPassword": "Forgot Password?",
            "signInWithApple": "Sign in with Apple", "cancel": "Cancel", "level": "Level",
            "moves": "Moves", "time": "Time", "noLevels": "No levels available.",
            "themeStore": "Theme Store", "applyTheme": "Apply", "purchase": "Purchase",
            "restorePurchases": "Restore Purchases", "language": "Language",
            "chinese": "简体中文 (Chinese)", "english": "English",
            "soundEffects": "Sound Effects", "music": "Music", "haptics": "Haptics",
            "resetProgress": "Reset Progress",
            "areYouSureReset": "Are you sure you want to reset all game progress? This cannot be undone.",
            "reset": "Reset", "pause": "Pause", "resume": "Resume",
            "backToMenu": "Back to Menu", "victoryTitle": "Congratulations!",
            "victoryMessage": "Level Cleared!", "confirmPassword": "Confirm Password",
            "passwordsDoNotMatch": "Passwords do not match!",
            "useiCloudLogin": "Use iCloud Login", 
            "iCloudLoginDescription": "Enables saving progress, purchases, and leaderboard scores via iCloud. You may need to enable iCloud for Klotski in iPhone Settings.", 
            "iCloudSectionTitle": "iCloud & Account", 
            "purchaseRequiresiCloud": "Purchasing this theme requires iCloud login to be enabled in settings.", 
            "applyPaidThemeRequiresiCloud": "Applying paid themes requires iCloud login to be enabled in settings.", 
            "leaderboardRequiresiCloud": "Leaderboard access and score submission require iCloud login to be enabled in settings.", 
            "iCloudLoginDisabledMessage": "iCloud login is disabled in settings.",
            "openSettings": "Open Settings", 
            "iCloudEnableInstructionTitle": "Enable iCloud for Klotski", 
            "iCloudEnableInstructionMessage": "To use iCloud features, please ensure Klotski is allowed to use iCloud in your iPhone's Settings:\n\n1. Go to Settings > [Your Name] > iCloud.\n2. Scroll down to 'APPS USING ICLOUD' and tap 'Show All'.\n3. Find Klotski and make sure the switch is ON.", 
            "iCloudNoAccount": "Not logged into an iCloud account. Please log in via device settings.",
            "iCloudRestricted": "iCloud account is restricted.",
            "iCloudCouldNotDetermine": "Could not determine iCloud account status.",
            "iCloudTempUnavailable": "iCloud service is temporarily unavailable. Please try again later.",
            "iCloudUnknownStatus": "Unknown iCloud account status.",
            "iCloudFetchUserFailed": "Failed to fetch user identity",
            "iCloudNoUserIdentity": "Failed to retrieve user identity.",
            "iCloudParseProfileErrorExisting": "Failed to parse user information (existing record).",
            "iCloudLoadProfileErrorFetch": "Failed to load user details (fetch error)",
            "iCloudLoadProfileErrorQuery": "Failed to load user information (query error)",
            "defaultPlayerName": "Klotski Player",
            "iCloudCreateProfileErrorSave": "Failed to create user profile (save error)",
            "iCloudParseProfileErrorNew": "Failed to parse user profile after creation.",
            "iCloudUnavailableCannotSave": "iCloud not available. Cannot save user profile.",
            "iCloudUserIdentityIncomplete": "User identity information is incomplete. Cannot save.",
            "iCloudSaveProfileErrorFetch": "Failed to save profile (error fetching existing)",
            "iCloudSaveProfileErrorWrite": "Failed to save user profile (write error)",
            "loggedOutMessage": "You have been signed out from the app.",
            "iCloudCheckingStatus": "Checking iCloud Status...", // For MainMenuView
            "iCloudUser": "iCloud User", // For MainMenuView
            "iCloudNoAccountDetailed": "Not logged into iCloud. Go to device settings to enable cloud features.", // For MainMenuView
            "iCloudConnectionError": "Cannot connect to iCloud.", // For MainMenuView
            "iCloudSyncError": "iCloud available, but app could not sync user data.", // For MainMenuView
            "iCloudLoginPrompt": "iCloud features require login. Check settings.", // For MainMenuView
            "iCloudDisabledInSettings": "iCloud login is disabled. Cloud features are unavailable." // For MainMenuView
        ],
        "zh": [
            "gameTitle": "华容道", "startGame": "开始游戏", "continueGame": "继续游戏",
            "selectLevel": "选择关卡", "themes": "主题", "leaderboard": "排行榜",
            "settings": "设置", "login": "登录", "register": "注册", "logout": "注销", "confirm": "确认",
            "loggedInAs": "已登录:", "email": "邮箱", "password": "密码",
            "displayName": "昵称", "forgotPassword": "忘记密码?",
            "signInWithApple": "通过Apple登录", "cancel": "取消", "level": "关卡",
            "moves": "步数", "time": "时间", "noLevels": "暂无可用关卡。",
            "themeStore": "主题商店", "applyTheme": "应用", "purchase": "购买",
            "restorePurchases": "恢复购买", "language": "语言",
            "chinese": "简体中文", "english": "English (英文)",
            "soundEffects": "音效", "music": "音乐", "haptics": "触感反馈",
            "resetProgress": "重置进度",
            "areYouSureReset": "您确定要重置所有游戏进度吗？此操作无法撤销。",
            "reset": "重置", "pause": "暂停", "resume": "继续",
            "backToMenu": "返回主菜单", "victoryTitle": "恭喜获胜!",
            "victoryMessage": "成功过关!", "confirmPassword": "确认密码",
            "passwordsDoNotMatch": "两次输入的密码不一致！",
            "useiCloudLogin": "使用iCloud登录", 
            "iCloudLoginDescription": "通过iCloud同步游戏进度、购买项目和排行榜记录。您可能需要在iPhone设置中为本App开启iCloud。", 
            "iCloudSectionTitle": "iCloud与账户", 
            "purchaseRequiresiCloud": "购买此主题需要在设置中启用iCloud登录。", 
            "applyPaidThemeRequiresiCloud": "应用付费主题需要在设置中启用iCloud登录。", 
            "leaderboardRequiresiCloud": "访问排行榜及提交记录需要在设置中启用iCloud登录。", 
            "iCloudLoginDisabledMessage": "iCloud登录已在设置中禁用。",
            "openSettings": "打开设置", 
            "iCloudEnableInstructionTitle": "为“华容道”启用iCloud", 
            "iCloudEnableInstructionMessage": "要使用iCloud功能，请确保在您的iPhone设置中允许“华容道”使用iCloud：\n\n1. 前往 设置 > [您的姓名] > iCloud。\n2. 向下滚动到“使用ICLOUD的应用”，并轻点“显示全部”。\n3. 找到“华容道”并确保其开关已打开。", 
            "iCloudNoAccount": "未登录iCloud账户。请在设备设置中登录。",
            "iCloudRestricted": "iCloud账户受限。",
            "iCloudCouldNotDetermine": "无法确定iCloud账户状态。",
            "iCloudTempUnavailable": "iCloud服务暂时不可用，请稍后再试。",
            "iCloudUnknownStatus": "未知的iCloud账户状态。",
            "iCloudFetchUserFailed": "获取用户身份失败",
            "iCloudNoUserIdentity": "未能检索到用户身份。",
            "iCloudParseProfileErrorExisting": "解析用户信息失败（已存在记录）。",
            "iCloudLoadProfileErrorFetch": "加载用户详情失败（获取错误）",
            "iCloudLoadProfileErrorQuery": "加载用户信息失败（查询错误）",
            "defaultPlayerName": "华容道玩家",
            "iCloudCreateProfileErrorSave": "创建用户配置失败（保存错误）",
            "iCloudParseProfileErrorNew": "创建后解析用户配置失败。",
            "iCloudUnavailableCannotSave": "iCloud不可用。无法保存用户配置。",
            "iCloudUserIdentityIncomplete": "用户身份信息不完整。无法保存。",
            "iCloudSaveProfileErrorFetch": "保存配置失败（获取现有配置错误）",
            "iCloudSaveProfileErrorWrite": "保存用户配置失败（写入错误）",
            "loggedOutMessage": "您已从此应用注销。",
            "iCloudCheckingStatus": "正在检查iCloud状态...", // For MainMenuView
            "iCloudUser": "iCloud用户", // For MainMenuView
            "iCloudNoAccountDetailed": "未登录iCloud账户。请前往设备设置登录以使用云功能。", // For MainMenuView
            "iCloudConnectionError": "无法连接到iCloud。", // For MainMenuView
            "iCloudSyncError": "iCloud可用，但应用未能同步用户数据。", // For MainMenuView
            "iCloudLoginPrompt": "iCloud功能需要登录。请检查设置。", // For MainMenuView
            "iCloudDisabledInSettings": "iCloud登录已禁用。云同步功能不可用。" // For MainMenuView
        ]
    ]

    func localizedString(forKey key: String) -> String {
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }
}

struct SoundManager {
    private static var audioPlayer: AVAudioPlayer?
    private static let hapticNotificationGenerator = UINotificationFeedbackGenerator()
    private static let hapticImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    static func playSound(named soundName: String, type: String = "mp3", settings: SettingsManager) {
        guard settings.soundEffectsEnabled else { return }
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

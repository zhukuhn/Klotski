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

        if let savedPiecesData = UserDefaults.standard.data(forKey: savedPiecesKey) {
            do {
                self.pieces = try JSONDecoder().decode([Piece].self, from: savedPiecesData)
                rebuildGameBoard()
                self.isGameActive = true; self.isGameWon = false
                print("继续游戏: \(levelToContinue.name) (索引: \(savedLevelIndex)), 棋子状态已加载。")
                SoundManager.playImpactHaptic(settings: settings)
                if !self.isPaused && !self.isGameWon { startTimer() } // 如果不是暂停状态且未胜利，则启动计时器
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
        UserDefaults.standard.set(isPaused, forKey: savedIsPausedKey)
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
        UserDefaults.standard.removeObject(forKey: savedLevelIndexKey)
        UserDefaults.standard.removeObject(forKey: savedMovesKey)
        UserDefaults.standard.removeObject(forKey: savedTimeKey)
        UserDefaults.standard.removeObject(forKey: savedPiecesKey) // Clear saved pieces
        UserDefaults.standard.removeObject(forKey: savedIsPausedKey)
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

    // MARK: - Initialization
    init(authManager: AuthManager, availableThemes: [Theme] = AppThemeRepository.allThemes) { // 传入可用主题列表
        self.themes = availableThemes // 使用传入的主题列表
        let fallback = Theme(id: "fallback", name: "备用", isPremium: false, backgroundColor: CodableColor(color: .gray), sliderColor: CodableColor(color: .secondary), sliderTextColor: CodableColor(color: .black), boardBackgroundColor: CodableColor(color: .white), boardGridLineColor: CodableColor(color: Color(.systemGray)))
        self.currentTheme = fallback // 'currentTheme' 在此初始化 (备用情况)
        
        // 1. 初始化 purchasedThemeIDs (首先包含所有免费主题)
        var initialPurchasedIDs = Set(availableThemes.filter { !$0.isPremium }.map { $0.id })

        // 2. 如果 AuthManager 已有 currentUser，则合并其 purchasedThemeIDs
        if let userProfile = authManager.currentUser {
            initialPurchasedIDs.formUnion(userProfile.purchasedThemeIDs)
            print("ThemeManager init: Initial purchased IDs from self.purchasedThemeIDs: \(initialPurchasedIDs)")
        }else{
            print("ThemeManager init: AuthManager has not currentUser")
        }
        self.purchasedThemeIDs = initialPurchasedIDs // 'purchasedThemeIDs' 在此初始化
        // print("ThemeManager init: Initial purchased IDs from self.purchasedThemeIDs: \(self.purchasedThemeIDs)")

        // 3. 初始化 currentTheme (基于 UserDefaults 和已购买状态)
        // 必须在 'purchasedThemeIDs' 初始化之后，并且在 'currentTheme' 赋值之前完成此逻辑
        let savedThemeID = UserDefaults.standard.string(forKey: self.currentThemeIDKey)
        var themeToSetAsCurrent: Theme? = nil

        if let themeID = savedThemeID,
           let savedThemeCandidate = self.themes.first(where: { $0.id == themeID }) {
            // [FIXED] 内联检查逻辑，避免在 self 完全初始化前调用实例方法
            if !savedThemeCandidate.isPremium || self.purchasedThemeIDs.contains(savedThemeCandidate.id) {
                themeToSetAsCurrent = savedThemeCandidate
            } else {
                print("ThemeManager init: Saved theme '\(savedThemeCandidate.name)' is no longer purchased. Will use default.")
            }
        }
        
        

        // 'currentTheme' 在此初始化
        if let theme = themeToSetAsCurrent {
            self.currentTheme = theme
            print("ThemeManager init: currentTheme.id is \(theme.id)")
        } else if let defaultLightTheme = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first {
            self.currentTheme = defaultLightTheme
            // 如果之前有保存但无效，或从未保存过，则更新/保存 UserDefaults
            if (savedThemeID != nil && self.currentTheme.id != savedThemeID) || savedThemeID == nil {
                UserDefaults.standard.set(self.currentTheme.id, forKey: self.currentThemeIDKey)
                print("ThemeManager init: Saved theme was invalid or nil. Set current theme to '\(self.currentTheme.name)' and updated UserDefaults.")
            }
        } else {
            print("ThemeManager WARNING: Initialized with a fallback theme. Check AppThemeRepository.allThemes and loading logic.")
        }
        if let userProfile = authManager.currentUser {
            //initialPurchasedIDs.formUnion(userProfile.purchasedThemeIDs)
            print("ThemeManager init: Initial purchased IDs from self.purchasedThemeIDs: \(initialPurchasedIDs)")
        }else{
            print("ThemeManager init: AuthManager has not currentUser")
        }
        // print("ThemeManager init: Final current theme set to '\(self.currentTheme.name)'.")

        // 4. 订阅 AuthManager 的 currentUser 变化 (现在 self 已完全初始化)
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                // print("ThemeManager: AuthManager.currentUser did change. Profile ID: \(userProfile?.id ?? "nil")")
                
                var newPurchasedIDs = Set(self.themes.filter { !$0.isPremium }.map { $0.id })
                if let profile = userProfile {
                    newPurchasedIDs.formUnion(profile.purchasedThemeIDs)
                }
                
                if self.purchasedThemeIDs != newPurchasedIDs {
                    self.purchasedThemeIDs = newPurchasedIDs
                    print("ThemeManager: purchasedThemeIDs updated from AuthManager: \(self.purchasedThemeIDs)")
                    
                    if !self.isThemePurchased(self.currentTheme) { // 现在可以安全调用实例方法
                        if let defaultTheme = self.themes.first(where: { $0.id == "default"}) ?? self.themes.first {
                            self.setCurrentTheme(defaultTheme)
                            print("ThemeManager: Current theme ('\(self.currentTheme.name)') was no longer purchased after auth change, reset to default theme ('\(defaultTheme.name)').")
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func setCurrentTheme(_ theme: Theme) {
        guard themes.contains(where: { $0.id == theme.id }), isThemePurchased(theme) else {
            print("ThemeManager: Attempted to set an invalid or unpurchased theme ('\(theme.name)').")
            if let defaultTheme = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first, isThemePurchased(defaultTheme) {
                 if currentTheme.id != defaultTheme.id {
                    currentTheme = defaultTheme
                    UserDefaults.standard.set(defaultTheme.id, forKey: currentThemeIDKey)
                    print("ThemeManager: Fallback to default theme ('\(defaultTheme.name)') as '\(theme.name)' was invalid/unpurchased.")
                 }
            }
            return
        }

        if currentTheme.id != theme.id {
            currentTheme = theme
            UserDefaults.standard.set(theme.id, forKey: currentThemeIDKey)
            print("ThemeManager: Current theme changed to '\(theme.name)' and saved to UserDefaults.")
        }
    }

    func isThemePurchased(_ theme: Theme) -> Bool {
        return !theme.isPremium || purchasedThemeIDs.contains(theme.id)
    }

    func themeDidGetPurchased(themeID: String, authManager: AuthManager) {
        guard let purchasedThemeObject = themes.first(where: { $0.id == themeID && $0.isPremium }) else {
            print("ThemeManager: Attempted to mark non-existent or free theme ID '\(themeID)' as purchased. Ignoring.")
            return
        }

        if purchasedThemeIDs.insert(themeID).inserted {
            print("ThemeManager: Theme ID '\(themeID)' successfully marked as purchased locally.")
            authManager.updateUserPurchasedThemes(themeIDs: purchasedThemeIDs)
            setCurrentTheme(purchasedThemeObject)
        } else {
            print("ThemeManager: Theme ID '\(themeID)' was already in purchased set.")
        }
    }
    
    func themesDidGetRestored(restoredThemeIDsFromStoreKit: Set<String>, authManager: AuthManager) {
        var didUpdateLocally = false
        var newCombinedPurchasedIDs = self.purchasedThemeIDs

        for themeID in restoredThemeIDsFromStoreKit {
            if let theme = themes.first(where: { $0.id == themeID && $0.isPremium }) {
                if newCombinedPurchasedIDs.insert(theme.id).inserted {
                    didUpdateLocally = true
                    print("ThemeManager: Restored theme ID '\(theme.id)' added to local set.")
                }
            }
        }

        if didUpdateLocally {
            self.purchasedThemeIDs = newCombinedPurchasedIDs
            print("ThemeManager: Purchased themes restored. New local set: \(self.purchasedThemeIDs)")
            authManager.updateUserPurchasedThemes(themeIDs: self.purchasedThemeIDs)
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

    init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        print("AuthManager (CloudKit v2): 初始化完成。") // Chinese log from previous version
        checkiCloudAccountStatusAndFetchProfile()

        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("AuthManager: Received CKAccountChanged notification. Will re-check account status and profile.") // Updated log
                self?.iCloudUserActualRecordID = nil
                self?.currentUser = nil
                self?.isLoggedIn = false
                self?.checkiCloudAccountStatusAndFetchProfile()
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        print("AuthManager (CloudKit v2): Deinitialized.") // Updated log
    }

    // MARK: - iCloud Account Status and User Profile Fetching

    func checkiCloudAccountStatusAndFetchProfile() {
        self.isLoading = true
        self.errorMessage = nil
        print("AuthManager: Checking iCloud account status...")

        container.accountStatus { [weak self] (status, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("AuthManager: Error checking iCloud account status: \(error.localizedDescription)")
                    self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)" // English error
                    self.iCloudAccountStatus = .couldNotDetermine
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                    return
                }

                self.iCloudAccountStatus = status
                print("AuthManager: iCloud Account Status: \(status.description)")

                switch status {
                case .available:
                    self.fetchICloudUserRecordID()
                case .noAccount:
                    self.errorMessage = "Not logged into an iCloud account. Please log in via device settings." // English error
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .restricted:
                    self.errorMessage = "iCloud account is restricted." // English error
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .couldNotDetermine:
                    self.errorMessage = "Could not determine iCloud account status." // English error
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .temporarilyUnavailable:
                    self.errorMessage = "iCloud service is temporarily unavailable. Please try again later." // English error
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                @unknown default:
                    self.errorMessage = "Unknown iCloud account status." // English error
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                }
            }
        }
    }

    private func fetchICloudUserRecordID() {
        print("AuthManager: Attempting to fetch iCloud User Record ID...") // Updated log
        self.isLoading = true
        container.fetchUserRecordID { [weak self] (recordID, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                if let error = error {
                    print("AuthManager: Error fetching iCloud User Record ID: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch user identity: \(error.localizedDescription)" // English error
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                    return
                }

                if let recordID = recordID {
                    print("AuthManager: Successfully fetched iCloud User Record ID: \(recordID.recordName)")
                    self.iCloudUserActualRecordID = recordID
                    self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: recordID.recordName)
                } else {
                    print("AuthManager: No iCloud User Record ID fetched.") // Updated log
                    self.errorMessage = "Failed to retrieve user identity." // English error
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    /// Fetches or creates a UserProfile record linked to the given iCloudUserRecordName.
    private func fetchOrCreateUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        print("AuthManager: Fetching or creating UserProfile for iCloud User \(iCloudRecordName)...") // Updated log
        self.isLoading = true

        let predicate = NSPredicate(format: "iCloudUserRecordName == %@", iCloudRecordName)
        let query = CKQuery(recordType: AuthManager.userProfileRecordType, predicate: predicate)
        
        // [MODIFIED] Using the new fetch API
        privateDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                switch result {
                case .success(let data):
                    // data is (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryCursor?)
                    if let firstMatch = data.matchResults.first {
                        // A record ID matched the query. Now check if the record itself was fetched successfully.
                        let matchedRecordID = firstMatch.0
                        switch firstMatch.1 { // This is Result<CKRecord, Error>
                        case .success(let existingUserProfileRecord):
                            print("AuthManager: Found existing UserProfile record: \(existingUserProfileRecord.recordID.recordName)")
                            if let userProfile = UserProfile(from: existingUserProfileRecord) {
                                self.currentUser = userProfile
                                self.isLoggedIn = true
                                print("AuthManager: UserProfile loaded: \(userProfile.displayName ?? userProfile.id)")
                            } else {
                                print("AuthManager: Failed to parse UserProfile from fetched record (ID: \(matchedRecordID.recordName)). This might indicate a data modeling mismatch.")
                                self.errorMessage = "Failed to parse user information (existing record)." // English error
                                self.currentUser = nil; self.isLoggedIn = false
                            }
                            self.isLoading = false
                        case .failure(let recordFetchError):
                            print("AuthManager: Matched UserProfile ID \(matchedRecordID.recordName), but failed to fetch record: \(recordFetchError.localizedDescription)")
                            self.errorMessage = "Failed to load user details (fetch error): \(recordFetchError.localizedDescription)" // English error
                            self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                        }
                    } else {
                        // No records matched the query, create a new UserProfile.
                        print("AuthManager: No UserProfile found for iCloud User \(iCloudRecordName). Creating new UserProfile.") // Updated log
                        self.createUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                    }
                case .failure(let queryError):
                    print("AuthManager: Error querying UserProfile: \(queryError.localizedDescription)")
                    self.errorMessage = "Failed to load user information (query error): \(queryError.localizedDescription)" // English error
                    self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func createUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        print("AuthManager: Creating new UserProfile linked to iCloud User \(iCloudRecordName)...") // Updated log
        self.isLoading = true

        let newUserProfile = UserProfile(
            iCloudUserRecordName: iCloudRecordName,
            displayName: "Klotski_Auth_1", // Default display name in English
            purchasedThemeIDs: Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        )
        
        let newUserProfileCKRecord = newUserProfile.toCKRecord()

        privateDB.save(newUserProfileCKRecord) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                if let error = error {
                    print("AuthManager: Error saving new UserProfile record: \(error.localizedDescription)")
                    self.errorMessage = "Failed to create user profile (save error): \(error.localizedDescription)" // English error
                    self.currentUser = nil; self.isLoggedIn = false
                    
                    if let ckError = error as? CKError, ckError.code == .constraintViolation {
                        print("AuthManager: Constraint violation while creating UserProfile. Record might already exist due to concurrency. Attempting to re-fetch.")
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
                    self.errorMessage = "Failed to parse user profile after creation." // English error
                    self.currentUser = nil; self.isLoggedIn = false
                }
                self.isLoading = false
            }
        }
    }
    
    func saveCurrentUserProfile() {
        guard let currentUserProfile = self.currentUser else {
            print("AuthManager: Cannot save profile. No current user.")
            return
        }
        guard iCloudAccountStatus == .available else {
            print("AuthManager: iCloud account not available. Cannot save profile to CloudKit.")
            self.errorMessage = "iCloud not available. Cannot save user profile." // English error
            return
        }
        guard self.iCloudUserActualRecordID != nil else {
            print("AuthManager: Cannot save profile. iCloudUserActualRecordID is unknown.")
            self.errorMessage = "User identity information is incomplete. Cannot save." // English error
            return
        }

        print("AuthManager: Saving current UserProfile (ID: \(currentUserProfile.id)) to CloudKit...")
        self.isLoading = true
        
        let userProfileRecordIDToFetch = CKRecord.ID(recordName: currentUserProfile.id)

        privateDB.fetch(withRecordID: userProfileRecordIDToFetch) { [weak self] (existingRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                var recordToSave: CKRecord
                if let fetchError = error as? CKError, fetchError.code == .unknownItem {
                    // Record doesn't exist, which is unexpected if currentUserProfile.id is valid.
                    // This might happen if the record was deleted externally. We'll create it.
                    print("AuthManager: UserProfile record (ID: \(currentUserProfile.id)) not found during save. Creating new.")
                    recordToSave = currentUserProfile.toCKRecord(existingRecord: nil) // Pass nil to create new
                } else if let error = error {
                    print("AuthManager: Error fetching existing record before save: \(error.localizedDescription)")
                    self.errorMessage = "Failed to save profile (error fetching existing): \(error.localizedDescription)" // English error
                    self.isLoading = false
                    return
                } else if let fetchedRecord = existingRecord {
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: fetchedRecord)
                } else {
                    // Should not happen if error is nil and existingRecord is nil
                     print("AuthManager: Unexpected state: no error but no existing record found for ID \(currentUserProfile.id) during save. Creating new.")
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                }


                self.privateDB.save(recordToSave) { (savedRecord, saveError) in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let saveError = saveError {
                            print("AuthManager: Error saving UserProfile to CloudKit: \(saveError.localizedDescription)")
                            self.errorMessage = "Failed to save user profile (write error): \(saveError.localizedDescription)" // English error
                        } else {
                            print("AuthManager: UserProfile successfully saved to CloudKit.")
                            if let sr = savedRecord, let updatedProfile = UserProfile(from: sr) {
                                self.currentUser = updatedProfile
                            }
                        }
                    }
                }
            }
        }
    }

    public func refreshAuthenticationState() {
        print("AuthManager: Manually refreshing authentication state...") // Updated log
        self.iCloudUserActualRecordID = nil
        self.currentUser = nil
        self.isLoggedIn = false
        checkiCloudAccountStatusAndFetchProfile()
    }

    public func pseudoLogout() {
        print("AuthManager: Performing pseudo-logout (clearing local session)...")
        DispatchQueue.main.async {
            self.currentUser = nil
            self.iCloudUserActualRecordID = nil
            self.isLoggedIn = false
            self.errorMessage = "You have been signed out from the app." // English error
            self.objectWillChange.send()
        }
    }

    func updateUserPurchasedThemes(themeIDs: Set<String>) {
        guard var profileToUpdate = self.currentUser else {
            print("AuthManager: Cannot update purchased themes. No current user.")
            self.errorMessage = "User not logged in. Cannot update purchased themes." // English error
            return
        }
        
        profileToUpdate.purchasedThemeIDs = themeIDs
        self.currentUser = profileToUpdate
        saveCurrentUserProfile()
    }
}

extension CKAccountStatus {
    var description: String {
        switch self {
        case .couldNotDetermine: return "无法确定"
        case .available: return "可用"
        case .restricted: return "受限"
        case .noAccount: return "无账户"
        case .temporarilyUnavailable: return "暂时不可用"
        @unknown default: return "未知状态"
        }
    }
}

// 在 KlotskiApp.swift 中传递 window 给 AuthManager
// KlotskiApp.swift
// ...
// .onReceive(NotificationCenter.default.publisher(for: UIWindow.didBecomeKeyNotification)) { notification in
//     if let window = notification.object as? UIWindow {
//         authManager.currentWindow = window
//         print("AuthManager currentWindow set.")
//     }
// }
// ...


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
            "victoryMessage": "Level Cleared!",
            "confirmPassword": "Confirm Password",
            "passwordsDoNotMatch": "Passwords do not match!"

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
            "confirmPassword": "确认密码",
            "passwordsDoNotMatch": "两次输入的密码不一致！"
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

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
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

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
    // MARK: - Static Properties
    static let defaultThemes: [Theme] = [
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

    // MARK: - Published Properties
    @Published var themes: [Theme]
    @Published var currentTheme: Theme
    @Published var purchasedThemeIDs: Set<String> // No default here, will be set in init

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let currentThemeIDKey = "currentThemeID_klotski_v2"

    // MARK: - Initialization
    init(authManager: AuthManager) {
        // --- Phase 1: Initialize all stored properties of this class ---

        // Step 1: Initialize `themes` from the static source.
        let localDefaultThemes = ThemeManager.defaultThemes
        self.themes = localDefaultThemes

        // Step 2: Calculate and initialize `purchasedThemeIDs`.
        // Use `localDefaultThemes` instead of `self.themes` here to avoid any ambiguity for the compiler.
        var calculatedPurchasedIDs = Set(localDefaultThemes.filter { !$0.isPremium }.map { $0.id })
        if let userProfile = authManager.currentUser {
            calculatedPurchasedIDs.formUnion(userProfile.purchasedThemeIDs)
        }
        self.purchasedThemeIDs = calculatedPurchasedIDs // `purchasedThemeIDs` is now initialized.

        // Step 3: Calculate and initialize `currentTheme`.
        // This logic also uses `localDefaultThemes` and `calculatedPurchasedIDs` to avoid early `self` access issues.
        let savedThemeID = UserDefaults.standard.string(forKey: self.currentThemeIDKey) // Accessing `self.currentThemeIDKey` (a let constant) is fine.
        var themeToSetAsCurrent: Theme? = nil

        if let themeID = savedThemeID,
           let savedThemeCandidate = localDefaultThemes.first(where: { $0.id == themeID }) {
            // Check if this savedThemeCandidate is "purchased" based on `calculatedPurchasedIDs`
            let isSavedThemeCandidatePurchased = !savedThemeCandidate.isPremium || calculatedPurchasedIDs.contains(savedThemeCandidate.id)
            if isSavedThemeCandidatePurchased {
                themeToSetAsCurrent = savedThemeCandidate
            }
        }

        if let theme = themeToSetAsCurrent {
            self.currentTheme = theme
        } else if let defaultLightTheme = localDefaultThemes.first(where: { $0.id == "default" }) ?? localDefaultThemes.first {
            self.currentTheme = defaultLightTheme
            // If we fell back to default, ensure UserDefaults reflects this if a savedThemeID existed but was invalid
             if savedThemeID != nil && self.currentTheme.id != savedThemeID {
                 UserDefaults.standard.set(self.currentTheme.id, forKey: self.currentThemeIDKey)
             }
        } else {
            // Fallback if defaultThemes is empty or "default" theme is missing.
            let fallback = Theme(id: "fallback", name: "备用", isPremium: false, backgroundColor: CodableColor(color: .gray), sliderColor: CodableColor(color: .secondary), sliderTextColor: CodableColor(color: .black), boardBackgroundColor: CodableColor(color: .white), boardGridLineColor: CodableColor(color: Color(.systemGray)))
            self.currentTheme = fallback
            print("CRITICAL WARNING: ThemeManager initialized with a fallback theme. Check defaultThemes and loading logic.")
        }
        // All stored properties (`themes`, `purchasedThemeIDs`, `currentTheme`, `cancellables`, `currentThemeIDKey`) are NOW initialized.
        // Phase 1 is complete.

        // --- Phase 2: `self` is now fully available ---
        print("ThemeManager initialized. Current theme: '\(self.currentTheme.name)'. Purchased IDs: \(self.purchasedThemeIDs)")

        // Setup Combine subscription to listen for changes in AuthManager's currentUser.
        authManager.$currentUser
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                
                var newPurchasedIDsOnAuthChange = Set(self.themes.filter { !$0.isPremium }.map { $0.id })
                
                if let profile = userProfile {
                    newPurchasedIDsOnAuthChange.formUnion(profile.purchasedThemeIDs)
                }
                
                if self.purchasedThemeIDs != newPurchasedIDsOnAuthChange {
                    self.purchasedThemeIDs = newPurchasedIDsOnAuthChange
                    print("ThemeManager: purchasedThemeIDs updated due to auth change: \(self.purchasedThemeIDs)")
                    
                    if !self.isThemePurchased(self.currentTheme) { // Now `self.isThemePurchased` can be safely called.
                        if let defaultTheme = self.themes.first(where: { $0.id == "default"}) ?? self.themes.first {
                            self.setCurrentTheme(defaultTheme) // `self.setCurrentTheme` can also be safely called.
                            print("ThemeManager: Current theme ('\(self.currentTheme.name)') was no longer purchased after auth change, reset to default theme ('\(defaultTheme.name)').")
                        }
                    }
                }
            }
            .store(in: &cancellables) // `self.cancellables` is fine to access here.
    }

    // MARK: - Public Methods
    func setCurrentTheme(_ theme: Theme) {
        guard themes.contains(where: { $0.id == theme.id }), isThemePurchased(theme) else {
            print("ThemeManager: Attempted to set an invalid or unpurchased theme ('\(theme.name)'). Ignoring.")
            if let defaultTheme = self.themes.first(where: { $0.id == "default"}) ?? self.themes.first, isThemePurchased(defaultTheme) {
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

    func themePurchased(themeID: String, authManager: AuthManager) {
        guard let purchasedThemeObject = themes.first(where: { $0.id == themeID && $0.isPremium }) else {
            print("ThemeManager: Attempted to mark non-existent or free theme ID '\(themeID)' as purchased. Ignoring.")
            return
        }

        if purchasedThemeIDs.insert(themeID).inserted {
            print("ThemeManager: Theme ID '\(themeID)' successfully marked as purchased locally.")
            if authManager.isLoggedIn {
                authManager.updateUserPurchasedThemes(themeIDs: purchasedThemeIDs)
            } else {
                print("ThemeManager: Theme '\(themeID)' purchased by a non-logged-in user. State updated locally. Consider prompting user to sign in to sync purchases.")
            }
            setCurrentTheme(purchasedThemeObject)
        } else {
            print("ThemeManager: Theme ID '\(themeID)' was already in purchased set. No local change needed.")
        }
    }
    
    func themesRestored(restoredThemeIDsFromStoreKit: Set<String>, authManager: AuthManager) {
        var didUpdate = false
        for themeID in restoredThemeIDsFromStoreKit {
            if let theme = themes.first(where: { $0.id == themeID && $0.isPremium }) {
                if purchasedThemeIDs.insert(theme.id).inserted {
                    didUpdate = true
                    print("ThemeManager: Restored theme ID '\(theme.id)' added to local purchased set.")
                }
            }
        }

        if didUpdate {
            print("ThemeManager: Purchased themes restored. New local set: \(purchasedThemeIDs)")
            if authManager.isLoggedIn {
                authManager.updateUserPurchasedThemes(themeIDs: purchasedThemeIDs)
            } else {
                print("ThemeManager: Themes restored for non-logged-in user. State updated locally. Consider prompting to sign in.")
            }
        } else {
            print("ThemeManager: No new themes were added from restoration, or restored IDs were not valid premium themes.")
        }
    }
}

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false // 用于指示认证操作是否正在进行
    @Published var errorMessage: String? // 用于向 UI 显示认证错误信息

    private var db = Firestore.firestore()
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    init() {
        listenToAuthState()
        print("AuthManager initialized.")
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
            print("Auth state listener removed.")
        }
    }

    /// 监听 Firebase Auth 状态变化
    private func listenToAuthState() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            self.isLoading = true // 开始加载状态
            self.errorMessage = nil

            if let firebaseUser = user {
                print("User is signed in with UID: \(firebaseUser.uid)")
                // 用户已登录，从 Firestore 获取 UserProfile
                self.fetchUserProfile(uid: firebaseUser.uid) { profile in
                    self.currentUser = profile
                    self.isLoggedIn = (profile != nil)
                    self.isLoading = false
                    if profile == nil {
                        print("AuthManager: User signed in but profile not found for UID: \(firebaseUser.uid). This might happen if profile creation failed after registration.")
                        // 这种情况可能需要特殊处理，例如尝试重新创建 Profile 或提示用户
                    } else {
                        print("AuthManager: UserProfile loaded for \(profile?.displayName ?? "N/A")")
                    }
                }
            } else {
                print("User is signed out.")
                self.currentUser = nil
                self.isLoggedIn = false
                self.isLoading = false
            }
        }
    }

    /// 从 Firestore 获取用户配置信息
    private func fetchUserProfile(uid: String, completion: @escaping (UserProfile?) -> Void) {
        let userDocRef = db.collection("users").document(uid)
        userDocRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                self.errorMessage = "无法加载用户信息: \(error.localizedDescription)"
                completion(nil)
                return
            }
            
            let result = Result {
                try document?.data(as: UserProfile.self)
            }
            switch result {
            case .success(let userProfile):
                if let profile = userProfile {
                    print("Successfully fetched user profile for UID: \(uid)")
                    completion(profile)
                } else {
                    print("User profile document does not exist for UID: \(uid) (or failed to decode)")
                    // 这可能发生在用户通过 Firebase Auth 注册，但 Firestore 文档创建失败的情况
                    completion(nil)
                }
            case .failure(let error):
                print("Error decoding user profile: \(error.localizedDescription)")
                self.errorMessage = "解析用户信息失败: \(error.localizedDescription)"
                // 如果是因为文档不存在而解码失败，错误类型可能是 `DecodingError.valueNotFound`
                // FirestoreSwift 的 `data(as:)` 在文档不存在时会返回 nil，然后尝试解包 nil 会导致错误
                // 更稳妥的做法是先检查 document?.exists
                if let document = document, !document.exists {
                     print("Document for UID \(uid) does not exist.")
                }
                completion(nil)
            }
        }
    }

    /// 创建或更新 Firestore 中的用户配置信息
    private func updateUserProfileInFirestore(userProfile: UserProfile) {
        let documentID = userProfile.uid
        do {
            // 使用 userProfile.uid 作为文档 ID
            try db.collection("users").document(documentID).setData(from: userProfile, merge: true) { error in
                if let error = error {
                    print("Error writing user profile to Firestore: \(error.localizedDescription)")
                    self.errorMessage = "保存用户信息失败: \(error.localizedDescription)"
                } else {
                    print("UserProfile successfully written to Firestore for UID: \(documentID)")
                }
            }
        } catch {
            print("Error encoding user profile for Firestore: \(error.localizedDescription)")
            self.errorMessage = "编码用户信息失败: \(error.localizedDescription)"
        }
    }

    /// 邮箱密码注册
    func register(email: String, pass: String, displayName: String) {
        self.isLoading = true
        self.errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: pass) { [weak self] (authResult, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error registering user: \(error.localizedDescription)")
                self.errorMessage = "注册失败: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            guard let firebaseUser = authResult?.user else {
                print("Registration successful, but no user object returned.")
                self.errorMessage = "注册成功但无法获取用户信息。"
                self.isLoading = false
                return
            }
            print("User registered successfully with UID: \(firebaseUser.uid)")
            // 创建 UserProfile 并保存到 Firestore
            let newUserProfile = UserProfile(
                uid: firebaseUser.uid, // 使用 Firebase Auth UID
                displayName: displayName,
                email: email,
                purchasedThemeIDs: Set(ThemeManager.defaultThemes.filter { !$0.isPremium }.map { $0.id }), // 默认拥有免费主题
                registrationDate: Date()
            )
            // 注意：此时 newUserProfile.id (来自 @DocumentID) 还是 nil，
            // updateUserProfileInFirestore 会使用 uid 作为文档 ID
            self.updateUserProfileInFirestore(userProfile: newUserProfile)
            // AuthStateDidChangeListener 会自动处理 currentUser 和 isLoggedIn 的更新
            // self.isLoading 会在 listener 中被设为 false
        }
    }

    /// 邮箱密码登录
    func login(email: String, pass: String) {
        self.isLoading = true
        self.errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: pass) { [weak self] (authResult, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error signing in user: \(error.localizedDescription)")
                self.errorMessage = "登录失败: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            print("User signed in successfully.")
            // AuthStateDidChangeListener 会自动处理 currentUser 和 isLoggedIn 的更新
            // self.isLoading 会在 listener 中被设为 false
        }
    }

    /// 注销
    func logout() {
        self.isLoading = true // 虽然注销很快，但保持一致性
        self.errorMessage = nil
        do {
            try Auth.auth().signOut()
            print("User signed out successfully.")
            // AuthStateDidChangeListener 会自动处理 currentUser 和 isLoggedIn 的更新
            // self.isLoading 会在 listener 中被设为 false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.errorMessage = "注销失败: \(signOutError.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // --- Sign in with Apple ---
    // 当前窗口，用于 Sign in with Apple 的 presentationContextProvider
    // 你需要从你的 App Scene 中获取这个 window
    // 例如，在 KlotskiApp.swift 中：
    // .onReceive(NotificationCenter.default.publisher(for: UIWindow.didBecomeKeyNotification)) { notification in
    //     if let window = notification.object as? UIWindow {
    //         authManager.currentWindow = window // 假设 authManager 是全局可访问的
    //     }
    // }
    weak var currentWindow: UIWindow?
    private var currentNonce: String? // 用于 Sign in with Apple

    // 准备 Sign in with Apple 请求
    func createAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email] // 请求用户全名和邮箱

        let nonce = randomNonceString() // 生成一个随机字符串作为 nonce
        currentNonce = nonce
        request.nonce = sha256(nonce) // SHA256 哈希处理 nonce

        return request
    }
    
    // 处理 Sign in with Apple 成功回调
    func handleAppleSignIn(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Error: Unable to get Apple ID Credential.")
            self.errorMessage = "Apple 登录凭证错误。"
            return
        }
        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token.")
            self.errorMessage = "无法获取 Apple ID Token。"
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            self.errorMessage = "无法序列化 Apple ID Token。"
            return
        }

        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: appleIDCredential.fullName)
        self.isLoading = true
        self.errorMessage = nil
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error signing in with Apple: \(error.localizedDescription)")
                self.errorMessage = "Apple 登录失败: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                print("Apple Sign In successful, but no user object returned.")
                self.errorMessage = "Apple 登录成功但无法获取用户信息。"
                self.isLoading = false
                return
            }
            print("User signed in with Apple successfully. UID: \(firebaseUser.uid)")

            // 检查 Firestore 中是否已存在该用户的 Profile
            // 如果是首次通过 Apple 登录，需要创建新的 UserProfile
            let userDocRef = self.db.collection("users").document(firebaseUser.uid)
            userDocRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    // Profile 已存在，AuthStateDidChangeListener 会处理加载
                    print("Apple user profile already exists.")
                    // self.isLoading 会在 listener 中被设为 false
                } else {
                    // Profile 不存在，创建新的
                    print("Apple user profile does not exist. Creating new one.")
                    let displayName = appleIDCredential.fullName?.givenName // 可能为空
                    let email = appleIDCredential.email // 首次登录时可能有，后续可能为空
                    
                    let newUserProfile = UserProfile(
                        uid: firebaseUser.uid,
                        displayName: displayName,
                        email: email,
                        purchasedThemeIDs: Set(ThemeManager.defaultThemes.filter { !$0.isPremium }.map { $0.id }),
                        registrationDate: Date()
                    )
                    self.updateUserProfileInFirestore(userProfile: newUserProfile)
                    // self.isLoading 会在 listener 中被设为 false
                }
            }
        }
    }
    
    // 处理 Sign in with Apple 失败回调
    func handleAppleSignInError(error: Error) {
        print("Sign in with Apple failed: \(error.localizedDescription)")
        self.errorMessage = "Apple 登录失败: \(error.localizedDescription)"
        self.isLoading = false
    }

    // Helper for Sign in with Apple nonce
    private func randomNonceString(length: Int = 32) -> String {
        // ... (实现见 Firebase 文档或网络示例) ...
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        // ... (实现见 Firebase 文档或网络示例) ...
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // 新增：用于更新用户已购买的主题列表到 Firestore
    func updateUserPurchasedThemes(themeIDs: Set<String>) {
        guard let uid = currentUser?.uid else {
            print("Cannot update purchased themes: User not logged in or UID missing.")
            return
        }
        guard var updatedProfile = currentUser else { return } // 获取当前用户信息的副本
        
        updatedProfile.purchasedThemeIDs = themeIDs // 更新副本中的主题ID

        db.collection("users").document(uid).updateData([
            "purchasedThemeIDs": Array(themeIDs) // Firestore Set 通常存储为 Array
        ]) { [weak self] error in
            if let error = error {
                print("Error updating purchased themes in Firestore: \(error.localizedDescription)")
                self?.errorMessage = "更新已购主题失败: \(error.localizedDescription)"
            } else {
                print("Successfully updated purchased themes in Firestore for UID: \(uid)")
                // 本地 currentUser 也需要更新，以确保 UI 立即响应
                // AuthStateChangeListener 理论上不应该因为这个字段的更新而重新获取整个 profile，
                // 所以这里手动更新本地副本。
                self?.currentUser?.purchasedThemeIDs = themeIDs
                self?.objectWillChange.send() // 手动通知 SwiftUI 视图更新
            }
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

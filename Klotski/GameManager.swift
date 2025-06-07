//
//  GameManeger.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI
import AVFoundation
import UIKit
import Combine
import CloudKit
import GameKit
import StoreKit

// MARK: - GameManager
class GameManager: ObservableObject {
    @Published var currentLevel: Level?
    @Published var currentLevelIndex: Int?
    @Published var pieces: [Piece] = []
    @Published var gameBoard: [[Int?]] = []
    
    static let classicLevel = Level(
        id: "classic_hdml", name: "横刀立马", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0), PiecePlacement(id: 2, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 3, type: .zhangFeiV, initialX: 0, initialY: 0), PiecePlacement(id: 4, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 5, type: .maChaoV, initialX: 0, initialY: 2), PiecePlacement(id: 6, type: .huangZhongV, initialX: 3, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3), PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 0, initialY: 4), PiecePlacement(id: 10, type: .soldier, initialX: 3, initialY: 4)
        ], targetPieceId: 1, targetX: 1, targetY: 3
    )
    static let easyExitLevel = Level(
        id: "easy_exit", name: "兵临城下", boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 1, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 2, type: .soldier, initialX: 0, initialY: 0), PiecePlacement(id: 3, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .soldier, initialX: 1, initialY: 2), PiecePlacement(id: 5, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .guanYuH, initialX: 1, initialY: 3)
        ], targetPieceId: 1, targetX: 1, targetY: 3
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
    
    @Published var levels: [Level] = [classicLevel, easyExitLevel, verticalChallengeLevel]
    
    @Published var moves: Int = 0
    @Published var timeElapsed: TimeInterval = 0 // TimeInterval is Double, suitable for precision
    @Published var isGameActive: Bool = false
    @Published var hasSavedGame: Bool = false
    @Published var isGameWon: Bool = false
    @Published var isPaused: Bool = false

    private var timerSubscription: Cancellable?
    private var lastTimerFireDate: Date? // To calculate precise time delta
    private let timerInterval: TimeInterval = 0.01 // Update every 0.01 seconds for centisecond precision

    private var cancellables = Set<AnyCancellable>()

    private let privateDB = CKContainer.default().privateCloudDatabase
    private var authManager: AuthManager?
    private var settingsManager: SettingsManager?

    private let savedInProgressLevelIDKey = "savedKlotskiInProgressLevelID"
    private let savedInProgressMovesKey = "savedKlotskiInProgressMoves"
    private let savedInProgressTimeKey = "savedKlotskiInProgressTime" // This will store TimeInterval (Double)
    private let savedInProgressPiecesKey = "savedKlotskiInProgressPieces"
    private let savedInProgressLevelIndexKey = "savedKlotskiInProgressLevelIndex"
    private let savedInProgressIsPausedKey = "savedKlotskiInProgressIsPaused"

    init() {
        let levelID = UserDefaults.standard.string(forKey: savedInProgressLevelIDKey)
        let piecesData = UserDefaults.standard.data(forKey: savedInProgressPiecesKey)
        let movesDataExists = UserDefaults.standard.object(forKey: savedInProgressMovesKey) != nil
        // For time, we now directly store TimeInterval (Double)
        let timeDataExists = UserDefaults.standard.object(forKey: savedInProgressTimeKey) != nil
        let levelIndexExists = UserDefaults.standard.object(forKey: savedInProgressLevelIndexKey) != nil
        let isPausedDataExists = UserDefaults.standard.object(forKey: savedInProgressIsPausedKey) != nil

        if levelID != nil, piecesData != nil, movesDataExists, timeDataExists, levelIndexExists, isPausedDataExists {
            hasSavedGame = true
        } else {
            hasSavedGame = false
            clearSavedGame() 
        }
        print("GameManager init: Local in-progress save check complete. hasSavedGame = \(hasSavedGame)")
    }

    func setupDependencies(authManager: AuthManager, settingsManager: SettingsManager) {
        self.authManager = authManager
        self.settingsManager = settingsManager

        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                if userProfile != nil && settingsManager.useiCloudLogin {
                    print("GameManager: User logged in. Fetching best scores from CloudKit.")
                    Task { await self.fetchBestScoresFromCloud() }
                } else if userProfile == nil {
                    print("GameManager: User logged out. Cloud scores will not be fetched/synced.")
                }
            }
            .store(in: &cancellables)

        if authManager.isLoggedIn && settingsManager.useiCloudLogin {
            print("GameManager: Initial setup with logged-in user. Fetching best scores.")
            Task { await self.fetchBestScoresFromCloud() }
        }
    }
    
    func startGame(level: Level, settings: SettingsManager, isNewSession: Bool = true) {
        currentLevel = level
        currentLevelIndex = levels.firstIndex(where: { $0.id == level.id })

        if isNewSession {
            moves = 0
            timeElapsed = 0.0 // Reset with double
            isPaused = true 
        }
        
        isGameActive = true
        isGameWon = false
        
        pieces = level.piecePlacements.map { Piece(id: $0.id, type: $0.type, x: $0.initialX, y: $0.initialY) }
        rebuildGameBoard()
        print("游戏开始/切换到: \(level.name), isPaused: \(isPaused)")
        SoundManager.playImpactHaptic(settings: settings)
        
        if !isPaused && !isGameWon { startTimer() } else { stopTimer() }
    }

    func switchToLevel(at index: Int, settings: SettingsManager) {
        guard index >= 0 && index < levels.count else { return }
        let newLevel = levels[index]
        
        moves = 0
        timeElapsed = 0.0 // Reset with double
        isPaused = false 
        isGameWon = false
        
        stopTimer() 
        startGame(level: newLevel, settings: settings, isNewSession: false) 
        clearSavedGameForCurrentLevelOnly()
    }

    func pauseGame() {
        guard isGameActive && !isGameWon else { return }
        if !isPaused {
            isPaused = true
            stopTimer() // Stops the timer and records the current timeElapsed
            print("游戏已暂停。时间: \(formattedTime(timeElapsed))")
        }
    }

    func resumeGame(settings: SettingsManager) {
        guard isGameActive && !isGameWon else { return }
        if isPaused {
            isPaused = false
            startTimer() // Restarts the timer
            SoundManager.playImpactHaptic(settings: settings)
            print("游戏已继续。")
        }
    }

    func startTimer() {
        stopTimer() 
        guard isGameActive && !isPaused && !isGameWon else { return }
        
        lastTimerFireDate = Date() // Set the initial fire date
        timerSubscription = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentDate in
                guard let self = self, let lastFire = self.lastTimerFireDate else { return }
                let interval = currentDate.timeIntervalSince(lastFire)
                self.timeElapsed += interval
                self.lastTimerFireDate = currentDate // Update for the next interval
            }
        print("计时器已启动 (间隔: \(timerInterval)s)。")
    }

    func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
        lastTimerFireDate = nil // Clear the last fire date
        print("计时器已停止。当前累计时间: \(timeElapsed)")
    }
    
    func attemptMove(pieceId: Int, dx: Int, dy: Int, settings: SettingsManager) -> Bool {
        guard isGameActive && !isPaused && !isGameWon,
              let level = currentLevel,
              var pieceToMove = pieces.first(where: { $0.id == pieceId }),
              (dx != 0 || dy != 0) else {
            return false
        }
        
        let originalX = pieceToMove.x
        let originalY = pieceToMove.y
        let newX = originalX + dx
        let newY = originalY + dy
        
        guard newX >= 0, newX + pieceToMove.width <= level.boardWidth,
              newY >= 0, newY + pieceToMove.height <= level.boardHeight else {
            return false
        }
        
        for r in 0..<pieceToMove.height {
            for c in 0..<pieceToMove.width {
                if let occupyingPieceId = gameBoard[newY + r][newX + c], occupyingPieceId != pieceId {
                    return false
                }
            }
        }
        
        for r in 0..<pieceToMove.height { for c in 0..<pieceToMove.width { gameBoard[originalY + r][originalX + c] = nil } }
        for r in 0..<pieceToMove.height { for c in 0..<pieceToMove.width { gameBoard[newY + r][newX + c] = pieceId } }
        
        if let index = pieces.firstIndex(where: { $0.id == pieceId }) {
            pieces[index].x = newX
            pieces[index].y = newY
            pieceToMove = pieces[index]
        }
        
        moves += 1 
        print("棋子 \(pieceId) 移动到 (\(newX), \(newY))，当前步数: \(moves)")
        
        checkWinCondition(movedPiece: pieceToMove, settings: settings)
        
        if isGameActive && !isGameWon {
            saveGame(settings: settings)
        }
        return true
    }
    
    func canMove(pieceId: Int, currentGridX: Int, currentGridY: Int, deltaX: Int, deltaY: Int) -> Bool {
        guard let level = currentLevel, let pieceToMove = pieces.first(where: { $0.id == pieceId }) else {
            return false
        }
        if deltaX == 0 && deltaY == 0 { return true }
        
        let newX = currentGridX + deltaX
        let newY = currentGridY + deltaY
        
        guard newX >= 0, newX + pieceToMove.width <= level.boardWidth,
              newY >= 0, newY + pieceToMove.height <= level.boardHeight else {
            return false 
        }
        
        for r_offset in 0..<pieceToMove.height {
            for c_offset in 0..<pieceToMove.width {
                let targetBoardY = newY + r_offset
                let targetBoardX = newX + c_offset
                if let occupyingPieceId = gameBoard[targetBoardY][targetBoardX], occupyingPieceId != pieceId {
                    return false 
                }
            }
        }
        return true
    }
    
    func checkWinCondition(movedPiece: Piece, settings: SettingsManager) {
        guard let level = currentLevel, !isGameWon else { return }
        if movedPiece.id == level.targetPieceId && movedPiece.x == level.targetX && movedPiece.y == level.targetY {
            isGameWon = true
            stopTimer() // Final timeElapsed recorded here
            print("恭喜！关卡 \(level.name) 完成！总步数: \(moves), 时间: \(formattedTime(timeElapsed))") // formattedTime will show precision
            SoundManager.playSound(named: "victory_fanfare", settings: settings)
            SoundManager.playHapticNotification(type: .success, settings: settings)
            
            updateAndSyncBestScore(levelId: level.id, currentMoves: moves, currentTime: timeElapsed)
            submitScoreToLeaderboard(levelID: level.id, moves: moves, time: timeElapsed) // Submit precise time
            
            clearSavedGameForCurrentLevelOnly()
        }
    }
    
    func continueGame(settings: SettingsManager) {
        guard let savedLevelID = UserDefaults.standard.string(forKey: savedInProgressLevelIDKey),
              let savedLevelIndex = UserDefaults.standard.object(forKey: savedInProgressLevelIndexKey) as? Int,
              savedLevelIndex >= 0 && savedLevelIndex < levels.count,
              let levelToContinue = levels.first(where: { $0.id == savedLevelID }),
              UserDefaults.standard.object(forKey: savedInProgressPiecesKey) != nil,
              UserDefaults.standard.object(forKey: savedInProgressMovesKey) != nil,
              UserDefaults.standard.object(forKey: savedInProgressTimeKey) != nil, // Time is Double
              UserDefaults.standard.object(forKey: savedInProgressIsPausedKey) != nil
        else {
            print("继续游戏失败：未找到有效或完整的本地存档。")
            clearSavedGame(); hasSavedGame = false; return
        }
        
        self.currentLevel = levelToContinue
        self.currentLevelIndex = savedLevelIndex
        self.moves = UserDefaults.standard.integer(forKey: savedInProgressMovesKey)
        self.timeElapsed = UserDefaults.standard.double(forKey: savedInProgressTimeKey) // Load Double
        self.isPaused = UserDefaults.standard.bool(forKey: savedInProgressIsPausedKey)

        if let savedPiecesData = UserDefaults.standard.data(forKey: savedInProgressPiecesKey) {
            do {
                self.pieces = try JSONDecoder().decode([Piece].self, from: savedPiecesData)
                rebuildGameBoard()
                self.isGameActive = true; self.isGameWon = false
                print("继续游戏: \(levelToContinue.name), 本地存档已加载, isPaused: \(self.isPaused)")
                if !self.isPaused && !self.isGameWon { startTimer() }
                else { stopTimer() } 
            } catch {
                print("错误：无法解码已保存的本地棋子状态: \(error)。")
                clearSavedGame(); hasSavedGame = false; isGameActive = false
            }
        }
    }
    
    func saveGame(settings: SettingsManager) { 
        guard let currentLevel = currentLevel, let currentIndex = currentLevelIndex, isGameActive && !isGameWon else {
            return
        }
        UserDefaults.standard.set(currentLevel.id, forKey: savedInProgressLevelIDKey)
        UserDefaults.standard.set(currentIndex, forKey: savedInProgressLevelIndexKey)
        UserDefaults.standard.set(moves, forKey: savedInProgressMovesKey)
        UserDefaults.standard.set(timeElapsed, forKey: savedInProgressTimeKey) // Save Double
        UserDefaults.standard.set(isPaused, forKey: savedInProgressIsPausedKey)
        do {
            let encodedPieces = try JSONEncoder().encode(pieces)
            UserDefaults.standard.set(encodedPieces, forKey: savedInProgressPiecesKey)
            hasSavedGame = true
            print("游戏进行中状态已保存到本地: \(currentLevel.name)")
        } catch {
            print("错误：无法编码并保存本地棋子状态: \(error)")
            hasSavedGame = false
        }
    }
    
    func clearSavedGame() { 
        UserDefaults.standard.removeObject(forKey: savedInProgressLevelIDKey)
        UserDefaults.standard.removeObject(forKey: savedInProgressLevelIndexKey)
        UserDefaults.standard.removeObject(forKey: savedInProgressMovesKey)
        UserDefaults.standard.removeObject(forKey: savedInProgressTimeKey)
        UserDefaults.standard.removeObject(forKey: savedInProgressPiecesKey)
        UserDefaults.standard.removeObject(forKey: savedInProgressIsPausedKey)
        hasSavedGame = false
        print("已清除本地保存的游戏进行中状态")
    }

    private func clearSavedGameForCurrentLevelOnly() {
        clearSavedGame()
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

    // Updated to show centiseconds (hundredths of a second)
    func formattedTime(_ time: TimeInterval?) -> String {
        guard let time = time else { return "--:--.--" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1.0)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    private func updateAndSyncBestScore(levelId: String, currentMoves: Int, currentTime: TimeInterval) {
        guard let levelIndex = levels.firstIndex(where: { $0.id == levelId }) else {
            print("Error: Could not find level with ID \(levelId) to update best score.")
            return
        }

        var updatedLocally = false
        if levels[levelIndex].bestMoves == nil || currentMoves < levels[levelIndex].bestMoves! {
            levels[levelIndex].bestMoves = currentMoves
            updatedLocally = true
            print("新本地最佳步数记录 for \(levelId): \(currentMoves)")
        }
        if levels[levelIndex].bestTime == nil || currentTime < levels[levelIndex].bestTime! {
            levels[levelIndex].bestTime = currentTime // currentTime is already precise
            updatedLocally = true
            print("新本地最佳时间记录 for \(levelId): \(formattedTime(currentTime))")
        }

        if updatedLocally {
            if let authMgr = authManager, let settingsMgr = settingsManager,
               authMgr.isLoggedIn, settingsMgr.useiCloudLogin {
                Task {
                    await saveBestScoreToCloud(
                        levelID: levelId,
                        moves: levels[levelIndex].bestMoves!, 
                        time: levels[levelIndex].bestTime!   
                    )
                }
            }
        }
    }

    @MainActor 
    func saveBestScoreToCloud(levelID: String, moves: Int, time: TimeInterval) async {
        guard let authMgr = authManager, let settingsMgr = settingsManager,
              authMgr.isLoggedIn, settingsMgr.useiCloudLogin else {
            print("CloudKit Sync: Not logged in or iCloud disabled. Skipping save for \(levelID).")
            return
        }
        
        print("CloudKit Sync: Attempting to save best score for level \(levelID): Moves - \(moves), Time - \(time)") // Time is Double

        let recordID = CKRecord.ID(recordName: levelID) 
        var statsToSave = CompletedLevelCloudStats(id: levelID, bestMoves: moves, bestTime: time)

        do {
            let existingRecord = try? await privateDB.record(for: recordID)
            statsToSave.ckRecordChangeTag = existingRecord?.recordChangeTag 
            
            let ckRecord = statsToSave.toCKRecord(existingRecord: existingRecord)
            
            try await privateDB.save(ckRecord)
            print("CloudKit Sync: Successfully saved best score for level \(levelID).")
            
        } catch let error as CKError where error.code == .unknownItem {
            print("CloudKit Sync: Record for \(levelID) not found, creating new one.")
            let ckRecord = statsToSave.toCKRecord() 
            do {
                try await privateDB.save(ckRecord)
                print("CloudKit Sync: Successfully created and saved best score for level \(levelID).")
            } catch {
                print("CloudKit Sync: Error creating new best score record for \(levelID): \(error.localizedDescription)")
            }
        } catch {
            print("CloudKit Sync: Error saving best score for level \(levelID): \(error.localizedDescription)")
        }
    }

    @MainActor
    func fetchBestScoresFromCloud() async {
        guard let authMgr = authManager, let settingsMgr = settingsManager,
              authMgr.isLoggedIn, settingsMgr.useiCloudLogin else {
            print("CloudKit Sync: Not logged in or iCloud disabled. Skipping fetch of best scores.")
            return
        }
        print("CloudKit Sync: Fetching all best scores from user's private database...")

        let query = CKQuery(recordType: CloudKitRecordTypes.CompletedLevelStats, predicate: NSPredicate(value: true))
        
        do {
            let (matchResults, _) = try await privateDB.records(matching: query)
            var cloudScoresUpdated = 0
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let cloudStats = CompletedLevelCloudStats(from: record) {
                        if let levelIndex = levels.firstIndex(where: { $0.id == cloudStats.id }) {
                            var localLevel = levels[levelIndex]
                            var needsCloudUpdate = false
                            var localBestChanged = false

                            let localMoves = localLevel.bestMoves
                            let cloudMoves = cloudStats.bestMoves
                            if localMoves == nil || cloudMoves < localMoves! {
                                localLevel.bestMoves = cloudMoves
                                localBestChanged = true
                                print("CloudKit Sync: Updated local best moves for \(cloudStats.id) from cloud: \(cloudMoves)")
                            } else if localMoves != nil && localMoves! < cloudMoves {
                                needsCloudUpdate = true 
                            }

                            let localTime = localLevel.bestTime
                            let cloudTime = cloudStats.bestTime // cloudTime is Double
                            if localTime == nil || cloudTime < localTime! {
                                localLevel.bestTime = cloudTime
                                localBestChanged = true
                                print("CloudKit Sync: Updated local best time for \(cloudStats.id) from cloud: \(formattedTime(cloudTime))")
                            } else if localTime != nil && localTime! < cloudTime {
                                needsCloudUpdate = true 
                            }
                            
                            if localBestChanged {
                                levels[levelIndex] = localLevel 
                                cloudScoresUpdated += 1
                            }

                            if needsCloudUpdate {
                                print("CloudKit Sync: Local score for \(localLevel.id) is better. Syncing to cloud.")
                                await saveBestScoreToCloud(levelID: localLevel.id, moves: localLevel.bestMoves!, time: localLevel.bestTime!)
                            }
                        }
                    }
                case .failure(let error):
                    print("CloudKit Sync: Error fetching a best score record: \(error.localizedDescription)")
                }
            }
            if cloudScoresUpdated > 0 {
                 print("CloudKit Sync: Successfully fetched and updated \(cloudScoresUpdated) local best scores from CloudKit.")
            } else if matchResults.isEmpty {
                print("CloudKit Sync: No best scores found in CloudKit for this user.")
            } else {
                print("CloudKit Sync: Fetched scores from CloudKit, but no local scores were updated (local might be same or better).")
            }

        } catch {
            print("CloudKit Sync: Error fetching all best scores: \(error.localizedDescription)")
        }
    }
    
    func submitScoreToLeaderboard(levelID: String, moves: Int, time: TimeInterval) {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Game Center: Player not authenticated. Cannot submit score.")
            return
        }
        
        // Leaderboard IDs should be defined in App Store Connect
        // Example format: com.yourbundleid.levelname.moves or com.yourbundleid.levelname.time
        let movesLeaderboardID = "\(levelID)_moves" // Make these unique and match App Store Connect
        let timeLeaderboardID = "\(levelID)_time"   // Make these unique and match App Store Connect

        print("Game Center: Attempting to submit to \(movesLeaderboardID) - Moves: \(moves)")
        GKLeaderboard.submitScore(moves, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [movesLeaderboardID]) { error in
            if let error = error {
                print("Game Center: Error submitting moves score to \(movesLeaderboardID): \(error.localizedDescription)")
            } else {
                print("Game Center: Successfully submitted moves score (\(moves)) to \(movesLeaderboardID).")
            }
        }

        // For time, Game Center expects an Int64.
        // Common practice is to submit time in milliseconds or centiseconds.
        // Let's use centiseconds (hundredths of a second) for better granularity in leaderboards.
        let timeInCentiseconds = Int64(time * 100)
        print("Game Center: Attempting to submit to \(timeLeaderboardID) - Time (centiseconds): \(timeInCentiseconds)")
        GKLeaderboard.submitScore(Int(timeInCentiseconds), context: 0, player: GKLocalPlayer.local, leaderboardIDs: [timeLeaderboardID]) { error in
            if let error = error {
                print("Game Center: Error submitting time score to \(timeLeaderboardID): \(error.localizedDescription)")
            } else {
                print("Game Center: Successfully submitted time score (\(timeInCentiseconds)cs) to \(timeLeaderboardID).")
            }
        }
    }

    @MainActor // 确保在主线程，因为会与 GameKit 交互
    func syncAllLocalBestScoresToGameCenter() {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Game Center: Player not authenticated. Cannot sync all local best scores.")
            // 考虑给用户提示，例如弹窗或信息条
            // 可以通过 AuthManager 或 SettingsManager 发布一个错误/消息
            return
        }

        print("GameManager: Attempting to sync all local best scores to Game Center...")
        var submittedCount = 0
        var skippedCount = 0

        for level in levels {
            if let bestMoves = level.bestMoves, let bestTime = level.bestTime {
                print("GameManager: Syncing score for level '\(level.name)' (ID: \(level.id)) - Moves: \(bestMoves), Time: \(String(format: "%.2f", bestTime))s")
                // 调用现有的提交函数
                // submitScoreToLeaderboard 已经包含了 Game Center 认证检查，但我们在此函数开头进行一次总检查更好
                submitScoreToLeaderboard(levelID: level.id, moves: bestMoves, time: bestTime)
                submittedCount += 1
            } else {
                print("GameManager: No local best score for level '\(level.name)' (ID: \(level.id)). Skipping sync for this level.")
                skippedCount += 1
            }
        }

        if submittedCount > 0 {
            print("GameManager: Sync process completed. Attempted to submit \(submittedCount) scores.")
            // 可以在此通知用户同步已尝试（成功与否取决于 Game Center 的响应）
        }
        if skippedCount > 0 && submittedCount == 0 {
            print("GameManager: Sync process completed. No local scores found to submit.")
            // 提示用户没有可同步的本地成绩
        } else if skippedCount > 0 {
            print("GameManager: Skipped \(skippedCount) levels as they had no local best scores.")
        }
    }
}

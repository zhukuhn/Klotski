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
        
    @Published var levels: [Level] = []
    
    @Published var moves: Int = 0
    @Published var timeElapsed: TimeInterval = 0
    @Published var isGameActive: Bool = false
    @Published var hasSavedGame: Bool = false
    @Published var isGameWon: Bool = false
    @Published var isPaused: Bool = false

    private var timerSubscription: Cancellable?
    private var lastTimerFireDate: Date?
    private let timerInterval: TimeInterval = 0.1

    private var cancellables = Set<AnyCancellable>()

    private let privateDB = CKContainer.default().privateCloudDatabase
    private var authManager: AuthManager?
    private var settingsManager: SettingsManager?

    private let savedInProgressLevelIDKey = "savedKlotskiInProgressLevelID"
    private let savedInProgressMovesKey = "savedKlotskiInProgressMoves"
    private let savedInProgressTimeKey = "savedKlotskiInProgressTime"
    private let savedInProgressPiecesKey = "savedKlotskiInProgressPieces"
    private let savedInProgressLevelIndexKey = "savedKlotskiInProgressLevelIndex"
    private let savedInProgressIsPausedKey = "savedKlotskiInProgressIsPaused"

    init(allLevels: [Level] = ClassicLevels.allClassicLevels) {
        self.levels = allLevels
        let levelID = UserDefaults.standard.string(forKey: savedInProgressLevelIDKey)
        let piecesData = UserDefaults.standard.data(forKey: savedInProgressPiecesKey)
        let movesDataExists = UserDefaults.standard.object(forKey: savedInProgressMovesKey) != nil
        let timeDataExists = UserDefaults.standard.object(forKey: savedInProgressTimeKey) != nil
        let levelIndexExists = UserDefaults.standard.object(forKey: savedInProgressLevelIndexKey) != nil
        let isPausedDataExists = UserDefaults.standard.object(forKey: savedInProgressIsPausedKey) != nil

        if levelID != nil, piecesData != nil, movesDataExists, timeDataExists, levelIndexExists, isPausedDataExists {
            hasSavedGame = true
        } else {
            hasSavedGame = false
            clearSavedGame() 
        }
        debugLog("GameManager init: Local in-progress save check complete. hasSavedGame = \(hasSavedGame)")
    }

    func setupDependencies(authManager: AuthManager, settingsManager: SettingsManager) {
        self.authManager = authManager
        self.settingsManager = settingsManager

        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                // Simplified logic: Sync if user is logged in.
                if userProfile != nil {
                    debugLog("GameManager: User logged in. Fetching best scores from CloudKit.")
                    Task { await self.fetchBestScoresFromCloud() }
                } else if userProfile == nil {
                    debugLog("GameManager: User logged out. Cloud scores will not be fetched/synced.")
                }
            }
            .store(in: &cancellables)

        // Simplified logic: Sync if user is logged in.
        if authManager.isLoggedIn {
            debugLog("GameManager: Initial setup with logged-in user. Fetching best scores.")
            Task { await self.fetchBestScoresFromCloud() }
        }
    }
    
    func startGame(level: Level, settings: SettingsManager, isNewSession: Bool = true) {
        currentLevel = level
        currentLevelIndex = levels.firstIndex(where: { $0.id == level.id })

        if isNewSession {
            moves = 0
            timeElapsed = 0.0
            isPaused = true 
        }
        
        isGameActive = true
        isGameWon = false
        
        pieces = level.piecePlacements.map { Piece(id: $0.id, type: $0.type, x: $0.initialX, y: $0.initialY) }
        rebuildGameBoard()
        debugLog("游戏开始/切换到: \(level.name), isPaused: \(isPaused)")
        SoundManager.playImpactHaptic(settings: settings)
        
        if !isPaused && !isGameWon { startTimer() } else { stopTimer() }
    }

    func switchToLevel(at index: Int, settings: SettingsManager) {
        guard index >= 0 && index < levels.count else { return }
        let newLevel = levels[index]
        
        moves = 0
        timeElapsed = 0.0
        isPaused = false 
        isGameWon = false
        
        stopTimer()
        startGame(level: newLevel, settings: settings, isNewSession: true) 
    }

    func pauseGame() {
        guard !isGameWon else { return }
        if !isPaused {
            isPaused = true
            stopTimer()
            debugLog("游戏已暂停。时间: \(formattedTime(timeElapsed))")
        }
    }

    func resumeGame(settings: SettingsManager) {
        guard isGameActive && !isGameWon else { return }
        if isPaused {
            isPaused = false
            startTimer()
            SoundManager.playImpactHaptic(settings: settings)
            debugLog("游戏已继续。")
        }
    }

    func startTimer() {
        stopTimer() 
        guard isGameActive && !isPaused && !isGameWon else { return }
        
        lastTimerFireDate = Date()
        timerSubscription = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentDate in
                guard let self = self, let lastFire = self.lastTimerFireDate else { return }
                let interval = currentDate.timeIntervalSince(lastFire)
                self.timeElapsed += interval
                self.lastTimerFireDate = currentDate
            }
        debugLog("计时器已启动 (间隔: \(timerInterval)s)。")
    }

    func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
        lastTimerFireDate = nil
        debugLog("计时器已停止。当前累计时间: \(timeElapsed)")
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
        debugLog("棋子 \(pieceId) 移动到 (\(newX), \(newY))，当前步数: \(moves)")
        
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
            stopTimer()
            debugLog("恭喜！关卡 \(level.name) 完成！总步数: \(moves), 时间: \(formattedTime(timeElapsed))")
            SoundManager.playSound(named: "victory_fanfare", settings: settings)
            SoundManager.playHapticNotification(type: .success, settings: settings)
            
            updateAndSyncBestScore(levelId: level.id, currentMoves: moves, currentTime: timeElapsed)
            submitScoreToLeaderboard(levelID: level.id, moves: moves, time: timeElapsed)
            
            clearSavedGame()
        }
    }
    
    func continueGame(settings: SettingsManager) {
        guard let savedLevelID = UserDefaults.standard.string(forKey: savedInProgressLevelIDKey),
              let savedLevelIndex = UserDefaults.standard.object(forKey: savedInProgressLevelIndexKey) as? Int,
              savedLevelIndex >= 0 && savedLevelIndex < levels.count,
              let levelToContinue = levels.first(where: { $0.id == savedLevelID }),
              UserDefaults.standard.object(forKey: savedInProgressPiecesKey) != nil,
              UserDefaults.standard.object(forKey: savedInProgressMovesKey) != nil,
              UserDefaults.standard.object(forKey: savedInProgressTimeKey) != nil,
              UserDefaults.standard.object(forKey: savedInProgressIsPausedKey) != nil
        else {
            debugLog("继续游戏失败：未找到有效或完整的本地存档。")
            clearSavedGame(); hasSavedGame = false; return
        }
        
        self.currentLevel = levelToContinue
        self.currentLevelIndex = savedLevelIndex
        self.moves = UserDefaults.standard.integer(forKey: savedInProgressMovesKey)
        self.timeElapsed = UserDefaults.standard.double(forKey: savedInProgressTimeKey)
        self.isPaused = UserDefaults.standard.bool(forKey: savedInProgressIsPausedKey)

        if let savedPiecesData = UserDefaults.standard.data(forKey: savedInProgressPiecesKey) {
            do {
                self.pieces = try JSONDecoder().decode([Piece].self, from: savedPiecesData)
                rebuildGameBoard()
                self.isGameActive = true; self.isGameWon = false
                debugLog("继续游戏: \(levelToContinue.name), 本地存档已加载, isPaused: \(self.isPaused)")
                if !self.isPaused && !self.isGameWon { startTimer() }
                else { stopTimer() } 
            } catch {
                debugLog("错误：无法解码已保存的本地棋子状态: \(error)。")
                clearSavedGame(); hasSavedGame = false; isGameActive = false
            }
        }
    }
    
    func saveGame(settings: SettingsManager) { 
        guard let currentLevel = currentLevel, let currentIndex = currentLevelIndex, timeElapsed > 0, !isGameWon else {
            return
        }
        UserDefaults.standard.set(currentLevel.id, forKey: savedInProgressLevelIDKey)
        UserDefaults.standard.set(currentIndex, forKey: savedInProgressLevelIndexKey)
        UserDefaults.standard.set(moves, forKey: savedInProgressMovesKey)
        UserDefaults.standard.set(timeElapsed, forKey: savedInProgressTimeKey)
        UserDefaults.standard.set(isPaused, forKey: savedInProgressIsPausedKey)
        do {
            let encodedPieces = try JSONEncoder().encode(pieces)
            UserDefaults.standard.set(encodedPieces, forKey: savedInProgressPiecesKey)
            hasSavedGame = true
            debugLog("游戏进行中状态已保存到本地: \(currentLevel.name)")
        } catch {
            debugLog("错误：无法编码并保存本地棋子状态: \(error)")
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
        debugLog("已清除本地保存的游戏进行中状态")
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
            debugLog("Error: Could not find level with ID \(levelId) to update best score.")
            return
        }

        var updatedLocally = false
        if levels[levelIndex].bestMoves == nil || currentMoves < levels[levelIndex].bestMoves! {
            levels[levelIndex].bestMoves = currentMoves
            updatedLocally = true
            debugLog("新本地最佳步数记录 for \(levelId): \(currentMoves)")
        }
        if levels[levelIndex].bestTime == nil || currentTime < levels[levelIndex].bestTime! {
            levels[levelIndex].bestTime = currentTime
            updatedLocally = true
            debugLog("新本地最佳时间记录 for \(levelId): \(formattedTime(currentTime))")
        }

        if updatedLocally {
            // Simplified logic: Sync if authManager exists and user is logged in.
            if let authMgr = authManager, authMgr.isLoggedIn {
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
        // Simplified logic: Sync if authManager exists and user is logged in.
        guard let authMgr = authManager, authMgr.isLoggedIn else {
            debugLog("CloudKit Sync: Not logged in. Skipping save for \(levelID).")
            return
        }
        
        debugLog("CloudKit Sync: Attempting to save best score for level \(levelID): Moves - \(moves), Time - \(time)")

        let recordID = CKRecord.ID(recordName: levelID) 
        var statsToSave = CompletedLevelCloudStats(id: levelID, bestMoves: moves, bestTime: time)

        do {
            let existingRecord = try? await privateDB.record(for: recordID)
            statsToSave.ckRecordChangeTag = existingRecord?.recordChangeTag 
            
            let ckRecord = statsToSave.toCKRecord(existingRecord: existingRecord)
            
            try await privateDB.save(ckRecord)
            debugLog("CloudKit Sync: Successfully saved best score for level \(levelID).")
            
        } catch let error as CKError where error.code == .unknownItem {
            debugLog("CloudKit Sync: Record for \(levelID) not found, creating new one.")
            let ckRecord = statsToSave.toCKRecord() 
            do {
                try await privateDB.save(ckRecord)
                debugLog("CloudKit Sync: Successfully created and saved best score for level \(levelID).")
            } catch {
                debugLog("CloudKit Sync: Error creating new best score record for \(levelID): \(error.localizedDescription)")
            }
        } catch {
            debugLog("CloudKit Sync: Error saving best score for level \(levelID): \(error.localizedDescription)")
        }
    }

    @MainActor
    func fetchBestScoresFromCloud() async {
        // Simplified logic: Fetch if authManager exists and user is logged in.
        guard let authMgr = authManager, authMgr.isLoggedIn else {
            debugLog("CloudKit Sync: Not logged in. Skipping fetch of best scores.")
            return
        }
        debugLog("CloudKit Sync: Fetching all best scores from user's private database...")

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
                                debugLog("CloudKit Sync: Updated local best moves for \(cloudStats.id) from cloud: \(cloudMoves)")
                            } else if localMoves != nil && localMoves! < cloudMoves {
                                needsCloudUpdate = true 
                            }

                            let localTime = localLevel.bestTime
                            let cloudTime = cloudStats.bestTime
                            if localTime == nil || cloudTime < localTime! {
                                localLevel.bestTime = cloudTime
                                localBestChanged = true
                                debugLog("CloudKit Sync: Updated local best time for \(cloudStats.id) from cloud: \(formattedTime(cloudTime))")
                            } else if localTime != nil && localTime! < cloudTime {
                                needsCloudUpdate = true 
                            }
                            
                            if localBestChanged {
                                levels[levelIndex] = localLevel 
                                cloudScoresUpdated += 1
                            }

                            if needsCloudUpdate {
                                debugLog("CloudKit Sync: Local score for \(localLevel.id) is better. Syncing to cloud.")
                                await saveBestScoreToCloud(levelID: localLevel.id, moves: localLevel.bestMoves!, time: localLevel.bestTime!)
                            }
                        }
                    }
                case .failure(let error):
                    debugLog("CloudKit Sync: Error fetching a best score record: \(error.localizedDescription)")
                }
            }
            if cloudScoresUpdated > 0 {
                 debugLog("CloudKit Sync: Successfully fetched and updated \(cloudScoresUpdated) local best scores from CloudKit.")
            } else if matchResults.isEmpty {
                debugLog("CloudKit Sync: No best scores found in CloudKit for this user.")
            } else {
                debugLog("CloudKit Sync: Fetched scores from CloudKit, but no local scores were updated (local might be same or better).")
            }

        } catch {
            debugLog("CloudKit Sync: Error fetching all best scores: \(error.localizedDescription)")
        }
    }

    func submitScoreToLeaderboard(levelID: String, moves: Int, time: TimeInterval) {
        guard GKLocalPlayer.local.isAuthenticated else {
            debugLog("Game Center: Player not authenticated. Cannot submit score.")
            return
        }
        
        let movesLeaderboardID = "\(levelID)_moves"
        let timeLeaderboardID = "\(levelID)_time"

        debugLog("Game Center: Attempting to submit to \(movesLeaderboardID) - Moves: \(moves)")
        GKLeaderboard.submitScore(moves, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [movesLeaderboardID]) { error in
            if let error = error {
                debugLog("Game Center: Error submitting moves score to \(movesLeaderboardID): \(error.localizedDescription)")
            } else {
                debugLog("Game Center: Successfully submitted moves score (\(moves)) to \(movesLeaderboardID).")
            }
        }

        let timeInCentiseconds = Int64(time * 100)
        debugLog("Game Center: Attempting to submit to \(timeLeaderboardID) - Time (centiseconds): \(timeInCentiseconds)")
        GKLeaderboard.submitScore(Int(timeInCentiseconds), context: 0, player: GKLocalPlayer.local, leaderboardIDs: [timeLeaderboardID]) { error in
            if let error = error {
                debugLog("Game Center: Error submitting time score to \(timeLeaderboardID): \(error.localizedDescription)")
            } else {
                debugLog("Game Center: Successfully submitted time score (\(timeInCentiseconds)cs) to \(timeLeaderboardID).")
            }
        }
    }

    @MainActor
    func syncAllLocalBestScoresToGameCenter() async {
        guard GKLocalPlayer.local.isAuthenticated else {
            debugLog("Game Center: Player not authenticated. Cannot sync all local best scores.")
            return
        }

        debugLog("GameManager: Attempting to sync all local best scores to Game Center...")
        var submittedCount = 0
        var skippedCount = 0

        for level in levels {
            if let bestMoves = level.bestMoves, let bestTime = level.bestTime {
                debugLog("GameManager: Syncing score for level '\(level.name)' (ID: \(level.id)) - Moves: \(bestMoves), Time: \(String(format: "%.2f", bestTime))s")
                submitScoreToLeaderboard(levelID: level.id, moves: bestMoves, time: bestTime)
                submittedCount += 1
            } else {
                debugLog("GameManager: No local best score for level '\(level.name)' (ID: \(level.id)). Skipping sync for this level.")
                skippedCount += 1
            }
        }

        if submittedCount > 0 {
            debugLog("GameManager: Sync process completed. Attempted to submit \(submittedCount) scores.")
        }
        if skippedCount > 0 && submittedCount == 0 {
            debugLog("GameManager: Sync process completed. No local scores found to submit.")
        } else if skippedCount > 0 {
            debugLog("GameManager: Skipped \(skippedCount) levels as they had no local best scores.")
        }
    }
}

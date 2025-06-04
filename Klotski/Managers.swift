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
        let movesLeaderboardID = "\(levelID)_moves_klotski_v1" // Make these unique and match App Store Connect
        let timeLeaderboardID = "\(levelID)_time_klotski_v1"   // Make these unique and match App Store Connect

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
}

// MARK: - ThemeManager
@MainActor
class ThemeManager: ObservableObject {
    @Published var themes: [Theme]
    @Published var currentTheme: Theme
    @Published private(set) var purchasedThemeIDs: Set<String>

    @Published var storeKitProducts: [Product] = []
    @Published var storeKitError: StoreKitError? = nil
    @Published var isStoreLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let storeKitManager = StoreKitManager.shared
    
    private let settingsManagerInstance: SettingsManager
    private var initialAuthCheckCompleted = false
    private let currentThemeIDKey = "currentThemeID"
    static let locallyKnownPaidThemeIDsKey = "locallyKnownPaidThemeIDs"


    init(authManager: AuthManager, settingsManager: SettingsManager, availableThemes: [Theme] = AppThemeRepository.allThemes) {
        self.settingsManagerInstance = settingsManager
        self.themes = availableThemes
        
        let fallbackTheme = Theme(id: "fallback", name: "备用", isPremium: false, backgroundColor: CodableColor(color: .gray), sliderColor: CodableColor(color: .secondary), sliderTextColor: CodableColor(color: .black), boardBackgroundColor: CodableColor(color: .white), boardGridLineColor: CodableColor(color: Color(.systemGray)))
        let defaultThemeToSet = availableThemes.first(where: { $0.id == "default" }) ?? fallbackTheme
        
        let initialPurchased = Set(availableThemes.filter { !$0.isPremium }.map { $0.id })
        self._purchasedThemeIDs = Published(initialValue: initialPurchased)
        self._currentTheme = Published(initialValue: defaultThemeToSet)

        print("ThemeManager init: Initial purchasedThemeIDs (only free themes): \(self.purchasedThemeIDs)")
        
        storeKitManager.purchaseOrRestoreSuccessfulPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processedProductIDs in
                guard let self = self else { return }
                print("ThemeManager: Received successful purchase/restore for StoreKit Product IDs: \(processedProductIDs)")
                self.handleSuccessfulStoreKitProcessing(storeKitProductIDs: processedProductIDs, authManager: authManager)
            }
            .store(in: &cancellables)
        
        storeKitManager.$fetchedProducts
            .receive(on: DispatchQueue.main)
            .assign(to: \.storeKitProducts, on: self)
            .store(in: &cancellables)

        storeKitManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isStoreLoading, on: self)
            .store(in: &cancellables)

        storeKitManager.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.storeKitError, on: self)
            .store(in: &cancellables)
        
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                print("ThemeManager: AuthManager.currentUser changed. New profile ID: \(userProfile?.id ?? "nil")")
                self.initialAuthCheckCompleted = true
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
                Task {
                    if self.settingsManagerInstance.useiCloudLogin {
                        await self.fetchSKProducts()
                        await self.storeKitManager.checkForCurrentEntitlements()
                    }
                }
            }
            .store(in: &cancellables)
        
        settingsManagerInstance.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let iCloudSettingChanged = self.settingsManagerInstance.useiCloudLogin
                print("ThemeManager: SettingsManager's useiCloudLogin might have changed to \(iCloudSettingChanged).")
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
                Task {
                     if iCloudSettingChanged {
                         await self.fetchSKProducts()
                         await self.storeKitManager.checkForCurrentEntitlements()
                     } else if !iCloudSettingChanged {
                         self.storeKitProducts = []
                     }
                }
            }
            .store(in: &cancellables)

        Task {
            if settingsManagerInstance.useiCloudLogin {
                await fetchSKProducts()
                await storeKitManager.checkForCurrentEntitlements()
            }
        }
        print("ThemeManager init: Fully initialized. Current theme: \(self.currentTheme.name)")
    }
    
    func fetchSKProducts() async {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager fetchSKProducts: iCloud login is disabled. Skipping fetch.")
            self.storeKitProducts = []
            return
        }
        let productIDs = Set(themes.compactMap { $0.isPremium ? $0.productID : nil })
        if !productIDs.isEmpty {
            print("ThemeManager: Requesting product information from StoreKit for IDs: \(productIDs)")
            await storeKitManager.fetchProducts(productIDs: productIDs)
        } else {
            print("ThemeManager: No premium themes with product IDs found to fetch.")
        }
    }

    func purchaseTheme(_ theme: Theme) async {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager purchaseTheme: iCloud login is disabled. Cannot purchase.")
            self.storeKitError = .userCannotMakePayments 
            return
        }
        guard theme.isPremium, let productID = theme.productID else {
            print("ThemeManager: Theme \(theme.name) is not premium or has no product ID.")
            return
        }
        
        if storeKitProducts.first(where: { $0.id == productID }) == nil {
            print("ThemeManager: Product \(productID) for theme \(theme.name) not found in local cache. Fetching products first.")
            await fetchSKProducts() 
        }

        if let product = storeKitProducts.first(where: { $0.id == productID }) {
            print("ThemeManager: Attempting to purchase product: \(product.id) for theme \(theme.name)")
            await storeKitManager.purchase(product)
        } else {
            print("ThemeManager: Product ID \(productID) for theme \(theme.name) not found in fetched StoreKit products even after attempting fetch.")
            self.storeKitError = .productsNotFound
        }
    }

    func restoreThemePurchases() async {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager restoreThemePurchases: iCloud login is disabled. Cannot restore.")
            self.storeKitError = .userCannotMakePayments 
            return
        }
        print("ThemeManager: Requesting sync/restore purchases from StoreKit.")
        await storeKitManager.syncTransactions()
    }
    
    private func handleSuccessfulStoreKitProcessing(storeKitProductIDs: Set<String>, authManager: AuthManager) {
        print("ThemeManager: Handling successful StoreKit processing for product IDs: \(storeKitProductIDs)")
        var newlyProcessedAppThemeIDs = Set<String>() 

        for skProductID in storeKitProductIDs {
            if let theme = themes.first(where: { $0.productID == skProductID && $0.isPremium }) {
                newlyProcessedAppThemeIDs.insert(theme.id) 
            } else {
                print("ThemeManager WARNING: Received a StoreKit product ID '\(skProductID)' that doesn't map to any known premium theme's productID.")
            }
        }

        let oldPurchasedIDs = self.purchasedThemeIDs
        self.purchasedThemeIDs.formUnion(newlyProcessedAppThemeIDs) 

        let purchasedIDsActuallyChanged = (self.purchasedThemeIDs != oldPurchasedIDs)

        if purchasedIDsActuallyChanged {
             print("ThemeManager: purchasedThemeIDs (Theme.id) updated due to StoreKit: \(self.purchasedThemeIDs)")
            print("ThemeManager: Syncing updated purchased themes to CloudKit via AuthManager.")
            authManager.updateUserPurchasedThemes(themeIDs: self.purchasedThemeIDs) 

            if newlyProcessedAppThemeIDs.count == 1, 
               let singleNewThemeID = newlyProcessedAppThemeIDs.first,
               let themeToApply = themes.first(where: {$0.id == singleNewThemeID}),
               currentTheme.id != themeToApply.id {
                setCurrentTheme(themeToApply)
                print("ThemeManager: Automatically applied newly purchased/restored theme: \(themeToApply.name)")
            }
        } else {
            print("ThemeManager: No new themes were added from StoreKit processing, or processed themes were already known.")
        }
        self.storeKitError = nil 
    }

    private func rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: AuthManager) {
        var newPurchased = Set(self.themes.filter { !$0.isPremium }.map { $0.id }) 

        if self.settingsManagerInstance.useiCloudLogin, let userProfile = authManager.currentUser {
            newPurchased.formUnion(userProfile.purchasedThemeIDs)
            print("ThemeManager rebuild (iCloud user \(userProfile.id)): Loaded \(userProfile.purchasedThemeIDs.count) themes from CloudKit profile. Combined with free: \(newPurchased.count)")
        } else {
            print("ThemeManager rebuild (No iCloud user or iCloud disabled): Only free themes considered purchased from app's perspective.")
        }
        
        if self.purchasedThemeIDs != newPurchased {
            self.purchasedThemeIDs = newPurchased
            print("ThemeManager: purchasedThemeIDs rebuilt. Final set: \(self.purchasedThemeIDs)")
        }

        let savedThemeID = UserDefaults.standard.string(forKey: currentThemeIDKey)
        var themeToRestore: Theme? = nil

        if let themeID = savedThemeID, let candidate = themes.first(where: { $0.id == themeID }) {
            if self.isThemePurchased(candidate) { 
                themeToRestore = candidate
            }
        }

        let themeToActuallySet: Theme
        if let validRestoredTheme = themeToRestore {
            themeToActuallySet = validRestoredTheme
        } else {
            let defaultThemeToSet = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
            themeToActuallySet = defaultThemeToSet
            if savedThemeID != nil && savedThemeID != defaultThemeToSet.id { 
                 print("ThemeManager rebuild: Previously selected theme '\(savedThemeID!)' is no longer purchased or invalid. Reverting to default '\(defaultThemeToSet.name)'.")
            }
        }
        
        if currentTheme.id != themeToActuallySet.id {
             setCurrentTheme(themeToActuallySet)
        } else if !isThemePurchased(currentTheme) { 
             let defaultTheme = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
             print("ThemeManager rebuild: Current theme '\(currentTheme.name)' is no longer purchased. Reverting to default '\(defaultTheme.name)'.")
             setCurrentTheme(defaultTheme)
        }
    }
    
    func setCurrentTheme(_ theme: Theme) {
        guard themes.contains(where: { $0.id == theme.id }) else {
            print("ThemeManager: Attempted to set an unknown theme ('\(theme.name)'). Ignoring.")
            return
        }

        let canApply: Bool
        if theme.isPremium {
            canApply = self.isThemePurchased(theme) 
        } else {
            canApply = true
        }

        guard canApply else {
            print("ThemeManager setCurrentTheme: Cannot apply theme '\(theme.name)'. It's premium and not purchased/accessible.")
            let defaultThemeToSet = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
            if self.currentTheme.id != defaultThemeToSet.id {
                self.currentTheme = defaultThemeToSet
                UserDefaults.standard.set(defaultThemeToSet.id, forKey: currentThemeIDKey)
                print("ThemeManager setCurrentTheme: Reverted to default theme '\(defaultThemeToSet.name)'.")
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
}

// MARK: - AuthManager
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
                print("AuthManager: Received CKAccountChanged notification. Clearing previous user session.")
                self.iCloudUserActualRecordID = nil 

                self.currentUser = nil
                self.isLoggedIn = false
                
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: ThemeManager.locallyKnownPaidThemeIDsKey)
                    print("AuthManager: Cleared ThemeManager.locallyKnownPaidThemeIDsKey from UserDefaults due to account change.")
                }

                let useiCloudCurrent = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                if useiCloudCurrent {
                    print("AuthManager: iCloud account changed, and preference is ON. Re-checking account status and profile.")
                    self.checkiCloudAccountStatusAndFetchProfile()
                } else {
                    print("AuthManager: iCloud account changed, but preference is OFF. Ensuring local session is cleared.")
                    self.clearLocalSessionForDisablediCloud(reason: "Account changed while preference is off.")
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
            }
        }
    }

    public func handleiCloudPreferenceChange(useiCloud: Bool) {
        print("AuthManager: iCloud preference changed to \(useiCloud).")
        UserDefaults.standard.set(useiCloud, forKey: AuthManager.useiCloudLoginKey) 

        if useiCloud {
            self.errorMessage = nil 
            self.isLoading = true 
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
                    self.isLoading = false 
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
        if !self.isLoading { self.isLoading = true }

        container.fetchUserRecordID { [weak self] (recordID, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager fetchUserRecordID callback: iCloud login preference turned OFF during async. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during user ID fetch.")
                    self.isLoading = false 
                    return
                }
                let sm = SettingsManager() 
                if let error = error {
                    print("AuthManager DEBUG: Fetched iCloud User Record ID: NIL, Error: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudFetchUserFailed")): \(error.localizedDescription)" 
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                    return
                }

                print("AuthManager DEBUG: Fetched iCloud User Record ID: \(recordID?.recordName ?? "NIL"), Error: No error")
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
        print("AuthManager DEBUG: Querying UserProfile for iCloudUserRecordName: \(iCloudRecordName)")
        let sm = SettingsManager() 

        let predicate = NSPredicate(format: "iCloudUserRecordName == %@", iCloudRecordName)
        let query = CKQuery(recordType: CloudKitRecordTypes.UserProfile, predicate: predicate)
        
        privateDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager fetchOrCreateUserProfile callback: iCloud login preference turned OFF. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during profile fetch/create.")
                    self.isLoading = false 
                    return
                }

                switch result {
                case .success(let data):
                    if let firstMatch = data.matchResults.first {
                        let matchedRecordID = firstMatch.0
                        switch firstMatch.1 {
                        case .success(let existingUserProfileRecord):
                            print("AuthManager DEBUG: Found existing UserProfile. RecordName: \(existingUserProfileRecord.recordID.recordName)")
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
                        print("AuthManager DEBUG: No UserProfile found. Attempting to create new one for iCloudUserRecordName: \(iCloudRecordName)")
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
                print("AuthManager DEBUG: Save new UserProfile result. Saved Record ID: \(savedRecord?.recordID.recordName ?? "NIL"), Error: \(error?.localizedDescription ?? "No error")")

                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false 
                guard currentiCloudPreference else { 
                    print("AuthManager createUserProfile callback: iCloud login preference turned OFF. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during profile creation.")
                    self.isLoading = false 
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
    @AppStorage(AuthManager.useiCloudLoginKey) var useiCloudLogin: Bool = false 

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
            "iCloudCheckingStatus": "Checking iCloud Status...", 
            "iCloudUser": "iCloud User", 
            "iCloudNoAccountDetailed": "Not logged into iCloud. Go to device settings to enable cloud features.", 
            "iCloudConnectionError": "Cannot connect to iCloud.", 
            "iCloudSyncError": "iCloud available, but app could not sync user data.", 
            "iCloudLoginPrompt": "iCloud features require login. Check settings.", 
            "iCloudDisabledInSettings": "iCloud login is disabled. Cloud features are unavailable.",
            "storeKitErrorUnknown": "An unknown App Store error occurred.",
            "storeKitErrorProductIDsEmpty": "No product identifiers were provided.",
            "storeKitErrorProductsNotFound": "Products not found in the App Store.",
            "storeKitErrorPurchaseFailed": "Purchase failed", 
            "storeKitErrorPurchaseCancelled": "Purchase was cancelled.",
            "storeKitErrorPurchasePending": "Purchase is pending.",
            "storeKitErrorTransactionVerificationFailed": "Transaction verification failed.",
            "storeKitErrorFailedToLoadEntitlements": "Failed to load current purchases",
            "storeKitErrorUserCannotMakePayments": "This account cannot make payments."
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
            "iCloudCheckingStatus": "正在检查iCloud状态...", 
            "iCloudUser": "iCloud用户", 
            "iCloudNoAccountDetailed": "未登录iCloud账户。请前往设备设置登录以使用云功能。", 
            "iCloudConnectionError": "无法连接到iCloud。", 
            "iCloudSyncError": "iCloud可用，但应用未能同步用户数据。", 
            "iCloudLoginPrompt": "iCloud功能需要登录。请检查设置。", 
            "iCloudDisabledInSettings": "iCloud登录已禁用。云同步功能不可用。",
            "storeKitErrorUnknown": "发生未知App Store错误。",
            "storeKitErrorProductIDsEmpty": "未提供产品ID。",
            "storeKitErrorProductsNotFound": "在App Store中未找到产品。",
            "storeKitErrorPurchaseFailed": "购买失败",
            "storeKitErrorPurchaseCancelled": "购买已取消。",
            "storeKitErrorPurchasePending": "购买待处理。",
            "storeKitErrorTransactionVerificationFailed": "交易验证失败。",
            "storeKitErrorFailedToLoadEntitlements": "加载当前购买项目失败",
            "storeKitErrorUserCannotMakePayments": "此账户无法进行支付。"
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

enum StoreKitError: Error, LocalizedError, Equatable { 
    case unknown
    case productIDsEmpty
    case productsNotFound
    case purchaseFailed(String?) 
    case purchaseCancelled
    case purchasePending
    case transactionVerificationFailed
    case failedToLoadCurrentEntitlements(String?) 
    case userCannotMakePayments

    static func == (lhs: StoreKitError, rhs: StoreKitError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown): return true
        case (.productIDsEmpty, .productIDsEmpty): return true
        case (.productsNotFound, .productsNotFound): return true
        case (.purchaseFailed(let lMsg), .purchaseFailed(let rMsg)): return lMsg == rMsg
        case (.purchaseCancelled, .purchaseCancelled): return true
        case (.purchasePending, .purchasePending): return true
        case (.transactionVerificationFailed, .transactionVerificationFailed): return true
        case (.failedToLoadCurrentEntitlements(let lMsg), .failedToLoadCurrentEntitlements(let rMsg)): return lMsg == rMsg
        case (.userCannotMakePayments, .userCannotMakePayments): return true
        default: return false
        }
    }

    var errorDescription: String? {
        let sm = SettingsManager() 
        switch self {
        case .unknown: return sm.localizedString(forKey: "storeKitErrorUnknown") 
        case .productIDsEmpty: return sm.localizedString(forKey: "storeKitErrorProductIDsEmpty")
        case .productsNotFound: return sm.localizedString(forKey: "storeKitErrorProductsNotFound")
        case .purchaseFailed(let msg):
            let base = sm.localizedString(forKey: "storeKitErrorPurchaseFailed")
            return msg != nil ? "\(base): \(msg!)" : base
        case .purchaseCancelled: return sm.localizedString(forKey: "storeKitErrorPurchaseCancelled")
        case .purchasePending: return sm.localizedString(forKey: "storeKitErrorPurchasePending")
        case .transactionVerificationFailed: return sm.localizedString(forKey: "storeKitErrorTransactionVerificationFailed")
        case .failedToLoadCurrentEntitlements(let msg):
            let base = sm.localizedString(forKey: "storeKitErrorFailedToLoadEntitlements")
            return msg != nil ? "\(base): \(msg!)" : base
        case .userCannotMakePayments: return sm.localizedString(forKey: "storeKitErrorUserCannotMakePayments")
        }
    }

    static func purchaseFailed(_ error: Error?) -> StoreKitError {
        return .purchaseFailed(error?.localizedDescription)
    }
    static func failedToLoadCurrentEntitlements(_ error: Error) -> StoreKitError {
        return .failedToLoadCurrentEntitlements(error.localizedDescription)
    }
}

@MainActor 
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var fetchedProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var error: StoreKitError? = nil 

    let purchaseOrRestoreSuccessfulPublisher = PassthroughSubject<Set<String>, Never>()

    private var transactionListener: Task<Void, Error>? = nil

    private init() {
        print("StoreKitManager (StoreKit 2): Initialized.")
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
        print("StoreKitManager (StoreKit 2): Deinitialized and transaction listener cancelled.")
    }

    func fetchProducts(productIDs: Set<String>) async {
        guard !productIDs.isEmpty else {
            print("StoreKitManager: No product IDs provided to fetch.")
            self.error = .productIDsEmpty
            return
        }
        print("StoreKitManager: Fetching products for IDs: \(productIDs)")
        self.isLoading = true
        self.error = nil

        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.fetchedProducts = storeProducts
            print("StoreKitManager: Fetched products: \(self.fetchedProducts.map { $0.id })")
            if self.fetchedProducts.isEmpty && !productIDs.isEmpty {
                print("StoreKitManager: No products returned from App Store for requested IDs.")
                self.error = .productsNotFound
            }
        } catch {
            print("StoreKitManager: Failed to fetch products: \(error)")
            self.error = .productsNotFound 
        }
        self.isLoading = false
    }

    func purchase(_ product: Product) async {
        guard AppStore.canMakePayments else {
            print("StoreKitManager: User cannot make payments.")
            self.error = .userCannotMakePayments
            return
        }
        
        print("StoreKitManager: Initiating purchase for product: \(product.id)")
        self.isLoading = true
        self.error = nil

        do {
            let result = try await product.purchase()
            try await handlePurchaseResult(result, for: product.id)
        } catch let actualStoreKitError as StoreKit.StoreKitError { 
             print("StoreKitManager: Purchase failed for \(product.id) with StoreKitError: \(actualStoreKitError.localizedDescription) (\(actualStoreKitError))")
             if case .userCancelled = actualStoreKitError {
                 self.error = .purchaseCancelled
             } else {
                 self.error = .purchaseFailed(actualStoreKitError) 
             }
        } catch { 
            print("StoreKitManager: Purchase failed for \(product.id) with error: \(error)")
            self.error = .purchaseFailed(error) 
        }
        self.isLoading = false
    }
    
    private func handlePurchaseResult(_ result: Product.PurchaseResult, for productID: Product.ID) async throws {
        switch result {
        case .success(let verificationResult):
            print("StoreKitManager: Purchase successful for \(productID), verifying transaction...")
            guard let transaction = await self.checkVerified(verificationResult) else {
                self.error = .transactionVerificationFailed
                return
            }
            print("StoreKitManager: Transaction verified for \(productID). Finishing transaction.")
            await transaction.finish() 
            purchaseOrRestoreSuccessfulPublisher.send([transaction.productID])

        case .pending:
            print("StoreKitManager: Purchase for \(productID) is pending.")
            self.error = .purchasePending

        case .userCancelled:
            print("StoreKitManager: User cancelled purchase for \(productID).")
            self.error = .purchaseCancelled
        
        @unknown default:
            print("StoreKitManager: Unknown purchase result for \(productID).")
            self.error = .unknown
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor [weak self] in 
            guard let self = self else { return }
            print("StoreKitManager: Starting transaction listener...")
            for await verificationResult in Transaction.updates {
                print("StoreKitManager: Received transaction update.")
                guard let transaction = await self.checkVerified(verificationResult) else {
                    print("StoreKitManager: Transaction update verification failed.")
                    continue
                }

                if transaction.revocationDate == nil { 
                     print("StoreKitManager: Verified transaction update for \(transaction.productID). Product type: \(transaction.productType)")
                     self.purchaseOrRestoreSuccessfulPublisher.send([transaction.productID])
                } else {
                     print("StoreKitManager: Transaction for \(transaction.productID) was revoked at \(transaction.revocationDate!).")
                }
                
                await transaction.finish() 
            }
        }
    }

    @discardableResult 
    private func checkVerified<T>(_ verificationResult: VerificationResult<T>) async -> T? {
        switch verificationResult {
        case .unverified(let unverifiedTransaction, let verificationError):
            print("StoreKitManager: Transaction unverified for \(unverifiedTransaction) with error: \(verificationError.localizedDescription)")
            return nil
        case .verified(let verifiedTransaction):
            return verifiedTransaction 
        }
    }

    func syncTransactions() async {
        print("StoreKitManager: Requesting AppStore.sync() to sync transactions.")
        self.isLoading = true
        self.error = nil
        do {
            try await AppStore.sync()
            print("StoreKitManager: AppStore.sync() completed. Updates (if any) will be handled by the transaction listener.")
            await checkForCurrentEntitlements()
        } catch {
            print("StoreKitManager: AppStore.sync() failed with error: \(error)")
            self.error = .purchaseFailed(error) 
        }
        self.isLoading = false
    }
    
    func checkForCurrentEntitlements() async {
        print("StoreKitManager: Checking for current entitlements...")
        var successfullyEntitledProductIDs = Set<String>()
        var entitlementsFound = false
        
        for await verificationResult in StoreKit.Transaction.currentEntitlements {
            entitlementsFound = true
            
            let typedResult: VerificationResult<StoreKit.Transaction> = verificationResult
            guard let transaction = await self.checkVerified(typedResult) else {
                print("StoreKitManager: Found an unverified current entitlement, skipping.")
                continue 
            }
            
            if transaction.productType == .nonConsumable && transaction.revocationDate == nil {
                print("StoreKitManager: Found current entitlement for non-consumable: \(transaction.productID)")
                successfullyEntitledProductIDs.insert(transaction.productID)
            }
        }

        if !entitlementsFound && self.error == nil { 
            print("StoreKitManager: No current entitlements found after iterating (or iterator was empty).")
        }

        if !successfullyEntitledProductIDs.isEmpty {
            print("StoreKitManager: Successfully processed current entitlements for IDs: \(successfullyEntitledProductIDs)")
            purchaseOrRestoreSuccessfulPublisher.send(successfullyEntitledProductIDs)
        }
    }
}

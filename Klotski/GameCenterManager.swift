//
//  GameCenterManager.swift
//  Klotski
//
//  Created by zhukun on 2025/6/23.
//

import Foundation
import GameKit

// MARK: - LeaderboardInfo Wrapper
// 创建一个包装结构体来安全地遵循 Identifiable，避免直接扩展 Apple 的 GKLeaderboard 类。
// This resolves the warning: "Conformance of imported type 'GKLeaderboard' to imported protocol 'Identifiable' will not behave correctly in the future."

public struct LeaderboardInfo: Identifiable {
    /// The unique and stable identifier for the leaderboard, used by SwiftUI's List.
    public let id: String
    
    /// The original GKLeaderboard object from GameKit.
    public let leaderboard: GKLeaderboard
    
    /// A computed property to safely access the leaderboard's title.
    public var title: String {
        return leaderboard.title ?? "未知排行榜"
    }
    
    /// Initializes the wrapper with a GKLeaderboard instance.
    init(leaderboard: GKLeaderboard) {
        self.id = leaderboard.baseLeaderboardID
        self.leaderboard = leaderboard
    }
}


// MARK: - GameCenterManager
@MainActor
class GameCenterManager: ObservableObject {
    
    /// 从 Game Center 获取到的真实排行榜列表，现在使用安全的包装类型。
    @Published var leaderboards: [LeaderboardInfo] = []
    
    /// 标记是否正在加载数据。
    @Published var isLoading: Bool = false
    
    /// 存储加载过程中可能发生的错误。
    @Published var loadingError: Error? = nil
    
    init() {
        print("GameCenterManager initialized.")
    }
    
    /// 从 Game Center 服务器异步获取所有为该应用配置的排行榜。
    func fetchAllLeaderboards() async {
        // 如果玩家未登录Game Center，则不执行任何操作。
        guard GKLocalPlayer.local.isAuthenticated else {
            print("GameCenterManager: Player is not authenticated. Skipping leaderboard fetch.")
            self.leaderboards = []
            return
        }
        
        // 避免重复加载
        guard !isLoading else {
            print("GameCenterManager: Already loading leaderboards.")
            return
        }
        
        print("GameCenterManager: Starting to fetch all leaderboards from App Store Connect...")
        self.isLoading = true
        self.loadingError = nil
        
        do {
            // 使用 `loadLeaderboards` 方法获取所有排行榜 (IDs: nil 表示获取全部)
            let allLeaderboards = try await GKLeaderboard.loadLeaderboards(IDs: nil)
            
            // 按排行榜标题排序
            let sortedLeaderboards = allLeaderboards.sorted {
                $0.title ?? "" < $1.title ?? ""
            }
            
            // 将 [GKLeaderboard] 映射到我们的 [LeaderboardInfo] 包装类型
            self.leaderboards = sortedLeaderboards.map { LeaderboardInfo(leaderboard: $0) }
            
            print("GameCenterManager: Successfully fetched and wrapped \(self.leaderboards.count) leaderboards.")
            
        } catch {
            print("GameCenterManager: Failed to fetch leaderboards with error: \(error.localizedDescription)")
            self.loadingError = error
        }
        
        self.isLoading = false
    }
}


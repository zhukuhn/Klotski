//
//  GameModels.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI
import CloudKit

// MARK: - CloudKit Record Types Constants
struct CloudKitRecordTypes {
    static let UserProfile = "UserProfiles" // Existing
    static let CompletedLevelStats = "CompletedLevelStats" // New for syncing best scores
    // static let GameSave = "GameSave" // For full game state sync (future)
}


// 新增：用于给 View 添加特定角圆角的扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 棋子类型定义
enum PieceType: String, Codable, CaseIterable, Identifiable {
    case caoCao         // 曹操 (2x2)
    case guanYuH        // 横向关羽 (2x1)
    case zhangFeiV      // 纵向张飞 (1x2)
    case zhaoYunV       // 纵向赵云 (1x2)
    case maChaoV        // 纵向马超 (1x2)
    case huangZhongV    // 纵向黄忠 (1x2)
    case soldier        // 兵 (1x1)

    var id: String { self.rawValue }

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .caoCao: return (2, 2)
        case .guanYuH: return (2, 1)
        case .zhangFeiV, .zhaoYunV, .maChaoV, .huangZhongV: return (1, 2)
        case .soldier: return (1, 1)
        }
    }

    var displayName: String {
        switch self {
        case .caoCao: return "曹"
        case .guanYuH: return "关"
        case .zhangFeiV: return "张"
        case .zhaoYunV: return "赵"
        case .maChaoV: return "马"
        case .huangZhongV: return "黄"
        case .soldier: return "兵"
        }
    }
}

// 代表棋盘上一个具体的棋子实例
struct Piece: Identifiable, Codable, Equatable {
    let id: Int
    let type: PieceType
    var x: Int
    var y: Int

    var width: Int { type.dimensions.width }
    var height: Int { type.dimensions.height }

    func occupies(gx: Int, gy: Int) -> Bool {
        return gx >= x && gx < x + width && gy >= y && gy < y + height
    }
}

// 关卡中棋子的初始放置定义
struct PiecePlacement: Codable, Identifiable {
    let id: Int
    let type: PieceType
    let initialX: Int
    let initialY: Int
}

struct Level: Identifiable, Codable {
    let id: String
    var name: String
    
    let boardWidth: Int
    let boardHeight: Int

    var piecePlacements: [PiecePlacement]
    
    let targetPieceId: Int
    let targetX: Int
    let targetY: Int
    
    var bestMoves: Int?
    var bestTime: TimeInterval?
    var isUnlocked: Bool = true

    var recordChangeTag: String? // For CloudKit optimistic locking if syncing whole Level object
}

// MARK: - Completed Level Stats for CloudKit
// This struct represents the data for a completed level's best score to be synced with CloudKit.
struct CompletedLevelCloudStats: Identifiable {
    var id: String // Corresponds to Level.id, will be used as CKRecord.ID.recordName
    var bestMoves: Int
    var bestTime: TimeInterval
    var ckRecordChangeTag: String? // To store the CKRecord's change tag for conflict resolution

    init(id: String, bestMoves: Int, bestTime: TimeInterval, ckRecordChangeTag: String? = nil) {
        self.id = id
        self.bestMoves = bestMoves
        self.bestTime = bestTime
        self.ckRecordChangeTag = ckRecordChangeTag
    }

    // Initialize from a CKRecord
    init?(from record: CKRecord) {
        guard record.recordType == CloudKitRecordTypes.CompletedLevelStats,
              let moves = record["bestMoves"] as? Int64, // CloudKit typically uses Int64 for numbers
              let time = record["bestTime"] as? Double else {
            print("Error: Could not initialize CompletedLevelCloudStats from CKRecord. Missing fields or type mismatch for record: \(record.recordID.recordName)")
            return nil
        }
        self.id = record.recordID.recordName // Assuming recordName is the levelID
        self.bestMoves = Int(moves)
        self.bestTime = time
        self.ckRecordChangeTag = record.recordChangeTag
    }

    // Convert to a CKRecord
    // If existingRecord is provided, it updates that record. Otherwise, creates a new one.
    func toCKRecord(existingRecord: CKRecord? = nil) -> CKRecord {
        let record: CKRecord
        if let existing = existingRecord {
            record = existing
            if let localTag = self.ckRecordChangeTag, localTag != existing.recordChangeTag {
                 print("Warning: CKRecord change tag mismatch for \(self.id). Local: \(localTag), Server: \(existing.recordChangeTag ?? "nil"). This might lead to a conflict if not handled by save policy.")
            }
        } else {
            let recordID = CKRecord.ID(recordName: self.id)
            record = CKRecord(recordType: CloudKitRecordTypes.CompletedLevelStats, recordID: recordID)
        }

        record["bestMoves"] = self.bestMoves as CKRecordValue
        record["bestTime"] = self.bestTime as CKRecordValue
        return record
    }
}






struct UserProfile: Identifiable, Codable {
    var id: String
    var iCloudUserRecordName: String
    
    var displayName: String?
    var email: String?
    var purchasedThemeIDs: Set<String> = []
    var registrationDate: Date?

    var recordChangeTag: String?

    init(id: String = UUID().uuidString,
         iCloudUserRecordName: String,
         displayName: String? = nil,
         email: String? = nil,
         purchasedThemeIDs: Set<String> = [],
         registrationDate: Date? = Date(),
         recordChangeTag: String? = nil) {
        self.id = id
        self.iCloudUserRecordName = iCloudUserRecordName
        self.displayName = displayName
        self.email = email
        self.purchasedThemeIDs = purchasedThemeIDs
        self.registrationDate = registrationDate
        self.recordChangeTag = recordChangeTag
    }
}

extension UserProfile {
    init?(from record: CKRecord) {
        guard record.recordType == CloudKitRecordTypes.UserProfile else {
            print("UserProfile init(from record): 记录类型不正确。预期为 '\(CloudKitRecordTypes.UserProfile)'，实际为 '\(record.recordType)'")
            return nil
        }
        
        self.id = record.recordID.recordName
        
        guard let iCloudUserRecordName = record["iCloudUserRecordName"] as? String else {
            print("UserProfile init(from record): 缺少 'iCloudUserRecordName' 字段或类型不匹配。")
            return nil
        }
        self.iCloudUserRecordName = iCloudUserRecordName
        
        self.displayName = record["displayName"] as? String
        self.email = record["email"] as? String
        
        if let purchasedIDsArray = record["purchasedThemeIDs"] as? [String] {
            self.purchasedThemeIDs = Set(purchasedIDsArray)
        } else {
            self.purchasedThemeIDs = Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        }
        
        self.registrationDate = record["registrationDate"] as? Date ?? record.creationDate
        self.recordChangeTag = record.recordChangeTag
    }

    func toCKRecord(existingRecord: CKRecord? = nil) -> CKRecord {
        let recordToUse: CKRecord

        if let existing = existingRecord {
            if existing.recordID.recordName == self.id && existing.recordType == CloudKitRecordTypes.UserProfile {
                recordToUse = existing
            } else {
                print("UserProfile toCKRecord: 严重错误 - 提供的 existingRecord (id: \(existing.recordID.recordName), type: \(existing.recordType)) 与 UserProfile (id: \(self.id)) 不匹配。将创建一个新记录。")
                let newRecordID = CKRecord.ID(recordName: self.id)
                recordToUse = CKRecord(recordType: CloudKitRecordTypes.UserProfile, recordID: newRecordID)
            }
        } else {
            let newRecordID = CKRecord.ID(recordName: self.id)
            recordToUse = CKRecord(recordType: CloudKitRecordTypes.UserProfile, recordID: newRecordID)
        }

        recordToUse["iCloudUserRecordName"] = self.iCloudUserRecordName as CKRecordValue
        recordToUse["displayName"] = self.displayName as CKRecordValue?
        recordToUse["email"] = self.email as CKRecordValue?
        recordToUse["purchasedThemeIDs"] = Array(self.purchasedThemeIDs) as CKRecordValue
        recordToUse["registrationDate"] = self.registrationDate as CKRecordValue?
        
        return recordToUse
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    var rank: Int
    var playerName: String
    var moves: Int
    var levelID: String
}

// For full game state sync (currently not implemented for CloudKit, only local save)
struct GameSave: Identifiable {
    var id: String
    var levelID: String
    var moves: Int
    var timeElapsed: TimeInterval
    var piecesData: Data
    var lastModified: Date
}

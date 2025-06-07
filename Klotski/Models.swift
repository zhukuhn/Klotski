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
            // Ensure the change tag matches for optimistic locking, if provided
            if let localTag = self.ckRecordChangeTag, localTag != existing.recordChangeTag {
                 print("Warning: CKRecord change tag mismatch for \(self.id). Local: \(localTag), Server: \(existing.recordChangeTag ?? "nil"). This might lead to a conflict if not handled by save policy.")
            }
        } else {
            // For a new record, the recordName will be the levelID
            let recordID = CKRecord.ID(recordName: self.id)
            record = CKRecord(recordType: CloudKitRecordTypes.CompletedLevelStats, recordID: recordID)
        }

        record["bestMoves"] = self.bestMoves as CKRecordValue
        record["bestTime"] = self.bestTime as CKRecordValue
        // 'levelID' is implicitly stored in record.recordID.recordName
        return record
    }
}


// 用于表示 SwiftUI.ColorScheme 的自定义 Codable 枚举
enum CodableColorScheme: String, Codable, Equatable, CaseIterable {
    case light, dark

    var swiftUIScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    init(_ scheme: ColorScheme) {
        switch scheme {
        case .light: self = .light
        case .dark: self = .dark
        @unknown default: self = .light 
        }
    }
}

struct Theme: Identifiable, Codable, Equatable {
    let id: String 
    var name: String 
    var isPremium: Bool 
    var price: Double? 
    var productID: String? 

    var backgroundColor: CodableColor 
    var sliderColor: CodableColor 
    var sliderTextColor: CodableColor 
    var boardBackgroundColor: CodableColor 
    var boardGridLineColor: CodableColor 
    var sliderShape: SliderShape = .roundedRectangle 
    var sliderContent: SliderContentType = .character 
    var fontName: String? 

    var codableColorScheme: CodableColorScheme = .light

    var swiftUIScheme: ColorScheme { codableColorScheme.swiftUIScheme }

    init(id: String, name: String, isPremium: Bool, price: Double? = nil, productID: String? = nil,
         backgroundColor: CodableColor, sliderColor: CodableColor,sliderTextColor: CodableColor,
         boardBackgroundColor: CodableColor, boardGridLineColor: CodableColor,
         sliderShape: SliderShape = .roundedRectangle, sliderContent: SliderContentType = .character,
         fontName: String? = nil, colorScheme: ColorScheme = .light) { 
        self.id = id
        self.name = name
        self.isPremium = isPremium
        self.price = price
        self.productID = productID
        self.backgroundColor = backgroundColor
        self.sliderColor = sliderColor
        self.sliderTextColor = sliderTextColor
        self.boardBackgroundColor = boardBackgroundColor
        self.boardGridLineColor = boardGridLineColor
        self.sliderShape = sliderShape
        self.sliderContent = sliderContent
        self.fontName = fontName
        self.codableColorScheme = CodableColorScheme(colorScheme) 
    }
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.id == rhs.id
    }
}

struct AppThemeRepository {
    static let allThemes: [Theme] = [
        Theme(id: "default", name: "默认浅色", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: .white),
              sliderColor: CodableColor(color: .blue), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(white: 0.9)), boardGridLineColor: CodableColor(color: Color(white: 0.7)),
              fontName: nil, colorScheme: .light),
        Theme(id: "dark", name: "深邃夜空", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: .black),
              sliderColor: CodableColor(color: .orange), sliderTextColor: CodableColor(color: .black),
              boardBackgroundColor: CodableColor(color: Color(white: 0.2)), boardGridLineColor: CodableColor(color: Color(white: 0.4)),
              fontName: nil, colorScheme: .dark),
        Theme(id: "neonNoir", name: "霓虹暗辉", isPremium: false, productID: nil,
              // 背景使用深色渐变，这里用一个基色代替，实际背景在 View 层实现
              backgroundColor: CodableColor(color: Color(red: 0.05, green: 0, blue: 0.15)), 
              // sliderColor 定义霓虹灯的主色调 (例如，洋红色)
              sliderColor: CodableColor(color: Color(red: 1, green: 0, blue: 0.5)), 
              // sliderTextColor 是霓虹灯上文字的颜色，通常是亮的
              sliderTextColor: CodableColor(color: .white), 
              // 棋盘背景是半透明黑色
              boardBackgroundColor: CodableColor(color: .black.opacity(0.3)),
              // 棋盘网格线是发光的霓虹蓝
              boardGridLineColor: CodableColor(color: Color(red: 0, green: 0.8, blue: 1)), 
              sliderShape: .roundedRectangle, 
              sliderContent: .character,
              fontName: "AvenirNext-Bold", // 使用一个现代感的字体
              colorScheme: .dark),
        Theme(id: "forest", name: "森林绿意", isPremium: true, price: 1.00, productID: "com.shenlan.Klotski.theme.forest",
              backgroundColor: CodableColor(color: Color(red: 161/255, green: 193/255, blue: 129/255)),
              sliderColor: CodableColor(color: Color(red: 103/255, green: 148/255, blue: 54/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 200/255, green: 220/255, blue: 180/255)), boardGridLineColor: CodableColor(color: Color(red: 120/255, green: 150/255, blue: 100/255)),
              fontName: "Georgia", colorScheme: .light),
        Theme(id: "ocean", name: "蔚蓝海洋", isPremium: true, price: 1.00, productID: "com.shenlan.Klotski.theme.ocean",
              backgroundColor: CodableColor(color: Color(red: 86/255, green: 207/255, blue: 225/255)),
              sliderColor: CodableColor(color: Color(red: 78/255, green: 168/255, blue: 222/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 180/255, green: 225/255, blue: 235/255)), boardGridLineColor: CodableColor(color: Color(red: 100/255, green: 150/255, blue: 180/255)),
              fontName: "HelveticaNeue-Light", colorScheme: .light)
    ]
}

enum SliderShape: String, Codable, CaseIterable {
    case roundedRectangle, square, customImage 
}

enum SliderContentType: String, Codable, CaseIterable {
    case number    
    case pattern   
    case character 
    case none      
}

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color { Color(red: red, green: green, blue: blue, opacity: opacity) }

    init(color: Color) {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        #else
        let uiColor = NSColor(color) 
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &o)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(o)
    }
    
    static func == (lhs: CodableColor, rhs: CodableColor) -> Bool {
        return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue && lhs.opacity == rhs.opacity
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: 
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: 
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: 
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
        guard record.recordType == CloudKitRecordTypes.UserProfile else { // Use constant
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
            // Default to only free themes if not found in CloudKit or on first creation
            self.purchasedThemeIDs = Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        }
        
        self.registrationDate = record["registrationDate"] as? Date ?? record.creationDate
        self.recordChangeTag = record.recordChangeTag
    }

    func toCKRecord(existingRecord: CKRecord? = nil) -> CKRecord {
        let recordToUse: CKRecord 

        if let existing = existingRecord {
            if existing.recordID.recordName == self.id && existing.recordType == CloudKitRecordTypes.UserProfile { // Use constant
                recordToUse = existing
            } else {
                print("UserProfile toCKRecord: 严重错误 - 提供的 existingRecord (id: \(existing.recordID.recordName), type: \(existing.recordType)) 与 UserProfile (id: \(self.id)) 不匹配。将创建一个新记录。")
                let newRecordID = CKRecord.ID(recordName: self.id) 
                recordToUse = CKRecord(recordType: CloudKitRecordTypes.UserProfile, recordID: newRecordID) // Use constant
            }
        } else {
            let newRecordID = CKRecord.ID(recordName: self.id) 
            recordToUse = CKRecord(recordType: CloudKitRecordTypes.UserProfile, recordID: newRecordID) // Use constant
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

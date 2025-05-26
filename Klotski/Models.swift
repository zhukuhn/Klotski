//
//  GameModels.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI
import FirebaseFirestore

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
    //可以根据需要添加更多，例如横向的武将

    var id: String { self.rawValue }

    // 定义每种棋子的尺寸 (宽度, 高度)，单位为格子数
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .caoCao: return (2, 2)
        case .guanYuH: return (2, 1)
        case .zhangFeiV, .zhaoYunV, .maChaoV, .huangZhongV: return (1, 2)
        case .soldier: return (1, 1)
        }
    }

    // 为棋子提供一个显示名称 (可选)
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
    let id: Int // 棋子的唯一实例ID (例如 1, 2, 3...)
    let type: PieceType
    var x: Int // 左上角 x 坐标 (格子索引)
    var y: Int // 左上角 y 坐标 (格子索引)

    var width: Int { type.dimensions.width }
    var height: Int { type.dimensions.height }

    // 辅助函数，用于检查此棋子是否占据某个格子
    func occupies(gx: Int, gy: Int) -> Bool {
        return gx >= x && gx < x + width && gy >= y && gy < y + height
    }
}

// 关卡中棋子的初始放置定义
struct PiecePlacement: Codable, Identifiable {
    let id: Int // 与 Piece.id 对应
    let type: PieceType
    let initialX: Int
    let initialY: Int
}
struct Level: Identifiable, Codable {
    let id: String
    var name: String //关卡名称
    
    // 棋盘尺寸 (总宽度，总高度)，单位为格子数
    let boardWidth: Int
    let boardHeight: Int

    // 棋子布局，使用 PiecePlacement 数组
    var piecePlacements: [PiecePlacement]
    
    // 胜利条件：例如，曹操 (通常是ID为1的棋子) 的目标位置
    let targetPieceId: Int
    let targetX: Int
    let targetY: Int
    
    var bestMoves: Int?
    var bestTime: TimeInterval?
    var isUnlocked: Bool = true // Or based on game progression
}

// 用于表示 SwiftUI.ColorScheme 的自定义 Codable 枚举
enum CodableColorScheme: String, Codable, Equatable, CaseIterable {
    case light, dark // 浅色模式，深色模式

    // 计算属性，用于转换为 SwiftUI.ColorScheme
    var swiftUIScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    // 初始化方法，用于从 SwiftUI.ColorScheme 转换
    init(_ scheme: ColorScheme) {
        switch scheme {
        case .light:
            self = .light
        case .dark:
            self = .dark
        @unknown default:
            self = .light // 对于未知的未来 case，默认为浅色模式
        }
    }
}

struct Theme: Identifiable, Codable, Equatable {
    let id: String // 主题唯一ID
    var name: String // 主题名称
    var isPremium: Bool // 是否为付费主题
    var price: Double? // 付费主题的价格

    // 视觉属性
    var backgroundColor: CodableColor // 背景颜色
    var sliderColor: CodableColor // 滑块颜色 (华容道方块)
    var sliderTextColor: CodableColor // 棋子上文字的默认颜色
    var boardBackgroundColor: CodableColor // 棋盘网格背景色
    var boardGridLineColor: CodableColor // 棋盘网格线颜色
    var sliderShape: SliderShape = .roundedRectangle // 滑块形状
    var sliderContent: SliderContentType = .character // 滑块上显示的内容 (数字、图案等)
    var fontName: String? // 此主题的可选自定义字体 (UI 和/或滑块内容)

    // 直接存储 CodableColorScheme 而不是 SwiftUI.ColorScheme
    var codableColorScheme: CodableColorScheme = .light

    // 计算属性，用于在视图中获取 SwiftUI.ColorScheme
    var swiftUIScheme: ColorScheme { codableColorScheme.swiftUIScheme }

    // 初始化方法已更新，接受 SwiftUI.ColorScheme 并进行转换
    init(id: String, name: String, isPremium: Bool, price: Double? = nil,
         backgroundColor: CodableColor, sliderColor: CodableColor,sliderTextColor: CodableColor,
         boardBackgroundColor: CodableColor, boardGridLineColor: CodableColor,
         sliderShape: SliderShape = .roundedRectangle, sliderContent: SliderContentType = .character,
         fontName: String? = nil, colorScheme: ColorScheme = .light) { // 接受 SwiftUI.ColorScheme
        self.id = id
        self.name = name
        self.isPremium = isPremium
        self.price = price
        self.backgroundColor = backgroundColor
        self.sliderColor = sliderColor
        self.sliderTextColor = sliderTextColor
        self.boardBackgroundColor = boardBackgroundColor
        self.boardGridLineColor = boardGridLineColor
        self.sliderShape = sliderShape
        self.sliderContent = sliderContent
        self.fontName = fontName
        self.codableColorScheme = CodableColorScheme(colorScheme) // 转换并存储
    }
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.id == rhs.id
//        lhs.name == rhs.name &&
//        lhs.isPremium == rhs.isPremium &&
//        lhs.price == rhs.price &&
//        lhs.backgroundColor == rhs.backgroundColor &&
//        lhs.sliderColor == rhs.sliderColor &&
//        lhs.sliderShape == rhs.sliderShape &&
//        lhs.sliderContent == rhs.sliderContent &&
//        lhs.fontName == rhs.fontName &&
//        lhs.codableColorScheme == rhs.codableColorScheme // 比较可编码的表示
    }
}

enum SliderShape: String, Codable, CaseIterable {
    case roundedRectangle, square, customImage // customImage might imply using image assets for sliders
}

enum SliderContentType: String, Codable, CaseIterable {
    case number    // e.g., for number-based Klotski or just as abstract identifiers
    case pattern   // Themed patterns on sliders
    case character // e.g., "曹操", "兵" if using traditional Klotski piece names
    case none      // Sliders are just colored shapes
}

// Helper to make Color Codable
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color { Color(red: red, green: green, blue: blue, opacity: opacity) }

    init(color: Color) {
        // UIColor conversion is more reliable for getting RGBA components
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        #else
        let uiColor = NSColor(color) // For macOS compatibility if ever needed
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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


struct UserProfile: Codable, Identifiable { // Identifiable 通常用于 SwiftUI 列表
    @DocumentID var id: String? // Firestore 文档 ID，会自动映射
    let uid: String // Firebase Auth 用户 UID，这将是 Firestore 文档的主要标识符
    var displayName: String?
    var email: String?
    var purchasedThemeIDs: Set<String> = []
    var registrationDate: Date? // 可选：记录用户注册时间

    // 如果 id 是 nil (例如新创建的 UserProfile 还未存入 Firestore)，或者你想在 SwiftUI 中使用 uid 作为 Identifiable 的 id：
    // var identifiableID: String { id ?? uid }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID() // For identifiable in SwiftUI lists
    var rank: Int
    var playerName: String
    var moves: Int
    var levelID: String // To associate entry with a specific level
}


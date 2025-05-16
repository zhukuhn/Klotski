//
//  GameModels.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//

import SwiftUI

struct Level: Identifiable, Codable {
    let id: String
    var name: String
    // Represents the board:
    // 0: empty space
    // Positive integers: unique ID for each block instance.
    // The actual block (e.g., CaoCao, Soldier) and its dimensions
    // would be defined elsewhere or inferred based on a convention for these IDs.
    // For simplicity here, it's just Int. A more robust model might use:
    // struct PiecePlacement { let pieceId: Int, type: PieceType, x: Int, y: Int, width: Int, height: Int }
    // And layout could be [PiecePlacement] or a 2D array storing pieceId.
    // The current [[Int]] implies a fixed grid where each number represents a part of a block
    // or a unique small block. This needs to be interpreted by the game logic.
    // For Klotski with different shapes, a list of (PieceType, x, y, width, height) is often better for initial setup.
    // Let's assume for now `layout` is a simplified representation for the grid.
    var layout: [[Int]] // Example: [[1,1,2,3],[1,1,4,5],[6,7,0,8],[9,10,11,12],[13,14,15,0]] for a 4x5 board
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
    var sliderShape: SliderShape = .roundedRectangle // 滑块形状
    var sliderContent: SliderContentType = .number // 滑块上显示的内容 (数字、图案等)
    var fontName: String? // 此主题的可选自定义字体 (UI 和/或滑块内容)

    // 直接存储 CodableColorScheme 而不是 SwiftUI.ColorScheme
    var codableColorScheme: CodableColorScheme = .light

    // 计算属性，用于在视图中获取 SwiftUI.ColorScheme
    var swiftUIScheme: ColorScheme {
        codableColorScheme.swiftUIScheme
    }

    // 初始化方法已更新，接受 SwiftUI.ColorScheme 并进行转换
    init(id: String, name: String, isPremium: Bool, price: Double? = nil,
         backgroundColor: CodableColor, sliderColor: CodableColor,
         sliderShape: SliderShape = .roundedRectangle, sliderContent: SliderContentType = .number,
         fontName: String? = nil, colorScheme: ColorScheme = .light) { // 接受 SwiftUI.ColorScheme
        self.id = id
        self.name = name
        self.isPremium = isPremium
        self.price = price
        self.backgroundColor = backgroundColor
        self.sliderColor = sliderColor
        self.sliderShape = sliderShape
        self.sliderContent = sliderContent
        self.fontName = fontName
        self.codableColorScheme = CodableColorScheme(colorScheme) // 转换并存储
    }
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.isPremium == rhs.isPremium &&
        lhs.price == rhs.price &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.sliderColor == rhs.sliderColor &&
        lhs.sliderShape == rhs.sliderShape &&
        lhs.sliderContent == rhs.sliderContent &&
        lhs.fontName == rhs.fontName &&
        lhs.codableColorScheme == rhs.codableColorScheme // 比较可编码的表示
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

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

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


struct UserProfile: Codable {
    let uid: String
    var displayName: String?
    var email: String?
    var purchasedThemeIDs: Set<String> = [] // Initialize as empty set
    // Add other user-specific data
}

struct LeaderboardEntry: Identifiable {
    let id = UUID() // For identifiable in SwiftUI lists
    var rank: Int
    var playerName: String
    var moves: Int
    var levelID: String // To associate entry with a specific level
}


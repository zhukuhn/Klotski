
//
//  ThemeFactory.swift
//  Klotski
//
//  Created by Your Name on 2025/6/7.
//
//  This file centralizes all theme-specific rendering logic using the Strategy Pattern.
//

import SwiftUI


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
    
    // --- 新增：返回对应的主题渲染策略 ---
    var viewFactory: any ThemeableViewFactory {
        switch id {
        case "dark":
            DarkThemeRenderer()
        case "forest":
            ForestThemeRenderer()
        case "ocean":
            OceanThemeRenderer()
        // 可以为未来的主题在这里添加 case
        case "auroraGlass":
            AuroraGlassThemeRenderer()
        default:
            DefaultThemeRenderer()
        }
    }

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
        Theme(id: "forest", name: "森林绿意", isPremium: true, price: 1.00, productID: "com.shenlan.Klotski.theme.forest",
              backgroundColor: CodableColor(color: Color(red: 161/255, green: 193/255, blue: 129/255)),
              sliderColor: CodableColor(color: Color(red: 103/255, green: 148/255, blue: 54/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 200/255, green: 220/255, blue: 180/255)), boardGridLineColor: CodableColor(color: Color(red: 120/255, green: 150/255, blue: 100/255)),
              fontName: "Georgia", colorScheme: .light),
        Theme(id: "ocean", name: "蔚蓝海洋", isPremium: true, price: 1.00, productID: "com.shenlan.Klotski.theme.ocean",
              backgroundColor: CodableColor(color: Color(red: 86/255, green: 207/255, blue: 225/255)),
              sliderColor: CodableColor(color: Color(red: 78/255, green: 168/255, blue: 222/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 180/255, green: 225/255, blue: 235/255)), boardGridLineColor: CodableColor(color: Color(red: 100/255, green: 150/255, blue: 180/255)),
              fontName: "HelveticaNeue-Light", colorScheme: .light),
        Theme(id: "auroraGlass", name: "极光玻璃", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: Color(red: 20/255, green: 20/255, blue: 40/255)), // 深紫色基底
              sliderColor: CodableColor(color: Color(red: 140/255, green: 160/255, blue: 200/255).opacity(0.5)), // 半透明的柔和蓝色
              sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: .clear), // 棋盘背景由材质提供
              boardGridLineColor: CodableColor(color: .white.opacity(0.2)), // 几乎不可见的网格线
              sliderShape: .roundedRectangle,
              sliderContent: .none, // 该主题不显示文字以保持简洁
              fontName: "AvenirNext-Regular", // 备用字体
              colorScheme: .dark)
    ]
}

// MARK: - Default Theme Renderer
/// Provides the views for the "Default Light" theme.
struct DefaultThemeRenderer: ThemeableViewFactory {

    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "default" }!

    @ViewBuilder
    func gameBackground() -> any View {
        theme.backgroundColor.color.ignoresSafeArea()
    }

    @ViewBuilder
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme)
    }

    @ViewBuilder
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging)
    }
    
    func menuButtonStyle() -> AnyButtonStyle {
        return AnyButtonStyle(StandardMenuButtonStyle(theme: theme))
    }
}

// MARK: - Dark Theme Renderer
/// Provides the views for the "Dark" theme.
struct DarkThemeRenderer: ThemeableViewFactory {
    
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "dark" }!

    @ViewBuilder
    func gameBackground() -> any View {
        theme.backgroundColor.color.ignoresSafeArea()
    }
    
    @ViewBuilder
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme)
    }

    @ViewBuilder
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging)
    }
    
    func menuButtonStyle() -> AnyButtonStyle {
        return AnyButtonStyle(StandardMenuButtonStyle(theme: theme))
    }
}

// MARK: - Forest Theme Renderer
struct ForestThemeRenderer: ThemeableViewFactory {
    
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "forest" }!

    @ViewBuilder
    func gameBackground() -> any View {
        theme.backgroundColor.color.ignoresSafeArea()
    }
    
    @ViewBuilder
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme)
    }

    @ViewBuilder
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging)
    }
    
    func menuButtonStyle() -> AnyButtonStyle {
        return AnyButtonStyle(StandardMenuButtonStyle(theme: theme))
    }
}

// MARK: - Ocean Theme Renderer
struct OceanThemeRenderer: ThemeableViewFactory {
    
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "ocean" }!
    
    @ViewBuilder
    func gameBackground() -> any View {
        theme.backgroundColor.color.ignoresSafeArea()
    }
    
    @ViewBuilder
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme)
    }

    @ViewBuilder
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging)
    }
    
    func menuButtonStyle() -> AnyButtonStyle {
        return AnyButtonStyle(StandardMenuButtonStyle(theme: theme))
    }
}

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
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, o: CGFloat = 0
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

// MARK: - Aurora Glass Theme Renderer
// --- 这是为新主题创建的全新渲染策略 ---
struct AuroraGlassThemeRenderer: ThemeableViewFactory {
    
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "auroraGlass" }!

    @ViewBuilder
    func gameBackground() -> any View {
        // --- 已修正的背景实现 ---
        ZStack {
            // 1. 首先，建立一个从上到下的深色渐变作为基底，确保背景足够暗
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.25), Color(red: 0.05, green: 0.05, blue: 0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 2. 然后，将极光色彩的角向渐变以半透明的方式叠加在上方
            AngularGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.7, blue: 0.8), // Soft Pink
                    Color(red: 0.6, green: 0.7, blue: 0.9), // Soft Purple
                    Color(red: 0.5, green: 0.8, blue: 0.9), // Soft Blue
                    Color(red: 0.5, green: 0.9, blue: 0.8), // Soft Teal
                    Color(red: 0.9, green: 0.7, blue: 0.8)  // Loop back to Pink
                ]),
                center: .center,
                angle: .degrees(90)
            )
            .blur(radius: 80) // 使用强力模糊来创造柔和的氛围
            .opacity(0.6) // 设置透明度让下方的深色基底能够透出来
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        // 2. 实现毛玻璃效果的棋盘
        ZStack {
            // 毛玻璃材质背景
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear) // 清除填充色，让材质效果可见
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 微妙的白色边框，增加层次感
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
    }

    @ViewBuilder
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        // 3. 实现半透明、有柔和阴影的棋子
        let pieceShape = RoundedRectangle(cornerRadius: cellSize * 0.15, style: .continuous)
        
        pieceShape
            .fill(theme.sliderColor.color)
            .shadow(
                color: .black.opacity(isDragging ? 0.3 : 0.15),
                radius: isDragging ? 10 : 5,
                x: 0,
                y: isDragging ? 8 : 4
            )
    }
    
    func menuButtonStyle() -> AnyButtonStyle {
        // 对于这个主题，我们可以复用标准按钮样式，因为它足够通用
        // 如果需要，也可以创建一个新的 AuroraMenuButtonStyle
        return AnyButtonStyle(StandardMenuButtonStyle(theme: theme))
    }
}


struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    /// Creates a type-erasing style that wraps the given style.
    /// - Parameter style: The concrete style to wrap.
    init<S: ButtonStyle>(_ style: S) {
        self._makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        return _makeBody(configuration)
    }
}

// MARK: - Themeable View Factory Protocol
/// Defines a set of rules for what components a theme must be able to produce.
/// Each theme will have a concrete implementation of this protocol.
protocol ThemeableViewFactory {
    /// Returns the main background for the game view.
    @ViewBuilder func gameBackground() -> any View

    /// Returns the view for the game board's background and grid.
    @ViewBuilder func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View

    /// Returns the view for a single puzzle piece.
    @ViewBuilder func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View
    
    /// Returns a type-erased style for the main menu buttons.
    func menuButtonStyle() -> AnyButtonStyle
}


// MARK: - Reusable Standard Views
/// These are the generic views used by the non-specialized themes.
/// Logic from the old PieceView and BoardBackgroundView is moved here.

fileprivate struct StandardBoardBackgroundView: View {
    let widthCells: Int
    let heightCells: Int
    let cellSize: CGFloat
    let theme: Theme

    var body: some View {
        ZStack {
            Rectangle().fill(theme.boardBackgroundColor.color)
            Path { path in
                for i in 0...widthCells {
                    let x = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: CGFloat(heightCells) * cellSize))
                }
                for i in 0...heightCells {
                    let y = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: CGFloat(widthCells) * cellSize, y: y))
                }
            }
            .stroke(theme.boardGridLineColor.color, lineWidth: 1)
        }
    }
}

fileprivate struct StandardPieceView: View {
    let piece: Piece
    let cellSize: CGFloat
    let theme: Theme
    var isDragging: Bool

    var body: some View {
        let pieceShape = RoundedRectangle(cornerRadius: cellSize * 0.1)
        ZStack {
            pieceShape
                .fill(theme.sliderColor.color)
                .overlay(
                    pieceShape.stroke(theme.sliderColor.color.opacity(0.5), lineWidth: 1)
                )
            
            // 只有当主题要求显示内容时才显示文字
            if theme.sliderContent == .character {
                Text(piece.type.displayName)
                    .font(theme.fontName != nil ? .custom(theme.fontName!, size: calculateFontSize(for: piece, cellSize: cellSize)) : .system(size: calculateFontSize(for: piece, cellSize: cellSize), weight: .bold))
                    .foregroundColor(theme.sliderTextColor.color)
            }
        }
        .shadow(color: .black.opacity(isDragging ? 0.4 : 0.2), radius: isDragging ? 8 : 3, x: isDragging ? 4 : 1, y: isDragging ? 4 : 1)
    }

    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat {
        let baseSize = cellSize * 0.5
        if piece.width == 1 && piece.height == 1 { return baseSize * 0.8 }
        if piece.width == 2 && piece.height == 2 { return baseSize * 1.2 }
        return baseSize
    }
}

fileprivate struct StandardMenuButtonStyle: ButtonStyle {
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.fontName != nil ? .custom(theme.fontName!, size: 18) : .headline)
            .fontWeight(.medium)
            .padding()
            .frame(maxWidth: 280, minHeight: 50)
            .background(theme.sliderColor.color.opacity(configuration.isPressed ? 0.7 : 0.9))
            .foregroundColor(theme.backgroundColor.color)
            .cornerRadius(12)
            .shadow(color: theme.sliderColor.color.opacity(0.3), radius: configuration.isPressed ? 3 : 5, x: 0, y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


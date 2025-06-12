//
//  ThemeFactory.swift
//  Klotski
//
//  Created by zhu kun on 2025/6/7.

import SwiftUI
// --- 定义一个自定义的环境键，用于传递偏移量 ---
private struct BackgroundOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var backgroundOffset: CGFloat {
        get { self[BackgroundOffsetKey.self] }
        set { self[BackgroundOffsetKey.self] = newValue }
    }
}
// --- 环境键定义结束 ---

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
    
    // --- 返回对应的主题渲染策略 ---
    var viewFactory: any ThemeableViewFactory {
        switch id {
        case "dark":
            DarkThemeRenderer()
        case "forest":
            ForestThemeRenderer()
        case "ocean":
            OceanThemeRenderer()
        case "auroraGlass":
            AuroraGlassThemeRenderer()
        case "toonPudding":
            ToonPuddingThemeRenderer()
        case "woodcut":
            WoodcutThemeRenderer()
        case "memphisPop":
            MemphisPopThemeRenderer()
        case "chocolate":
            ChocolateThemeRenderer()
        case "mechanism":
            MechanismThemeRenderer()
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
        
        Theme(id: "auroraGlass", name: "极光玻璃", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: Color(red: 20/255, green: 20/255, blue: 40/255)), // 深紫色基底
              sliderColor: CodableColor(color: Color(red: 140/255, green: 160/255, blue: 200/255).opacity(0.5)), // 半透明的柔和蓝色
              sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: .clear), // 棋盘背景由材质提供
              boardGridLineColor: CodableColor(color: .white.opacity(0.2)), // 几乎不可见的网格线
              sliderShape: .roundedRectangle,
              sliderContent: .none,
              fontName: "AvenirNext-Regular",
              colorScheme: .dark),
              
        Theme(id: "toonPudding", name: "卡通布丁", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: Color(hex: "#FFF5E1")), // 柔和的奶油黄
              sliderColor: CodableColor(color: Color(hex: "#FFC93C")),     // 明亮的芒果黄
              sliderTextColor: CodableColor(color: Color(hex: "#4A4A4A")), // 深灰色文字
              boardBackgroundColor: CodableColor(color: Color(hex: "#FFE0B5")), // 稍深的背景
              boardGridLineColor: CodableColor(color: Color(hex: "#E8C8A0")),   // 描边色
              fontName: "ChalkboardSE-Bold", // 趣味字体
              colorScheme: .light),

        Theme(id: "woodcut", name: "拟物木刻", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: Color(hex: "#6F4E37")), // 深木色
              sliderColor: CodableColor(color: Color(hex: "#C4A484")),     // 浅木色 (棋子)
              sliderTextColor: CodableColor(color: Color(hex: "#4B382A")), // 雕刻文字色
              boardBackgroundColor: CodableColor(color: Color(hex: "#A07855")), // 棋盘木板色
              boardGridLineColor: CodableColor(color: .clear),            // 无网格线
              fontName: "Georgia-Bold",
              colorScheme: .light),
              
        Theme(id: "memphisPop", name: "孟菲斯波普", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: Color(hex: "#FDF0D5")), // 浅米色
              sliderColor: CodableColor(color: Color(hex: "#003049")),     // 深海军蓝 (棋子)
              sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(hex: "#C1121F").opacity(0.1)), // 红色棋盘底
              boardGridLineColor: CodableColor(color: Color(hex: "#F77F00").opacity(0.5)),   // 橙色网格
              fontName: "AvenirNext-Heavy",
              colorScheme: .light),

        
        Theme(id: "chocolate", name: "浓情巧克力", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: Color(hex: "#3D2B1F")), // 背景色作为图片加载失败时的后备
              sliderColor: CodableColor(color: Color(hex: "#8B5E3C")), // 用于按钮主体色
              sliderTextColor: CodableColor(color: .white), // 用于按钮图标
              boardBackgroundColor: CodableColor(color: Color(hex: "#5C4033")), // 棋盘背景色
              boardGridLineColor: CodableColor(color: .clear), // 棋盘不需要网格线
              sliderContent: .none, // 滑块内容由代码绘制，而非文字
              fontName: "Georgia-Bold", // 用于按钮字体
              colorScheme: .dark),
        
        Theme(id: "mechanism", name: "层岩机关", isPremium: false, productID: nil,
                backgroundColor: CodableColor(color: Color(red: 100/255, green: 60/255, blue: 40/255)),    // 后备背景色：深暖棕4A3F3C
                sliderColor: CodableColor(color: Color(hex: "#7B6F6A")),        // 棋子颜色：暖棕褐色
                sliderTextColor: CodableColor(color: Color(hex: "#D9D1CB")),    // 文字颜色：柔和米灰
                boardBackgroundColor: CodableColor(color: Color(hex: "#5D534F")),// 棋盘颜色：岩石灰
                boardGridLineColor: CodableColor(color: .clear),                // 不需要网格线
                fontName: "AvenirNext-Bold",
                colorScheme: .dark),
        
        Theme(id: "dark", name: "深邃夜空", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: .black),
              sliderColor: CodableColor(color: .orange), sliderTextColor: CodableColor(color: .black),
              boardBackgroundColor: CodableColor(color: Color(white: 0.2)), boardGridLineColor: CodableColor(color: Color(white: 0.4)),
              fontName: nil, colorScheme: .dark),
        Theme(id: "forest", name: "森林绿意", isPremium: false, productID: "com.shenlan.Klotski.theme.forest",
              backgroundColor: CodableColor(color: Color(red: 161/255, green: 193/255, blue: 129/255)),
              sliderColor: CodableColor(color: Color(red: 103/255, green: 148/255, blue: 54/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 200/255, green: 220/255, blue: 180/255)), boardGridLineColor: CodableColor(color: Color(red: 120/255, green: 150/255, blue: 100/255)),
              fontName: "Georgia", colorScheme: .light),
        Theme(id: "ocean", name: "蔚蓝海洋", isPremium: false, productID: "com.shenlan.Klotski.theme.ocean",
              backgroundColor: CodableColor(color: Color(red: 86/255, green: 207/255, blue: 225/255)),
              sliderColor: CodableColor(color: Color(red: 78/255, green: 168/255, blue: 222/255)), sliderTextColor: CodableColor(color: .white),
              boardBackgroundColor: CodableColor(color: Color(red: 180/255, green: 225/255, blue: 235/255)), boardGridLineColor: CodableColor(color: Color(red: 100/255, green: 150/255, blue: 180/255)),
              fontName: "HelveticaNeue-Light", colorScheme: .light),
    ]
}

enum CodableColorScheme: String, Codable, Equatable, CaseIterable {
    case light, dark
    var swiftUIScheme: ColorScheme { self == .light ? .light : .dark }
    init(_ scheme: ColorScheme) { self = (scheme == .light) ? .light : .dark }
}

enum SliderShape: String, Codable, CaseIterable { case roundedRectangle, square, customImage }
enum SliderContentType: String, Codable, CaseIterable { case number, pattern, character, none }

struct CodableColor: Codable, Equatable {
    var red: Double, green: Double, blue: Double, opacity: Double
    var color: Color { Color(red: red, green: green, blue: blue, opacity: opacity) }
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, o: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &o)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.opacity = Double(o)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    /// **FIX:** Helper function to adjust color brightness and return a new Color object.
    func adjusted(by brightness: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var oldBrightness: CGFloat = 0
        var alpha: CGFloat = 0

        // Try to get HSB components
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &oldBrightness, alpha: &alpha) {
            let newBrightness = min(max(oldBrightness + brightness, 0.0), 1.0)
            return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        }
        
        // Fallback for grayscale colors
        var white: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            let newWhite = min(max(white + brightness, 0.0), 1.0)
            return Color(UIColor(white: newWhite, alpha: alpha))
        }
        
        // Return original color if conversion fails
        return self
    }
}

// MARK: - THEME RENDERERS (FACTORIES)

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) { self._makeBody = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { _makeBody(configuration) }
}

protocol ThemeableViewFactory {
    @ViewBuilder func gameBackground() -> any View
    @ViewBuilder func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View
    @ViewBuilder func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View
    func menuButtonStyle() -> AnyButtonStyle
}

// MARK: - Standard & Existing Renderers

struct MechanismThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "mechanism" }!

    func gameBackground() -> any View {
        ZStack {
            // 后备的纯色背景，以防图片加载失败
            theme.backgroundColor.color.ignoresSafeArea()

            // 移除所有不必要的颜色遮罩，保持图片原始色彩
            Image("mechanism_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
        }
    }
    
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return shape
            .fill(theme.boardBackgroundColor.color.opacity(0.8))
            .overlay(
                shape
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .blur(radius: 6)
                    .offset(x: 4, y: 4)
                    .mask(shape)
            )
            .overlay(
                shape
                    .stroke(Color.black.opacity(0.4), lineWidth: 8)
                    .blur(radius: 6)
                    .offset(x: -4, y: -4)
                    .mask(shape)
            )
    }

    // --- 棋子视图修改 (已修复错误) ---
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        let shape = RoundedRectangle(cornerRadius: cellSize * 0.15, style: .continuous)
        
        return ZStack {
            // 棋子的基础形状和阴影，提供立体感
            shape
                .fill(theme.sliderColor.color) // 图片加载失败时的后备颜色
                .shadow(color: Color.white.opacity(0.15), radius: isDragging ? 6 : 4, x: isDragging ? -4 : -2, y: isDragging ? -4 : -2)
                .shadow(color: Color.black.opacity(0.4), radius: isDragging ? 6 : 4, x: isDragging ? 4 : 2, y: isDragging ? 4 : 2)

            // --- 错误修复 ---
            // 直接在视图构建器 (@ViewBuilder) 中使用 switch 语句创建 Image 视图。
            // 这样避免了在 @ViewBuilder 中声明局部变量，从而解决了 'buildExpression' 错误。
            switch (piece.width, piece.height) {
            case (2, 2):
                // 请将 "mechanism_piece_2x2" 替换为你的 2x2 棋子图片名称
                Image("mechanism_piece_2x2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case (2, 1):
                // 请将 "mechanism_piece_2x1" 替换为你的 2x1 棋子图片名称
                Image("mechanism_piece_2x1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case (1, 2):
                // 请将 "mechanism_piece_1x2" 替换为你的 1x2 棋子图片名称
                Image("mechanism_piece_1x2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default: // 1x1
                // 请将 "mechanism_piece_1x1" 替换为你的 1x1 棋子图片名称
                Image("mechanism_piece_1x1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .clipShape(shape) // 保证图片被裁剪为棋子形状
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
    }


    func menuButtonStyle() -> AnyButtonStyle {
        AnyButtonStyle(MechanismButtonStyle(theme: theme))
    }
}

struct MechanismButtonStyle: ButtonStyle {
    let theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        StyleHelper(theme: theme, configuration: configuration)
    }

    private struct StyleHelper: View {
        let theme: Theme
        let configuration: Configuration
        @State private var isActive = true
        
        @Environment(\.backgroundOffset) private var backgroundOffset: CGFloat

        var body: some View {
            let isPressed = configuration.isPressed && isActive
            
            // --- 修改部分：实现雕刻文字效果 ---
            ZStack {
                // 内阴影 (模拟雕刻的暗边，在左上方)
                configuration.label
                    .offset(x: -1, y: -1)
                    .foregroundColor(Color.black.opacity(0.4))

                // 内高光 (模拟雕刻的亮边，在右下方)
                configuration.label
                    .offset(x: 1, y: 1)
                    .foregroundColor(Color.white.opacity(0.15))
                
                // 主文字层
                configuration.label
                    .foregroundColor(theme.sliderTextColor.color)
            }
            .font(.custom(theme.fontName ?? "AvenirNext-Bold", size: 20))
            .padding()
            .frame(maxWidth: 280, minHeight: 50)
            .background(
                GeometryReader { geo in
                    let frame = geo.frame(in: .named("MechanismBackground"))
                    
                    if frame.origin.x.isFinite && frame.origin.y.isFinite {
                        Image("mechanism_background")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .offset(
                                x: -frame.minX,
                                y: -frame.minY - backgroundOffset
                            )
                            .frame(width: UIScreen.main.bounds.width, 
                                   height: UIScreen.main.bounds.height)
                            .scaleEffect(isPressed ? 0.98 : 1.0)
                    } else {
                        theme.sliderColor.color
                    }
                }
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
            .overlay(
                Group {
                    if isPressed {
                        Capsule()
                            .stroke(Color.black, lineWidth: 6)
                            .blur(radius: 3)
                            .offset(x: 2, y: 2)
                            .mask(Capsule())
                    }
                }
            )
            .offset(y: isPressed ? 5 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: isPressed)
            .onAppear { isActive = true }
            .onDisappear { isActive = false }
        }
    }
}








struct DefaultThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "default" }!
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View { StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme) }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View { StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging) }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
}

struct DarkThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "dark" }!
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View { StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme) }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View { StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging) }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
}

struct ForestThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "forest" }!
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View { StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme) }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View { StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging) }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
}

struct OceanThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "ocean" }!
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View { StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme) }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View { StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging) }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
}

struct AuroraGlassThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "auroraGlass" }!
    func gameBackground() -> any View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.25), Color(red: 0.05, green: 0.05, blue: 0.15)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            AngularGradient(gradient: Gradient(colors: [Color(hex: "#E0BBE4"), Color(hex: "#957DAD"), Color(hex: "#D291BC"), Color(hex: "#FEC8D8")]), center: .center).blur(radius: 80).opacity(0.6).ignoresSafeArea()
        }
    }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.clear).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
    }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        RoundedRectangle(cornerRadius: cellSize * 0.15, style: .continuous).fill(theme.sliderColor.color).shadow(color: .black.opacity(isDragging ? 0.3 : 0.15), radius: isDragging ? 10 : 5, x: 0, y: isDragging ? 8 : 4)
    }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
}

// MARK: - New Theme Renderers

struct ToonPuddingThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "toonPudding" }!
    
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        RoundedRectangle(cornerRadius: 20)
            .fill(theme.boardBackgroundColor.color)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.boardGridLineColor.color, lineWidth: 4)
            )
    }
    
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        let pieceShape = RoundedRectangle(cornerRadius: cellSize * 0.2)
        ZStack {
            pieceShape.fill(theme.sliderColor.color)
            pieceShape.stroke(Color.black.opacity(0.6), lineWidth: 3)
            
            Text(piece.type.displayName)
                .font(.custom(theme.fontName!, size: calculateFontSize(for: piece, cellSize: cellSize)))
                .foregroundColor(theme.sliderTextColor.color)
        }
        .shadow(color: .black.opacity(isDragging ? 0.35 : 0.2), radius: 2, x: isDragging ? 6 : 4, y: isDragging ? 6 : 4)
    }
    
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat { max(12, cellSize * 0.4) }
}

struct WoodcutThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "woodcut" }!
    
    func gameBackground() -> any View {
        ZStack {
            theme.backgroundColor.color.ignoresSafeArea()
            Rectangle()
                .fill(Color(white: 0.3, opacity: 0.1))
                .ignoresSafeArea()
        }
    }
    
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        RoundedRectangle(cornerRadius: 10).fill(theme.boardBackgroundColor.color)
    }
    
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        let pieceShape = RoundedRectangle(cornerRadius: 6)
        ZStack {
            pieceShape.fill(LinearGradient(gradient: Gradient(colors: [theme.sliderColor.color, theme.sliderColor.color.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
            pieceShape.stroke(Color.black.opacity(0.3), lineWidth: 2).blur(radius: 2).offset(x: 1, y: 1)
            pieceShape.stroke(Color.white.opacity(0.1), lineWidth: 1).blur(radius: 1).offset(x: -1, y: -1)

            Text(piece.type.displayName)
                .font(.custom(theme.fontName!, size: calculateFontSize(for: piece, cellSize: cellSize)))
                .foregroundColor(theme.sliderTextColor.color)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
        }
        .scaleEffect(isDragging ? 1.05 : 1.0)
    }
    
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat { max(14, cellSize * 0.45) }
}

struct MemphisPopThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "memphisPop" }!
    
    func gameBackground() -> any View {
        ZStack {
            theme.backgroundColor.color.ignoresSafeArea()
            GeometryReader { geo in
                let size = geo.size.width * 0.3
                Circle().fill(Color(hex: "#F77F00").opacity(0.5)).frame(width: size, height: size).position(x: geo.size.width * 0.2, y: geo.size.height * 0.25)
                Rectangle().fill(Color(hex: "#D62828").opacity(0.6)).frame(width: size, height: size * 0.4).rotationEffect(.degrees(-30)).position(x: geo.size.width * 0.8, y: geo.size.height * 0.4)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.8))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.7))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                }.fill(Color(hex: "#FCBF49").opacity(0.5))
            }
            .blur(radius: 20)
            .ignoresSafeArea()
        }
    }
    
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        RoundedRectangle(cornerRadius: 0).fill(theme.boardBackgroundColor.color)
    }
    
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        let pieceShape = Rectangle()
        ZStack {
            pieceShape.fill(theme.sliderColor.color)
            pieceShape.stroke(Color.black, lineWidth: 4)
            Text(piece.type.displayName)
                .font(.custom(theme.fontName!, size: calculateFontSize(for: piece, cellSize: cellSize)))
                .foregroundColor(theme.sliderTextColor.color)
        }
    }
    
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat { max(16, cellSize * 0.5) }
}

// 浓情巧克力
struct ChocolateThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "chocolate" }!

    func gameBackground() -> any View {
        Image("chocolate_background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.2))
    }

    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        let boardShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return boardShape
            .fill(theme.boardBackgroundColor.color.opacity(0.5))
            .background(.ultraThinMaterial)
            .clipShape(boardShape)
            .overlay(
                boardShape
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 15)
    }

    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        let content = ZStack {
            switch (piece.width, piece.height) {
            case (2, 2):
                ChocolatePieceView(isDragging: isDragging, config: .dark)
            case (1, 2), (2, 1):
                ChocolatePieceView(isDragging: isDragging, config: .milk)
            default: // 1x1
                ChocolatePieceView(isDragging: isDragging, config: .white)
            }
        }

        return content
            .frame(width: CGFloat(piece.width) * cellSize, height: CGFloat(piece.height) * cellSize)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }
    
    func menuButtonStyle() -> AnyButtonStyle {
        AnyButtonStyle(ChocolateButtonStyle(theme: theme))
    }
}


// MARK: - Unified Chocolate Piece View (Final Design)

/// 统一的巧克力块视图，采用浮雕设计
private struct ChocolatePieceView: View {
    let isDragging: Bool
    let config: ChocolateConfig

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        
        ZStack {
            // 主体颜色
            shape.fill(config.baseColor)
            
            // 内阴影 - 营造凹陷感/立体感
            shape
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [config.innerShadowColor.opacity(0.8), .clear]),
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    ),
                    lineWidth: 5
                )
                .clipped()
            

        }
    }
}

/// 巧克力颜色和样式的配置
private struct ChocolateConfig {
    let baseColor: Color
    let innerShadowColor: Color
    let highlightColor: Color
    let dropShadowColor: Color

    static let dark = ChocolateConfig(
        baseColor: Color(hex: "#422820"),
        innerShadowColor: Color(hex: "#2E1E18"),
        highlightColor: .white.opacity(0.35),
        dropShadowColor: .black
    )

    static let milk = ChocolateConfig(
        baseColor: Color(hex: "#9F6B47"),
        innerShadowColor: Color(hex: "#7F5636"),
        highlightColor: .white.opacity(0.35),
        dropShadowColor: .black
    )

    static let white = ChocolateConfig(
        baseColor: Color(hex: "#FDF6E9"), // 奶油白
        innerShadowColor: Color(hex: "#EAE0D1"),
        highlightColor: .white.opacity(0.35),
        dropShadowColor: .black
    )
}

/// 用于新巧克力主题的按钮样式 (代码实现)
struct ChocolateButtonStyle: ButtonStyle {
    let theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(theme.fontName ?? "Georgia-Bold", size: 20))
            .fontWeight(.bold)
            .padding(.vertical, 12)
            .frame(maxWidth: 280)
            .foregroundColor(Color(hex: "#F5EDE3")) // 象牙白文字
            .background(
                // 使用与牛奶巧克力类似的渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#A0522D"), Color(hex: "#8B4513")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: "#6F4E37").opacity(0.8), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: configuration.isPressed ? 3 : 6, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Reusable Standard Components

fileprivate struct StandardBoardBackgroundView: View {
    let widthCells: Int, heightCells: Int, cellSize: CGFloat, theme: Theme
    var body: some View {
        ZStack {
            Rectangle().fill(theme.boardBackgroundColor.color)
            Path { path in
                for i in 0...widthCells { let x = CGFloat(i) * cellSize; path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: CGFloat(heightCells) * cellSize)) }
                for i in 0...heightCells { let y = CGFloat(i) * cellSize; path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: CGFloat(widthCells) * cellSize, y: y)) }
            }.stroke(theme.boardGridLineColor.color, lineWidth: 1)
        }
    }
}

fileprivate struct StandardPieceView: View {
    let piece: Piece, cellSize: CGFloat, theme: Theme, isDragging: Bool
    var body: some View {
        let pieceShape = RoundedRectangle(cornerRadius: cellSize * 0.1)
        ZStack {
            pieceShape.fill(theme.sliderColor.color).overlay(pieceShape.stroke(theme.sliderColor.color.opacity(0.5), lineWidth: 1))
            if theme.sliderContent == .character {
                Text(piece.type.displayName)
                    .font(theme.fontName != nil ? .custom(theme.fontName!, size: calculateFontSize(for: piece, cellSize: cellSize)) : .system(size: calculateFontSize(for: piece, cellSize: cellSize), weight: .bold))
                    .foregroundColor(theme.sliderTextColor.color)
            }
        }.shadow(color: .black.opacity(isDragging ? 0.4 : 0.2), radius: isDragging ? 8 : 3, x: isDragging ? 4 : 1, y: isDragging ? 4 : 1)
    }
    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat { max(12, piece.width == 2 && piece.height == 2 ? cellSize * 0.6 : cellSize * 0.5) }
}

fileprivate struct StandardMenuButtonStyle: ButtonStyle {
    let theme: Theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.fontName != nil ? .custom(theme.fontName!, size: 18) : .headline)
            .fontWeight(.medium).padding().frame(maxWidth: 280, minHeight: 50)
            .background(theme.sliderColor.color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(theme.sliderTextColor.color)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: configuration.isPressed ? 2 : 5, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

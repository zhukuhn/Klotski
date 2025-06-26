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
    // --- 新增：专门用于UI文本的颜色 ---
    var textColor: CodableColor
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
        case "auroraGlass":
            AuroraGlassThemeRenderer()
        case "woodcut":
            WoodcutThemeRenderer()
        case "memphisPop":
            MemphisPopThemeRenderer()
        case "mechanism":
            MechanismThemeRenderer()
        default:
            DefaultThemeRenderer()
        }
    }

    // --- 修改：更新初始化方法以包含 textColor ---
    init(id: String, name: String, isPremium: Bool, price: Double? = nil, productID: String? = nil,
         backgroundColor: CodableColor, sliderColor: CodableColor,sliderTextColor: CodableColor,
         textColor: CodableColor, // 添加新参数
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
        self.textColor = textColor // 赋值
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
    // --- 修改：更新所有主题定义以包含 textColor ---
    static let allThemes: [Theme] = [
        Theme(id: "default", name: "经典浅色", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: .white),
              sliderColor: CodableColor(color: .blue), sliderTextColor: CodableColor(color: .white),
              textColor: CodableColor(color: Color(hex: "#333333")), // 深灰色文本
              boardBackgroundColor: CodableColor(color: Color(white: 0.9)), boardGridLineColor: CodableColor(color: Color(white: 0.7)),
              fontName: nil, colorScheme: .light),

        Theme(id: "dark", name: "深邃暗黑", isPremium: false, productID: nil,
              backgroundColor: CodableColor(color: .black),
              sliderColor: CodableColor(color: .orange), sliderTextColor: CodableColor(color: .black),
              textColor: CodableColor(color: .orange), // 橙色文本
              boardBackgroundColor: CodableColor(color: Color(white: 0.2)), boardGridLineColor: CodableColor(color: Color(white: 0.4)),
              fontName: nil, colorScheme: .dark),

        Theme(id: "forest", name: "清新绿意", isPremium: true,  price:1, productID: "com.shenlan.Klotski.theme.green",
              backgroundColor: CodableColor(color: Color(red: 161/255, green: 193/255, blue: 129/255)),
              sliderColor: CodableColor(color: Color(red: 103/255, green: 148/255, blue: 54/255)), sliderTextColor: CodableColor(color: .white),
              textColor: CodableColor(color: Color(red: 45/255, green: 80/255, blue: 20/255)), // 深绿色文本
              boardBackgroundColor: CodableColor(color: Color(red: 200/255, green: 220/255, blue: 180/255)), boardGridLineColor: CodableColor(color: Color(red: 120/255, green: 150/255, blue: 100/255)),
              fontName: "Georgia-Bold", colorScheme: .light),
        
        Theme(id: "auroraGlass", name: "琉璃月色", isPremium: true, price:2, productID: "com.shenlan.Klotski.theme.auroraGlass",
              backgroundColor: CodableColor(color: Color(red: 20/255, green: 20/255, blue: 40/255)), // 深紫色基底
              sliderColor: CodableColor(color: Color(red: 140/255, green: 160/255, blue: 200/255).opacity(0.5)), // 半透明的柔和蓝色
              sliderTextColor: CodableColor(color: .white),
              textColor: CodableColor(color: .white.opacity(0.9)), // 高亮白色文本
              boardBackgroundColor: CodableColor(color: .clear), // 棋盘背景由材质提供
              boardGridLineColor: CodableColor(color: .white.opacity(0.2)), // 几乎不可见的网格线
              sliderShape: .roundedRectangle,
              sliderContent: .none,
              fontName: "Georgia-Bold",
              colorScheme: .dark),

        Theme(id: "woodcut", name: "沉香木韵", isPremium: true, price:2, productID: "com.shenlan.Klotski.theme.woodcut",
              backgroundColor: CodableColor(color: Color(hex: "#6F4E37")), // 深木色
              sliderColor: CodableColor(color: Color(hex: "#C4A484")),     // 浅木色 (棋子)
              sliderTextColor: CodableColor(color: Color(hex: "#4B382A")), // 雕刻文字色
              textColor: CodableColor(color: Color(hex: "#F3EAD3")), // 亚麻色文本
              boardBackgroundColor: CodableColor(color: Color(hex: "#A07855")), // 棋盘木板色
              boardGridLineColor: CodableColor(color: .clear),            // 无网格线
              sliderContent: .none,
              fontName: "Georgia-Bold",
              colorScheme: .light),
              
        Theme(id: "memphisPop", name: "孟菲斯波普", isPremium: true, price:2, productID: "com.shenlan.Klotski.theme.memphisPop",
              backgroundColor: CodableColor(color: Color(hex: "#FDF0D5")), // 浅米色
              sliderColor: CodableColor(color: Color(hex: "#003049")),     // 深海军蓝 (棋子)
              sliderTextColor: CodableColor(color: .white),
              textColor: CodableColor(color: Color(hex: "#C1121F")), // 亮红色文本
              boardBackgroundColor: CodableColor(color: Color(hex: "#C1121F").opacity(0.1)), // 红色棋盘底
              boardGridLineColor: CodableColor(color: Color(hex: "#F77F00").opacity(0.5)),   // 橙色网格
              //sliderContent: .none,
              fontName: "Georgia-Bold",
              colorScheme: .light),
        
        Theme(id: "mechanism", name: "热烈砂岩", isPremium: true, price:3, productID: "com.shenlan.Klotski.theme.mechanism",
              backgroundColor: CodableColor(color: Color(red: 100/255, green: 60/255, blue: 40/255)),    // 后备背景色：深暖棕4A3F3C
              sliderColor: CodableColor(color: Color(hex: "#7B6F6A")),        // 棋子颜色：暖棕褐色
              sliderTextColor: CodableColor(color: Color(hex: "#D9D1CB")),    // 文字颜色：柔和米灰
              textColor: CodableColor(color: Color(hex: "#FFD08A")), // 发光的金色文本
              boardBackgroundColor: CodableColor(color: Color(hex: "#5D534F")),// 棋盘颜色：岩石灰
              boardGridLineColor: CodableColor(color: .clear),                // 不需要网格线
              fontName: "Georgia-Bold",
              colorScheme: .dark),
            
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

    func adjusted(by brightness: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var oldBrightness: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getHue(&hue, saturation: &saturation, brightness: &oldBrightness, alpha: &alpha) {
            let newBrightness = min(max(oldBrightness + brightness, 0.0), 1.0)
            return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        }
        
        var white: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            let newWhite = min(max(white + brightness, 0.0), 1.0)
            return Color(UIColor(white: newWhite, alpha: alpha))
        }
        
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
    func victoryButtonStyle() -> AnyButtonStyle
}

// MARK: - Standard & Existing Renderers

struct MechanismThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "mechanism" }!

    func gameBackground() -> any View {
        ZStack {
            theme.backgroundColor.color.ignoresSafeArea()
            Image("mechanism_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
        }
    }
    
    // --- 修改：给棋盘做出更真实的边缘 ---
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        
        return ZStack {
            // 1. 棋盘底色
            shape.fill(theme.boardBackgroundColor.color)

            // 2. 模拟内嵌边缘（内阴影）
            shape.strokeBorder(Color.black.opacity(0.5)).blur(radius: 2)

            // 3. 模拟外边缘高光
            shape
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(0.25), .clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // 4. 清晰的外框线，增加质感
            shape
                .stroke(Color.black.opacity(0.3), lineWidth: 3)
        }
    }

    // --- 修改：去掉棋子阴影 ---
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View {
        let shape = RoundedRectangle(cornerRadius: cellSize * 0.15, style: .continuous)
        
        return ZStack {
            // 棋子纹理/图片层作为最底层
            switch (piece.width, piece.height) {
            case (2, 2):
                Image("mechanism_piece_2x2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case (2, 1):
                Image("mechanism_piece_2x1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case (1, 2):
                Image("mechanism_piece_1x2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default: // 1x1
                Image("mechanism_piece_1x1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            
            // 在图片上层叠加高光和描边效果
            shape.strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
        }
        .background(theme.sliderColor.color)
        .clipShape(shape)
        // 阴影已移除 .shadow(...)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
    }


    func menuButtonStyle() -> AnyButtonStyle {
        AnyButtonStyle(MechanismButtonStyle(theme: theme))
    }
    func victoryButtonStyle() -> AnyButtonStyle {
        AnyButtonStyle(StandardMenuButtonStyle(theme: theme))
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
            
            ZStack {
                // 内阴影
                configuration.label
                    .offset(x: -1, y: -1)
                    .foregroundColor(Color.black.opacity(0.4))

                // 内高光
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
    func victoryButtonStyle() -> AnyButtonStyle { menuButtonStyle() }
}

struct DarkThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "dark" }!
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View { StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme) }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View { StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging) }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
    func victoryButtonStyle() -> AnyButtonStyle { menuButtonStyle() }
}

struct ForestThemeRenderer: ThemeableViewFactory {
    private let theme: Theme = AppThemeRepository.allThemes.first { $0.id == "forest" }!
    func gameBackground() -> any View { theme.backgroundColor.color.ignoresSafeArea() }
    func boardBackground(widthCells: Int, heightCells: Int, cellSize: CGFloat) -> any View { StandardBoardBackgroundView(widthCells: widthCells, heightCells: heightCells, cellSize: cellSize, theme: theme) }
    func pieceView(for piece: Piece, cellSize: CGFloat, isDragging: Bool) -> any View { StandardPieceView(piece: piece, cellSize: cellSize, theme: theme, isDragging: isDragging) }
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
    func victoryButtonStyle() -> AnyButtonStyle { menuButtonStyle() }
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
    func victoryButtonStyle() -> AnyButtonStyle { menuButtonStyle() }
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

    func victoryButtonStyle() -> AnyButtonStyle { menuButtonStyle() }
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
            if(theme.sliderContent != .none){
                Text(piece.type.displayName)
                .font(.custom(theme.fontName!, size: calculateFontSize(for: piece, cellSize: cellSize)))
                .foregroundColor(theme.sliderTextColor.color)
            }
            
        }
    }
    
    func menuButtonStyle() -> AnyButtonStyle { AnyButtonStyle(StandardMenuButtonStyle(theme: theme)) }
    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat { max(16, cellSize * 0.5) }

    func victoryButtonStyle() -> AnyButtonStyle { menuButtonStyle() }
}

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


// 1. 定义一个视图修饰符，它会应用主题到导航栏
struct NavigationBarThemeModifier: ViewModifier {
    var theme: Theme

    init(theme: Theme) {
        self.theme = theme
        
        // 创建一个标准的外观配置对象
        let appearance = UINavigationBarAppearance()

        // --- 配置背景颜色 ---
        // 'configureWithOpaqueBackground' 会创建一个不透明的背景
        // 当页面上划时，导航栏的背景就是这个颜色
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear

        appearance.shadowColor = .clear
        
        // --- 配置标题颜色 ---
        // 'titleTextAttributes' 用于小标题（inline display mode）
        appearance.titleTextAttributes = [.foregroundColor: UIColor(theme.textColor.color)]
        
        // --- 配置返回按钮：隐藏文字，只留箭头 ---
        let backButtonAppearance = UIBarButtonItemAppearance()
        // 通过将文字颜色设为透明来隐藏 "Back" 文字
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance
        
        // --- 修改：将返回箭头颜色与主题的文本颜色绑定 ---
        // tintColor 控制着导航栏中所有可交互元素的默认颜色，包括返回箭头
        UINavigationBar.appearance().tintColor = UIColor(theme.textColor.color)

        // --- 应用外观配置 ---
        // 'standardAppearance' 是导航栏在滚动时的标准外观
        UINavigationBar.appearance().standardAppearance = appearance
        // 'scrollEdgeAppearance' 是内容视图的顶部边缘与导航栏底部边缘对齐时的外观
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        // 'compactAppearance' 是在紧凑环境下（如横屏的iPhone）的外观
        UINavigationBar.appearance().compactAppearance = appearance
    }

    func body(content: Content) -> some View {
        content
    }
}

// 2. 创建一个View扩展，让修饰符的调用更方便、更具SwiftUI风格
extension View {
    func navigationBarTheme(_ theme: Theme) -> some View {
        self.modifier(NavigationBarThemeModifier(theme: theme))
    }
}


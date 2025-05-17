//
//  Untitled.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//
import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingLoginSheet = false
    @State private var showingRegisterSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "gameTitle"))
                   .font(.system(size: 36, weight: .bold, design: .rounded)) // Example of a custom font style
                   .padding(.top, 40)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)

                Spacer()

                NavigationLink(destination: LevelSelectionView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "startGame"))
                }

                // "Continue Game" button and programmatic navigation
                if gameManager.hasSavedGame {
                    Button(action: {
                        gameManager.continueGame() // This sets gameManager.isGameActive to true
                    }) {
                        MenuButton(title: settingsManager.localizedString(forKey: "continueGame"))
                    }
                }
                
                NavigationLink(destination: LevelSelectionView()) {
                     MenuButton(title: settingsManager.localizedString(forKey: "selectLevel"))
                }

                NavigationLink(destination: ThemeSelectionView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "themes"))
                }

                NavigationLink(destination: LeaderboardView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "leaderboard"))
                }

                NavigationLink(destination: SettingsView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "settings"))
                }
                
                Spacer()
                
                authStatusView()
                   .padding(.bottom)

            }
           .frame(maxWidth:.infinity, maxHeight:.infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .sheet(isPresented: $showingLoginSheet) { LoginView().environmentObject(authManager).environmentObject(settingsManager).environmentObject(themeManager) }
           .sheet(isPresented: $showingRegisterSheet) { RegisterView().environmentObject(authManager).environmentObject(settingsManager).environmentObject(themeManager) }
           // Modifier for programmatic navigation to GameView
           .navigationDestination(isPresented: $gameManager.isGameActive) {
               GameView() // Destination view
           }
        }
    }
    
    @ViewBuilder
    private func authStatusView() -> some View {
        VStack {
            if authManager.isLoggedIn, let user = authManager.currentUser {
                Text("\(settingsManager.localizedString(forKey: "loggedInAs")) \(user.displayName ?? user.email ?? "User")")
                   .font(.caption)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)
                Button(settingsManager.localizedString(forKey: "logout")) {
                    authManager.logout()
                }
               .buttonStyle(.bordered)
               .tint(themeManager.currentTheme.sliderColor.color)
            } else {
                HStack {
                    Button(settingsManager.localizedString(forKey: "login")) {
                        showingLoginSheet = true
                    }
                   .buttonStyle(.borderedProminent)
                   .tint(themeManager.currentTheme.sliderColor.color)
                    
                    Button(settingsManager.localizedString(forKey: "register")) {
                        showingRegisterSheet = true
                    }
                   .buttonStyle(.bordered)
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text(title)
           .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
           .fontWeight(.medium)
           .padding()
           .frame(maxWidth: 280, minHeight: 50) // Ensure buttons have a good tap target size
           .background(themeManager.currentTheme.sliderColor.color.opacity(0.9))
           .foregroundColor(themeManager.currentTheme.backgroundColor.color) // Text color contrasts with button
           .cornerRadius(12) // Softer corners
           .shadow(color: themeManager.currentTheme.sliderColor.color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// 游戏主界面
struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var internalTimeElapsed: TimeInterval = 0
    
    // 用于跟踪拖动的棋子及其状态
    @GestureState private var draggingPieceInfo: (id: Int, offset: CGSize, initialPositionInDrag: CGPoint)? = nil
    @State private var lockedDragAxis: Axis? = nil // 拖动时锁定的轴

    // 棋盘格子大小，可以根据屏幕尺寸动态计算
    private let boardPadding: CGFloat = 10
    private func calculateCellSize(geometry: GeometryProxy, boardWidthCells: Int, boardHeightCells: Int) -> CGFloat {
        let boardAreaWidth = geometry.size.width - (boardPadding * 2)
        let boardAreaHeight = geometry.size.height * 0.6 - (boardPadding * 2) // 假设棋盘区域占高度的60%
        
        let cellWidth = boardAreaWidth / CGFloat(boardWidthCells)
        let cellHeight = boardAreaHeight / CGFloat(boardHeightCells)
        return min(cellWidth, cellHeight, 80) // 限制最大格子大小
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let level = gameManager.currentLevel {
                    let cellSize = calculateCellSize(geometry: geometry, boardWidthCells: level.boardWidth, boardHeightCells: level.boardHeight)
                    let boardTotalWidth = cellSize * CGFloat(level.boardWidth)
                    let boardTotalHeight = cellSize * CGFloat(level.boardHeight)

                    // 游戏信息 (关卡名, 步数, 时间)
                    gameInfoView.padding(.horizontal)

                    // 游戏棋盘
                    ZStack {
                        // 棋盘背景和网格线
                        BoardBackgroundView(
                            widthCells: level.boardWidth,
                            heightCells: level.boardHeight,
                            cellSize: cellSize,
                            theme: themeManager.currentTheme
                        )
                        .frame(width: boardTotalWidth, height: boardTotalHeight)

                        // 渲染棋子
                        ForEach(gameManager.pieces) { piece in
                            PieceView(
                                piece: piece,
                                cellSize: cellSize,
                                theme: themeManager.currentTheme,
                                isDragging: draggingPieceInfo?.id == piece.id,
                                dragOffset: (draggingPieceInfo?.id == piece.id) ? draggingPieceInfo!.offset : .zero
                            )
                            .position(
                                x: CGFloat(piece.x) * cellSize + (CGFloat(piece.width) * cellSize / 2),
                                y: CGFloat(piece.y) * cellSize + (CGFloat(piece.height) * cellSize / 2)
                            )
                            .offset( (draggingPieceInfo?.id == piece.id) ? draggingPieceInfo!.offset : .zero )
                            .gesture(
                                DragGesture(minimumDistance: 5, coordinateSpace: .global)
                                    .updating($draggingPieceInfo) { value, state, _ in
                                        if state == nil { // 拖动开始
                                            state = (id: piece.id, offset: .zero, initialPositionInDrag: value.location)
                                        }
                                        var newOffset = value.translation
                                        
                                        // 锁定轴向
                                        if lockedDragAxis == nil {
                                            if abs(newOffset.width) > abs(newOffset.height) {
                                                lockedDragAxis = .horizontal
                                            } else {
                                                lockedDragAxis = .vertical
                                            }
                                        }
                                        if lockedDragAxis == .horizontal { newOffset.height = 0 }
                                        else { newOffset.width = 0 }

                                        // 尝试将拖动量转换为格子单位，并进行碰撞检测
                                        let attemptedDxCells = Int(round(newOffset.width / cellSize))
                                        let attemptedDyCells = Int(round(newOffset.height / cellSize))
                                        
                                        var currentValidDxCells = 0
                                        var currentValidDyCells = 0

                                        if lockedDragAxis == .horizontal {
                                            for i in 1...abs(attemptedDxCells) {
                                                let stepDx = i * (attemptedDxCells > 0 ? 1 : -1)
                                                if gameManager.canMove(pieceId: piece.id, dx: stepDx, dy: 0) {
                                                    currentValidDxCells = stepDx
                                                } else { break }
                                            }
                                        } else { // Vertical
                                            for i in 1...abs(attemptedDyCells) {
                                                let stepDy = i * (attemptedDyCells > 0 ? 1 : -1)
                                                if gameManager.canMove(pieceId: piece.id, dx: 0, dy: stepDy) {
                                                    currentValidDyCells = stepDy
                                                } else { break }
                                            }
                                        }
                                        
                                        // 更新拖动偏移量，使其对齐到有效的格子
                                        state!.offset = CGSize(width: CGFloat(currentValidDxCells) * cellSize, height: CGFloat(currentValidDyCells) * cellSize)
                                    }
                                    .onEnded { value in
                                        let finalDxCells = Int(round(value.translation.width / cellSize))
                                        let finalDyCells = Int(round(value.translation.height / cellSize))
                                        
                                        var actualDx = 0
                                        var actualDy = 0

                                        if lockedDragAxis == .horizontal {
                                            actualDy = 0
                                            for i in 1...abs(finalDxCells) {
                                                 let stepDx = i * (finalDxCells > 0 ? 1 : -1)
                                                 if gameManager.canMove(pieceId: piece.id, dx: stepDx, dy: 0) {
                                                     actualDx = stepDx
                                                 } else { break }
                                             }
                                        } else if lockedDragAxis == .vertical {
                                            actualDx = 0
                                             for i in 1...abs(finalDyCells) {
                                                 let stepDy = i * (finalDyCells > 0 ? 1 : -1)
                                                 if gameManager.canMove(pieceId: piece.id, dx: 0, dy: stepDy) {
                                                     actualDy = stepDy
                                                 } else { break }
                                             }
                                        }
                                        
                                        if actualDx != 0 || actualDy != 0 {
                                            gameManager.attemptMove(pieceId: piece.id, dx: actualDx, dy: actualDy)
                                        }
                                        lockedDragAxis = nil // 重置锁定轴
                                    }
                            )
                        }
                    }
                    .frame(width: boardTotalWidth, height: boardTotalHeight)
                    .padding(.vertical)
                    
                    if gameManager.isGameWon {
                        Text("恭喜你，成功过关！")
                            .font(.largeTitle).foregroundColor(.green).padding()
                        Button("返回主菜单") { dismiss() }
                           .buttonStyle(.borderedProminent)
                    }


                    Spacer() // 将棋盘推向中间

                } else {
                    Text("未选择关卡。请返回主菜单选择一个关卡。")
                        .foregroundColor(themeManager.currentTheme.sliderColor.color)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 使VStack充满GeometryReader
            .navigationTitle(gameManager.currentLevel?.name ?? settingsManager.localizedString(forKey: "gameTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(gameManager.isGameActive && !gameManager.isGameWon)
            .toolbar { navigationToolbarItems }
            .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
            .onAppear(perform: setupGameView)
            .onDisappear(perform: cleanupGameView)
            .onReceive(timer) { _ in if gameManager.isGameActive && !gameManager.isGameWon { internalTimeElapsed += 1 } }
        }
    }

    private var gameInfoView: some View {
        HStack {
            Text("\(settingsManager.localizedString(forKey: "level")): \(gameManager.currentLevel?.name ?? "N/A")")
            Spacer()
            Text("\(settingsManager.localizedString(forKey: "moves")): \(gameManager.moves)")
            Spacer()
            Text("\(settingsManager.localizedString(forKey: "time")): \(formattedTime(internalTimeElapsed))")
        }
        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .callout)
        .foregroundColor(themeManager.currentTheme.sliderColor.color)
    }

    @ToolbarContentBuilder
    private var navigationToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if gameManager.isGameActive && !gameManager.isGameWon {
                Button {
                    // gameManager.saveGame() // 拖动过程中不便保存，或考虑暂停菜单
                    gameManager.isGameActive = false // 触发返回
                    dismiss()
                } label: { Image(systemName: "chevron.backward"); Text("暂停") }
                .tint(themeManager.currentTheme.sliderColor.color)
            }
        }
    }

    private func setupGameView() {
        if gameManager.isGameActive {
            internalTimeElapsed = gameManager.timeElapsed
            startTimer()
        }
    }
    private func cleanupGameView() {
        stopTimer()
        if gameManager.isGameActive && !gameManager.isGameWon {
            gameManager.timeElapsed = internalTimeElapsed
            // gameManager.saveGame() // 自动保存
        }
    }
    private func startTimer() { stopTimer(); timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() }
    private func stopTimer() { timer.upstream.connect().cancel() }
    private func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let m = Int(totalSeconds) / 60; let s = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// 棋盘背景和网格线视图
struct BoardBackgroundView: View {
    let widthCells: Int
    let heightCells: Int
    let cellSize: CGFloat
    let theme: Theme

    var body: some View {
        ZStack {
            // 棋盘背景色
            Rectangle()
                .fill(theme.boardBackgroundColor.color)
            
            // 绘制网格线
            Path { path in
                // 垂直线
                for i in 0...widthCells {
                    let x = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: CGFloat(heightCells) * cellSize))
                }
                // 水平线
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


// 单个棋子视图
struct PieceView: View {
    let piece: Piece
    let cellSize: CGFloat
    let theme: Theme
    var isDragging: Bool = false
    var dragOffset: CGSize = .zero // 这个在 GameView 中更新，此处仅接收

    // 辅助计算属性：创建并填充形状
    @ViewBuilder
    private var filledShapeView: some View {
        switch theme.sliderShape {
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .fill(theme.sliderColor.color)
        case .square:
            Rectangle()
                .fill(theme.sliderColor.color)
        case .customImage:
            // TODO: 实现自定义图片逻辑
            RoundedRectangle(cornerRadius: cellSize * 0.1) // 备用
                .fill(theme.sliderColor.color)
        }
    }

    // 辅助计算属性：创建并描边形状
    @ViewBuilder
    private var strokedShapeView: some View {
        switch theme.sliderShape {
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .stroke(theme.sliderColor.color.opacity(0.5), lineWidth: 1)
        case .square:
            Rectangle()
                .stroke(theme.sliderColor.color.opacity(0.5), lineWidth: 1)
        case .customImage:
            // TODO: 实现自定义图片逻辑的描边
            RoundedRectangle(cornerRadius: cellSize * 0.1) // 备用
                .stroke(theme.sliderColor.color.opacity(0.5), lineWidth: 1)
        }
    }
    
    // 辅助计算属性，用于构建棋子上的文本内容
    @ViewBuilder
    private var pieceTextContent: some View {
        if theme.sliderContent == .character || theme.sliderContent == .number {
            Text(piece.type.displayName) // 或 piece.id.description (如果内容是数字)
                .font(Font.system(size: calculateFontSize(for: piece, cellSize: cellSize)))
                .fontWeight(.bold)
                .foregroundColor(theme.sliderTextColor.color)
        }
        // TODO: 实现 .pattern 和 .none 的逻辑
    }

    var body: some View {
        ZStack {
            // 棋子背景 (填充和描边)
            filledShapeView
                .frame(width: CGFloat(piece.width) * cellSize - 2, height: CGFloat(piece.height) * cellSize - 2)
                .overlay(
                    strokedShapeView
                        .frame(width: CGFloat(piece.width) * cellSize - 2, height: CGFloat(piece.height) * cellSize - 2) // 确保描边与填充对齐
                )
                .shadow(color: .black.opacity(isDragging ? 0.4 : 0.2), radius: isDragging ? 8 : 3, x: isDragging ? 4 : 1, y: isDragging ? 4 : 1)
            
            // 棋子内容
            pieceTextContent
        }
        // 注意：dragOffset 是通过 .offset() 修饰符在 GameView 中应用的，这里不需要再处理
        // .animation(.spring(), value: dragOffset) // 如果需要动画，应在 GameView 中应用到棋子位置或偏移上
    }

    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat {
        let baseSize = cellSize * 0.5
        if piece.width == 1 && piece.height == 1 { // 兵
            return baseSize * 0.8
        }
        if piece.width == 2 && piece.height == 2 { // 曹操
            return baseSize * 1.2
        }
        return baseSize // 其他武将
    }
}

struct LevelSelectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        List {
            ForEach(gameManager.levels.filter { $0.isUnlocked }) { level in
                // NavigationLink now uses .navigationDestination in MainMenuView for GameView
                // So, when a level is selected, we just need to set it in GameManager and activate the game.
                Button(action: {
                    gameManager.startGame(level: level) // This sets isGameActive to true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.name)
                               .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                               .foregroundColor(themeManager.currentTheme.sliderColor.color)
                            if let moves = level.bestMoves {
                                Text("最佳: \(moves) \(settingsManager.localizedString(forKey: "moves"))")
                                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                            } else {
                                Text("未完成")
                                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.5))
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right") // Visual cue for navigation
                           .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.5))
                        // TODO: Add preview of level layout or difficulty icon
                    }
                   .padding(.vertical, 8)
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
            if gameManager.levels.filter({ $0.isUnlocked }).isEmpty {
                Text(settingsManager.localizedString(forKey: "noLevels"))
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "selectLevel"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden) // For iOS 16+ to make List background transparent
    }
}

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        List {
            Section(header: Text(settingsManager.localizedString(forKey: "themeStore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                ForEach(themeManager.themes) { theme in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.name)
                               .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                            // Simple preview of theme colors
                            HStack {
                                Circle().fill(theme.backgroundColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                                Circle().fill(theme.sliderColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                                if let font = theme.fontName { Text(font).font(.caption2).italic() }
                            }
                        }
                       .foregroundColor(themeManager.currentTheme.sliderColor.color)

                        Spacer()

                        if themeManager.currentTheme.id == theme.id {
                            Image(systemName: "checkmark.circle.fill")
                               .foregroundColor(.green)
                               .font(.title2)
                        } else if themeManager.isThemePurchased(theme) {
                            Button(settingsManager.localizedString(forKey: "applyTheme")) {
                                themeManager.setCurrentTheme(theme)
                            }
                           .buttonStyle(.bordered)
                           .tint(themeManager.currentTheme.sliderColor.color)
                        } else {
                            Button("\(settingsManager.localizedString(forKey: "purchase")) \(theme.price != nil ? String(format: "¥%.2f", theme.price!) : "")") {
                                themeManager.purchaseTheme(theme) // This is a simulated purchase
                            }
                           .buttonStyle(.borderedProminent)
                           .tint(theme.isPremium ? .pink : themeManager.currentTheme.sliderColor.color) // Highlight premium themes
                        }
                    }
                   .padding(.vertical, 8)
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
            
            Section {
                 Button(settingsManager.localizedString(forKey: "restorePurchases")) {
                    themeManager.restorePurchases() // Simulated
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
               .foregroundColor(themeManager.currentTheme.sliderColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "themes"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
    }
}

struct LeaderboardView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager // To get level names for picker
    // TODO: Inject Game Center manager or data source

    // Sample data, replace with actual Game Center data
    @State private var leaderboardData: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, playerName: "高手玩家", moves: 25, levelID: "easy-1"),
        LeaderboardEntry(rank: 2, playerName: "新手上路", moves: 30, levelID: "easy-1"),
        LeaderboardEntry(rank: 1, playerName: "解谜大师", moves: 120, levelID: "medium-1"),
    ]
    @State private var selectedLevelFilter: String = "all" // "all" or a levelID

    var body: some View {
        VStack {
            // TODO: Implement actual Game Center leaderboard view
            // (e.g., using GKGameCenterViewController as a sheet)
            // Or a custom UI that fetches data from Game Center.
            
            Picker(settingsManager.localizedString(forKey: "selectLevel"), selection: $selectedLevelFilter) {
                Text("所有关卡").tag("all")
                ForEach(gameManager.levels) { level in
                    Text(level.name).tag(level.id)
                }
            }
           .pickerStyle(.segmented) // Or .menu for more items
           .padding()
           .tint(themeManager.currentTheme.sliderColor.color)


            List {
                ForEach(filteredLeaderboardData()) { entry in
                    HStack {
                        Text("\(entry.rank).")
                           .fontWeight(.bold)
                        Text(entry.playerName)
                        Spacer()
                        Text("\(entry.moves) \(settingsManager.localizedString(forKey: "moves"))")
                           .fontWeight(.semibold)
                    }
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .body)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
                if filteredLeaderboardData().isEmpty {
                    Text("此关卡暂无排行数据。")
                        .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                        .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
           .scrollContentBackground(.hidden)
            
            Text("排行榜功能待 Game Center 集成")
               .font(.caption)
               .padding()
               .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
        }
       .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
    }

    func filteredLeaderboardData() -> [LeaderboardEntry] {
        if selectedLevelFilter == "all" {
            return leaderboardData.sorted { $0.moves < $1.moves } // Example sorting
        }
        return leaderboardData.filter { $0.levelID == selectedLevelFilter }.sorted { $0.moves < $1.moves }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager // For reset progress

    @State private var showingResetAlert = false

    var body: some View {
        Form { // Form provides a standard iOS settings look
            Section(header: Text("通用设置")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Picker(settingsManager.localizedString(forKey: "language"), selection: $settingsManager.language) {
                    Text(settingsManager.localizedString(forKey: "chinese")).tag("zh")
                    Text(settingsManager.localizedString(forKey: "english")).tag("en")
                }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5)) // Slightly different for Form
           .foregroundColor(themeManager.currentTheme.sliderColor.color)


            Section(header: Text("音频与触感")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Toggle(settingsManager.localizedString(forKey: "soundEffects"), isOn: $settingsManager.soundEffectsEnabled)
                Toggle(settingsManager.localizedString(forKey: "music"), isOn: $settingsManager.musicEnabled)
                Toggle(settingsManager.localizedString(forKey: "haptics"), isOn: $settingsManager.hapticsEnabled)
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.sliderColor.color)
           .tint(themeManager.currentTheme.sliderColor.color) // Tint for Toggles

            Section(header: Text("游戏数据")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Button(settingsManager.localizedString(forKey: "resetProgress"), role: .destructive) {
                    showingResetAlert = true
                }
               .foregroundColor(.red) // Standard destructive color
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
            
            // TODO: Add links to Privacy Policy, About, etc.
            // Section("About") { Link("Privacy Policy", destination: URL(string: "...")!) }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "settings"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea()) // Background for the whole view
       .scrollContentBackground(.hidden) // Makes Form background transparent
       .alert(settingsManager.localizedString(forKey: "resetProgress"), isPresented: $showingResetAlert) {
            Button(settingsManager.localizedString(forKey: "reset"), role: .destructive) {
                // Reset best scores in levels
                gameManager.levels.indices.forEach { gameManager.levels[$0].bestMoves = nil; gameManager.levels[$0].bestTime = nil }
                // Clear any currently saved game progress
                gameManager.clearSavedGame()
                // TODO: Potentially reset other game-specific stats if any
                print("游戏进度已重置")
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {}
        } message: {
            Text(settingsManager.localizedString(forKey: "areYouSureReset"))
        }
    }
}

// Common UI for Login and Register text fields
struct AuthTextFieldStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    func body(content: Content) -> some View {
        content
           .padding(12)
           .background(themeManager.currentTheme.sliderColor.color.opacity(0.1))
           .cornerRadius(8)
           .overlay(
                RoundedRectangle(cornerRadius: 8)
                   .stroke(themeManager.currentTheme.sliderColor.color.opacity(0.3), lineWidth: 1)
            )
           .foregroundColor(themeManager.currentTheme.sliderColor.color)
    }
}


struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager // For styling
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "login"))
                   .font(.system(size: 32, weight: .bold, design: .rounded))
                   .padding(.bottom, 30)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)


                TextField(settingsManager.localizedString(forKey: "email"), text: $email)
                   .keyboardType(.emailAddress)
                   .autocapitalization(.none)
                   .textContentType(.emailAddress)
                   .modifier(AuthTextFieldStyle())

                SecureField(settingsManager.localizedString(forKey: "password"), text: $password)
                   .textContentType(.password)
                   .modifier(AuthTextFieldStyle())
                
                Button(settingsManager.localizedString(forKey: "login")) {
                    authManager.login(email: email, pass: password)
                }
               .buttonStyle(.borderedProminent)
               .tint(themeManager.currentTheme.sliderColor.color)
               .frame(maxWidth:.infinity)
               .padding(.vertical)
               .disabled(email.isEmpty || password.isEmpty)
                
                Button(settingsManager.localizedString(forKey: "forgotPassword")) {
                    // TODO: Implement forgot password flow (e.g., show another sheet or navigate)
                }
               .font(.caption)
               .tint(themeManager.currentTheme.sliderColor.color)
                
                Divider().padding(.vertical)
                
                Button(action: {
                    authManager.signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "apple.logo") // Corrected Apple logo system name
                        Text(settingsManager.localizedString(forKey: "signInWithApple"))
                    }
                   .padding(.horizontal)
                }
               .buttonStyle(.bordered) // Use bordered for a less prominent look than login
               .tint(themeManager.currentTheme.sliderColor.color) // Or .primary for system default
               .frame(maxWidth:.infinity)


                Spacer()
            }
           .padding(30) // More padding for the content
           .frame(maxWidth:.infinity, maxHeight:.infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .navigationTitle(settingsManager.localizedString(forKey: "login"))
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Changed from .automatic for consistency
                    Button(settingsManager.localizedString(forKey: "cancel")) {
                        dismiss()
                    }
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in // Use newValue directly
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    // @State private var confirmPassword = "" // Good practice to add

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "register"))
                   .font(.system(size: 32, weight: .bold, design: .rounded))
                   .padding(.bottom, 30)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)


                TextField(settingsManager.localizedString(forKey: "displayName"), text: $displayName)
                   .textContentType(.nickname)
                   .modifier(AuthTextFieldStyle())

                TextField(settingsManager.localizedString(forKey: "email"), text: $email)
                   .keyboardType(.emailAddress)
                   .autocapitalization(.none)
                   .textContentType(.emailAddress)
                   .modifier(AuthTextFieldStyle())

                SecureField(settingsManager.localizedString(forKey: "password"), text: $password)
                   .textContentType(.newPassword) // Hint for password managers
                   .modifier(AuthTextFieldStyle())
                
                // SecureField("Confirm Password", text: $confirmPassword)
                //    .modifier(AuthTextFieldStyle())

                Button(settingsManager.localizedString(forKey: "register")) {
                    // TODO: Add password confirmation validation
                    authManager.register(email: email, pass: password, displayName: displayName)
                }
               .buttonStyle(.borderedProminent)
               .tint(themeManager.currentTheme.sliderColor.color)
               .frame(maxWidth:.infinity)
               .padding(.vertical)
               .disabled(email.isEmpty || password.isEmpty || displayName.isEmpty /*|| password != confirmPassword */)

                Spacer()
            }
           .padding(30)
           .frame(maxWidth:.infinity, maxHeight:.infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .navigationTitle(settingsManager.localizedString(forKey: "register"))
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsManager.localizedString(forKey: "cancel")) {
                        dismiss()
                    }
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

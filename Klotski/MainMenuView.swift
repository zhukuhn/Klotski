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

    // --- 拖动状态 ---
    @State private var draggingPieceID: Int? = nil // 当前拖动的棋子ID
    @State private var dragStartLocation: CGPoint? = nil // 手指开始拖动时的屏幕位置
    @State private var pieceInitialGridPos: CGPoint? = nil // 棋子开始拖动时的格子位置 (x,y)
    @State private var currentDragOffsetInCells: CGSize = .zero // 当前拖动累积的格子位移 (dx,dy)
                                                              // 这个值会在拖动过程中根据canMove的结果更新

    // --- 计时器等其他状态 ---
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var internalTimeElapsed: TimeInterval = 0
    
    private let boardPadding: CGFloat = 10
    private func calculateCellSize(geometry: GeometryProxy, boardWidthCells: Int, boardHeightCells: Int) -> CGFloat {
        guard boardWidthCells > 0, boardHeightCells > 0 else { return 1 }
        let boardAreaWidth = geometry.size.width - (boardPadding * 2)
        let boardAreaHeight = geometry.size.height * 0.6 - (boardPadding * 2)
        guard boardAreaWidth > 0, boardAreaHeight > 0 else { return 1 }
        let cellWidth = boardAreaWidth / CGFloat(boardWidthCells)
        let cellHeight = boardAreaHeight / CGFloat(boardHeightCells)
        let minSize = min(cellWidth, cellHeight)
        return max(1, min(minSize, 80)) // 确保cellSize至少为1
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let level = gameManager.currentLevel {
                    let cellSize = calculateCellSize(geometry: geometry, boardWidthCells: level.boardWidth, boardHeightCells: level.boardHeight)
                    
                    if cellSize <= 1 {
                        Text("错误：棋盘尺寸计算异常。").foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        gameInfoView.padding(.horizontal)
                        gameBoardArea(level: level, cellSize: cellSize) // 传递cellSize
                        if gameManager.isGameWon { /* ... 胜利UI ... */ Text("恭喜！").font(.largeTitle); Button("返回"){dismiss()} }
                        Spacer()
                    }
                } else {
                    Text("未选择关卡。").foregroundColor(themeManager.currentTheme.sliderColor.color).padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(gameManager.currentLevel?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(gameManager.isGameActive && !gameManager.isGameWon)
            .toolbar { navigationToolbarItems }
            .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
            .onAppear(perform: setupGameView)
            .onDisappear(perform: cleanupGameView)
            .onReceive(timer) { _ in if gameManager.isGameActive && !gameManager.isGameWon { internalTimeElapsed += 1 } }
        }
    }

        @ViewBuilder
        private func gameBoardArea(level: Level, cellSize: CGFloat) -> some View {
            let boardTotalWidth = cellSize * CGFloat(level.boardWidth)
            let boardTotalHeight = cellSize * CGFloat(level.boardHeight)

            ZStack {
                BoardBackgroundView(widthCells: level.boardWidth, heightCells: level.boardHeight, cellSize: cellSize, theme: themeManager.currentTheme)
                    .frame(width: boardTotalWidth, height: boardTotalHeight)

                ForEach(gameManager.pieces) { piece in
                    PieceView(
                        piece: piece,
                        cellSize: cellSize,
                        theme: themeManager.currentTheme,
                        isDragging: piece.id == draggingPieceID
                    )
                    .position( // 棋子的基础逻辑位置
                        x: CGFloat(piece.x) * cellSize + (CGFloat(piece.width) * cellSize / 2),
                        y: CGFloat(piece.y) * cellSize + (CGFloat(piece.height) * cellSize / 2)
                    )
                    .offset( // 应用拖动时的视觉偏移 (基于累积的有效格子位移)
                        x: piece.id == draggingPieceID ? currentDragOffsetInCells.width * cellSize : 0,
                        y: piece.id == draggingPieceID ? currentDragOffsetInCells.height * cellSize : 0
                    )
                    .gesture(
                        DragGesture(minimumDistance: 5, coordinateSpace: .global) // 使用 .global 更易于计算总位移
                            .onChanged { value in
                                guard cellSize > 0 else { return }

                                if draggingPieceID == nil { // 拖动开始
                                    draggingPieceID = piece.id
                                    pieceInitialGridPos = CGPoint(x: piece.x, y: piece.y)
                                    dragStartLocation = value.startLocation // 手指开始的屏幕位置
                                    currentDragOffsetInCells = .zero // 重置累积格子偏移
                                }

                                guard draggingPieceID == piece.id,
                                      let initialGridPos = pieceInitialGridPos,
                                      let startScreenPos = dragStartLocation else { return }

                                // 1. 计算手指当前总的屏幕拖动位移
                                let totalScreenDrag = CGSize(
                                    width: value.location.x - startScreenPos.x,
                                    height: value.location.y - startScreenPos.y
                                )

                                // 2. 将总屏幕拖动位移转换为目标格子位移
                                let targetGridDeltaX = Int(round(totalScreenDrag.width / cellSize))
                                let targetGridDeltaY = Int(round(totalScreenDrag.height / cellSize))
                                
                                // 3. 从当前已累积的有效格子位移 (currentDragOffsetInCells) 尝试向目标格子位移移动
                                var nextCumulativeGridDelta = currentDragOffsetInCells
                                
                                // 尝试水平移动一步
                                if Int(nextCumulativeGridDelta.width) != targetGridDeltaX {
                                    let stepX = (targetGridDeltaX > Int(nextCumulativeGridDelta.width)) ? 1 : -1
                                    if gameManager.canMove(pieceId: piece.id,
                                                           currentGridX: Int(initialGridPos.x) + Int(nextCumulativeGridDelta.width),
                                                           currentGridY: Int(initialGridPos.y) + Int(nextCumulativeGridDelta.height),
                                                           deltaX: stepX, deltaY: 0) {
                                        nextCumulativeGridDelta.width += CGFloat(stepX)
                                    }
                                }
                                
                                // 尝试垂直移动一步 (基于可能已更新的水平位置)
                                if Int(nextCumulativeGridDelta.height) != targetGridDeltaY {
                                    let stepY = (targetGridDeltaY > Int(nextCumulativeGridDelta.height)) ? 1 : -1
                                    if gameManager.canMove(pieceId: piece.id,
                                                           currentGridX: Int(initialGridPos.x) + Int(nextCumulativeGridDelta.width), // 使用最新的累积X
                                                           currentGridY: Int(initialGridPos.y) + Int(nextCumulativeGridDelta.height),
                                                           deltaX: 0, deltaY: stepY) {
                                        nextCumulativeGridDelta.height += CGFloat(stepY)
                                    }
                                }
                                
                                // 4. 更新当前有效的累积格子偏移
                                currentDragOffsetInCells = nextCumulativeGridDelta
                            }
                            .onEnded { value in
                                guard let pieceId = draggingPieceID,
                                      currentDragOffsetInCells.width != 0 || currentDragOffsetInCells.height != 0 else {
                                    // 如果没有有效移动，或者没有棋子在拖动，则重置
                                    draggingPieceID = nil
                                    pieceInitialGridPos = nil
                                    dragStartLocation = nil
                                    currentDragOffsetInCells = .zero
                                    return
                                }

                                gameManager.attemptMove(pieceId: pieceId,
                                                        dx: Int(currentDragOffsetInCells.width),
                                                        dy: Int(currentDragOffsetInCells.height))

                                // 重置拖动状态
                                draggingPieceID = nil
                                pieceInitialGridPos = nil
                                dragStartLocation = nil
                                currentDragOffsetInCells = .zero
                            }
                    )
                }
            }
            .frame(width: boardTotalWidth, height: boardTotalHeight)
            .padding(.vertical)
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
                    gameManager.isGameActive = false
                    dismiss()
                } label: { Image(systemName: "chevron.backward"); Text("暂停") }
                .tint(themeManager.currentTheme.sliderColor.color)
            }
        }
    }
    private func setupGameView(){if gameManager.isGameActive{internalTimeElapsed=gameManager.timeElapsed;startTimer()}}
    private func cleanupGameView(){stopTimer();if gameManager.isGameActive && !gameManager.isGameWon{gameManager.timeElapsed=internalTimeElapsed}}
    private func startTimer(){stopTimer();timer=Timer.publish(every:1,on:.main,in:.common).autoconnect()}
    private func stopTimer(){timer.upstream.connect().cancel()}
    private func formattedTime(_ tS:TimeInterval)->String{let m=Int(tS)/60;let s=Int(tS)%60;return String(format:"%02d:%02d",m,s)}
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

struct PieceWithGestureView: View {
    let piece: Piece // 当前视图代表的棋子数据
    let cellSize: CGFloat
    
    @ObservedObject var gameManager: GameManager // 用于调用 canMove 和 attemptMove
    @EnvironmentObject var themeManager: ThemeManager // 用于获取主题以传递给 PieceView

    // 绑定到 GameView 中的状态，用于协调拖动
    @Binding var draggedPieceId_GV: Int? // GameView 中当前被拖动棋子的ID
    @Binding var draggedPiece_visualOffset_GV: CGSize // GameView 中棋子的视觉偏移
    @Binding var draggedPiece_startGridPos_GV: CGPoint? // GameView 中拖动开始的格子位置
    @Binding var draggedPiece_cumulativeGridDelta_GV: CGSize // GameView 中累积的格子位移

    var body: some View {
        PieceView(
            piece: piece,
            cellSize: cellSize,
            theme: themeManager.currentTheme,
            isDragging: piece.id == draggedPieceId_GV // 根据 GameView 的状态判断是否高亮
        )
        // 注意：.position 和 .offset 是在 GameView 的 ForEach 中应用的
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .local) // 使用 .local 通常更简单
                .onChanged { value in
                    guard cellSize > 0 else { return }

                    if draggedPieceId_GV == nil { // 拖动开始
                        draggedPieceId_GV = piece.id
                        draggedPiece_startGridPos_GV = CGPoint(x: piece.x, y: piece.y)
                        draggedPiece_cumulativeGridDelta_GV = .zero
                        draggedPiece_visualOffset_GV = .zero
                    }
                    
                    // 确保当前手势操作的是这个 PieceWithGestureView 对应的棋子
                    guard draggedPieceId_GV == piece.id, let startGridPos = draggedPiece_startGridPos_GV else { return }

                    let currentTotalRawPixelDrag = value.translation
                    let lastCommittedPixelDrag = CGSize(
                        width: draggedPiece_cumulativeGridDelta_GV.width * cellSize,
                        height: draggedPiece_cumulativeGridDelta_GV.height * cellSize
                    )
                    let pixelDeltaSinceLastCommit = CGSize(
                        width: currentTotalRawPixelDrag.width - lastCommittedPixelDrag.width,
                        height: currentTotalRawPixelDrag.height - lastCommittedPixelDrag.height
                    )

                    var stepDx = 0
                    var stepDy = 0
                    let snapThreshold = cellSize * 0.4 // 稍微减小阈值，更容易触发单步

                    // 优先确定主要拖动方向的意图
                    if abs(pixelDeltaSinceLastCommit.width) > abs(pixelDeltaSinceLastCommit.height) { // 水平优先
                        if abs(pixelDeltaSinceLastCommit.width) >= snapThreshold {
                            stepDx = pixelDeltaSinceLastCommit.width > 0 ? 1 : -1
                        }
                    } else { // 垂直优先或相等
                        if abs(pixelDeltaSinceLastCommit.height) >= snapThreshold {
                            stepDy = pixelDeltaSinceLastCommit.height > 0 ? 1 : -1
                        }
                    }
                    
                    // 如果有明确的单步移动意图
                    if stepDx != 0 || stepDy != 0 {
                        let currentLogicalGridX = Int(startGridPos.x) + Int(draggedPiece_cumulativeGridDelta_GV.width)
                        let currentLogicalGridY = Int(startGridPos.y) + Int(draggedPiece_cumulativeGridDelta_GV.height)
                        
                        var movedThisStep = false
                        // 尝试主要意图方向
                        if stepDx != 0 { // 水平意图
                            if gameManager.canMove(pieceId: piece.id, currentGridX: currentLogicalGridX, currentGridY: currentLogicalGridY, deltaX: stepDx, deltaY: 0) {
                                draggedPiece_cumulativeGridDelta_GV.width += CGFloat(stepDx)
                                movedThisStep = true
                            }
                        }
                        
                        // 如果主要方向（水平）未移动成功，且有垂直意图，则尝试垂直移动
                        if !movedThisStep && stepDy != 0 { // 垂直意图
                            if gameManager.canMove(pieceId: piece.id, currentGridX: currentLogicalGridX, currentGridY: currentLogicalGridY, deltaX: 0, deltaY: stepDy) {
                                draggedPiece_cumulativeGridDelta_GV.height += CGFloat(stepDy)
                                // movedThisStep = true // 可选
                            }
                        }
                    }
                    
                    // 更新 GameView 中的视觉偏移量
                    draggedPiece_visualOffset_GV = CGSize(
                        width: draggedPiece_cumulativeGridDelta_GV.width * cellSize,
                        height: draggedPiece_cumulativeGridDelta_GV.height * cellSize
                    )
                }
                .onEnded { value in
                    // 使用 piece.id，因为 draggedPieceId_GV 此时应该等于 piece.id
                    guard draggedPieceId_GV == piece.id else {
                        // 如果不是当前棋子，可能是手势意外结束，重置以防万一
                        draggedPieceId_GV = nil
                        draggedPiece_startGridPos_GV = nil
                        draggedPiece_cumulativeGridDelta_GV = .zero
                        draggedPiece_visualOffset_GV = .zero
                        return
                    }
                    
                    let finalGridDeltaX = Int(draggedPiece_cumulativeGridDelta_GV.width)
                    let finalGridDeltaY = Int(draggedPiece_cumulativeGridDelta_GV.height)

                    if finalGridDeltaX != 0 || finalGridDeltaY != 0 {
                        gameManager.attemptMove(pieceId: piece.id, dx: finalGridDeltaX, dy: finalGridDeltaY)
                    }

                    // 重置 GameView 中的拖动状态
                    draggedPieceId_GV = nil
                    draggedPiece_startGridPos_GV = nil
                    draggedPiece_cumulativeGridDelta_GV = .zero
                    draggedPiece_visualOffset_GV = .zero
                }
        )
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

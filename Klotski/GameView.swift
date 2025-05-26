//
//  GameView.swift
//  Klotski
//
//  Created by zhukun on 2025/5/18.
//

import SwiftUI

// MARK: 游戏主界面
struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    // --- 拖动状态 ---
    @State private var draggingPieceID: Int? = nil
    @State private var pieceInitialGridPos_onDragStart: CGPoint? = nil
    @State private var fingerStartScreenPos_onDragStart: CGPoint? = nil
    @State private var currentValidCumulativeGridOffset: CGSize = .zero
    @State private var dragSnapThresholdFactor: CGFloat = 0.2 // 拖动阈值

    @State private var navigateToLevelSelection = false
    
    private let boardPadding: CGFloat = 10
    private let controlButtonSize: CGFloat = 44
    private let panelWidthRatio: CGFloat = 0.85 // 面板宽度占屏幕宽度的比例，可以调整
    private let panelCornerRadius: CGFloat = 20 // 面板圆角

    private func calculateCellSize(geometry: GeometryProxy, boardWidthCells: Int, boardHeightCells: Int) -> CGFloat {
        guard boardWidthCells > 0, boardHeightCells > 0 else { return 1 }
        let availableWidth = geometry.size.width - (boardPadding * 2)
        let controlAreaHeight = controlButtonSize + 15 + 60 // 大约是两行按钮的高度和间距
        let availableHeight = (geometry.size.height * 0.9) - (boardPadding * 2) - controlAreaHeight
        guard availableWidth > 0, availableHeight > 0 else { return 1 }
        return max(1, min(availableWidth / CGFloat(boardWidthCells), availableHeight / CGFloat(boardHeightCells), 80)) // Max cell size 80
    }

    // 自定义带阈值的取整函数
    private func customRoundWithThreshold(_ value: CGFloat, threshold: CGFloat) -> Int {
        let av = abs(value); let sign = value >= 0 ? 1 : -1
        return av.truncatingRemainder(dividingBy: 1.0) >= threshold ? Int(ceil(av)) * sign : Int(floor(av)) * sign
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack { // 主 ZStack，用于容纳游戏内容和各种浮层/面板
                // 游戏核心内容区域
                gameAreaView(geometry: geometry)
                    //.blur(radius: showLevelSelectionPanel || (gameManager.isPaused && !gameManager.isGameWon) ? 5 : 0) // 面板或暂停时模糊背景
                    //.allowsHitTesting(!(showLevelSelectionPanel || (gameManager.isPaused && !gameManager.isGameWon))) // 面板或暂停时禁用背景交互

            }
            .navigationTitle(gameManager.currentLevel?.name ?? settingsManager.localizedString(forKey: "gameTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // 始终隐藏系统返回按钮
            .toolbar { navigationToolbarItems } // 自定义工具栏
            .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
            .onAppear(perform: setupGameView)
            .onDisappear(perform: cleanupGameView)
            .navigationDestination(isPresented: $navigateToLevelSelection) {
                LevelSelectionView(
                    isPresentedAsPanel: false, // 确保它被视为完整视图
                    // dismissPanelAction 此处不需要，因为它不是面板
                    onLevelSelected: { self.navigateToLevelSelection = false } // 用于关闭此视图的回调
                )
            }
        }
    }

    @ViewBuilder
    private func gameAreaView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            if let level = gameManager.currentLevel {
                let cellSize = calculateCellSize(geometry: geometry, boardWidthCells: level.boardWidth, boardHeightCells: level.boardHeight)
                if cellSize <= 1 {
                    Text("错误：棋盘尺寸计算异常。").foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    gameInfoView.padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 5)
                    bestRecordsView.padding(.bottom, 10)
                    
                    // 棋盘和棋子
                    ZStack {
                        BoardBackgroundView(widthCells: level.boardWidth, heightCells: level.boardHeight, cellSize: cellSize, theme: themeManager.currentTheme)
                            .frame(width: cellSize * CGFloat(level.boardWidth), height: cellSize * CGFloat(level.boardHeight))
                        ForEach(gameManager.pieces) { piece in
                            PieceView(piece: piece, cellSize: cellSize, theme: themeManager.currentTheme, isDragging: piece.id == draggingPieceID)
                                .position(x: CGFloat(piece.x) * cellSize + (CGFloat(piece.width) * cellSize / 2), y: CGFloat(piece.y) * cellSize + (CGFloat(piece.height) * cellSize / 2))
                                .offset(x: piece.id == draggingPieceID ? currentValidCumulativeGridOffset.width * cellSize : 0, y: piece.id == draggingPieceID ? currentValidCumulativeGridOffset.height * cellSize : 0)
                                .gesture(pieceDragGesture(piece: piece, cellSize: cellSize))
                        }

                        // 暂停浮层 (在选择关卡面板之下，游戏内容之上)
                        if gameManager.isPaused && !gameManager.isGameWon {
                            pauseOverlay
                        }

                        // 胜利浮层 (最高优先级)
                        if gameManager.isGameWon {
                            victoryOverlay
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.7).ignoresSafeArea())
                        }

                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameManager.pieces)
                    .frame(width: cellSize * CGFloat(level.boardWidth), height: cellSize * CGFloat(level.boardHeight))
                    
                    gameControlsView.padding(.top, 20)
                    gameMainControlsView.padding(.top, 20)
                    Spacer()
                }
            } else {
                Text("未选择关卡。").foregroundColor(themeManager.currentTheme.sliderColor.color).padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    func pieceDragGesture(piece: Piece, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged { value in
                guard cellSize > 0, !gameManager.isGameWon, !gameManager.isPaused else { return }

                if draggingPieceID == nil { // Start of a new drag
                    draggingPieceID = piece.id
                    pieceInitialGridPos_onDragStart = CGPoint(x: piece.x, y: piece.y)
                    fingerStartScreenPos_onDragStart = value.startLocation
                    currentValidCumulativeGridOffset = .zero // Reset offset
                    SoundManager.playImpactHaptic(settings: settingsManager) // Haptic for drag start
                }

                guard draggingPieceID == piece.id,
                      let initialGridPos = pieceInitialGridPos_onDragStart,
                      let fingerStartPos = fingerStartScreenPos_onDragStart else { return }

                let totalScreenDrag = CGSize(width: value.location.x - fingerStartPos.x, height: value.location.y - fingerStartPos.y)
                let targetTotalGridDeltaX = customRoundWithThreshold(totalScreenDrag.width / cellSize, threshold: dragSnapThresholdFactor)
                let targetTotalGridDeltaY = customRoundWithThreshold(totalScreenDrag.height / cellSize, threshold: dragSnapThresholdFactor)
                
                var newCumulativeGridOffset = currentValidCumulativeGridOffset
                
                if Int(newCumulativeGridOffset.width) != targetTotalGridDeltaX {
                    let stepX = (targetTotalGridDeltaX > Int(newCumulativeGridOffset.width)) ? 1 : -1
                    if gameManager.canMove(pieceId: piece.id, currentGridX: Int(initialGridPos.x) + Int(newCumulativeGridOffset.width), currentGridY: Int(initialGridPos.y) + Int(newCumulativeGridOffset.height), deltaX: stepX, deltaY: 0) {
                        newCumulativeGridOffset.width += CGFloat(stepX)
                    }
                }
                
                if Int(newCumulativeGridOffset.height) != targetTotalGridDeltaY {
                    let stepY = (targetTotalGridDeltaY > Int(newCumulativeGridOffset.height)) ? 1 : -1
                    if gameManager.canMove(pieceId: piece.id, currentGridX: Int(initialGridPos.x) + Int(newCumulativeGridOffset.width), currentGridY: Int(initialGridPos.y) + Int(newCumulativeGridOffset.height), deltaX: 0, deltaY: stepY) {
                        newCumulativeGridOffset.height += CGFloat(stepY)
                    }
                }
                
                if newCumulativeGridOffset != currentValidCumulativeGridOffset {
                    currentValidCumulativeGridOffset = newCumulativeGridOffset
                    // SoundManager.playImpactHaptic(settings: settingsManager) // Haptic for each grid snap (can be too much)
                }
            }
            .onEnded { value in
                guard let pieceId = draggingPieceID,
                      (currentValidCumulativeGridOffset.width != 0 || currentValidCumulativeGridOffset.height != 0) else {
                    // No significant drag, or drag ended without valid offset
                    draggingPieceID = nil; pieceInitialGridPos_onDragStart = nil; fingerStartScreenPos_onDragStart = nil; currentValidCumulativeGridOffset = .zero
                    return
                }

                let finalDx = Int(currentValidCumulativeGridOffset.width)
                let finalDy = Int(currentValidCumulativeGridOffset.height)

                // Reset drag states BEFORE model update for cleaner animation
                self.draggingPieceID = nil
                self.pieceInitialGridPos_onDragStart = nil
                self.fingerStartScreenPos_onDragStart = nil
                self.currentValidCumulativeGridOffset = .zero

                // Attempt the move. Changes to gameManager.pieces will be animated.
                let moveSuccessful = gameManager.attemptMove(pieceId: pieceId, dx: finalDx, dy: finalDy, settings: settingsManager)

                if moveSuccessful {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                } else if (finalDx != 0 || finalDy != 0) { // Attempted a move but it was invalid
                    SoundManager.playHapticNotification(type: .error, settings: settingsManager)
                    // The piece will snap back due to animation on gameManager.pieces and offset reset
                }
            }
    }

    // 完成浮层
    @ViewBuilder
    private var victoryOverlay: some View {
        VStack(spacing: 20) { // 增加间距
            Text(settingsManager.localizedString(forKey: "victoryTitle"))
                .font(.system(size: 36, weight: .bold, design: .rounded)) // 增大字体
                .foregroundColor(themeManager.currentTheme.sliderTextColor.color)
                .padding(.bottom, 10) // 增加底部内边距

            Text(settingsManager.localizedString(forKey: "victoryMessage"))
                .font(.title2) // 使用 title2 更突出
                .foregroundColor(themeManager.currentTheme.sliderTextColor.color)
                .padding(.bottom, 20) // 增加底部内边距
            
            Button(action: {
                SoundManager.playImpactHaptic(settings: settingsManager)
                gameManager.isGameActive = false // 在这里设置 isGameActive 为 false
                dismiss()
            }) {
                Text(settingsManager.localizedString(forKey: "backToMenu"))
                    .font(.headline)
                    .padding(.horizontal, 30) // 增加按钮内边距
                    .padding(.vertical, 15)
            }
            .buttonStyle(MenuButtonStyle(themeManager: themeManager)) // 应用统一样式
        }
        .padding(EdgeInsets(top: 40, leading: 30, bottom: 40, trailing: 30)) // 调整整体内边距
        .background(themeManager.currentTheme.sliderColor.color.opacity(0.9)) // 背景更不透明一些
        .cornerRadius(20) // 更大的圆角
        .shadow(color: .black.opacity(0.3), radius: 10, x:0, y:5) // 调整阴影
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }

    // 暂停浮层
    @ViewBuilder 
    private var pauseOverlay: some View {
        VStack(spacing: 25) { 
            
            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                gameManager.resumeGame(settings: settingsManager) 
            }) { 
                Image(systemName: "play.rectangle.fill").resizable().scaledToFit()
            }
            .frame(width: controlButtonSize*5, height: controlButtonSize*5)
            .foregroundColor(themeManager.currentTheme.backgroundColor.color.opacity(0.5))

        }
        // .frame(width: controlButtonSize*3, height: controlButtonSize*3)
        // .foregroundColor(themeManager.currentTheme.sliderColor.color)
        // .padding(EdgeInsets(top: 50, leading: 40, bottom: 50, trailing: 40))
        // .background(themeManager.currentTheme.backgroundColor.color.opacity(0.95).blur(radius: 5))
        // .cornerRadius(20)
        // .shadow(color: .black.opacity(0.4), radius: 15, x:0, y:8)
        // .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .background(Color.black.opacity(0.6).ignoresSafeArea())
        // .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    // 游戏信息 (当前时间、步数)
    private var gameInfoView: some View {
        HStack { 
            Text("\(settingsManager.localizedString(forKey: "time")): \(gameManager.formattedTime(gameManager.timeElapsed))")
            Spacer()
            Text("\(settingsManager.localizedString(forKey: "moves")): \(gameManager.moves)").frame(minWidth:100, alignment: .leading) 
        }
        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .callout)
        .foregroundColor(themeManager.currentTheme.sliderColor.color)
    }

    // 显示最佳记录的视图
    private var bestRecordsView: some View {
        HStack {
            Text("\(settingsManager.localizedString(forKey: "bestTime")): \(gameManager.formattedTime(gameManager.currentLevel?.bestTime))")
            Spacer()
            Text("\(settingsManager.localizedString(forKey: "bestMoves")): \(gameManager.currentLevel?.bestMoves != nil ? "\(gameManager.currentLevel!.bestMoves!)" : "--")")
                .frame(minWidth:100, alignment: .leading)
        }
        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
        .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))
        .padding(.horizontal, 20)
    }

    // 游戏控制按钮视图 (上一关, 开始/暂停, 下一关)
    private var gameControlsView: some View { // 控制按钮调用 gameManager 的方法
        HStack(spacing: 30) {
            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                if let currentIndex = gameManager.currentLevelIndex, currentIndex > 0 {
                    gameManager.switchToLevel(at: currentIndex - 1, settings: settingsManager) 
                }
            }){ 
                Image(systemName: "backward.circle.fill").resizable().scaledToFit() 
            }
            .frame(width: controlButtonSize, height: controlButtonSize)
            .foregroundColor(themeManager.currentTheme.sliderColor.color)
            .disabled(gameManager.currentLevelIndex == nil || gameManager.currentLevelIndex == 0 || gameManager.isPaused || gameManager.isGameWon)
            
            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                if gameManager.isPaused { 
                    gameManager.resumeGame(settings: settingsManager) 
                } else { 
                    gameManager.pauseGame() 
                } 
            }) { 
                Image(systemName: gameManager.isPaused ? "play.circle.fill" : "pause.circle.fill").resizable().scaledToFit() 
            }
            .frame(width: controlButtonSize * 2, height: controlButtonSize * 2)
            .foregroundColor(themeManager.currentTheme.sliderColor.color).disabled(gameManager.isGameWon)

            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                if let currentIndex = gameManager.currentLevelIndex, currentIndex < gameManager.levels.count - 1 {
                    gameManager.switchToLevel(at: currentIndex + 1, settings: settingsManager) 
                } 
            }) { 
                Image(systemName: "forward.circle.fill").resizable().scaledToFit() 
            }
            .frame(width: controlButtonSize, height: controlButtonSize)
            .foregroundColor(themeManager.currentTheme.sliderColor.color)
            .disabled(gameManager.currentLevelIndex == nil || gameManager.currentLevelIndex == gameManager.levels.count - 1 || gameManager.isPaused || gameManager.isGameWon)
        }.padding(.top, 20)
    }
    // 菜单，重来，关卡
    private var gameMainControlsView: some View { 
        HStack(spacing: 30) {
            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                gameManager.pauseGame()
                gameManager.saveGame(settings: settingsManager)
                gameManager.isGameActive = false
                dismiss() 
            }) { 
                Image(systemName: "house.circle.fill").resizable().scaledToFit()
            }
            .frame(width: controlButtonSize, height: controlButtonSize)
            .foregroundColor(themeManager.currentTheme.sliderColor.color)
            
            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                if let currentIndex = gameManager.currentLevelIndex{
                    gameManager.switchToLevel(at: currentIndex, settings: settingsManager)
                }
            }) { 
                Image(systemName: "arrow.clockwise.circle.fill").resizable().scaledToFit()
            }
            .frame(width: controlButtonSize+10, height: controlButtonSize+10)
            .foregroundColor(themeManager.currentTheme.sliderColor.color)

            // 游戏内选择关卡按钮
            Button(action: {
                SoundManager.playImpactHaptic(settings: settingsManager)
                if !gameManager.isPaused { // 如果游戏当前未暂停，则暂停它
                    gameManager.pauseGame()
                }
                gameManager.saveGame(settings: settingsManager) // 打开面板前保存一下，确保状态最新
                self.navigateToLevelSelection = true
            }) {
                Image(systemName: "list.bullet.circle.fill").resizable().scaledToFit()
            }
            .frame(width: controlButtonSize, height: controlButtonSize)
            .foregroundColor(themeManager.currentTheme.sliderColor.color)
    
            
        }.padding(.top, 20)
    }
    
    @ToolbarContentBuilder 
    private var navigationToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { 
            SoundManager.playImpactHaptic(settings: settingsManager)
            gameManager.pauseGame()
            gameManager.saveGame(settings: settingsManager)
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
            .imageScale(.large) }
            .tint(themeManager.currentTheme.sliderColor.color)
            
        }
    }
    private func setupGameView(){
        print("GameView onAppear: isGameActive=\(gameManager.isGameActive), isPaused=\(gameManager.isPaused), isGameWon=\(gameManager.isGameWon)")
        if gameManager.isGameActive && !gameManager.isPaused && !gameManager.isGameWon {
            gameManager.resumeGame(settings: settingsManager) // 确保计时器启动（如果之前是暂停状态）
        } else if gameManager.isGameActive && gameManager.isPaused && !gameManager.isGameWon {
            // 如果游戏是活跃的，但已标记为暂停（例如从后台恢复），则保持暂停状态，等待用户操作
            print("GameView onAppear: Game is active but paused. Timer remains stopped.")
        } else {
            gameManager.stopTimer() // 其他情况（如游戏未激活或已胜利）确保计时器停止
        }
    }

    private func cleanupGameView(){
        print("GameView onDisappear: isGameActive=\(gameManager.isGameActive), isPaused=\(gameManager.isPaused), isGameWon=\(gameManager.isGameWon)")
        if gameManager.isGameActive && !gameManager.isGameWon {
            // 当视图消失时（例如导航离开，而不是应用进入后台），
            // 我们应该暂停游戏并保存状态。
            // 应用进入后台的保存由 KlotskiApp 中的 scenePhase 处理。
            print("GameView onDisappear: Pausing and saving game.")
            gameManager.pauseGame() // 这会停止计时器
            gameManager.saveGame(settings: settingsManager)
        } else {
            // 如果游戏已胜利或已不活跃，则不需要额外操作，计时器应已停止。
            gameManager.stopTimer() // 确保计时器停止
        }
    }

    
}

// MARK: 棋盘背景和网格线视图
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


// MARK: 单个棋子视图
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

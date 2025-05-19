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

    // --- 新增：可调拖动吸附阈值 ---
    // 代表需要拖动超过格子尺寸的多少比例才吸附到下一个格子。
    // 0.5 表示标准的四舍五入 (拖动半格)。
    // 较小的值 (如 0.3) 表示更灵敏，拖动较少距离就吸附。
    // 较大的值 (如 0.7) 表示需要拖动更多距离才吸附。
    @State private var dragSnapThresholdFactor: CGFloat = 0.2 // 您可以更改此值进行测试

    // --- 计时器等其他状态 ---
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var internalTimeElapsed: TimeInterval = 0
    
    private let boardPadding: CGFloat = 10

    private func calculateCellSize(geometry: GeometryProxy, boardWidthCells: Int, boardHeightCells: Int) -> CGFloat {
        guard boardWidthCells > 0, boardHeightCells > 0 else { return 1 }
        let availableWidth = geometry.size.width - (boardPadding * 2)
        // Allocate more height for game board, e.g., 70% of available height if info view is present
        let availableHeight = (geometry.size.height * (gameManager.isGameWon ? 0.8 : 0.7)) - (boardPadding * 2) // Adjust based on win state
        guard availableWidth > 0, availableHeight > 0 else { return 1 }
        return max(1, min(availableWidth / CGFloat(boardWidthCells), availableHeight / CGFloat(boardHeightCells), 80)) // Max cell size 80
    }

    // 自定义取整函数，基于阈值
    private func customRoundWithThreshold(_ value: CGFloat, threshold: CGFloat) -> Int {
        let absoluteValue = abs(value)
        let sign = value >= 0 ? 1 : -1
        
        // 检查是否超过了整数部分加上阈值
        if absoluteValue.truncatingRemainder(dividingBy: 1.0) >= threshold {
            return Int(ceil(absoluteValue)) * sign
        } else {
            return Int(floor(absoluteValue)) * sign
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let level = gameManager.currentLevel {
                    let cellSize = calculateCellSize(geometry: geometry, boardWidthCells: level.boardWidth, boardHeightCells: level.boardHeight)
                    
                    if cellSize <= 1 {
                        Text("错误：棋盘尺寸计算异常。").foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        
                        gameInfoView.padding(.horizontal, 40).padding(.top, 40)
                        ZStack {
                            BoardBackgroundView(widthCells: level.boardWidth, heightCells: level.boardHeight, cellSize: cellSize, theme: themeManager.currentTheme)
                                .frame(width: cellSize * CGFloat(level.boardWidth), height: cellSize * CGFloat(level.boardHeight))

                            ForEach(gameManager.pieces) { piece in
                                PieceView(piece: piece, cellSize: cellSize, theme: themeManager.currentTheme, isDragging: piece.id == draggingPieceID)
                                    .position(
                                        x: CGFloat(piece.x) * cellSize + (CGFloat(piece.width) * cellSize / 2),
                                        y: CGFloat(piece.y) * cellSize + (CGFloat(piece.height) * cellSize / 2)
                                    )
                                    .offset( // This offset is for visual drag effect only
                                        x: piece.id == draggingPieceID ? currentValidCumulativeGridOffset.width * cellSize : 0,
                                        y: piece.id == draggingPieceID ? currentValidCumulativeGridOffset.height * cellSize : 0
                                    )
                                    .gesture(pieceDragGesture(piece: piece, cellSize: cellSize))
                            }
                            
                            //显示完成视图
                            if gameManager.isGameWon {
                                victoryOverlay
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameManager.pieces) // Animates piece movements
                        .frame(width: cellSize * CGFloat(level.boardWidth), height: cellSize * CGFloat(level.boardHeight))
                        .padding(.vertical)
                        
                        Spacer()
                    }
                } else {
                    Text("未选择关卡。").foregroundColor(themeManager.currentTheme.sliderColor.color).padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    func pieceDragGesture(piece: Piece, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged { value in
                guard cellSize > 0, !gameManager.isGameWon else { return }

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
    
    private var gameInfoView: some View {
        HStack {
            //Text("\(settingsManager.localizedString(forKey: "level")): \(gameManager.currentLevel?.name ?? "N/A")")
            //Spacer()
            Text("\(settingsManager.localizedString(forKey: "time")): \(formattedTime(internalTimeElapsed))")
            Spacer()
            Text("\(settingsManager.localizedString(forKey: "moves")): \(gameManager.moves)").frame(width:80, alignment: .leading)
        }
        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .callout)
        .foregroundColor(themeManager.currentTheme.sliderColor.color)
    }
    
    @ToolbarContentBuilder
    private var navigationToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if gameManager.isGameActive && !gameManager.isGameWon { // 仅当活跃且未胜利时显示
                Button {
                    gameManager.timeElapsed = internalTimeElapsed // 捕获当前时间
                    if gameManager.isGameActive && !gameManager.isGameWon { // 再次检查以防万一
                        print("暂停按钮按下：正在保存游戏...")
                        gameManager.saveGame(settings: settingsManager) // 暂停时明确保存游戏
                    }
                    gameManager.isGameActive = false // 这将通过 NavigationDestination 触发返回
                    // dismiss() // 不需要显式调用 dismiss，isGameActive=false 会处理
                } label: {
                    HStack { Image(systemName: "chevron.backward"); Text(settingsManager.localizedString(forKey: "pause")) }
                }
                .tint(themeManager.currentTheme.sliderColor.color)
            }
        }
    }
    private func setupGameView(){ 
        if gameManager.isGameActive { internalTimeElapsed = gameManager.timeElapsed; startTimer() 
    } else { print("GameView setup: gameManager is not active.")} }

    private func cleanupGameView(){
        stopTimer()
        // 当视图消失时，如果游戏仍然被认为是活跃的（例如，不是通过胜利或暂停按钮正常退出）
        // 并且未胜利，则保存其状态。
        // 这主要处理应用进入后台或被系统中断的情况。
        if gameManager.isGameActive && !gameManager.isGameWon {
            print("GameView cleanup: Game is still active and not won. Saving time and game state.")
            gameManager.timeElapsed = internalTimeElapsed
            gameManager.saveGame(settings: settingsManager)
        } else if gameManager.isGameWon {
            print("GameView cleanup: Game was won. State should have been cleared.")
        } else {
            print("GameView cleanup: Game was not active (likely paused or dismissed normally). No save action here.")
        }
    }

    private func startTimer(){stopTimer();timer=Timer.publish(every:1,on:.main,in:.common).autoconnect()}
    private func stopTimer(){timer.upstream.connect().cancel()}
    private func formattedTime(_ tS:TimeInterval)->String{let m=Int(tS)/60;let s=Int(tS)%60;return String(format:"%02d:%02d",m,s)}
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

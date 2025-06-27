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
    @State private var dragSnapThresholdFactor: CGFloat = 0.3 // 拖动阈值

    @State private var navigateToLevelSelection = false

    // 获取当前主题的渲染策略
    private var themeFactory: any ThemeableViewFactory {
        themeManager.currentTheme.viewFactory
    }
    
    private let controlButtonSize: CGFloat = 44

    private func calculateCellSize(geometry: GeometryProxy, boardWidthCells: Int, boardHeightCells: Int) -> CGFloat {
        let boardPadding: CGFloat = 10
        guard boardWidthCells > 0, boardHeightCells > 0 else { return 1 }
        let availableWidth = geometry.size.width - (boardPadding * 2)
        let controlAreaHeight = controlButtonSize + 15 + 60 + 80 // 增加了更多控制区域高度的估算
        let availableHeight = (geometry.size.height * 0.9) - (boardPadding * 2) - controlAreaHeight
        guard availableWidth > 0, availableHeight > 0 else { return 1 }
        return max(1, min(availableWidth / CGFloat(boardWidthCells), availableHeight / CGFloat(boardHeightCells), 80))
    }

    private func customRoundWithThreshold(_ value: CGFloat, threshold: CGFloat) -> Int {
        let av = abs(value); let sign = value >= 0 ? 1 : -1
        return av.truncatingRemainder(dividingBy: 1.0) >= threshold ? Int(ceil(av)) * sign : Int(floor(av)) * sign
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 由主题工厂提供背景
                AnyView(themeFactory.gameBackground())

                // 游戏核心内容区域
                gameAreaView(geometry: geometry)
            }
            .navigationTitle(gameManager.currentLevel?.name ?? settingsManager.localizedString(forKey: "gameTitle"))
            .navigationBarTitleDisplayMode(.inline)
            //.navigationBarBackButtonHidden(true)
            //.toolbar { navigationToolbarItems }
            
            .onAppear(perform: setupGameView)
            .onDisappear(perform: cleanupGameView)
            .navigationDestination(isPresented: $navigateToLevelSelection) {
                LevelSelectionView(showLevelSelection: $navigateToLevelSelection)
            }
        }
        
    }

    @ViewBuilder
    private func gameAreaView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            if let level = gameManager.currentLevel {
                let cellSize = calculateCellSize(geometry: geometry, boardWidthCells: level.boardWidth, boardHeightCells: level.boardHeight)
                if cellSize <= 1 {
                    Text(settingsManager.localizedString(forKey: "boardSizeError")).foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(){
                        currentInfoView
                        Spacer()
                        recordInfoView

                    }
                    .frame(width:cellSize * CGFloat(level.boardWidth))
                    .padding(.top,20)
                    .padding(.bottom,10)
                    
                    
                    ZStack {
                        // 由主题工厂提供棋盘背景
                        AnyView(themeFactory.boardBackground(widthCells: level.boardWidth, heightCells: level.boardHeight, cellSize: cellSize))
                            .frame(width: cellSize * CGFloat(level.boardWidth), height: cellSize * CGFloat(level.boardHeight))

                        ForEach(gameManager.pieces) { piece in
                            // 由主题工厂提供棋子视图
                            AnyView(themeFactory.pieceView(for: piece, cellSize: cellSize, isDragging: piece.id == draggingPieceID))
                                .frame(width: CGFloat(piece.width) * cellSize - 2, height: CGFloat(piece.height) * cellSize - 2)
                                .position(x: CGFloat(piece.x) * cellSize + (CGFloat(piece.width) * cellSize / 2), y: CGFloat(piece.y) * cellSize + (CGFloat(piece.height) * cellSize / 2))
                                .offset(x: piece.id == draggingPieceID ? currentValidCumulativeGridOffset.width * cellSize : 0, y: piece.id == draggingPieceID ? currentValidCumulativeGridOffset.height * cellSize : 0)
                                .gesture(pieceDragGesture(piece: piece, cellSize: cellSize))
                        }

                        if gameManager.isPaused && !gameManager.isGameWon {
                            pauseOverlay
                        }

                        if gameManager.isGameWon {
                            //RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.black.opacity(0.6))
                            victoryOverlay
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameManager.pieces)
                    .frame(width: cellSize * CGFloat(level.boardWidth), height: cellSize * CGFloat(level.boardHeight))
                    
                    gameControlsView.padding(.top, 20)
                    gameMainControlsView.padding(.top, 5)
                    Spacer()
                }
            } else {
                Text(settingsManager.localizedString(forKey: "noLevelSelected")).foregroundColor(themeManager.currentTheme.textColor.color).padding()
            }
            Spacer()
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
                    draggingPieceID = nil; pieceInitialGridPos_onDragStart = nil; fingerStartScreenPos_onDragStart = nil; currentValidCumulativeGridOffset = .zero
                    return
                }

                let finalDx = Int(currentValidCumulativeGridOffset.width)
                let finalDy = Int(currentValidCumulativeGridOffset.height)

                self.draggingPieceID = nil
                self.pieceInitialGridPos_onDragStart = nil
                self.fingerStartScreenPos_onDragStart = nil
                self.currentValidCumulativeGridOffset = .zero

                let moveSuccessful = gameManager.attemptMove(pieceId: pieceId, dx: finalDx, dy: finalDy, settings: settingsManager)

                if moveSuccessful {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                } else if (finalDx != 0 || finalDy != 0) {
                    SoundManager.playHapticNotification(type: .error, settings: settingsManager)
                }
            }
    }

    @ViewBuilder
    private var victoryOverlay: some View {
        VStack() {
            Spacer()
            Text(settingsManager.localizedString(forKey: "victoryTitle"))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.sliderTextColor.color)
                .padding(.bottom, 10)
            
            Spacer()
            Button(action: {
                SoundManager.playImpactHaptic(settings: settingsManager)
                gameManager.isGameActive = false
                dismiss()
            }) {
                Text(settingsManager.localizedString(forKey: "backToMenu"))
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
            }
            .buttonStyle(themeFactory.victoryButtonStyle())
            Spacer()
        }
        .padding(EdgeInsets(top: 50, leading: 20, bottom: 50, trailing: 20))
        .background(themeManager.currentTheme.textColor.color.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, x:0, y:5)
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }

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
    }

    // --- 修改：游戏信息 (当前时间、步数) ---
    private var currentInfoView: some View {
        VStack(alignment: .leading,spacing: 10) {
            Text("\(settingsManager.localizedString(forKey: "moves")): \(gameManager.moves)")
            Text("\(settingsManager.localizedString(forKey: "time")): \(gameManager.formattedTime(gameManager.timeElapsed))")
            
            
        }
        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .callout)
        .foregroundColor(themeManager.currentTheme.textColor.color) // 使用 textColor
    }

    // --- 修改：显示最佳记录的视图 ---
    private var recordInfoView: some View {
        VStack(alignment: .trailing,spacing: 10) {
            Text("\(settingsManager.localizedString(forKey: "bestMoves")): \(gameManager.currentLevel?.bestMoves != nil ? "\(gameManager.currentLevel!.bestMoves!)" : "--")")
            Text("\(settingsManager.localizedString(forKey: "bestTime")): \(gameManager.formattedTime(gameManager.currentLevel?.bestTime))")
        }
        .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .callout)
        .foregroundColor(themeManager.currentTheme.textColor.color) // 使用 textColor
    }

    // --- 修改：游戏控制按钮视图 (上一关, 开始/暂停, 下一关) ---
    private var gameControlsView: some View {
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
            .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用 textColor
            .disabled(gameManager.currentLevelIndex == nil || gameManager.currentLevelIndex == 0)
            
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
            .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用 textColor
            .disabled(gameManager.isGameWon)

            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                if let currentIndex = gameManager.currentLevelIndex, currentIndex < gameManager.levels.count - 1 {
                    gameManager.switchToLevel(at: currentIndex + 1, settings: settingsManager) 
                } 
            }) { 
                Image(systemName: "forward.circle.fill").resizable().scaledToFit() 
            }
            .frame(width: controlButtonSize, height: controlButtonSize)
            .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用 textColor
            .disabled(gameManager.currentLevelIndex == nil || gameManager.currentLevelIndex == gameManager.levels.count - 1)
        }.padding(.top, 20)
    }

    // --- 修改：菜单，重来，关卡按钮 ---
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
            .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用 textColor
            
            Button(action: { 
                SoundManager.playImpactHaptic(settings: settingsManager)
                if let currentIndex = gameManager.currentLevelIndex{
                    gameManager.switchToLevel(at: currentIndex, settings: settingsManager)
                }
            }) { 
                Image(systemName: "arrow.clockwise.circle.fill").resizable().scaledToFit()
            }
            .frame(width: controlButtonSize+10, height: controlButtonSize+10)
            .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用 textColor

            Button(action: {
                SoundManager.playImpactHaptic(settings: settingsManager)
                if !gameManager.isPaused {
                    gameManager.pauseGame()
                }
                gameManager.saveGame(settings: settingsManager)
                self.navigateToLevelSelection = true
            }) {
                Image(systemName: "list.bullet.circle.fill").resizable().scaledToFit()
            }
            .frame(width: controlButtonSize, height: controlButtonSize)
            .foregroundColor(themeManager.currentTheme.sliderColor.color) // 使用 textColor
        }.padding(.top, 20)
    }
    
    // --- 修改：导航栏工具栏项目 ---
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
                    .imageScale(.large)
            }
            .tint(themeManager.currentTheme.textColor.color) // 使用 textColor
        }
    }

    private func setupGameView(){
        debugLog("GameView onAppear: isGameActive=\(gameManager.isGameActive), isPaused=\(gameManager.isPaused), isGameWon=\(gameManager.isGameWon)")
        if gameManager.isGameActive && !gameManager.isPaused && !gameManager.isGameWon {
            gameManager.resumeGame(settings: settingsManager)
        } else if gameManager.isGameActive && gameManager.isPaused && !gameManager.isGameWon {
            debugLog("GameView onAppear: Game is active but paused. Timer remains stopped.")
        } else {
            gameManager.stopTimer()
        }
    }

    private func cleanupGameView(){
        debugLog("GameView onDisappear: isGameActive=\(gameManager.isGameActive), isPaused=\(gameManager.isPaused), isGameWon=\(gameManager.isGameWon)")
        if  !gameManager.isGameWon {
            debugLog("GameView onDisappear: Pausing and saving game.")
            gameManager.pauseGame()
            gameManager.saveGame(settings: settingsManager)
        } else {
            gameManager.stopTimer()
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
            Rectangle()
                .fill(theme.boardBackgroundColor.color)
            
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


// MARK: 单个棋子视图
struct PieceView: View {
    let piece: Piece
    let cellSize: CGFloat
    let theme: Theme
    var isDragging: Bool = false

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
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .fill(theme.sliderColor.color)
        }
    }

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
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .stroke(theme.sliderColor.color.opacity(0.5), lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var pieceTextContent: some View {
        if theme.sliderContent == .character || theme.sliderContent == .number {
            Text(piece.type.displayName)
                .font(Font.system(size: calculateFontSize(for: piece, cellSize: cellSize)))
                .fontWeight(.bold)
                .foregroundColor(theme.sliderTextColor.color)
        }
    }

    var body: some View {
        ZStack {
            filledShapeView
                .frame(width: CGFloat(piece.width) * cellSize - 2, height: CGFloat(piece.height) * cellSize - 2)
                .overlay(
                    strokedShapeView
                        .frame(width: CGFloat(piece.width) * cellSize - 2, height: CGFloat(piece.height) * cellSize - 2)
                )
                .shadow(color: .black.opacity(isDragging ? 0.4 : 0.2), radius: isDragging ? 8 : 3, x: isDragging ? 4 : 1, y: isDragging ? 4 : 1)
            
            pieceTextContent
        }
    }

    private func calculateFontSize(for piece: Piece, cellSize: CGFloat) -> CGFloat {
        let baseSize = cellSize * 0.5
        if piece.width == 1 && piece.height == 1 {
            return baseSize * 0.8
        }
        if piece.width == 2 && piece.height == 2 {
            return baseSize * 1.2
        }
        return baseSize
    }
}

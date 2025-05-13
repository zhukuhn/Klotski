//
//  GameScene.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    private let gridRows = 5
    private let gridCols = 4
    private var tileSize: CGSize = .zero
    private var gameBoardOrigin: CGPoint = .zero // 棋盘在场景中的左上角原点

    // 逻辑棋盘: 存储每个网格单元属于哪个棋子 (用棋子类型或ID)
    // 这里简化用 PieceType，对于多个同类型棋子，需要更复杂的标识
    // 或者用一个 GamePieceNode? 的二维数组
    private var logicalBoard: [[PieceType]] = []
    private var pieceNodes: [GamePieceNode] = [] // 存储所有棋子精灵节点

    private var selectedPiece: GamePieceNode?
    private var originalTouchPoint: CGPoint?
    private var originalPieceGridPos: (col: Int, row: Int)?

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .lightGray
        // anchorPoint 已经在 ContentView 中设置为 (0,1) 左上角

        // 1. 计算瓦片大小和棋盘原点
        // scene.size 是由 ContentView 传递过来的
        tileSize = CGSize(width: size.width / CGFloat(gridCols),
                          height: size.height / CGFloat(gridRows))
        // 由于 anchorPoint 是 (0,1)，场景的 (0,0) 点在左下角
        // 我们希望棋盘左上角对应场景的 (0, -size.height) [如果用标准SpriteKit坐标系]
        // 但因为我们设置了 anchorPoint = (0,1)，所以场景的 (0,0) 就是左上角。
        gameBoardOrigin = CGPoint.zero // 左上角

        // 2. 初始化逻辑棋盘
        initializeLogicalBoard()

        // 3. 设置初始棋子布局 ("横刀立马")
        setupHengDaoLiMaLayout()

        // 4. (可选) 绘制网格线用于调试
        drawGrid()
    }

    private func initializeLogicalBoard() {
        logicalBoard = Array(repeating: Array(repeating: .empty, count: gridCols), count: gridRows)
    }

    // MARK: - Layout Setup
    private func setupHengDaoLiMaLayout() {
        // 定义10棋子“横刀立马”布局
        // (类型, 左上角列, 左上角行)
        let layout: [(type: PieceType, x: Int, y: Int, name: String)] = [
            (.caoCao,          1, 0, "CC"),
            (.verticalGeneral, 0, 0, "V1"), // 张飞
            (.verticalGeneral, 3, 0, "V2"), // 赵云
            (.guanYu,          1, 2, "GY"),
            (.verticalGeneral, 0, 2, "V3"), // 马超
            (.verticalGeneral, 3, 2, "V4"), // 黄忠
            (.soldier,         1, 3, "S1"),
            (.soldier,         2, 3, "S2"),
            (.soldier,         0, 4, "S3"),
            (.soldier,         3, 4, "S4")
        ]

        for item in layout {
            let pieceNode = GamePieceNode(type: item.type,
                                          initialGridX: item.x,
                                          initialGridY: item.y,
                                          tileSize: tileSize)
            // 设置棋子在场景中的位置
            // 注意：SpriteKit Y轴向上，而我们的网格Y向下。
            // 我们在 gridToScreenPosition 中处理这个转换。
            pieceNode.position = gridToScreenPosition(col: item.x, row: item.y,
                                                      pieceWidthInUnits: pieceNode.gridWidth,
                                                      pieceHeightInUnits: pieceNode.gridHeight)
            pieceNode.name = item.name // 给每个棋子一个唯一的名字以便区分
            addChild(pieceNode)
            pieceNodes.append(pieceNode)
            updateLogicalBoard(with: pieceNode, occupying: true) // 标记棋盘
        }
    }

    // MARK: - Coordinate Conversion
    // 将屏幕上的点转换为网格坐标 (列, 行)
    private func screenToGridPosition(screenPoint: CGPoint) -> (col: Int, row: Int)? {
        // 调整 screenPoint 使其相对于 gameBoardOrigin
        // 因为我们设置了 anchorPoint=(0,1) 且 gameBoardOrigin=(0,0)，
        // 场景Y轴向下为正 (相对于视觉)。
        let boardRelativePoint = CGPoint(x: screenPoint.x - gameBoardOrigin.x,
                                         y: -(screenPoint.y - gameBoardOrigin.y)) // Y轴反转

        if boardRelativePoint.x < 0 || boardRelativePoint.x >= size.width ||
           boardRelativePoint.y < 0 || boardRelativePoint.y >= size.height {
            return nil // 点在棋盘外
        }

        let col = Int(boardRelativePoint.x / tileSize.width)
        let row = Int(boardRelativePoint.y / tileSize.height)

        // 确保在边界内
        guard col >= 0 && col < gridCols && row >= 0 && row < gridRows else {
            return nil
        }
        return (col, row)
    }

    // 将网格坐标 (棋子左上角) 转换为屏幕上的位置 (SKSpriteNode的中心点)
    private func gridToScreenPosition(col: Int, row: Int, pieceWidthInUnits: Int, pieceHeightInUnits: Int) -> CGPoint {
        let pieceWidthPx = CGFloat(pieceWidthInUnits) * tileSize.width
        let pieceHeightPx = CGFloat(pieceHeightInUnits) * tileSize.height

        // SKSpriteNode的position是其中心点
        // 左上角锚点 (0,1) 的场景，Y轴向下为正 (视觉上)
        // x: 棋盘原点X + 列数 * 瓦片宽度 + 棋子宽度的一半
        // y: 棋盘原点Y -行数 * 瓦片高度 - 棋子高度的一半 (因为Y轴向下为正)
        let screenX = gameBoardOrigin.x + CGFloat(col) * tileSize.width + pieceWidthPx / 2.0
        let screenY = gameBoardOrigin.y - (CGFloat(row) * tileSize.height + pieceHeightPx / 2.0)

        return CGPoint(x: screenX, y: screenY)
    }


    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)

        if let (touchedCol, touchedRow) = screenToGridPosition(screenPoint: touchLocation) {
            // 查找被触摸的棋子
            for piece in pieceNodes {
                if touchedCol >= piece.gridX && touchedCol < piece.gridX + piece.gridWidth &&
                   touchedRow >= piece.gridY && touchedRow < piece.gridY + piece.gridHeight {
                    selectedPiece = piece
                    originalTouchPoint = touchLocation
                    originalPieceGridPos = (piece.gridX, piece.gridY)
                    selectedPiece?.zPosition = 10 // 拖动时置于顶层
                    break
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let selectedPiece = selectedPiece,
              let touch = touches.first,
              let originalTouchPoint = originalTouchPoint else { return }

        let touchLocation = touch.location(in: self)
        let translation = CGPoint(x: touchLocation.x - originalTouchPoint.x,
                                  y: touchLocation.y - originalTouchPoint.y)

        // 更新棋子视觉位置以跟随拖动
        let originalScreenPos = gridToScreenPosition(col: selectedPiece.gridX, row: selectedPiece.gridY,
                                                     pieceWidthInUnits: selectedPiece.gridWidth,
                                                     pieceHeightInUnits: selectedPiece.gridHeight)
        selectedPiece.position = CGPoint(x: originalScreenPos.x + translation.x,
                                         y: originalScreenPos.y + translation.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let selectedPiece = selectedPiece,
              let originalPieceGridPos = originalPieceGridPos else {
            self.selectedPiece?.zPosition = 0 // 恢复层级
            self.selectedPiece = nil
            self.originalTouchPoint = nil
            self.originalPieceGridPos = nil
            return
        }

        selectedPiece.zPosition = 0 // 恢复层级

        let currentPieceScreenPos = selectedPiece.position
        let originalScreenPos = gridToScreenPosition(col: originalPieceGridPos.col, row: originalPieceGridPos.row,
                                                     pieceWidthInUnits: selectedPiece.gridWidth,
                                                     pieceHeightInUnits: selectedPiece.gridHeight)

        let deltaX = currentPieceScreenPos.x - originalScreenPos.x
        let deltaY = currentPieceScreenPos.y - originalScreenPos.y // 注意SpriteKit Y轴向上

        var targetCol = originalPieceGridPos.col
        var targetRow = originalPieceGridPos.row
        var intendedMove = false

        // 判断主要拖动方向和幅度 (至少半个瓦片才算有效拖动)
        if abs(deltaX) > tileSize.width / 2 || abs(deltaY) > tileSize.height / 2 {
            intendedMove = true
            if abs(deltaX) > abs(deltaY) { // 水平拖动为主
                let moveUnits = Int(round(deltaX / tileSize.width))
                targetCol += moveUnits
            } else { // 垂直拖动为主
                let moveUnits = Int(round(-deltaY / tileSize.height)) // -deltaY 因为屏幕Y向下为正，但SpriteKit Y向上
                targetRow += moveUnits
            }
        }

        if intendedMove && isMoveValid(for: selectedPiece, toCol: targetCol, toRow: targetRow, fromCol: originalPieceGridPos.col, fromRow: originalPieceGridPos.row) {
            // 1. 更新逻辑棋盘 (清除旧位置, 标记新位置)
            updateLogicalBoard(with: selectedPiece, occupying: false) // 清除旧位置
            selectedPiece.gridX = targetCol
            selectedPiece.gridY = targetRow
            updateLogicalBoard(with: selectedPiece, occupying: true) // 标记新位置

            // 2. 吸附棋子到新的网格位置
            selectedPiece.position = gridToScreenPosition(col: targetCol, row: targetRow,
                                                          pieceWidthInUnits: selectedPiece.gridWidth,
                                                          pieceHeightInUnits: selectedPiece.gridHeight)
            // 3. 检查胜利条件
            checkWinCondition()
        } else {
            // 无效移动或未达到拖动阈值，则棋子归位
            selectedPiece.position = gridToScreenPosition(col: originalPieceGridPos.col, row: originalPieceGridPos.row,
                                                          pieceWidthInUnits: selectedPiece.gridWidth,
                                                          pieceHeightInUnits: selectedPiece.gridHeight)
        }

        self.selectedPiece = nil
        self.originalTouchPoint = nil
        self.originalPieceGridPos = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let piece = selectedPiece, let originalPos = originalPieceGridPos {
            piece.position = gridToScreenPosition(col: originalPos.col, row: originalPos.row,
                                                  pieceWidthInUnits: piece.gridWidth,
                                                  pieceHeightInUnits: piece.gridHeight)
            piece.zPosition = 0
        }
        selectedPiece = nil
        originalTouchPoint = nil
        originalPieceGridPos = nil
    }


    // MARK: - Game Logic
    private func updateLogicalBoard(with piece: GamePieceNode, occupying: Bool) {
        let typeToSet: PieceType = occupying ? piece.pieceType : .empty
        // 如果是占据，还需要一个唯一ID来区分同类型的棋子，这里简化了
        // 例如，可以用 piece.name 或者一个专门的 pieceId
        let occupyingName: String? = occupying ? piece.name : nil

        for r in 0..<piece.gridHeight {
            for c in 0..<piece.gridWidth {
                let boardRow = piece.gridY + r
                let boardCol = piece.gridX + c
                if boardRow < gridRows && boardCol < gridCols {
                    // 在实际应用中，logicalBoard可能需要存储更详细的信息，
                    // 例如指向 GamePieceNode 的引用或其唯一ID，而不仅仅是 PieceType。
                    // 这样才能正确处理多个相同类型棋子的情况。
                    // 为了简单起见，这里只用PieceType，但对于“清除旧位置”的逻辑，
                    // 我们需要确保只清除当前移动的棋子。
                    // 暂时用 typeToSet，但更健壮的方案是基于棋子ID。
                    logicalBoard[boardRow][boardCol] = typeToSet
                }
            }
        }
    }


    private func isMoveValid(for piece: GamePieceNode, toCol: Int, toRow: Int, fromCol: Int, fromRow: Int) -> Bool {
        // 1. 检查目标位置是否在棋盘边界内
        if toCol < 0 || (toCol + piece.gridWidth) > gridCols ||
           toRow < 0 || (toRow + piece.gridHeight) > gridRows {
            return false
        }

        // 2. 检查移动路径是否只有一步 (或者说，是否是单方向移动)
        // Klotski规则：棋子只能在空位上滑动，不能跳跃。
        // 这个简化版检查目标位置，但没有检查中间路径是否有障碍 (对于大于1格的滑动)
        // 真正的华容道是每次移动到相邻的空格。这里我们先简化为直接检查目标位置。

        let deltaCol = toCol - fromCol
        let deltaRow = toRow - fromRow

        // 只允许水平或垂直移动
        guard (deltaCol != 0 && deltaRow == 0) || (deltaCol == 0 && deltaRow != 0) else {
            return false
        }
        
        // 检查路径上的所有格子 (如果是多步移动) 或仅目标格子 (如果是一步移动)
        // 简化：我们假设玩家总是试图移动到最近的有效网格位置
        // 并且一次拖动只对应一个方向上的一系列单位移动。
        // 真实的游戏可能需要更复杂的路径检查或限制单次拖动只能移动一格。

        // 检查目标区域是否为空 (除了当前棋子本身占据的原始位置)
        for r_offset in 0..<piece.gridHeight {
            for c_offset in 0..<piece.gridWidth {
                let checkRow = toRow + r_offset
                let checkCol = toCol + c_offset

                // 判断这个格子是否是原棋子占据的格子
                let isOriginalCell = (checkCol >= fromCol && checkCol < fromCol + piece.gridWidth &&
                                      checkRow >= fromRow && checkRow < fromRow + piece.gridHeight)

                if !isOriginalCell && logicalBoard[checkRow][checkCol] != .empty {
                    return false // 目标位置被其他棋子占据
                }
            }
        }
        
        // 针对特定棋子滑动规则的更精细检查：
        // 确保棋子只能滑入完全空出的区域
        if deltaCol != 0 { // 水平移动
            let step = deltaCol > 0 ? 1 : -1
            var currentCheckCol = fromCol
            while currentCheckCol != toCol {
                currentCheckCol += step
                for r_offset in 0..<piece.gridHeight {
                    let r = fromRow + r_offset
                    if logicalBoard[r][currentCheckCol + (step > 0 ? piece.gridWidth - 1 : 0)] != .empty {
                         return false //路径上有阻挡
                    }
                }
            }
        } else if deltaRow != 0 { // 垂直移动
            let step = deltaRow > 0 ? 1 : -1
            var currentCheckRow = fromRow
             while currentCheckRow != toRow {
                currentCheckRow += step
                for c_offset in 0..<piece.gridWidth {
                    let c = fromCol + c_offset
                     if logicalBoard[currentCheckRow + (step > 0 ? piece.gridHeight-1 : 0)][c] != .empty {
                        return false //路径上有阻挡
                    }
                }
            }
        }


        return true
    }


    private func checkWinCondition() {
        if let caoCaoNode = pieceNodes.first(where: { $0.pieceType == .caoCao }) {
            // 曹操的目标位置 (左上角): 列1, 行3
            if caoCaoNode.gridX == 1 && caoCaoNode.gridY == 3 {
                print("Congratulations! Cao Cao escaped!")
                // 这里可以添加游戏结束的逻辑，例如显示一个胜利标签或切换场景
                let winLabel = SKLabelNode(text: "曹操成功逃脱！")
                winLabel.fontSize = tileSize.width * 0.8
                winLabel.fontColor = .blue
                winLabel.position = CGPoint(x: size.width / 2, y: -size.height / 2) // 场景中心
                winLabel.zPosition = 100
                addChild(winLabel)
                // 可以禁用进一步的触摸
                self.isUserInteractionEnabled = false
            }
        }
    }
    
    // MARK: - Debugging
    private func drawGrid() {
        for row in 0...gridRows {
            let yPos = gameBoardOrigin.y - CGFloat(row) * tileSize.height
            let startPoint = CGPoint(x: gameBoardOrigin.x, y: yPos)
            let endPoint = CGPoint(x: gameBoardOrigin.x + size.width, y: yPos)
            let line = SKShapeNode()
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: startPoint)
            pathToDraw.addLine(to: endPoint)
            line.path = pathToDraw
            line.strokeColor = .black
            line.lineWidth = 1
            addChild(line)
        }

        for col in 0...gridCols {
            let xPos = gameBoardOrigin.x + CGFloat(col) * tileSize.width
            let startPoint = CGPoint(x: xPos, y: gameBoardOrigin.y)
            let endPoint = CGPoint(x: xPos, y: gameBoardOrigin.y - size.height)
            let line = SKShapeNode()
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: startPoint)
            pathToDraw.addLine(to: endPoint)
            line.path = pathToDraw
            line.strokeColor = .black
            line.lineWidth = 1
            addChild(line)
        }
    }
}

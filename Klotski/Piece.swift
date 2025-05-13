//
//  Piece.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SpriteKit

// 棋子类型
enum PieceType: String, CaseIterable {
    case caoCao, guanYu, verticalGeneral, soldier, empty
    // 为不同类型的棋子定义尺寸 (单位: 网格单元)
    var sizeInUnits: (width: Int, height: Int) {
        switch self {
        case .caoCao: return (2, 2)
        case .guanYu: return (2, 1) // 横向
        case .verticalGeneral: return (1, 2) // 纵向
        case .soldier: return (1, 1)
        case .empty: return (1, 1)
        }
    }
    // 为不同类型的棋子定义颜色 (方便调试)
    var color: SKColor {
        switch self {
        case .caoCao: return .red
        case .guanYu: return .cyan
        case .verticalGeneral: return .yellow
        case .soldier: return .green
        case .empty: return .clear // 空白格透明
        }
    }
}

// 代表一个游戏棋子 (逻辑和视觉的结合)
class GamePieceNode: SKSpriteNode {
    let pieceType: PieceType
    var gridX: Int // 棋子左上角在棋盘网格中的列索引
    var gridY: Int // 棋子左上角在棋盘网格中的行索引

    let gridWidth: Int  // 棋子占用的网格宽度
    let gridHeight: Int // 棋子占用的网格高度

    // 自定义初始化器
    init(type: PieceType, initialGridX: Int, initialGridY: Int, tileSize: CGSize) {
        self.pieceType = type
        self.gridX = initialGridX
        self.gridY = initialGridY
        self.gridWidth = type.sizeInUnits.width
        self.gridHeight = type.sizeInUnits.height

        let pieceSize = CGSize(width: CGFloat(gridWidth) * tileSize.width,
                               height: CGFloat(gridHeight) * tileSize.height)
        super.init(texture: nil, color: type.color, size: pieceSize)
        self.name = type.rawValue // 用于识别
        // 可以添加一个标签显示棋子名称 (可选)
        let label = SKLabelNode(text: type.rawValue.prefix(2).uppercased())
        label.fontSize = tileSize.width * 0.4
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        self.addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

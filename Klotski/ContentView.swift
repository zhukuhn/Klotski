//
//  ContentView.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    // 创建并配置 GameScene 实例
    var scene: SKScene {
        let scene = GameScene()
        // 根据实际屏幕尺寸和期望的棋盘大小调整
        // 这里假设一个固定的场景大小，具体适配方案可能更复杂
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        // 简单起见，让场景宽度等于屏幕宽度，高度自适应或设定比例
        // 棋盘是 4x5，可以设定一个 tileWidth，然后计算场景大小
        // 例如，如果棋盘在屏幕上显示宽度为 320pt
        let boardDisplayWidth: CGFloat = min(screenWidth, screenHeight) * 0.9 // 棋盘占屏幕宽度的90%
        let tileWidth = boardDisplayWidth / 4.0 // 棋盘有4列

        scene.size = CGSize(width: boardDisplayWidth, height: tileWidth * 5.0) // 棋盘有5行
        scene.scaleMode = .aspectFit // 保持宽高比填充
        scene.anchorPoint = CGPoint(x: 0, y: 1) // 左上角为锚点 (0,1) 因为SpriteKit Y轴向上
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .frame(width: scene.size.width, height: scene.size.height) // SwiftUI视图大小匹配场景
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

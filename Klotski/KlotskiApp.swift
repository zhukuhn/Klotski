//
//  KlotskiApp.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SwiftUI

@main
struct KlotskiApp: App {
    @StateObject var gameManager = GameManager()
    @StateObject var themeManager = ThemeManager()
    @StateObject var authManager = AuthManager()
    @StateObject var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
               .environmentObject(gameManager)
               .environmentObject(themeManager)
               .environmentObject(authManager)
               .environmentObject(settingsManager)
               .preferredColorScheme(themeManager.currentTheme.swiftUIScheme) // Example of applying theme
        }
    }
}

// MARK: - Previews
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
           .environmentObject(GameManager())
           .environmentObject(ThemeManager())
           .environmentObject(AuthManager())
           .environmentObject(SettingsManager())
    }
}

//struct GameView_Previews: PreviewProvider {
//    static var previews: some View {
//        // 要正确预览 GameView，请确保 GameManager 中有一个活动的关卡
//        let gameManager = GameManager()
//        // 如果 GameView 依赖于活动游戏，最好为其设置特定的预览。
//        // 目前，除非在预览前启动游戏，否则这将显示“未选择关卡”状态。
//        // 要查看其运行情况，您可能需要在预览的 onAppear 中触发 startGame
//        // 或确保 currentLevel 已设置。
//        
//        // 为预览模拟启动游戏
//        if let firstLevel = gameManager.levels.first {
//             gameManager.startGame(level: firstLevel)
//        }
//
//        return NavigationView { // GameView 通常被推入 NavigationStack
//            GameView()
//               .environmentObject(gameManager)
//               .environmentObject(ThemeManager())
//               .environmentObject(SettingsManager())
//        }
//    }
//}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            SettingsView()
//               .environmentObject(SettingsManager())
//               .environmentObject(ThemeManager())
//               .environmentObject(GameManager())
//        }
//    }
//}

//struct ThemeSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            ThemeSelectionView()
//               .environmentObject(ThemeManager())
//               .environmentObject(SettingsManager())
//        }
//    }
//}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//            .environmentObject(AuthManager())
//            .environmentObject(SettingsManager())
//            .environmentObject(ThemeManager())
//    }
//}

//struct RegisterView_Previews: PreviewProvider {
//    static var previews: some View {
//        RegisterView()
//            .environmentObject(AuthManager())
//            .environmentObject(SettingsManager())
//            .environmentObject(ThemeManager())
//    }
//}

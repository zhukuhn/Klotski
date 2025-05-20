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
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            MainMenuView()
               .environmentObject(gameManager)
               .environmentObject(themeManager)
               .environmentObject(authManager)
               .environmentObject(settingsManager)
               .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
               .onChange(of: scenePhase) { oldPhase, newPhase in
                   if newPhase == .background || newPhase == .inactive {
                       if gameManager.isGameActive && !gameManager.isGameWon {
                           print("App entering background/inactive. Pausing and saving game.")
                           gameManager.pauseGame() // 先暂停游戏（会停止计时器）
                           gameManager.saveGame(settings: settingsManager) // 然后保存
                       }
                   } else if newPhase == .active {
                       if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused { // 之前是暂停状态
                           // 根据游戏逻辑，可能需要用户手动点击继续，或者自动继续
                           // 为简单起见，这里不自动继续，用户需点击 GameView 中的继续按钮
                           print("App became active, game was paused. User needs to resume manually if desired.")
                       }
                   }
               }
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

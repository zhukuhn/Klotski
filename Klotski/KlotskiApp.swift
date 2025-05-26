//
//  KlotskiApp.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SwiftUI
import FirebaseCore

@main
struct KlotskiApp: App {
    // MARK: - State Objects (状态对象)
    // @StateObject 属性包装器用于创建和管理 ObservableObject 实例的生命周期。
    // 这些对象将在整个应用的生命周期内存在。

    // SettingsManager: 管理应用的设置（语言、音效、音乐等）。
    @StateObject var settingsManager = SettingsManager()
    
    // AuthManager: 管理用户认证（登录、注册、注销）。它需要在 ThemeManager 之前初始化，因为它会被注入到 ThemeManager。
    @StateObject var authManager: AuthManager
    
    // ThemeManager: 管理应用的主题（颜色、字体等）。它依赖于 AuthManager 来处理与用户相关的已购买主题。
    @StateObject var themeManager: ThemeManager
    
    // GameManager: 管理游戏逻辑、状态、关卡数据等。
    @StateObject var gameManager = GameManager()

    // MARK: - Environment (环境值)
    // @Environment 属性包装器用于读取当前环境中的值，例如场景阶段。
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Initialization (初始化)
    init() {
        // 1. 配置 Firebase
        // FirebaseApp.configure() 应该在应用启动时尽早调用一次。
        FirebaseApp.configure()
        print("Firebase configured in KlotskiApp init!")

        // 2. 初始化管理器，注意依赖关系
        // AuthManager 需要先于 ThemeManager 初始化，因为 ThemeManager 的构造函数需要 AuthManager 实例。
        let authMgr = AuthManager() // 创建 AuthManager 实例
        _authManager = StateObject(wrappedValue: authMgr) // 将实例包装为 @StateObject

        // 将 AuthManager 实例注入到 ThemeManager 的构造函数中
        _themeManager = StateObject(wrappedValue: ThemeManager(authManager: authMgr))
        
        print("All managers initialized in KlotskiApp init!")
    }

    // MARK: - Body (场景定义)
    var body: some Scene {
        WindowGroup {
            // MainMenuView 是应用的初始视图。
            MainMenuView()
                // 使用 .environmentObject 将 StateObject 实例注入到视图层级中，
                // 以便子视图可以访问和观察这些对象。
               .environmentObject(settingsManager)
               .environmentObject(authManager)
               .environmentObject(themeManager)
               .environmentObject(gameManager)
                // 设置应用的首选颜色方案，基于当前主题。
               .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
                // 监听场景阶段的变化，用于在应用进入后台或返回前台时执行操作。
               .onChange(of: scenePhase) { oldPhase, newPhase in
                   switch newPhase {
                   case .active:
                       // 应用变为活动状态 (例如，从后台返回或首次启动完成)
                       print("App became active.")
                       // 如果游戏之前是暂停状态，并且游戏仍在进行中且未胜利，
                       // 用户可能需要手动在 GameView 中点击“继续”来恢复计时器。
                       // GameManager 的 onAppear 逻辑会处理计时器的启动（如果需要）。
                       if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused {
                           print("App active, game was paused. User may need to resume manually in GameView.")
                       }
                   case .inactive:
                       // 应用变为非活动状态 (例如，被电话中断，或进入多任务切换界面)
                       print("App became inactive.")
                       // 在此状态下，如果游戏正在进行，也应该暂停和保存。
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App inactive: Pausing and saving game.")
                           gameManager.pauseGame() // 暂停游戏（会停止计时器）
                           gameManager.saveGame(settings: settingsManager) // 保存游戏状态
                       }
                   case .background:
                       // 应用进入后台
                       print("App entered background.")
                       // 确保游戏已暂停并保存。
                       // 通常 .inactive 状态会先于 .background 发生，所以上面的逻辑可能已经处理了。
                       // 但作为保险，可以再次检查。
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App background: Ensuring game is paused and saved.")
                           gameManager.pauseGame()
                           gameManager.saveGame(settings: settingsManager)
                       } else if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused {
                           // 如果已经是暂停状态，确保它被保存了
                           print("App background: Game was already paused, ensuring it's saved.")
                           gameManager.saveGame(settings: settingsManager)
                       }
                   @unknown default:
                       // 处理未来可能出现的未知场景阶段
                       print("Unknown scene phase.")
                   }
               }
               // 尝试将 window 实例传递给 AuthManager，用于 Sign in with Apple
               // 更可靠的方式可能是在 AppDelegate 或 SceneDelegate 中处理，
               // 但对于纯 SwiftUI 应用，可以尝试以下方法。
               .onReceive(NotificationCenter.default.publisher(for: UIWindow.didBecomeKeyNotification)) { notification in
                    if let window = notification.object as? UIWindow {
                        authManager.currentWindow = window
                        print("AuthManager currentWindow set via UIWindow.didBecomeKeyNotification.")
                    }
                }
        }
    }
}

// MARK: - Previews
//struct MainMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainMenuView()
//           .environmentObject(GameManager())
//           .environmentObject(ThemeManager())
//           .environmentObject(AuthManager())
//           .environmentObject(SettingsManager())
//    }
//}

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

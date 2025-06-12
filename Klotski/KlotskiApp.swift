//
//  KlotskiApp.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SwiftUI
import GameKit

@main
struct KlotskiApp: App {
    // MARK: - State Objects
    @StateObject var settingsManager: SettingsManager
    @StateObject var authManager: AuthManager
    @StateObject var themeManager: ThemeManager
    @StateObject var gameManager: GameManager

    // MARK: - Environment
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Game Center
    // isGameCenterAuthenticated 会在应用启动时根据 GKLocalPlayer.local.isAuthenticated 初始化
    // 并且后续会通过 authenticateHandler 或 GKPlayerAuthenticationDidChangeNotificationName 更新
    @State private var isGameCenterAuthenticated: Bool

    // MARK: - Initialization
    init() {
        // 按照依赖顺序初始化 Managers
        print(String(repeating:"-", count:100))
        let sm = SettingsManager()
        _settingsManager = StateObject(wrappedValue: sm)

        let authMgr = AuthManager()
        _authManager = StateObject(wrappedValue: authMgr)
        
        // ThemeManager 需要在 isGameCenterAuthenticated 之前初始化，因为它可能会被 MainMenuView 立即使用
        let tm = ThemeManager(authManager: authMgr, settingsManager: sm)
        _themeManager = StateObject(wrappedValue: tm)
        
        let gm = GameManager()
        _gameManager = StateObject(wrappedValue: gm)
        
        _ = StoreKitManager.shared
        
        // 初始化 Game Center 认证状态
        // 这一步只是获取初始值，真正的认证尝试会在 authenticateGameCenterPlayer 中进行
        _isGameCenterAuthenticated = State(initialValue: GKLocalPlayer.local.isAuthenticated)

        print("All managers initialized in KlotskiApp init!")
        print(String(repeating:"-", count:100) + "\n")
        
        // 在 init 中设置认证回调。这是一个轻量级操作，不会阻塞UI。
        // 实际的认证过程是异步的。
        // authenticateGameCenterPlayer() // 将调用移至 MainMenuView 的 onAppear
    }

    var body: some Scene {
        WindowGroup {
            // 直接显示主菜单视图
            MainMenuView()
               .environmentObject(settingsManager)
               .environmentObject(authManager)
               .environmentObject(themeManager)
               .environmentObject(gameManager)

               .environment(\.isGameCenterAuthenticated, $isGameCenterAuthenticated) // 注入状态供子视图使用
               .onAppear {
                   // 在主菜单出现时，执行依赖注入和Game Center认证
                   gameManager.setupDependencies(authManager: authManager, settingsManager: settingsManager)
                   authenticateGameCenterPlayer() // 触发 Game Center 认证
               }
               .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
               .onChange(of: scenePhase) { oldPhase, newPhase in
                   let useiCloudCurrent = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? true
                   switch newPhase {
                   case .active:
                        print(String(repeating:"-", count:100))
                        print("App became active.")
                        print()
                        Task { await StoreKitManager.shared.checkForCurrentEntitlements() }
                        if useiCloudCurrent { authManager.refreshAuthenticationState() }

                        // 当应用从后台激活时，再次尝试认证，以处理在后台可能发生的登录状态变化
                        // 或者处理首次启动时 authenticateHandler 可能尚未完成的情况
                        authenticateGameCenterPlayer()

                   case .inactive:
                       print("App became inactive.")
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App inactive: Pausing and saving game (local in-progress).")
                           gameManager.pauseGame()
                           gameManager.saveGame(settings: settingsManager)
                       }
                   case .background:
                       print("App entered background.")
                       if gameManager.isGameActive && !gameManager.isGameWon {
                           print("App background: Ensuring game is paused and saved (local in-progress).")
                           if !gameManager.isPaused { gameManager.pauseGame() }
                           gameManager.saveGame(settings: settingsManager)
                       }
                   @unknown default:
                       print("Unknown scene phase.")
                   }
               }
               .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
                    DispatchQueue.main.async {
                        let currentAuthStatus = GKLocalPlayer.local.isAuthenticated
                        print("Game Center authentication changed via Notification. Current system status: \(currentAuthStatus)")
                        if self.isGameCenterAuthenticated != currentAuthStatus {
                            self.isGameCenterAuthenticated = currentAuthStatus
                        }
                    }
               }
        }
    }

    func authenticateGameCenterPlayer() {
        print("Attempting to authenticate Game Center player (current state: \(isGameCenterAuthenticated)).")
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if viewController != nil {
                    print("Game Center: Needs to present authentication view controller.")
                    // 如果需要显示 Game Center 的登录界面，它会在此处以模态形式呈现
                    // 您需要找到应用当前的根视图控制器来 present 这个 vc
                    // UIApplication.shared.windows.first?.rootViewController?.present(vc, animated: true)
                }

                if let error = error {
                    print("Game Center: Authentication error: \(error.localizedDescription)")
                    if self.isGameCenterAuthenticated != false { // 避免不必要的UI更新
                        self.isGameCenterAuthenticated = false
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    print("Game Center: Player authenticated successfully: \(GKLocalPlayer.local.displayName)")
                    if self.isGameCenterAuthenticated != true {
                        self.isGameCenterAuthenticated = true
                    }
                } else {
                    print("Game Center: Player authentication failed, was cancelled, or Game Center is unavailable.")
                    if self.isGameCenterAuthenticated != false {
                        self.isGameCenterAuthenticated = false
                    }
                }
                print("Game Center: Authentication attempt finished. New state: isAuthed=\(self.isGameCenterAuthenticated)")
            }
        }
    }
}

// 为了让子视图可以方便地访问 isGameCenterAuthenticated 状态，我们定义一个 EnvironmentKey
private struct GameCenterAuthenticatedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isGameCenterAuthenticated: Binding<Bool> {
        get { self[GameCenterAuthenticatedKey.self] }
        set { self[GameCenterAuthenticatedKey.self] = newValue }
    }
}

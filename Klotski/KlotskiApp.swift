//
//  KlotskiApp.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SwiftUI

@main
struct KlotskiApp: App {
    // MARK: - State Objects (状态对象)
    @StateObject var settingsManager = SettingsManager()
    @StateObject var authManager: AuthManager // Will be initialized with settingsManager
    @StateObject var themeManager: ThemeManager // Will be initialized with authManager and settingsManager
    @StateObject var gameManager = GameManager()

    // MARK: - Environment (环境值)
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Initialization (初始化)
    init() {
        // Initialize SettingsManager first as others might depend on its @AppStorage values indirectly
        let sm = SettingsManager()
        _settingsManager = StateObject(wrappedValue: sm)

        // AuthManager might read AppStorage values set by SettingsManager during its init
        let authMgr = AuthManager() // AuthManager now reads "useiCloudLogin" from UserDefaults
        _authManager = StateObject(wrappedValue: authMgr)
        
        // ThemeManager depends on AuthManager and SettingsManager
        _themeManager = StateObject(wrappedValue: ThemeManager(authManager: authMgr, settingsManager: sm))
        
        print("All managers initialized in KlotskiApp init!")
    }

    // MARK: - Body (场景定义)
    var body: some Scene {
        WindowGroup {
            MainMenuView()
               .environmentObject(settingsManager)
               .environmentObject(authManager)
               .environmentObject(themeManager)
               .environmentObject(gameManager)
               .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
               .onChange(of: scenePhase) { oldPhase, newPhase in
                   let useiCloudCurrent = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? true
                   switch newPhase {
                   case .active:
                       print("App became active.")
                       // When app becomes active, if iCloud is enabled, good to refresh auth state
                       // as user might have changed iCloud account in device settings.
                       if useiCloudCurrent {
                           authManager.refreshAuthenticationState()
                       }
                       if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused {
                           print("App active, game was paused. User may need to resume manually in GameView.")
                       }
                   case .inactive:
                       print("App became inactive.")
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App inactive: Pausing and saving game.")
                           gameManager.pauseGame() 
                           // Game save should ideally also be conditional on iCloud if it involves cloud sync for game state
                           // For now, local save continues.
                           gameManager.saveGame(settings: settingsManager)
                       }
                   case .background:
                       print("App entered background.")
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App background: Ensuring game is paused and saved.")
                           gameManager.pauseGame()
                           gameManager.saveGame(settings: settingsManager)
                       } else if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused {
                           print("App background: Game was already paused, ensuring it's saved.")
                           gameManager.saveGame(settings: settingsManager)
                       }
                   @unknown default:
                       print("Unknown scene phase.")
                   }
               }
        }
    }
}

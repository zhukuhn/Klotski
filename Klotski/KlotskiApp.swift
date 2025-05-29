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
    @StateObject var authManager: AuthManager
    @StateObject var themeManager: ThemeManager
    @StateObject var gameManager = GameManager()

    // MARK: - Environment (环境值)
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Initialization (初始化)
    init() {

        // Initialize managers, noting dependencies
        let authMgr = AuthManager()
        _authManager = StateObject(wrappedValue: authMgr)
        _themeManager = StateObject(wrappedValue: ThemeManager(authManager: authMgr)) // ThemeManager depends on AuthManager
        
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
                   switch newPhase {
                   case .active:
                       print("App became active.")
                       if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused {
                           print("App active, game was paused. User may need to resume manually in GameView.")
                       }
                   case .inactive:
                       print("App became inactive.")
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App inactive: Pausing and saving game.")
                           gameManager.pauseGame() 
                           gameManager.saveGame(settings: settingsManager) // This will need CloudKit update later
                       }
                   case .background:
                       print("App entered background.")
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           print("App background: Ensuring game is paused and saved.")
                           gameManager.pauseGame()
                           gameManager.saveGame(settings: settingsManager) // This will need CloudKit update later
                       } else if gameManager.isGameActive && !gameManager.isGameWon && gameManager.isPaused {
                           print("App background: Game was already paused, ensuring it's saved.")
                           gameManager.saveGame(settings: settingsManager) // This will need CloudKit update later
                       }
                   @unknown default:
                       print("Unknown scene phase.")
                   }
               }
        }
    }
}

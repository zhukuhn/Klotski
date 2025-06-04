//
//  KlotskiApp.swift
//  Klotski
//
//  Created by zhukun on 2025/5/13.
//

import SwiftUI
import GameKit // Import GameKit

@main
struct KlotskiApp: App {
    // MARK: - State Objects
    @StateObject var settingsManager = SettingsManager()
    @StateObject var authManager: AuthManager 
    @StateObject var themeManager: ThemeManager 
    @StateObject var gameManager = GameManager() // GameManager now initializes without dependencies

    // MARK: - Environment
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Game Center
    @State private var isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated

    // MARK: - Initialization
    init() {
        let sm = SettingsManager()
        _settingsManager = StateObject(wrappedValue: sm)

        let authMgr = AuthManager() 
        _authManager = StateObject(wrappedValue: authMgr)
        
        _themeManager = StateObject(wrappedValue: ThemeManager(authManager: authMgr, settingsManager: sm))
        
        // GameManager is initialized above, dependencies will be injected later
        // _gameManager = StateObject(wrappedValue: GameManager(authManager: authMgr, settingsManager: sm)) // Old way

        _ = StoreKitManager.shared
        
        print("All managers initialized in KlotskiApp init!")
    }

    var body: some Scene {
        WindowGroup {
            Group { // Use a Group to conditionally show views or handle Game Center auth
                if isGameCenterAuthenticated {
                    MainMenuView()
                       .environmentObject(settingsManager)
                       .environmentObject(authManager)
                       .environmentObject(themeManager)
                       .environmentObject(gameManager)
                       .onAppear {
                           // Inject dependencies into GameManager once AuthManager and SettingsManager are ready
                           gameManager.setupDependencies(authManager: authManager, settingsManager: settingsManager)
                       }
                } else {
                    // Placeholder for Game Center authentication view or logic
                    VStack {
                        Text("正在验证 Game Center...")
                        ProgressView()
                    }
                    .onAppear(perform: authenticateGameCenterPlayer)
                }
            }
           .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
           .onChange(of: scenePhase) { oldPhase, newPhase in
               let useiCloudCurrent = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? true
               switch newPhase {
               case .active:
                   print("App became active.")
                   Task { await StoreKitManager.shared.checkForCurrentEntitlements() }
                   if useiCloudCurrent { authManager.refreshAuthenticationState() }
                   // Game resume logic is handled within GameView.onAppear or GameManager
               case .inactive:
                   print("App became inactive.")
                   if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                       print("App inactive: Pausing and saving game (local in-progress).")
                       gameManager.pauseGame() 
                       gameManager.saveGame(settings: settingsManager) // Saves in-progress game
                   }
               case .background:
                   print("App entered background.")
                   if gameManager.isGameActive && !gameManager.isGameWon { // Save even if paused
                       print("App background: Ensuring game is paused and saved (local in-progress).")
                       if !gameManager.isPaused { gameManager.pauseGame() }
                       gameManager.saveGame(settings: settingsManager) // Saves in-progress game
                   }
               @unknown default:
                   print("Unknown scene phase.")
               }
           }
           // Listen for Game Center authentication changes
           .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
                self.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
                if !GKLocalPlayer.local.isAuthenticated {
                    // Player might have signed out of Game Center from settings, or auth failed.
                    // You might want to re-trigger authentication or guide the user.
                    print("Game Center authentication changed. Current status: \(GKLocalPlayer.local.isAuthenticated)")
                }
           }
        }
    }

    func authenticateGameCenterPlayer() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let vc = viewController {
                // Present the Game Center login view controller
                // This requires access to the root view controller, which is tricky in pure SwiftUI.
                // A common approach is to use a UIViewControllerRepresentable or an AppDelegate.
                // For now, we'll just log it. A more robust solution is needed for UI.
                print("Game Center: Needs to present authentication view controller.")
                // KlotskiApp.getRootViewController()?.present(vc, animated: true) // Example if you have a helper
                // If not presenting a VC, at least update the state
                self.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
                return
            }
            if let error = error {
                print("Game Center: Authentication error: \(error.localizedDescription)")
                self.isGameCenterAuthenticated = false
                return
            }
            if GKLocalPlayer.local.isAuthenticated {
                print("Game Center: Player authenticated successfully: \(GKLocalPlayer.local.displayName)")
                self.isGameCenterAuthenticated = true
            } else {
                print("Game Center: Player authentication failed or was cancelled.")
                self.isGameCenterAuthenticated = false
            }
        }
    }

    // Helper to get root view controller (you might need to implement this based on your app structure)
    // static func getRootViewController() -> UIViewController? {
    //     return UIApplication.shared.connectedScenes
    //         .filter { $0.activationState == .foregroundActive }
    //         .compactMap { $0 as? UIWindowScene }
    //         .first?.windows
    //         .filter { $0.isKeyWindow }
    //         .first?.rootViewController
    // }
}

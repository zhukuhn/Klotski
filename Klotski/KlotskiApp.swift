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

    @State private var showStoreErrorAlert = false

    // MARK: - Environment
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Game Center
    @State private var isGameCenterAuthenticated: Bool

    // MARK: - Initialization
    init() {

        print(String(repeating:"-", count:100))
        let sm = SettingsManager()
        _settingsManager = StateObject(wrappedValue: sm)

        let authMgr = AuthManager()
        _authManager = StateObject(wrappedValue: authMgr)
        
        let tm = ThemeManager(authManager: authMgr, settingsManager: sm)
        _themeManager = StateObject(wrappedValue: tm)
        
        let gm = GameManager()
        _gameManager = StateObject(wrappedValue: gm)
        
        _ = StoreKitManager.shared
        
        _isGameCenterAuthenticated = State(initialValue: GKLocalPlayer.local.isAuthenticated)

        print("All managers initialized in KlotskiApp init!")
        print(String(repeating:"-", count:100) + "\n")
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView()
               .environmentObject(settingsManager)
               .environmentObject(authManager)
               .environmentObject(themeManager)
               .environmentObject(gameManager)
               .environment(\.isGameCenterAuthenticated, $isGameCenterAuthenticated)
               .onAppear {
                   gameManager.setupDependencies(authManager: authManager, settingsManager: settingsManager)
                   authenticateGameCenterPlayer()
               }
               .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
               .onChange(of: scenePhase) { oldPhase, newPhase in
                   switch newPhase {
                   case .active:
                        print(String(repeating:"-", count:100))
                        print("App became active.")
                        print()
                        Task { await StoreKitManager.shared.checkForCurrentEntitlements() }
                        authManager.refreshAuthenticationState()
                        authenticateGameCenterPlayer()

                   case .inactive:
                       print("App became inactive.")
                       if gameManager.isGameActive && !gameManager.isGameWon && !gameManager.isPaused {
                           gameManager.pauseGame()
                           gameManager.saveGame(settings: settingsManager)
                       }
                   case .background:
                       print("App entered background.")
                       if gameManager.isGameActive && !gameManager.isGameWon {
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
                        print("Game Center authentication changed. Current status: \(currentAuthStatus)")
                        if self.isGameCenterAuthenticated != currentAuthStatus {
                            self.isGameCenterAuthenticated = currentAuthStatus
                        }
                    }
               }
               // 试用结束弹窗
               .alert(
                   settingsManager.localizedString(forKey: "trialEnded"),
                   isPresented: $themeManager.showTrialEndedAlert,
                   presenting: themeManager.trialThemeForPurchase
               ) { theme in
                   Button(settingsManager.localizedString(forKey: "purchase")) {
                       Task {
                           await themeManager.purchaseTheme(theme, authManager: authManager)
                       }
                       themeManager.clearTrialEndedAlertFlag()
                   }
                   Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {
                       themeManager.clearTrialEndedAlertFlag()
                   }
               } message: { theme in
                   Text(String(format: settingsManager.localizedString(forKey: "trialEndedMessage"), theme.name))
               }
               // --- 关键修复: 新增的全局商店错误弹窗 ---
               .alert(isPresented: $showStoreErrorAlert, error: themeManager.storeKitError) { _ in
                   Button("OK") {
                        showStoreErrorAlert = false
                       themeManager.storeKitError = nil
                   }
               } message: { error in
                   Text(error.recoverySuggestion ?? "An unknown error occurred.")
               }
               .onChange(of: themeManager.storeKitError) { oldValue, newValue in
                    if newValue != nil {
                        showStoreErrorAlert = true
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
                }

                if let error = error {
                    print("Game Center: Authentication error: \(error.localizedDescription)")
                    if self.isGameCenterAuthenticated != false {
                        self.isGameCenterAuthenticated = false
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    print("Game Center: Player authenticated successfully: \(GKLocalPlayer.local.displayName)")
                    if self.isGameCenterAuthenticated != true {
                        self.isGameCenterAuthenticated = true
                    }
                } else {
                    print("Game Center: Player authentication failed or unavailable.")
                    if self.isGameCenterAuthenticated != false {
                        self.isGameCenterAuthenticated = false
                    }
                }
            }
        }
    }
}

private struct GameCenterAuthenticatedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isGameCenterAuthenticated: Binding<Bool> {
        get { self[GameCenterAuthenticatedKey.self] }
        set { self[GameCenterAuthenticatedKey.self] = newValue }
    }
}

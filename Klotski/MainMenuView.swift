//
//  Untitled.swift
//  Klotski
//
//  Created by zhukun on 2025/5/16.
//
import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingLoginSheet = false
    @State private var showingRegisterSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "gameTitle"))
                   .font(.system(size: 36, weight: .bold, design: .rounded)) // Example of a custom font style
                   .padding(.top, 40)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)

                Spacer()

                NavigationLink(destination: LevelSelectionView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "startGame"))
                }

                // "Continue Game" button and programmatic navigation
                if gameManager.hasSavedGame {
                    Button(action: {
                        gameManager.continueGame() // This sets gameManager.isGameActive to true
                    }) {
                        MenuButton(title: settingsManager.localizedString(forKey: "continueGame"))
                    }
                }
                
                NavigationLink(destination: LevelSelectionView()) {
                     MenuButton(title: settingsManager.localizedString(forKey: "selectLevel"))
                }

                NavigationLink(destination: ThemeSelectionView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "themes"))
                }

                NavigationLink(destination: LeaderboardView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "leaderboard"))
                }

                NavigationLink(destination: SettingsView()) {
                    MenuButton(title: settingsManager.localizedString(forKey: "settings"))
                }
                
                Spacer()
                
                authStatusView()
                   .padding(.bottom)

            }
           .frame(maxWidth:.infinity, maxHeight:.infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .sheet(isPresented: $showingLoginSheet) { LoginView().environmentObject(authManager).environmentObject(settingsManager).environmentObject(themeManager) }
           .sheet(isPresented: $showingRegisterSheet) { RegisterView().environmentObject(authManager).environmentObject(settingsManager).environmentObject(themeManager) }
           // Modifier for programmatic navigation to GameView
           .navigationDestination(isPresented: $gameManager.isGameActive) {
               GameView() // Destination view
           }
        }
    }
    
    @ViewBuilder
    private func authStatusView() -> some View {
        VStack {
            if authManager.isLoggedIn, let user = authManager.currentUser {
                Text("\(settingsManager.localizedString(forKey: "loggedInAs")) \(user.displayName ?? user.email ?? "User")")
                   .font(.caption)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)
                Button(settingsManager.localizedString(forKey: "logout")) {
                    authManager.logout()
                }
               .buttonStyle(.bordered)
               .tint(themeManager.currentTheme.sliderColor.color)
            } else {
                HStack {
                    Button(settingsManager.localizedString(forKey: "login")) {
                        showingLoginSheet = true
                    }
                   .buttonStyle(.borderedProminent)
                   .tint(themeManager.currentTheme.sliderColor.color)
                    
                    Button(settingsManager.localizedString(forKey: "register")) {
                        showingRegisterSheet = true
                    }
                   .buttonStyle(.bordered)
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text(title)
           .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
           .fontWeight(.medium)
           .padding()
           .frame(maxWidth: 280, minHeight: 50) // Ensure buttons have a good tap target size
           .background(themeManager.currentTheme.sliderColor.color.opacity(0.9))
           .foregroundColor(themeManager.currentTheme.backgroundColor.color) // Text color contrasts with button
           .cornerRadius(12) // Softer corners
           .shadow(color: themeManager.currentTheme.sliderColor.color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss // Used to pop the view if NavigationStack is used by parent

    // Timer for game duration
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var internalTimeElapsed: TimeInterval = 0 // To manage timer locally

    var body: some View {
        VStack {
            if let level = gameManager.currentLevel {
                Text("\(settingsManager.localizedString(forKey: "level")): \(level.name)")
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 24) : .title)
                   .fontWeight(.bold)
                   .padding()
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)

                // TODO: Implement the actual Klotski game board UI here
                // This would involve:
                // - A Grid or similar layout to represent the board.
                // - Rendering individual blocks based on level.layout, their types, dimensions.
                // - Applying themeManager.currentTheme.sliderColor, sliderShape, sliderContent to each block.
                // - Handling swipe gestures (DragGesture) or tap-to-select-and-tap-to-move logic.
                // - Updating gameManager.currentLevel.layout and calling gameManager.moveBlock().
                
                ZStack { // Placeholder for the game board
                    Rectangle()
                       .fill(themeManager.currentTheme.sliderColor.color.opacity(0.1)) // Board background
                       .aspectRatio(4/5, contentMode: .fit) // Assuming a 4x5 Klotski board aspect ratio
                       .frame(maxWidth: 320, maxHeight: 400) // Max dimensions
                       .cornerRadius(10)
                       .overlay(
                           RoundedRectangle(cornerRadius: 10)
                               .stroke(themeManager.currentTheme.sliderColor.color, lineWidth: 2)
                       )
                    
                    Text("游戏区域占位符\nKlotski Board (4x5)")
                       .multilineTextAlignment(.center)
                       .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .body)
                       .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                }
               .padding()


                HStack {
                    Text("\(settingsManager.localizedString(forKey: "moves")): \(gameManager.moves)")
                    Spacer()
                    Text("\(settingsManager.localizedString(forKey: "time")): \(formattedTime(internalTimeElapsed))")
                }
               .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
               .padding()
               .foregroundColor(themeManager.currentTheme.sliderColor.color)


                Button("模拟移动滑块") { // Placeholder for actual game interaction
                    gameManager.moveBlock()
                }
               .padding()
               .buttonStyle(.bordered)
               .tint(themeManager.currentTheme.sliderColor.color)


                Button("模拟完成关卡") {
                    gameManager.completeLevel(moves: gameManager.moves, time: internalTimeElapsed)
                    // isGameActive will be set to false in completeLevel, triggering dismissal by navigationDestination
                }
               .padding()
               .buttonStyle(.borderedProminent)
               .tint(themeManager.currentTheme.sliderColor.color)
                
                Spacer()
            } else {
                Text("未选择关卡。请返回主菜单选择一个关卡。")
                    .foregroundColor(themeManager.currentTheme.sliderColor.color)
                    .padding()
            }
        }
       .navigationTitle(gameManager.currentLevel?.name ?? settingsManager.localizedString(forKey: "gameTitle"))
       .navigationBarTitleDisplayMode(.inline)
       .navigationBarBackButtonHidden(gameManager.isGameActive) // Hide back button while game is active to prevent accidental exit without saving
       .toolbar {
           ToolbarItem(placement: .navigationBarLeading) {
               if gameManager.isGameActive { // Show a custom back/pause button if game is active
                   Button {
                       gameManager.saveGame()
                       gameManager.isGameActive = false // This will trigger dismissal
                   } label: {
                       Image(systemName: "chevron.backward")
                       Text("暂停") // Pause and go back
                   }
                   .tint(themeManager.currentTheme.sliderColor.color)
               }
           }
       }
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .onAppear {
            if gameManager.isGameActive { // Only sync and start timer if game is supposed to be active
                internalTimeElapsed = gameManager.timeElapsed // Sync with manager on appear
                startTimer()
            } else {
                // If GameView appears but game is not active (e.g., error or direct navigation attempt),
                // consider dismissing or showing an error. For now, it shows "No level selected".
            }
        }
       .onDisappear {
            stopTimer()
            // Save game state if the game is still marked as active
            // (e.g., if view disappears for reasons other than level completion or explicit pause)
            if gameManager.isGameActive {
                gameManager.timeElapsed = internalTimeElapsed
                gameManager.saveGame()
            }
        }
       .onReceive(timer) { _ in
            if gameManager.isGameActive {
                internalTimeElapsed += 1
            }
        }
    }

    func startTimer() {
        stopTimer() // Ensure no multiple timers are running
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    func stopTimer() {
        timer.upstream.connect().cancel()
    }
    
    func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct LevelSelectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        List {
            ForEach(gameManager.levels.filter { $0.isUnlocked }) { level in
                // NavigationLink now uses .navigationDestination in MainMenuView for GameView
                // So, when a level is selected, we just need to set it in GameManager and activate the game.
                Button(action: {
                    gameManager.startGame(level: level) // This sets isGameActive to true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.name)
                               .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                               .foregroundColor(themeManager.currentTheme.sliderColor.color)
                            if let moves = level.bestMoves {
                                Text("最佳: \(moves) \(settingsManager.localizedString(forKey: "moves"))")
                                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                            } else {
                                Text("未完成")
                                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 12) : .caption)
                                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.5))
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right") // Visual cue for navigation
                           .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.5))
                        // TODO: Add preview of level layout or difficulty icon
                    }
                   .padding(.vertical, 8)
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
            if gameManager.levels.filter({ $0.isUnlocked }).isEmpty {
                Text(settingsManager.localizedString(forKey: "noLevels"))
                   .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "selectLevel"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden) // For iOS 16+ to make List background transparent
    }
}

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        List {
            Section(header: Text(settingsManager.localizedString(forKey: "themeStore"))
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                ForEach(themeManager.themes) { theme in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.name)
                               .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 18) : .headline)
                            // Simple preview of theme colors
                            HStack {
                                Circle().fill(theme.backgroundColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                                Circle().fill(theme.sliderColor.color).frame(width: 15, height: 15).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                                if let font = theme.fontName { Text(font).font(.caption2).italic() }
                            }
                        }
                       .foregroundColor(themeManager.currentTheme.sliderColor.color)

                        Spacer()

                        if themeManager.currentTheme.id == theme.id {
                            Image(systemName: "checkmark.circle.fill")
                               .foregroundColor(.green)
                               .font(.title2)
                        } else if themeManager.isThemePurchased(theme) {
                            Button(settingsManager.localizedString(forKey: "applyTheme")) {
                                themeManager.setCurrentTheme(theme)
                            }
                           .buttonStyle(.bordered)
                           .tint(themeManager.currentTheme.sliderColor.color)
                        } else {
                            Button("\(settingsManager.localizedString(forKey: "purchase")) \(theme.price != nil ? String(format: "¥%.2f", theme.price!) : "")") {
                                themeManager.purchaseTheme(theme) // This is a simulated purchase
                            }
                           .buttonStyle(.borderedProminent)
                           .tint(theme.isPremium ? .pink : themeManager.currentTheme.sliderColor.color) // Highlight premium themes
                        }
                    }
                   .padding(.vertical, 8)
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
            
            Section {
                 Button(settingsManager.localizedString(forKey: "restorePurchases")) {
                    themeManager.restorePurchases() // Simulated
                }
               .listRowBackground(themeManager.currentTheme.backgroundColor.color)
               .foregroundColor(themeManager.currentTheme.sliderColor.color)
            }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "themes"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
       .scrollContentBackground(.hidden)
    }
}

struct LeaderboardView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager // To get level names for picker
    // TODO: Inject Game Center manager or data source

    // Sample data, replace with actual Game Center data
    @State private var leaderboardData: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, playerName: "高手玩家", moves: 25, levelID: "easy-1"),
        LeaderboardEntry(rank: 2, playerName: "新手上路", moves: 30, levelID: "easy-1"),
        LeaderboardEntry(rank: 1, playerName: "解谜大师", moves: 120, levelID: "medium-1"),
    ]
    @State private var selectedLevelFilter: String = "all" // "all" or a levelID

    var body: some View {
        VStack {
            // TODO: Implement actual Game Center leaderboard view
            // (e.g., using GKGameCenterViewController as a sheet)
            // Or a custom UI that fetches data from Game Center.
            
            Picker(settingsManager.localizedString(forKey: "selectLevel"), selection: $selectedLevelFilter) {
                Text("所有关卡").tag("all")
                ForEach(gameManager.levels) { level in
                    Text(level.name).tag(level.id)
                }
            }
           .pickerStyle(.segmented) // Or .menu for more items
           .padding()
           .tint(themeManager.currentTheme.sliderColor.color)


            List {
                ForEach(filteredLeaderboardData()) { entry in
                    HStack {
                        Text("\(entry.rank).")
                           .fontWeight(.bold)
                        Text(entry.playerName)
                        Spacer()
                        Text("\(entry.moves) \(settingsManager.localizedString(forKey: "moves"))")
                           .fontWeight(.semibold)
                    }
                   .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 16) : .body)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)
                   .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
                if filteredLeaderboardData().isEmpty {
                    Text("此关卡暂无排行数据。")
                        .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
                        .listRowBackground(themeManager.currentTheme.backgroundColor.color)
                }
            }
           .scrollContentBackground(.hidden)
            
            Text("排行榜功能待 Game Center 集成")
               .font(.caption)
               .padding()
               .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.7))
        }
       .navigationTitle(settingsManager.localizedString(forKey: "leaderboard"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
    }

    func filteredLeaderboardData() -> [LeaderboardEntry] {
        if selectedLevelFilter == "all" {
            return leaderboardData.sorted { $0.moves < $1.moves } // Example sorting
        }
        return leaderboardData.filter { $0.levelID == selectedLevelFilter }.sorted { $0.moves < $1.moves }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameManager: GameManager // For reset progress

    @State private var showingResetAlert = false

    var body: some View {
        Form { // Form provides a standard iOS settings look
            Section(header: Text("通用设置")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Picker(settingsManager.localizedString(forKey: "language"), selection: $settingsManager.language) {
                    Text(settingsManager.localizedString(forKey: "chinese")).tag("zh")
                    Text(settingsManager.localizedString(forKey: "english")).tag("en")
                }
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5)) // Slightly different for Form
           .foregroundColor(themeManager.currentTheme.sliderColor.color)


            Section(header: Text("音频与触感")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Toggle(settingsManager.localizedString(forKey: "soundEffects"), isOn: $settingsManager.soundEffectsEnabled)
                Toggle(settingsManager.localizedString(forKey: "music"), isOn: $settingsManager.musicEnabled)
                Toggle(settingsManager.localizedString(forKey: "haptics"), isOn: $settingsManager.hapticsEnabled)
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
           .foregroundColor(themeManager.currentTheme.sliderColor.color)
           .tint(themeManager.currentTheme.sliderColor.color) // Tint for Toggles

            Section(header: Text("游戏数据")
                .font(themeManager.currentTheme.fontName != nil ? .custom(themeManager.currentTheme.fontName!, size: 14) : .caption)
                .foregroundColor(themeManager.currentTheme.sliderColor.color.opacity(0.8))) {
                Button(settingsManager.localizedString(forKey: "resetProgress"), role: .destructive) {
                    showingResetAlert = true
                }
               .foregroundColor(.red) // Standard destructive color
            }
           .listRowBackground(themeManager.currentTheme.backgroundColor.color.opacity(0.5))
            
            // TODO: Add links to Privacy Policy, About, etc.
            // Section("About") { Link("Privacy Policy", destination: URL(string: "...")!) }
        }
       .navigationTitle(settingsManager.localizedString(forKey: "settings"))
       .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea()) // Background for the whole view
       .scrollContentBackground(.hidden) // Makes Form background transparent
       .alert(settingsManager.localizedString(forKey: "resetProgress"), isPresented: $showingResetAlert) {
            Button(settingsManager.localizedString(forKey: "reset"), role: .destructive) {
                // Reset best scores in levels
                gameManager.levels.indices.forEach { gameManager.levels[$0].bestMoves = nil; gameManager.levels[$0].bestTime = nil }
                // Clear any currently saved game progress
                gameManager.clearSavedGame()
                // TODO: Potentially reset other game-specific stats if any
                print("游戏进度已重置")
            }
            Button(settingsManager.localizedString(forKey: "cancel"), role: .cancel) {}
        } message: {
            Text(settingsManager.localizedString(forKey: "areYouSureReset"))
        }
    }
}

// Common UI for Login and Register text fields
struct AuthTextFieldStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    func body(content: Content) -> some View {
        content
           .padding(12)
           .background(themeManager.currentTheme.sliderColor.color.opacity(0.1))
           .cornerRadius(8)
           .overlay(
                RoundedRectangle(cornerRadius: 8)
                   .stroke(themeManager.currentTheme.sliderColor.color.opacity(0.3), lineWidth: 1)
            )
           .foregroundColor(themeManager.currentTheme.sliderColor.color)
    }
}


struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager // For styling
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "login"))
                   .font(.system(size: 32, weight: .bold, design: .rounded))
                   .padding(.bottom, 30)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)


                TextField(settingsManager.localizedString(forKey: "email"), text: $email)
                   .keyboardType(.emailAddress)
                   .autocapitalization(.none)
                   .textContentType(.emailAddress)
                   .modifier(AuthTextFieldStyle())

                SecureField(settingsManager.localizedString(forKey: "password"), text: $password)
                   .textContentType(.password)
                   .modifier(AuthTextFieldStyle())
                
                Button(settingsManager.localizedString(forKey: "login")) {
                    authManager.login(email: email, pass: password)
                }
               .buttonStyle(.borderedProminent)
               .tint(themeManager.currentTheme.sliderColor.color)
               .frame(maxWidth:.infinity)
               .padding(.vertical)
               .disabled(email.isEmpty || password.isEmpty)
                
                Button(settingsManager.localizedString(forKey: "forgotPassword")) {
                    // TODO: Implement forgot password flow (e.g., show another sheet or navigate)
                }
               .font(.caption)
               .tint(themeManager.currentTheme.sliderColor.color)
                
                Divider().padding(.vertical)
                
                Button(action: {
                    authManager.signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "apple.logo") // Corrected Apple logo system name
                        Text(settingsManager.localizedString(forKey: "signInWithApple"))
                    }
                   .padding(.horizontal)
                }
               .buttonStyle(.bordered) // Use bordered for a less prominent look than login
               .tint(themeManager.currentTheme.sliderColor.color) // Or .primary for system default
               .frame(maxWidth:.infinity)


                Spacer()
            }
           .padding(30) // More padding for the content
           .frame(maxWidth:.infinity, maxHeight:.infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .navigationTitle(settingsManager.localizedString(forKey: "login"))
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Changed from .automatic for consistency
                    Button(settingsManager.localizedString(forKey: "cancel")) {
                        dismiss()
                    }
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in // Use newValue directly
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    // @State private var confirmPassword = "" // Good practice to add

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "register"))
                   .font(.system(size: 32, weight: .bold, design: .rounded))
                   .padding(.bottom, 30)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)


                TextField(settingsManager.localizedString(forKey: "displayName"), text: $displayName)
                   .textContentType(.nickname)
                   .modifier(AuthTextFieldStyle())

                TextField(settingsManager.localizedString(forKey: "email"), text: $email)
                   .keyboardType(.emailAddress)
                   .autocapitalization(.none)
                   .textContentType(.emailAddress)
                   .modifier(AuthTextFieldStyle())

                SecureField(settingsManager.localizedString(forKey: "password"), text: $password)
                   .textContentType(.newPassword) // Hint for password managers
                   .modifier(AuthTextFieldStyle())
                
                // SecureField("Confirm Password", text: $confirmPassword)
                //    .modifier(AuthTextFieldStyle())

                Button(settingsManager.localizedString(forKey: "register")) {
                    // TODO: Add password confirmation validation
                    authManager.register(email: email, pass: password, displayName: displayName)
                }
               .buttonStyle(.borderedProminent)
               .tint(themeManager.currentTheme.sliderColor.color)
               .frame(maxWidth:.infinity)
               .padding(.vertical)
               .disabled(email.isEmpty || password.isEmpty || displayName.isEmpty /*|| password != confirmPassword */)

                Spacer()
            }
           .padding(30)
           .frame(maxWidth:.infinity, maxHeight:.infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .navigationTitle(settingsManager.localizedString(forKey: "register"))
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsManager.localizedString(forKey: "cancel")) {
                        dismiss()
                    }
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

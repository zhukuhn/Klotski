//
//  ThemeManager.swift
//  Klotski
//
//  Created by zhukun on 2025/6/4.
//

import SwiftUI
import AVFoundation
import UIKit
import Combine
import CloudKit
import GameKit
import StoreKit

@MainActor
class ThemeManager: ObservableObject {
    @Published var themes: [Theme]
    @Published var currentTheme: Theme
    @Published private(set) var purchasedThemeIDs: Set<String>

    @Published var storeKitProducts: [Product] = []
    @Published var storeKitError: StoreKitError? = nil

    @Published var purchasingThemeID: String? = nil

    @Published private(set) var isTrialActive: Bool = false
    @Published var showTrialEndedAlert: Bool = false
    private(set) var trialThemeForPurchase: Theme? = nil

    private var cancellables = Set<AnyCancellable>()
    private let storeKitManager = StoreKitManager.shared
    
    // --- FIX: Define keys for UserDefaults persistence ---
    private let currentThemeIDKey = "currentThemeID"
    private let locallyPurchasedThemeIDsKey = "locallyPurchasedThemeIDsKey"

    private var previousThemeID: String?
    private var trialTimer: Timer?


    init(authManager: AuthManager, settingsManager: SettingsManager, availableThemes: [Theme] = AppThemeRepository.allThemes) {
        self.themes = availableThemes
        
        // Initialize purchased themes from local storage and free themes FIRST ---
        // This ensures that even before iCloud syncs, we know what the user owns on THIS device.
        var initialPurchased = Set(UserDefaults.standard.stringArray(forKey: locallyPurchasedThemeIDsKey) ?? [])
        initialPurchased.formUnion(availableThemes.filter { !$0.isPremium }.map { $0.id })
        self._purchasedThemeIDs = Published(initialValue: initialPurchased)

        // Restore the last used theme immediately upon initialization ---
        // We use the already-hydrated `purchasedThemeIDs` to validate it.
        let savedThemeID = UserDefaults.standard.string(forKey: currentThemeIDKey)
        let fallbackTheme = availableThemes.first { $0.id == "default" }!
        
        if let themeID = savedThemeID,
           let candidateTheme = availableThemes.first(where: { $0.id == themeID }),
           initialPurchased.contains(candidateTheme.id) {
            self._currentTheme = Published(initialValue: candidateTheme)
            debugLog("ThemeManager init: Successfully restored last used theme '\(candidateTheme.name)' from UserDefaults.")
        } else {
            self._currentTheme = Published(initialValue: fallbackTheme)
            debugLog("ThemeManager init: Could not restore last theme or it's not purchased. Reverted to default.")
        }
        
        debugLog("ThemeManager init: Initial purchased themes count: \(initialPurchased.count).")
        
        setupBindings(authManager: authManager)

    }
    private func setupBindings(authManager: AuthManager) {
        // This subscription handles successful purchases/restores from StoreKitManager
        storeKitManager.purchaseOrRestoreSuccessfulPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processedProductIDs in
                guard let self = self else { return }
                self.handleSuccessfulStoreKitProcessing(storeKitProductIDs: processedProductIDs, authManager: authManager)
            }
            .store(in: &cancellables)
        
        // Binds the fetched products from StoreKitManager to our local property
        storeKitManager.$fetchedProducts.receive(on: DispatchQueue.main).assign(to: \.storeKitProducts, on: self).store(in: &cancellables)
        
        // Handles errors from StoreKitManager
        storeKitManager.$error.receive(on: DispatchQueue.main).sink { [weak self] error in
            if error != nil {
                self?.purchasingThemeID = nil
                self?.storeKitError = error
            }
        }.store(in: &cancellables)
        
        // This subscription reacts to iCloud login/logout events
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Add debounce to avoid rapid changes
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                debugLog("ThemeManager: Auth user profile changed. Rebuilding purchased themes list.")
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Theme Management
    
    func setCurrentTheme(_ theme: Theme) {
        if isTrialActive { cancelTrial() }
        guard themes.contains(where: { $0.id == theme.id }) else { return }
        guard isThemePurchased(theme) else {
            debugLog("ThemeManager Warning: Attempted to set a non-purchased theme '\(theme.name)'.")
            return
        }
        if currentTheme.id != theme.id {
            currentTheme = theme
            UserDefaults.standard.set(theme.id, forKey: currentThemeIDKey)
            debugLog("ThemeManager: Current theme changed to '\(theme.name)' and saved to UserDefaults.")
        }
    }

    func isThemePurchased(_ theme: Theme) -> Bool {
        return !theme.isPremium || purchasedThemeIDs.contains(theme.id)
    }

    // MARK: - StoreKit Operations

    func fetchSKProducts() async {
        guard storeKitProducts.isEmpty else {
            debugLog("ThemeManager: Products already fetched. Skipping.")
            return
        }
        let productIDs = Set(themes.compactMap { $0.isPremium ? $0.productID : nil })
        if !productIDs.isEmpty {
            await storeKitManager.fetchProducts(productIDs: productIDs)
        }
    }

    func purchaseTheme(_ theme: Theme, authManager: AuthManager) async {
        guard authManager.isLoggedIn else {
            self.storeKitError = .userCannotMakePayments; return
        }
        guard theme.isPremium, let productID = theme.productID else { return }
        
        if storeKitProducts.first(where: { $0.id == productID }) == nil {
             await fetchSKProducts()
        }

        if let product = storeKitProducts.first(where: { $0.id == productID }) {
            self.purchasingThemeID = theme.id
            await storeKitManager.purchase(product)
            self.purchasingThemeID = nil // Reset this regardless of outcome
        } else {
            self.storeKitError = .productsNotFound
        }
    }

    func restoreThemePurchases(authManager: AuthManager) async {
        guard authManager.isLoggedIn else {
            self.storeKitError = .userCannotMakePayments; return
        }
        self.purchasingThemeID = "restore"
        await storeKitManager.syncTransactions()
        self.purchasingThemeID = nil
    }
    
    private func handleSuccessfulStoreKitProcessing(storeKitProductIDs: Set<String>, authManager: AuthManager) {
        var newlyProcessedAppThemeIDs = Set<String>()
        for skProductID in storeKitProductIDs {
            if let theme = themes.first(where: { $0.productID == skProductID && $0.isPremium }) {
                newlyProcessedAppThemeIDs.insert(theme.id)
            }
        }
        
        let oldPurchasedIDs = self.purchasedThemeIDs
        self.purchasedThemeIDs.formUnion(newlyProcessedAppThemeIDs)

        if self.purchasedThemeIDs != oldPurchasedIDs {
            debugLog("ThemeManager: New themes processed. Updating storage and iCloud.")
            
            let currentPurchased = Array(self.purchasedThemeIDs)
            UserDefaults.standard.set(currentPurchased, forKey: locallyPurchasedThemeIDsKey)
            
            // Also update iCloud if user is logged in
            authManager.updateUserPurchasedThemes(themeIDs: self.purchasedThemeIDs)
            
            // If it was a single new purchase, apply the theme
            if newlyProcessedAppThemeIDs.count == 1,
               let singleNewThemeID = newlyProcessedAppThemeIDs.first,
               let themeToApply = themes.first(where: {$0.id == singleNewThemeID}) {
                setCurrentTheme(themeToApply)
            }
        }
        self.storeKitError = nil
    }

    private func rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: AuthManager) {
        if isTrialActive { cancelTrial() }
        
        // 1. Start with free themes
        var newPurchased = Set(self.themes.filter { !$0.isPremium }.map { $0.id })
        
        // 2. Add themes from local storage
        let localPurchases = Set(UserDefaults.standard.stringArray(forKey: locallyPurchasedThemeIDsKey) ?? [])
        newPurchased.formUnion(localPurchases)
        
        // 3. Add themes from iCloud, and if new ones are found, save them locally
        if let userProfile = authManager.currentUser {
            let cloudPurchases = userProfile.purchasedThemeIDs
            let newFromCloud = cloudPurchases.subtracting(newPurchased)
            
            newPurchased.formUnion(cloudPurchases)
            
            if !newFromCloud.isEmpty {
                debugLog("ThemeManager: Found \(newFromCloud.count) new themes from iCloud. Saving them locally.")
                UserDefaults.standard.set(Array(newPurchased), forKey: locallyPurchasedThemeIDsKey)
            }
        }
        
        if self.purchasedThemeIDs != newPurchased {
            debugLog("ThemeManager: Purchased themes list has been rebuilt and updated.")
            self.purchasedThemeIDs = newPurchased
        }

        if !isThemePurchased(self.currentTheme) {
             debugLog("ThemeManager: Current theme '\(self.currentTheme.name)' is no longer valid after sync. Reverting to default.")
             let defaultTheme = themes.first { $0.id == "default" } ?? themes.first!
             setCurrentTheme(defaultTheme)
        }
    }
    
    // MARK: - Trial Management (No changes needed here)

    func clearTrialEndedAlertFlag() {
        if showTrialEndedAlert {
            showTrialEndedAlert = false
            trialThemeForPurchase = nil
            debugLog("ThemeManager: Trial ended alert flag cleared.")
        }
    }

    func startTrial(for theme: Theme, duration: TimeInterval = 10) {
        guard !isTrialActive else { return }
        debugLog("ThemeManager: Starting trial for theme '\(theme.name)' for \(duration) seconds.")
        trialTimer?.invalidate()
        previousThemeID = self.currentTheme.id
        isTrialActive = true
        currentTheme = theme
        
        trialTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.endTrial()
            }
        }
    }
    
    private func endTrial() {
        guard isTrialActive else { return }
        debugLog("ThemeManager: Trial ended.")
        trialTimer?.invalidate()
        trialTimer = nil
        
        self.trialThemeForPurchase = self.currentTheme
        
        if let prevID = previousThemeID, let prevTheme = themes.first(where: { $0.id == prevID }) {
            currentTheme = prevTheme
        } else {
            currentTheme = themes.first { $0.id == "default" } ?? themes.first!
        }
        
        isTrialActive = false
        previousThemeID = nil
        
        showTrialEndedAlert = true
    }
    
    func cancelTrial() {
        guard isTrialActive else { return }
        trialTimer?.invalidate()
        trialTimer = nil
        if let prevID = previousThemeID, let prevTheme = themes.first(where: { $0.id == prevID }) {
            currentTheme = prevTheme
        }
        isTrialActive = false
        previousThemeID = nil
        trialThemeForPurchase = nil
    }
}

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
    @Published var isStoreLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let storeKitManager = StoreKitManager.shared
    
    private let settingsManagerInstance: SettingsManager
    private var initialAuthCheckCompleted = false
    private let currentThemeIDKey = "currentThemeID"
    static let locallyKnownPaidThemeIDsKey = "locallyKnownPaidThemeIDs"


    init(authManager: AuthManager, settingsManager: SettingsManager, availableThemes: [Theme] = AppThemeRepository.allThemes) {
        self.settingsManagerInstance = settingsManager
        self.themes = availableThemes
        
        let fallbackTheme = Theme(id: "fallback", name: "备用", isPremium: false, backgroundColor: CodableColor(color: .gray), sliderColor: CodableColor(color: .secondary), sliderTextColor: CodableColor(color: .black), boardBackgroundColor: CodableColor(color: .white), boardGridLineColor: CodableColor(color: Color(.systemGray)))
        let defaultThemeToSet = availableThemes.first(where: { $0.id == "default" }) ?? fallbackTheme
        
        let initialPurchased = Set(availableThemes.filter { !$0.isPremium }.map { $0.id })
        self._purchasedThemeIDs = Published(initialValue: initialPurchased)
        self._currentTheme = Published(initialValue: defaultThemeToSet)

        print("ThemeManager init: Initial purchasedThemeIDs (only two themes): \(self.purchasedThemeIDs)")
        
        storeKitManager.purchaseOrRestoreSuccessfulPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processedProductIDs in
                guard let self = self else { return }
                print("ThemeManager: Received successful purchase/restore for StoreKit Product IDs: \(processedProductIDs)")
                self.handleSuccessfulStoreKitProcessing(storeKitProductIDs: processedProductIDs, authManager: authManager)
            }
            .store(in: &cancellables)
        
        storeKitManager.$fetchedProducts
            .receive(on: DispatchQueue.main)
            .assign(to: \.storeKitProducts, on: self)
            .store(in: &cancellables)

        storeKitManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isStoreLoading, on: self)
            .store(in: &cancellables)

        storeKitManager.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.storeKitError, on: self)
            .store(in: &cancellables)
        
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                print("ThemeManager: AuthManager.currentUser changed. New profile ID: \(userProfile?.id ?? "nil")")
                self.initialAuthCheckCompleted = true
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
                Task {
                    if self.settingsManagerInstance.useiCloudLogin {
                        await self.fetchSKProducts()
                        await self.storeKitManager.checkForCurrentEntitlements()
                    }
                }
            }
            .store(in: &cancellables)
        
        settingsManagerInstance.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let iCloudSettingChanged = self.settingsManagerInstance.useiCloudLogin
                print("ThemeManager: SettingsManager's useiCloudLogin might have changed to \(iCloudSettingChanged).")
                self.rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: authManager)
                Task {
                     if iCloudSettingChanged {
                         await self.fetchSKProducts()
                         await self.storeKitManager.checkForCurrentEntitlements()
                     } else if !iCloudSettingChanged {
                         self.storeKitProducts = []
                     }
                }
            }
            .store(in: &cancellables)

        Task {
            if settingsManagerInstance.useiCloudLogin {
                await fetchSKProducts()
                await storeKitManager.checkForCurrentEntitlements()
            }
        }
        print("ThemeManager init: Fully initialized. Current theme: \(self.currentTheme.name)")
    }
    
    func fetchSKProducts() async {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager fetchSKProducts: iCloud login is disabled. Skipping fetch.")
            self.storeKitProducts = []
            return
        }
        let productIDs = Set(themes.compactMap { $0.isPremium ? $0.productID : nil })
        if !productIDs.isEmpty {
            print("ThemeManager: Requesting product information from StoreKit for IDs: \(productIDs)")
            await storeKitManager.fetchProducts(productIDs: productIDs)
        } else {
            print("ThemeManager: No premium themes with product IDs found to fetch.")
        }
    }

    func purchaseTheme(_ theme: Theme) async {
    
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager purchaseTheme: iCloud login is disabled. Cannot purchase.")
            self.storeKitError = .userCannotMakePayments
            return
        }
        guard theme.isPremium, let productID = theme.productID else {
            print("ThemeManager: Theme \(theme.name) is not premium or has no product ID.")
            return
        }
        
        if storeKitProducts.first(where: { $0.id == productID }) == nil {
            print("ThemeManager: Product \(productID) for theme \(theme.name) not found in local cache. Fetching products first.")
            await fetchSKProducts()
        }

        if let product = storeKitProducts.first(where: { $0.id == productID }) {
            print("ThemeManager: Attempting to purchase product: \(product.id) for theme \(theme.name)")
            await storeKitManager.purchase(product)
        } else {
            print("ThemeManager: Product ID \(productID) for theme \(theme.name) not found in fetched StoreKit products even after attempting fetch.")
            self.storeKitError = .productsNotFound
        }
    }

    func restoreThemePurchases() async {
        guard settingsManagerInstance.useiCloudLogin else {
            print("ThemeManager restoreThemePurchases: iCloud login is disabled. Cannot restore.")
            self.storeKitError = .userCannotMakePayments
            return
        }
        print("ThemeManager: Requesting sync/restore purchases from StoreKit.")
        await storeKitManager.syncTransactions()
    }
    
    private func handleSuccessfulStoreKitProcessing(storeKitProductIDs: Set<String>, authManager: AuthManager) {

        print("ThemeManager: Handling successful StoreKit processing for product IDs: \(storeKitProductIDs)")
        var newlyProcessedAppThemeIDs = Set<String>()

        for skProductID in storeKitProductIDs {
            if let theme = themes.first(where: { $0.productID == skProductID && $0.isPremium }) {
                newlyProcessedAppThemeIDs.insert(theme.id)
            } else {
                print("ThemeManager WARNING: Received a StoreKit product ID '\(skProductID)' that doesn't map to any known premium theme's productID.")
            }
        }

        let oldPurchasedIDs = self.purchasedThemeIDs
        self.purchasedThemeIDs.formUnion(newlyProcessedAppThemeIDs)

        let purchasedIDsActuallyChanged = (self.purchasedThemeIDs != oldPurchasedIDs)

        if purchasedIDsActuallyChanged {
            print("ThemeManager: purchasedThemeIDs (Theme.id) updated due to StoreKit: \(self.purchasedThemeIDs)")
            print("ThemeManager: Syncing updated purchased themes to CloudKit via AuthManager.")
            authManager.updateUserPurchasedThemes(themeIDs: self.purchasedThemeIDs)

            if newlyProcessedAppThemeIDs.count == 1,
               let singleNewThemeID = newlyProcessedAppThemeIDs.first,
               let themeToApply = themes.first(where: {$0.id == singleNewThemeID}),
               currentTheme.id != themeToApply.id {
                setCurrentTheme(themeToApply)
                print("ThemeManager: Automatically applied newly purchased/restored theme: \(themeToApply.name)")
            }
        } else {
            print("ThemeManager: No new themes were added from StoreKit processing, or processed themes were already known.")
        }
        self.storeKitError = nil
    }

    private func rebuildPurchasedThemeIDsAndRefreshCurrentTheme(authManager: AuthManager) {
        var newPurchased = Set(self.themes.filter { !$0.isPremium }.map { $0.id })

        if self.settingsManagerInstance.useiCloudLogin, let userProfile = authManager.currentUser {
            newPurchased.formUnion(userProfile.purchasedThemeIDs)
            print("ThemeManager rebuild (iCloud user \(userProfile.id)): Loaded \(userProfile.purchasedThemeIDs.count) themes from CloudKit profile. Combined with free: \(newPurchased.count)")
        } else {
            print("ThemeManager rebuild (No iCloud user or iCloud disabled): No purchased themes from iCloud.")
        }
        
        if self.purchasedThemeIDs != newPurchased {
            self.purchasedThemeIDs = newPurchased
            print("ThemeManager: purchasedThemeIDs confirms. Free and purchased themes from StoreKit. Final set: \(self.purchasedThemeIDs)")
        }else{
            print("ThemeManager: purchasedThemeIDs confirms. Only Free themes can apply. Final set: \(self.purchasedThemeIDs)")
        }

        let savedThemeID = UserDefaults.standard.string(forKey: currentThemeIDKey)
        var themeToRestore: Theme? = nil

        if let themeID = savedThemeID, let candidate = themes.first(where: { $0.id == themeID }) {
            if self.isThemePurchased(candidate) {
                themeToRestore = candidate
            }
        }

        let themeToActuallySet: Theme
        if let validRestoredTheme = themeToRestore {
            themeToActuallySet = validRestoredTheme
        } else {
            let defaultThemeToSet = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
            themeToActuallySet = defaultThemeToSet
            if savedThemeID != nil && savedThemeID != defaultThemeToSet.id {
                 print("ThemeManager rebuild: Previously selected theme '\(savedThemeID!)' is no longer purchased or invalid. Reverting to default '\(defaultThemeToSet.name)'.")
            }
        }
        
        if currentTheme.id != themeToActuallySet.id {
             setCurrentTheme(themeToActuallySet)
        } else if !isThemePurchased(currentTheme) {
             let defaultTheme = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
             print("ThemeManager rebuild: Current theme '\(currentTheme.name)' is no longer purchased. Reverting to default '\(defaultTheme.name)'.")
             setCurrentTheme(defaultTheme)
        }
    }
    
    func setCurrentTheme(_ theme: Theme) {
        guard themes.contains(where: { $0.id == theme.id }) else {
            print("ThemeManager: Attempted to set an unknown theme ('\(theme.name)'). Ignoring.")
            return
        }

        let canApply: Bool
        if theme.isPremium {
            canApply = self.isThemePurchased(theme)
        } else {
            canApply = true
        }

        guard canApply else {
            print("ThemeManager setCurrentTheme: Cannot apply theme '\(theme.name)'. It's premium and not purchased/accessible.")
            let defaultThemeToSet = self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!
            if self.currentTheme.id != defaultThemeToSet.id {
                self.currentTheme = defaultThemeToSet
                UserDefaults.standard.set(defaultThemeToSet.id, forKey: currentThemeIDKey)
                print("ThemeManager setCurrentTheme: Reverted to default theme '\(defaultThemeToSet.name)'.")
            }
            return
        }

        if currentTheme.id != theme.id {
            currentTheme = theme
            UserDefaults.standard.set(theme.id, forKey: currentThemeIDKey)
            print("ThemeManager: Current theme changed to '\(theme.name)' and saved to UserDefaults.")
        }
    }

    func isThemePurchased(_ theme: Theme) -> Bool {
        return !theme.isPremium || purchasedThemeIDs.contains(theme.id)
    }

}

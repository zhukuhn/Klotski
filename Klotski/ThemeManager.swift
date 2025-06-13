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

    // --- 新增：试用功能相关属性 ---
    @Published private(set) var isTrialActive: Bool = false
    @Published var showTrialEndedAlert: Bool = false
    private(set) var trialThemeForPurchase: Theme? = nil

    private var cancellables = Set<AnyCancellable>()
    private let storeKitManager = StoreKitManager.shared
    
    private let settingsManagerInstance: SettingsManager
    private var initialAuthCheckCompleted = false
    private let currentThemeIDKey = "currentThemeID"
    static let locallyKnownPaidThemeIDsKey = "locallyKnownPaidThemeIDs"

    // --- 新增：试用功能私有属性 ---
    private var previousThemeID: String?
    private var trialTimer: Timer?


    init(authManager: AuthManager, settingsManager: SettingsManager, availableThemes: [Theme] = AppThemeRepository.allThemes) {
        self.settingsManagerInstance = settingsManager
        self.themes = availableThemes
        
        let fallbackTheme = Theme(id: "fallback", name: "备用", isPremium: false,
                                  backgroundColor: CodableColor(color: .gray),
                                  sliderColor: CodableColor(color: .secondary),
                                  sliderTextColor: CodableColor(color: .white),
                                  textColor: CodableColor(color: .primary),
                                  boardBackgroundColor: CodableColor(color: .white),
                                  boardGridLineColor: CodableColor(color: Color(.systemGray)))
        
        let defaultThemeToSet = availableThemes.first(where: { $0.id == "default" }) ?? fallbackTheme
        
        let initialPurchased = Set(availableThemes.filter { !$0.isPremium }.map { $0.id })
        self._purchasedThemeIDs = Published(initialValue: initialPurchased)
        self._currentTheme = Published(initialValue: defaultThemeToSet)

        print("ThemeManager init: Initial purchasedThemeIDs (only free themes): \(self.purchasedThemeIDs)")
        
        setupBindings(authManager: authManager)

        Task {
            if settingsManagerInstance.useiCloudLogin {
                await fetchSKProducts()
                await storeKitManager.checkForCurrentEntitlements()
            }
        }
        print("ThemeManager init: Fully initialized. Current theme: \(self.currentTheme.name)")
    }
    
    private func setupBindings(authManager: AuthManager) {
        // ... 原有的 bindings 保持不变 ...
        storeKitManager.purchaseOrRestoreSuccessfulPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processedProductIDs in
                guard let self = self else { return }
                print("ThemeManager: Received successful purchase/restore for StoreKit Product IDs: \(processedProductIDs)")
                self.handleSuccessfulStoreKitProcessing(storeKitProductIDs: processedProductIDs, authManager: authManager)
            }
            .store(in: &cancellables)
        
        storeKitManager.$fetchedProducts.receive(on: DispatchQueue.main).assign(to: \.storeKitProducts, on: self).store(in: &cancellables)
        storeKitManager.$isLoading.receive(on: DispatchQueue.main).assign(to: \.isStoreLoading, on: self).store(in: &cancellables)
        storeKitManager.$error.receive(on: DispatchQueue.main).assign(to: \.storeKitError, on: self).store(in: &cancellables)
        
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userProfile in
                guard let self = self else { return }
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
    }
    /// 开始一个主题的试用
    /// - Parameters:
    ///   - theme: 要试用的主题
    ///   - duration: 试用时长（秒）
    func startTrial(for theme: Theme, duration: TimeInterval = 10) {
        guard !isTrialActive else {
            print("ThemeManager: Cannot start a new trial while another is active.")
            return
        }

        print("ThemeManager: Starting trial for theme '\(theme.name)' for \(duration) seconds.")
        
        // 取消任何可能存在的旧计时器
        trialTimer?.invalidate()
        
        // 保存当前主题，以便试用结束后恢复
        previousThemeID = self.currentTheme.id
        isTrialActive = true
        
        // 立即应用试用主题
        // 注意：这里我们绕过了 setCurrentTheme 中的购买检查
        currentTheme = theme
        
        // 启动计时器，在试用结束后调用 endTrial
        trialTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.endTrial()
            }
        }
    }
    
    /// 结束试用
    private func endTrial() {
        guard isTrialActive else { return }

        print("ThemeManager: Trial ended.")
        
        trialTimer?.invalidate()
        trialTimer = nil
        
        // 保存试用过的主题信息，以便在弹窗中提供购买选项
        self.trialThemeForPurchase = self.currentTheme
        
        // 恢复到之前的主题
        if let prevID = previousThemeID, let prevTheme = themes.first(where: { $0.id == prevID }) {
            currentTheme = prevTheme
        } else {
            // 如果找不到之前的主题，则恢复到默认主题
            currentTheme = themes.first { $0.id == "default" } ?? themes.first!
        }
        
        isTrialActive = false
        previousThemeID = nil
        
        // 触发UI显示“试用结束”的弹窗
        showTrialEndedAlert = true
    }
    
    /// 由用户操作（如切换到已购买主题）取消试用
    func cancelTrial() {
        guard isTrialActive else { return }
        
        print("ThemeManager: Trial cancelled by user action.")
        
        trialTimer?.invalidate()
        trialTimer = nil
        
        // 直接恢复主题，不显示弹窗
        if let prevID = previousThemeID, let prevTheme = themes.first(where: { $0.id == prevID }) {
            currentTheme = prevTheme
        } else {
            currentTheme = themes.first { $0.id == "default" } ?? themes.first!
        }
        
        isTrialActive = false
        previousThemeID = nil
        trialThemeForPurchase = nil
    }

    // MARK: - Public Methods
    
    func setCurrentTheme(_ theme: Theme) {
        // 如果用户在试用期间选择了一个已购买的主题，则取消试用
        if isTrialActive {
            cancelTrial()
        }
        
        // --- 原有的逻辑保持不变 ---
        guard themes.contains(where: { $0.id == theme.id }) else {
            print("ThemeManager: Attempted to set an unknown theme ('\(theme.name)'). Ignoring.")
            return
        }

        guard isThemePurchased(theme) else {
            print("ThemeManager setCurrentTheme: Cannot apply theme '\(theme.name)'. It's premium and not purchased.")
            // 不应该会发生，因为UI层会阻止
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
        // 在重建之前，如果试用正在进行，则取消试用以避免状态冲突
        if isTrialActive {
            cancelTrial()
        }
        
        // --- 原有的逻辑保持不变 ---
        var newPurchased = Set(self.themes.filter { !$0.isPremium }.map { $0.id })
        if self.settingsManagerInstance.useiCloudLogin, let userProfile = authManager.currentUser {
            newPurchased.formUnion(userProfile.purchasedThemeIDs)
        }
        self.purchasedThemeIDs = newPurchased

        let savedThemeID = UserDefaults.standard.string(forKey: currentThemeIDKey)
        var themeToRestore: Theme? = nil
        if let themeID = savedThemeID, let candidate = themes.first(where: { $0.id == themeID }) {
            if self.isThemePurchased(candidate) {
                themeToRestore = candidate
            }
        }
        let themeToActuallySet = themeToRestore ?? (self.themes.first(where: { $0.id == "default" }) ?? self.themes.first!)
        
        if currentTheme.id != themeToActuallySet.id {
             setCurrentTheme(themeToActuallySet)
        }
    }

}

//
//  StoreKitManager.swift
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

enum StoreKitError: Error, LocalizedError, Equatable {
    case unknown
    case productIDsEmpty
    case productsNotFound
    case purchaseFailed(String?)
    case purchaseCancelled
    case purchasePending
    case transactionVerificationFailed
    case failedToLoadCurrentEntitlements(String?)
    case userCannotMakePayments

    static func == (lhs: StoreKitError, rhs: StoreKitError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown): return true
        case (.productIDsEmpty, .productIDsEmpty): return true
        case (.productsNotFound, .productsNotFound): return true
        case (.purchaseFailed(let lMsg), .purchaseFailed(let rMsg)): return lMsg == rMsg
        case (.purchaseCancelled, .purchaseCancelled): return true
        case (.purchasePending, .purchasePending): return true
        case (.transactionVerificationFailed, .transactionVerificationFailed): return true
        case (.failedToLoadCurrentEntitlements(let lMsg), .failedToLoadCurrentEntitlements(let rMsg)): return lMsg == rMsg
        case (.userCannotMakePayments, .userCannotMakePayments): return true
        default: return false
        }
    }

    var errorDescription: String? {
        let sm = SettingsManager()
        switch self {
        case .unknown: return sm.localizedString(forKey: "storeKitErrorUnknown")
        case .productIDsEmpty: return sm.localizedString(forKey: "storeKitErrorProductIDsEmpty")
        case .productsNotFound: return sm.localizedString(forKey: "storeKitErrorProductsNotFound")
        case .purchaseFailed(let msg):
            let base = sm.localizedString(forKey: "storeKitErrorPurchaseFailed")
            return msg != nil ? "\(base): \(msg!)" : base
        case .purchaseCancelled: return sm.localizedString(forKey: "storeKitErrorPurchaseCancelled")
        case .purchasePending: return sm.localizedString(forKey: "storeKitErrorPurchasePending")
        case .transactionVerificationFailed: return sm.localizedString(forKey: "storeKitErrorTransactionVerificationFailed")
        case .failedToLoadCurrentEntitlements(let msg):
            let base = sm.localizedString(forKey: "storeKitErrorFailedToLoadEntitlements")
            return msg != nil ? "\(base): \(msg!)" : base
        case .userCannotMakePayments: return sm.localizedString(forKey: "storeKitErrorUserCannotMakePayments")
        }
    }

    static func purchaseFailed(_ error: Error?) -> StoreKitError {
        return .purchaseFailed(error?.localizedDescription)
    }
    static func failedToLoadCurrentEntitlements(_ error: Error) -> StoreKitError {
        return .failedToLoadCurrentEntitlements(error.localizedDescription)
    }
}

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var fetchedProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var error: StoreKitError? = nil

    let purchaseOrRestoreSuccessfulPublisher = PassthroughSubject<Set<String>, Never>()

    private var transactionListener: Task<Void, Error>? = nil

    private init() {
        debugLog("StoreKitManager (StoreKit 2): Initialized.")
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
        debugLog("StoreKitManager (StoreKit 2): Deinitialized and transaction listener cancelled.")
    }

    func fetchProducts(productIDs: Set<String>) async {
        guard !productIDs.isEmpty else {
            debugLog("StoreKitManager: No product IDs provided to fetch.")
            self.error = .productIDsEmpty
            return
        }
        debugLog("StoreKitManager: Fetching products for IDs: \(productIDs)")
        self.isLoading = true
        self.error = nil

        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.fetchedProducts = storeProducts
            debugLog("StoreKitManager: Fetched products: \(self.fetchedProducts.map { $0.id })")
            if self.fetchedProducts.isEmpty && !productIDs.isEmpty {
                debugLog("StoreKitManager: No products returned from App Store for requested IDs.")
                self.error = .productsNotFound
            }
        } catch {
            debugLog("StoreKitManager: Failed to fetch products: \(error)")
            self.error = .productsNotFound
        }
        self.isLoading = false
    }

    func purchase(_ product: Product) async {
        guard AppStore.canMakePayments else {
            debugLog("StoreKitManager: User cannot make payments.")
            self.error = .userCannotMakePayments
            return
        }
        
        debugLog("StoreKitManager: Initiating purchase for product: \(product.id)")
        self.isLoading = true
        self.error = nil

        do {
            let result = try await product.purchase()
            try await handlePurchaseResult(result, for: product.id)
        } catch let actualStoreKitError as StoreKit.StoreKitError {
             debugLog("StoreKitManager: Purchase failed for \(product.id) with StoreKitError: \(actualStoreKitError.localizedDescription) (\(actualStoreKitError))")
             if case .userCancelled = actualStoreKitError {
                 self.error = .purchaseCancelled
             } else {
                 self.error = .purchaseFailed(actualStoreKitError)
             }
        } catch {
            debugLog("StoreKitManager: Purchase failed for \(product.id) with error: \(error)")
            self.error = .purchaseFailed(error)
        }
        self.isLoading = false
    }
    
    private func handlePurchaseResult(_ result: Product.PurchaseResult, for productID: Product.ID) async throws {
        switch result {
        case .success(let verificationResult):
            debugLog("StoreKitManager: Purchase successful for \(productID), verifying transaction...")
            guard let transaction = await self.checkVerified(verificationResult) else {
                self.error = .transactionVerificationFailed
                return
            }
            debugLog("StoreKitManager: Transaction verified for \(productID). Finishing transaction.")
            await transaction.finish()
            purchaseOrRestoreSuccessfulPublisher.send([transaction.productID])

        case .pending:
            debugLog("StoreKitManager: Purchase for \(productID) is pending.")
            self.error = .purchasePending

        case .userCancelled:
            debugLog("StoreKitManager: User cancelled purchase for \(productID).")
            self.error = .purchaseCancelled
        
        @unknown default:
            debugLog("StoreKitManager: Unknown purchase result for \(productID).")
            self.error = .unknown
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor [weak self] in
            guard let self = self else { return }
            debugLog("StoreKitManager: Starting transaction listener...")
            for await verificationResult in Transaction.updates {
                debugLog("StoreKitManager: Received transaction update.")
                guard let transaction = await self.checkVerified(verificationResult) else {
                    debugLog("StoreKitManager: Transaction update verification failed.")
                    continue
                }

                if transaction.revocationDate == nil {
                     debugLog("StoreKitManager: Verified transaction update for \(transaction.productID). Product type: \(transaction.productType)")
                     self.purchaseOrRestoreSuccessfulPublisher.send([transaction.productID])
                } else {
                     debugLog("StoreKitManager: Transaction for \(transaction.productID) was revoked at \(transaction.revocationDate!).")
                }
                
                await transaction.finish()
            }
        }
    }

    @discardableResult
    private func checkVerified<T>(_ verificationResult: VerificationResult<T>) async -> T? {
        switch verificationResult {
        case .unverified(let unverifiedTransaction, let verificationError):
            debugLog("StoreKitManager: Transaction unverified for \(unverifiedTransaction) with error: \(verificationError.localizedDescription)")
            return nil
        case .verified(let verifiedTransaction):
            return verifiedTransaction
        }
    }

    func syncTransactions() async {
        debugLog("StoreKitManager: Requesting AppStore.sync() to sync transactions.")
        self.isLoading = true
        self.error = nil
        do {
            try await AppStore.sync()
            debugLog("StoreKitManager: AppStore.sync() completed. Updates (if any) will be handled by the transaction listener.")
            await checkForCurrentEntitlements()
        } catch {
            debugLog("StoreKitManager: AppStore.sync() failed with error: \(error)")
            self.error = .purchaseFailed(error)
        }
        self.isLoading = false
    }

    func checkForCurrentEntitlements() async {
        debugLog(String(repeating:"-",count:100))
        debugLog("StoreKitManager: Checking for current entitlements")
        var successfullyEntitledProductIDs = Set<String>()
        var entitlementsFound = false
        
        for await verificationResult in StoreKit.Transaction.currentEntitlements {
            entitlementsFound = true
            
            let typedResult: VerificationResult<StoreKit.Transaction> = verificationResult
            guard let transaction = await self.checkVerified(typedResult) else {
                debugLog("StoreKitManager: Found an unverified current entitlement, skipping.")
                continue
            }
            
            if transaction.productType == .nonConsumable && transaction.revocationDate == nil {
                debugLog("StoreKitManager: Found current entitlement for non-consumable: \(transaction.productID)")
                successfullyEntitledProductIDs.insert(transaction.productID)
            }
        }

        if !entitlementsFound && self.error == nil {
            debugLog("StoreKitManager: No current entitlements found after iterating (or iterator was empty).")
        }

        if !successfullyEntitledProductIDs.isEmpty {
            debugLog("StoreKitManager: Successfully processed current entitlements for IDs: \(successfullyEntitledProductIDs)")
            purchaseOrRestoreSuccessfulPublisher.send(successfullyEntitledProductIDs)
        }
        debugLog(String(repeating:"-",count:100))
    }
}


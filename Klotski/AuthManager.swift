//
//  AuthManager.swift
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

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine

    private let container: CKContainer
    private let privateDB: CKDatabase
    
    private var iCloudUserActualRecordID: CKRecord.ID?

    private var cancellables = Set<AnyCancellable>()

    // This key is no longer used to control logic, but might be kept if other parts of the app reference it.
    // For a full cleanup, it should be removed everywhere. Here we leave its definition but remove its usage.
    static let useiCloudLoginKey = "useiCloudLogin"

    init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        debugLog("AuthManager (CloudKit v2): 初始化完成。现在将始终尝试使用iCloud。")

        // Logic now directly attempts to check iCloud status, ignoring any old preference.
        checkiCloudAccountStatusAndFetchProfile()
        
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                debugLog("AuthManager: Received CKAccountChanged notification. Clearing previous user session.")
                self.iCloudUserActualRecordID = nil

                self.currentUser = nil
                self.isLoggedIn = false
                
                // Directly re-check account status without checking any preference.
                debugLog("AuthManager: iCloud account changed. Re-checking account status and profile.")
                self.checkiCloudAccountStatusAndFetchProfile()
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        debugLog("AuthManager (CloudKit v2): Deinitialized.")
    }
    
    private func clearLocalUserSession(reason: String) {
        DispatchQueue.main.async {
            if self.currentUser != nil || self.isLoggedIn || self.isLoading {
                debugLog("AuthManager: Clearing local session. Reason: \(reason)")
                self.currentUser = nil
                self.isLoggedIn = false
                self.iCloudUserActualRecordID = nil
                self.isLoading = false
                
                if self.iCloudAccountStatus == .available {
                   self.iCloudAccountStatus = .couldNotDetermine
                }
            }
        }
    }

    func checkiCloudAccountStatusAndFetchProfile() {
        // Removed guard check for the preference.
        self.isLoading = true
        debugLog("AuthManager: Checking iCloud account status...")

        container.accountStatus { [weak self] (status, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Removed guard check for preference during async callback.

                if let error = error {
                    debugLog("AuthManager: Error checking iCloud account status: \(error.localizedDescription)")
                    self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
                    self.iCloudAccountStatus = .couldNotDetermine
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                    return
                }

                self.iCloudAccountStatus = status
                debugLog("AuthManager: iCloud Account Status: \(status.description)")
                let sm = SettingsManager()

                switch status {
                case .available:
                    self.errorMessage = nil
                    self.fetchICloudUserRecordID()
                case .noAccount:
                    self.errorMessage = sm.localizedString(forKey: "iCloudNoAccount")
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .restricted:
                    self.errorMessage = sm.localizedString(forKey: "iCloudRestricted")
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .couldNotDetermine:
                    self.errorMessage = sm.localizedString(forKey: "iCloudCouldNotDetermine")
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                case .temporarilyUnavailable:
                    self.errorMessage = sm.localizedString(forKey: "iCloudTempUnavailable")
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                @unknown default:
                    self.errorMessage = sm.localizedString(forKey: "iCloudUnknownStatus")
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                }
            }
        }
    }

    private func fetchICloudUserRecordID() {
        // Removed guard check for the preference.
        debugLog("AuthManager: Attempting to fetch iCloud User Record ID...")
        if !self.isLoading { self.isLoading = true }

        container.fetchUserRecordID { [weak self] (recordID, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                // Removed guard check for preference during async callback.
                
                let sm = SettingsManager()
                if let error = error {
                    debugLog("AuthManager DEBUG: Fetched iCloud User Record ID: NIL, Error: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudFetchUserFailed")): \(error.localizedDescription)"
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                    return
                }

                debugLog("AuthManager DEBUG: Fetched iCloud User Record ID: \(recordID?.recordName ?? "NIL"), Error: No error")
                if let recordID = recordID {
                    debugLog("AuthManager: Successfully fetched iCloud User Record ID: \(recordID.recordName)")
                    self.iCloudUserActualRecordID = recordID
                    self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: recordID.recordName)
                } else {
                    debugLog("AuthManager: No iCloud User Record ID fetched.")
                    self.errorMessage = sm.localizedString(forKey: "iCloudNoUserIdentity")
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func fetchOrCreateUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        // Removed guard check for the preference.
        debugLog("AuthManager: Fetching or creating UserProfile for iCloud User \(iCloudRecordName)...")
        debugLog("AuthManager DEBUG: Querying UserProfile for iCloudUserRecordName: \(iCloudRecordName)")
        let sm = SettingsManager()

        let predicate = NSPredicate(format: "iCloudUserRecordName == %@", iCloudRecordName)
        let query = CKQuery(recordType: CloudKitRecordTypes.UserProfile, predicate: predicate)
        
        privateDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                // Removed guard check for preference during async callback.

                switch result {
                case .success(let data):
                    if let firstMatch = data.matchResults.first {
                        let matchedRecordID = firstMatch.0
                        switch firstMatch.1 {
                        case .success(let existingUserProfileRecord):
                            debugLog("AuthManager DEBUG: Found existing UserProfile. RecordName: \(existingUserProfileRecord.recordID.recordName)")
                            debugLog("AuthManager: Found existing UserProfile record: \(existingUserProfileRecord.recordID.recordName)")
                            if let userProfile = UserProfile(from: existingUserProfileRecord) {
                                self.currentUser = userProfile
                                self.isLoggedIn = true
                                debugLog("AuthManager: UserProfile loaded: \(userProfile.displayName ?? userProfile.id)")
                            } else {
                                debugLog("AuthManager: Failed to parse UserProfile from fetched record (ID: \(matchedRecordID.recordName)).")
                                self.errorMessage = sm.localizedString(forKey: "iCloudParseProfileErrorExisting")
                                self.currentUser = nil; self.isLoggedIn = false
                            }
                            self.isLoading = false
                        case .failure(let recordFetchError):
                            debugLog("AuthManager: Matched UserProfile ID \(matchedRecordID.recordName), but failed to fetch record: \(recordFetchError.localizedDescription)")
                            self.errorMessage = "\(sm.localizedString(forKey: "iCloudLoadProfileErrorFetch")): \(recordFetchError.localizedDescription)"
                            self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                        }
                    } else {
                        debugLog("AuthManager DEBUG: No UserProfile found. Attempting to create new one for iCloudUserRecordName: \(iCloudRecordName)")
                        debugLog("AuthManager: No UserProfile found for iCloud User \(iCloudRecordName). Creating new UserProfile.")
                        self.createUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                    }
                case .failure(let queryError):
                    debugLog("AuthManager: Error querying UserProfile: \(queryError.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudLoadProfileErrorQuery")): \(queryError.localizedDescription)"
                    self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func createUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        // Removed guard check for the preference.
        debugLog("AuthManager: Creating new UserProfile linked to iCloud User \(iCloudRecordName)...")
        let sm = SettingsManager()

        let newUserProfile = UserProfile(
            iCloudUserRecordName: iCloudRecordName,
            displayName: sm.localizedString(forKey: "defaultPlayerName"),
            purchasedThemeIDs: Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        )
        
        let newUserProfileCKRecord = newUserProfile.toCKRecord()

        privateDB.save(newUserProfileCKRecord) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                debugLog("AuthManager DEBUG: Save new UserProfile result. Saved Record ID: \(savedRecord?.recordID.recordName ?? "NIL"), Error: \(error?.localizedDescription ?? "No error")")

                // Removed guard check for preference during async callback.

                if let error = error {
                    debugLog("AuthManager: Error saving new UserProfile record: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudCreateProfileErrorSave")): \(error.localizedDescription)"
                    self.currentUser = nil; self.isLoggedIn = false
                    
                    if let ckError = error as? CKError, ckError.code == .constraintViolation {
                        debugLog("AuthManager: Constraint violation while creating UserProfile. Attempting to re-fetch.")
                        self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                        return
                    }
                    self.isLoading = false
                    return
                }

                if let record = savedRecord, let finalProfile = UserProfile(from: record) {
                    self.currentUser = finalProfile
                    self.isLoggedIn = true
                    debugLog("AuthManager: New UserProfile successfully created and loaded: \(finalProfile.displayName ?? finalProfile.id)")
                } else {
                    debugLog("AuthManager: Failed to create UserProfile from newly saved record, or save did not return a record.")
                    self.errorMessage = sm.localizedString(forKey: "iCloudParseProfileErrorNew")
                    self.currentUser = nil; self.isLoggedIn = false
                }
                self.isLoading = false
            }
        }
    }
    
    func saveCurrentUserProfile() {
        // Removed guard check for the preference.
        guard let currentUserProfile = self.currentUser else {
            debugLog("AuthManager: Cannot save profile. No current user.")
            return
        }
        guard iCloudAccountStatus == .available else {
            debugLog("AuthManager: iCloud account not available. Cannot save profile to CloudKit.")
            let sm = SettingsManager()
            self.errorMessage = sm.localizedString(forKey: "iCloudUnavailableCannotSave")
            return
        }
        guard self.iCloudUserActualRecordID != nil else {
            debugLog("AuthManager: Cannot save profile. iCloudUserActualRecordID is unknown.")
            let sm = SettingsManager()
            self.errorMessage = sm.localizedString(forKey: "iCloudUserIdentityIncomplete")
            return
        }

        debugLog("AuthManager: Saving current UserProfile (ID: \(currentUserProfile.id)) to CloudKit...")
        self.isLoading = true
        let sm = SettingsManager()
        
        let userProfileRecordIDToFetch = CKRecord.ID(recordName: currentUserProfile.id)

        privateDB.fetch(withRecordID: userProfileRecordIDToFetch) { [weak self] (existingRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                // Removed guard check for preference during async callback.

                var recordToSave: CKRecord
                if let fetchError = error as? CKError, fetchError.code == .unknownItem {
                    debugLog("AuthManager: UserProfile record (ID: \(currentUserProfile.id)) not found during save. Creating new.")
                    recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                } else if let error = error {
                    debugLog("AuthManager: Error fetching existing record before save: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudSaveProfileErrorFetch")): \(error.localizedDescription)"
                    self.isLoading = false
                    return
                } else if let fetchedRecord = existingRecord {
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: fetchedRecord)
                } else {
                     debugLog("AuthManager: Unexpected state: no error but no existing record found for ID \(currentUserProfile.id) during save. Creating new.")
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                }

                self.privateDB.save(recordToSave) { (savedRecord, saveError) in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let saveError = saveError {
                            debugLog("AuthManager: Error saving UserProfile to CloudKit: \(saveError.localizedDescription)")
                            self.errorMessage = "\(sm.localizedString(forKey: "iCloudSaveProfileErrorWrite")): \(saveError.localizedDescription)"
                        } else {
                            debugLog("AuthManager: UserProfile successfully saved to CloudKit.")
                            if let sr = savedRecord, let updatedProfile = UserProfile(from: sr) {
                                if self.currentUser?.recordChangeTag != updatedProfile.recordChangeTag || self.currentUser?.purchasedThemeIDs != updatedProfile.purchasedThemeIDs {
                                    self.currentUser = updatedProfile
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public func refreshAuthenticationState() {
        debugLog("AuthManager: Manually refreshing authentication state...")
        self.iCloudUserActualRecordID = nil
        checkiCloudAccountStatusAndFetchProfile()
    }

    public func pseudoLogout() {
        debugLog("AuthManager: Performing pseudo-logout (clearing local app session)...")
        clearLocalUserSession(reason: "Pseudo-logout called.")
        let sm = SettingsManager()
        self.errorMessage = sm.localizedString(forKey: "loggedOutMessage")
    }

    func updateUserPurchasedThemes(themeIDs: Set<String>) {
        // Removed guard check for the preference.
        guard var profileToUpdate = self.currentUser else {
            debugLog("AuthManager: Cannot update purchased themes. No current user.")
            return
        }
        
        if profileToUpdate.purchasedThemeIDs != themeIDs {
            profileToUpdate.purchasedThemeIDs = themeIDs
            self.currentUser = profileToUpdate
            debugLog("AuthManager: User's purchased themes updated locally. Attempting to save to CloudKit.")
            saveCurrentUserProfile()
        } else {
            debugLog("AuthManager: No change in purchased themes. Skipping save.")
        }
    }
    
    //开发者按钮：重置账户付费ID
    func resetPurchasedThemesInCloud() {
        debugLog("AuthManager: Attempting to reset purchased themes in CloudKit...")
        
        // 1. 确保用户已登录
        guard self.isLoggedIn, let profileToUpdate = self.currentUser else {
            debugLog("AuthManager: Cannot reset themes. User is not logged in.")
            return
        }
        
        // 2. 创建一个只包含免费主题ID的集合
        let freeThemeIDs = Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        
        // 3. 检查是否有变化 (例如，如果已经是重置状态，则无需操作)
        if profileToUpdate.purchasedThemeIDs == freeThemeIDs {
            debugLog("AuthManager: Purchased themes are already in a reset state (only free themes). No action needed.")
            return
        }
        
        debugLog("AuthManager: Resetting purchased themes to only include free themes: \(freeThemeIDs)")
        
        // 4. 更新本地 profile 并调用现有的保存逻辑
        // 我们复用 updateUserPurchasedThemes 方法，它内部包含了保存到 CloudKit 的逻辑
        self.updateUserPurchasedThemes(themeIDs: freeThemeIDs)
    }
}

extension CKAccountStatus {
    var description: String {
        switch self {
        case .couldNotDetermine: return "无法确定 (Could Not Determine)"
        case .available: return "可用 (Available)"
        case .restricted: return "受限 (Restricted)"
        case .noAccount: return "无账户 (No Account)"
        case .temporarilyUnavailable: return "暂时不可用 (Temporarily Unavailable)"
        @unknown default: return "未知状态 (Unknown)"
        }
    }
}

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

    static let useiCloudLoginKey = "useiCloudLogin"

    init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        print("AuthManager (CloudKit v2): 初始化完成。")

        let useiCloudInitial = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        if UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) == nil {
            UserDefaults.standard.set(useiCloudInitial, forKey: AuthManager.useiCloudLoginKey)
        }

        if useiCloudInitial {
            print("AuthManager init: iCloud login is enabled by preference. Checking status.")
            checkiCloudAccountStatusAndFetchProfile()
        } else {
            print("AuthManager init: iCloud login is disabled by preference (default or user set).")
            DispatchQueue.main.async {
                self.clearLocalSessionForDisablediCloud(reason: "Initial setting is off.")
                self.errorMessage = self.localizedErrorMessageForDisablediCloud()
            }
        }

        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("AuthManager: Received CKAccountChanged notification. Clearing previous user session.")
                self.iCloudUserActualRecordID = nil

                self.currentUser = nil
                self.isLoggedIn = false
                
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: ThemeManager.locallyKnownPaidThemeIDsKey)
                    print("AuthManager: Cleared ThemeManager.locallyKnownPaidThemeIDsKey from UserDefaults due to account change.")
                }

                let useiCloudCurrent = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
                if useiCloudCurrent {
                    print("AuthManager: iCloud account changed, and preference is ON. Re-checking account status and profile.")
                    self.checkiCloudAccountStatusAndFetchProfile()
                } else {
                    print("AuthManager: iCloud account changed, but preference is OFF. Ensuring local session is cleared.")
                    self.clearLocalSessionForDisablediCloud(reason: "Account changed while preference is off.")
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        print("AuthManager (CloudKit v2): Deinitialized.")
    }
    
    private func localizedErrorMessageForDisablediCloud() -> String {
        let sm = SettingsManager()
        return sm.localizedString(forKey: "iCloudLoginDisabledMessage")
    }

    private func clearLocalSessionForDisablediCloud(reason: String) {
        DispatchQueue.main.async {
            if self.currentUser != nil || self.isLoggedIn || self.isLoading {
                print("AuthManager: Clearing local session. Reason: \(reason)")
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

    public func handleiCloudPreferenceChange(useiCloud: Bool) {
        print("AuthManager: iCloud preference changed to \(useiCloud).")
        UserDefaults.standard.set(useiCloud, forKey: AuthManager.useiCloudLoginKey)

        if useiCloud {
            self.errorMessage = nil
            self.isLoading = true
            print("AuthManager: Preference ON. Attempting to check iCloud status and fetch profile.")
            checkiCloudAccountStatusAndFetchProfile()
        } else {
            clearLocalSessionForDisablediCloud(reason: "User toggled preference to OFF.")
            self.errorMessage = localizedErrorMessageForDisablediCloud()
        }
    }

    func checkiCloudAccountStatusAndFetchProfile() {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager checkiCloudAccountStatusAndFetchProfile: iCloud login preference is OFF. Aborting check.")
            clearLocalSessionForDisablediCloud(reason: "Check called while preference is off.")
            if self.errorMessage == nil {
                 self.errorMessage = localizedErrorMessageForDisablediCloud()
            }
            return
        }

        self.isLoading = true
        print("AuthManager: Checking iCloud account status (preference is ON)...")

        container.accountStatus { [weak self] (status, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
                guard currentiCloudPreference else {
                    print("AuthManager accountStatus callback: iCloud login preference turned OFF during async. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during account status check.")
                    self.isLoading = false
                    return
                }

                if let error = error {
                    print("AuthManager: Error checking iCloud account status: \(error.localizedDescription)")
                    self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
                    self.iCloudAccountStatus = .couldNotDetermine
                    self.isLoggedIn = false; self.currentUser = nil; self.isLoading = false
                    return
                }

                self.iCloudAccountStatus = status
                print("AuthManager: iCloud Account Status: \(status.description)")
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
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager fetchICloudUserRecordID: iCloud login preference is OFF. Aborting fetch.")
            clearLocalSessionForDisablediCloud(reason: "User Record ID fetch called while preference is off.")
            return
        }

        print("AuthManager: Attempting to fetch iCloud User Record ID (preference is ON)...")
        if !self.isLoading { self.isLoading = true }

        container.fetchUserRecordID { [weak self] (recordID, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
                guard currentiCloudPreference else {
                    print("AuthManager fetchUserRecordID callback: iCloud login preference turned OFF during async. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during user ID fetch.")
                    self.isLoading = false
                    return
                }
                let sm = SettingsManager()
                if let error = error {
                    print("AuthManager DEBUG: Fetched iCloud User Record ID: NIL, Error: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudFetchUserFailed")): \(error.localizedDescription)"
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                    return
                }

                print("AuthManager DEBUG: Fetched iCloud User Record ID: \(recordID?.recordName ?? "NIL"), Error: No error")
                if let recordID = recordID {
                    print("AuthManager: Successfully fetched iCloud User Record ID: \(recordID.recordName)")
                    self.iCloudUserActualRecordID = recordID
                    self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: recordID.recordName)
                } else {
                    print("AuthManager: No iCloud User Record ID fetched.")
                    self.errorMessage = sm.localizedString(forKey: "iCloudNoUserIdentity")
                    self.iCloudUserActualRecordID = nil; self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func fetchOrCreateUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager fetchOrCreateUserProfile: iCloud login preference is OFF. Aborting.")
            clearLocalSessionForDisablediCloud(reason: "Profile fetch/create called while preference is off.")
            return
        }
        print("AuthManager: Fetching or creating UserProfile for iCloud User \(iCloudRecordName) (preference is ON)...")
        print("AuthManager DEBUG: Querying UserProfile for iCloudUserRecordName: \(iCloudRecordName)")
        let sm = SettingsManager()

        let predicate = NSPredicate(format: "iCloudUserRecordName == %@", iCloudRecordName)
        let query = CKQuery(recordType: CloudKitRecordTypes.UserProfile, predicate: predicate)
        
        privateDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }

                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
                guard currentiCloudPreference else {
                    print("AuthManager fetchOrCreateUserProfile callback: iCloud login preference turned OFF. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during profile fetch/create.")
                    self.isLoading = false
                    return
                }

                switch result {
                case .success(let data):
                    if let firstMatch = data.matchResults.first {
                        let matchedRecordID = firstMatch.0
                        switch firstMatch.1 {
                        case .success(let existingUserProfileRecord):
                            print("AuthManager DEBUG: Found existing UserProfile. RecordName: \(existingUserProfileRecord.recordID.recordName)")
                            print("AuthManager: Found existing UserProfile record: \(existingUserProfileRecord.recordID.recordName)")
                            if let userProfile = UserProfile(from: existingUserProfileRecord) {
                                self.currentUser = userProfile
                                self.isLoggedIn = true
                                print("AuthManager: UserProfile loaded: \(userProfile.displayName ?? userProfile.id)")
                            } else {
                                print("AuthManager: Failed to parse UserProfile from fetched record (ID: \(matchedRecordID.recordName)).")
                                self.errorMessage = sm.localizedString(forKey: "iCloudParseProfileErrorExisting")
                                self.currentUser = nil; self.isLoggedIn = false
                            }
                            self.isLoading = false
                        case .failure(let recordFetchError):
                            print("AuthManager: Matched UserProfile ID \(matchedRecordID.recordName), but failed to fetch record: \(recordFetchError.localizedDescription)")
                            self.errorMessage = "\(sm.localizedString(forKey: "iCloudLoadProfileErrorFetch")): \(recordFetchError.localizedDescription)"
                            self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                        }
                    } else {
                        print("AuthManager DEBUG: No UserProfile found. Attempting to create new one for iCloudUserRecordName: \(iCloudRecordName)")
                        print("AuthManager: No UserProfile found for iCloud User \(iCloudRecordName). Creating new UserProfile.")
                        self.createUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                    }
                case .failure(let queryError):
                    print("AuthManager: Error querying UserProfile: \(queryError.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudLoadProfileErrorQuery")): \(queryError.localizedDescription)"
                    self.currentUser = nil; self.isLoggedIn = false; self.isLoading = false
                }
            }
        }
    }

    private func createUserProfile(linkedToICloudUserRecordName iCloudRecordName: String) {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager createUserProfile: iCloud login preference is OFF. Aborting.")
            clearLocalSessionForDisablediCloud(reason: "Profile create called while preference is off.")
            return
        }
        print("AuthManager: Creating new UserProfile linked to iCloud User \(iCloudRecordName) (preference is ON)...")
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
                print("AuthManager DEBUG: Save new UserProfile result. Saved Record ID: \(savedRecord?.recordID.recordName ?? "NIL"), Error: \(error?.localizedDescription ?? "No error")")

                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
                guard currentiCloudPreference else {
                    print("AuthManager createUserProfile callback: iCloud login preference turned OFF. Aborting.")
                    self.clearLocalSessionForDisablediCloud(reason: "Preference changed during profile creation.")
                    self.isLoading = false
                    return
                }

                if let error = error {
                    print("AuthManager: Error saving new UserProfile record: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudCreateProfileErrorSave")): \(error.localizedDescription)"
                    self.currentUser = nil; self.isLoggedIn = false
                    
                    if let ckError = error as? CKError, ckError.code == .constraintViolation {
                        print("AuthManager: Constraint violation while creating UserProfile. Attempting to re-fetch.")
                        self.fetchOrCreateUserProfile(linkedToICloudUserRecordName: iCloudRecordName)
                        return
                    }
                    self.isLoading = false
                    return
                }

                if let record = savedRecord, let finalProfile = UserProfile(from: record) {
                    self.currentUser = finalProfile
                    self.isLoggedIn = true
                    print("AuthManager: New UserProfile successfully created and loaded: \(finalProfile.displayName ?? finalProfile.id)")
                } else {
                    print("AuthManager: Failed to create UserProfile from newly saved record, or save did not return a record.")
                    self.errorMessage = sm.localizedString(forKey: "iCloudParseProfileErrorNew")
                    self.currentUser = nil; self.isLoggedIn = false
                }
                self.isLoading = false
            }
        }
    }
    
    func saveCurrentUserProfile() {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager saveCurrentUserProfile: iCloud login preference is OFF. Cannot save profile.")
            self.errorMessage = localizedErrorMessageForDisablediCloud()
            return
        }

        guard let currentUserProfile = self.currentUser else {
            print("AuthManager: Cannot save profile. No current user.")
            return
        }
        guard iCloudAccountStatus == .available else {
            print("AuthManager: iCloud account not available. Cannot save profile to CloudKit.")
            let sm = SettingsManager()
            self.errorMessage = sm.localizedString(forKey: "iCloudUnavailableCannotSave")
            return
        }
        guard self.iCloudUserActualRecordID != nil else {
            print("AuthManager: Cannot save profile. iCloudUserActualRecordID is unknown.")
            let sm = SettingsManager()
            self.errorMessage = sm.localizedString(forKey: "iCloudUserIdentityIncomplete")
            return
        }

        print("AuthManager: Saving current UserProfile (ID: \(currentUserProfile.id)) to CloudKit (preference is ON)...")
        self.isLoading = true
        let sm = SettingsManager()
        
        let userProfileRecordIDToFetch = CKRecord.ID(recordName: currentUserProfile.id)

        privateDB.fetch(withRecordID: userProfileRecordIDToFetch) { [weak self] (existingRecord, error) in
            DispatchQueue.main.async {
                guard let self = self else { self?.isLoading = false; return }
                
                let currentiCloudPreference = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
                guard currentiCloudPreference else {
                    print("AuthManager saveCurrentUserProfile callback: iCloud login preference turned OFF. Aborting save.")
                    self.isLoading = false
                    return
                }

                var recordToSave: CKRecord
                if let fetchError = error as? CKError, fetchError.code == .unknownItem {
                    print("AuthManager: UserProfile record (ID: \(currentUserProfile.id)) not found during save. Creating new.")
                    recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                } else if let error = error {
                    print("AuthManager: Error fetching existing record before save: \(error.localizedDescription)")
                    self.errorMessage = "\(sm.localizedString(forKey: "iCloudSaveProfileErrorFetch")): \(error.localizedDescription)"
                    self.isLoading = false
                    return
                } else if let fetchedRecord = existingRecord {
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: fetchedRecord)
                } else {
                     print("AuthManager: Unexpected state: no error but no existing record found for ID \(currentUserProfile.id) during save. Creating new.")
                     recordToSave = currentUserProfile.toCKRecord(existingRecord: nil)
                }

                self.privateDB.save(recordToSave) { (savedRecord, saveError) in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let saveError = saveError {
                            print("AuthManager: Error saving UserProfile to CloudKit: \(saveError.localizedDescription)")
                            self.errorMessage = "\(sm.localizedString(forKey: "iCloudSaveProfileErrorWrite")): \(saveError.localizedDescription)"
                        } else {
                            print("AuthManager: UserProfile successfully saved to CloudKit.")
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
        print("AuthManager: Manually refreshing authentication state...")
        self.iCloudUserActualRecordID = nil
        checkiCloudAccountStatusAndFetchProfile()
    }

    public func pseudoLogout() {
        print("AuthManager: Performing pseudo-logout (clearing local app session)...")
        clearLocalSessionForDisablediCloud(reason: "Pseudo-logout called.")
        let sm = SettingsManager()
        self.errorMessage = sm.localizedString(forKey: "loggedOutMessage")
    }

    func updateUserPurchasedThemes(themeIDs: Set<String>) {
        let useiCloud = UserDefaults.standard.object(forKey: AuthManager.useiCloudLoginKey) as? Bool ?? false
        guard useiCloud else {
            print("AuthManager updateUserPurchasedThemes: iCloud login preference is OFF. Cannot update themes on CloudKit.")
            return
        }

        guard var profileToUpdate = self.currentUser else {
            print("AuthManager: Cannot update purchased themes. No current user (or iCloud disabled).")
            return
        }
        
        if profileToUpdate.purchasedThemeIDs != themeIDs {
            profileToUpdate.purchasedThemeIDs = themeIDs
            self.currentUser = profileToUpdate
            print("AuthManager: User's purchased themes updated locally. Attempting to save to CloudKit.")
            saveCurrentUserProfile()
        } else {
            print("AuthManager: No change in purchased themes. Skipping save.")
        }
    }
    //开发者按钮：重置账户付费ID
    func resetPurchasedThemesInCloud() {
        print("AuthManager: Attempting to reset purchased themes in CloudKit...")
        
        // 1. 确保用户已登录
        guard self.isLoggedIn, let profileToUpdate = self.currentUser else {
            print("AuthManager: Cannot reset themes. User is not logged in.")
            return
        }
        
        // 2. 创建一个只包含免费主题ID的集合
        let freeThemeIDs = Set(AppThemeRepository.allThemes.filter { !$0.isPremium }.map { $0.id })
        
        // 3. 检查是否有变化 (例如，如果已经是重置状态，则无需操作)
        if profileToUpdate.purchasedThemeIDs == freeThemeIDs {
            print("AuthManager: Purchased themes are already in a reset state (only free themes). No action needed.")
            return
        }
        
        print("AuthManager: Resetting purchased themes to only include free themes: \(freeThemeIDs)")
        
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

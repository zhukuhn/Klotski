//
//  SettingManager.swift
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

class SettingsManager: ObservableObject {
    @AppStorage("selectedLanguage") var language: String = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "en"
    @AppStorage("isSoundEffectsEnabled") var soundEffectsEnabled: Bool = true
    @AppStorage("isMusicEnabled") var musicEnabled: Bool = true
    @AppStorage("isHapticsEnabled") var hapticsEnabled: Bool = true

    // The 'useiCloudLogin' @AppStorage property has been removed.
    // All iCloud logic will now be handled directly by AuthManager based on account status.

    private let translations: [String: [String: String]] = [
        "en": [
            "gameTitle": "Klotski", "startGame": "Start Game", "continueGame": "Continue Game",
            "selectLevel": "Select Level", "themes": "Themes", "leaderboard": "Leaderboard",
            "settings": "Settings", "login": "Login", "register": "Register", "logout": "Logout", "confirm": "Confirm",
            "loggedInAs": "Logged in as:", "email": "Email", "password": "Password",
            "displayName": "Display Name", "forgotPassword": "Forgot Password?",
            "signInWithApple": "Sign in with Apple", "cancel": "Cancel", "level": "Level",
            "moves": "Moves","bestMoves":"Best", "time": "Time","bestTime": "Best", "noLevels": "No levels available.",
            "themeStore": "Theme Store", "applyTheme": "Apply", "purchase": "Purchase",
            "restorePurchases": "Restore Purchases", "language": "Language",
            "chinese": "简体中文 (Chinese)", "english": "English",
            "soundEffects": "Sound Effects", "music": "Music", "haptics": "Haptics",
            "resetProgress": "Reset Progress",
            "areYouSureReset": "Are you sure you want to reset all game progress? This cannot be undone.",
            "reset": "Reset", "pause": "Pause", "resume": "Resume",
            "backToMenu": "Back to Menu", "victoryTitle": "Congratulations",
            "victoryMessage": "Level Cleared!", "confirmPassword": "Confirm Password",
            "passwordsDoNotMatch": "Passwords do not match!",
            "iCloudSectionTitle": "iCloud & Account",
            "iCloudLoginDisabledMessage": "iCloud login is required for this feature.",
            "openSettings": "Open Settings",
            "iCloudEnableInstructionTitle": "Enable iCloud for Klotski",
            "iCloudEnableInstructionMessage": "To use iCloud features, please ensure Klotski is allowed to use iCloud in your iPhone's Settings:\n\n1. Go to Settings > [Your Name] > iCloud.\n2. Scroll down to 'APPS USING ICLOUD' and tap 'Show All'.\n3. Find Klotski and make sure the switch is ON.",
            "iCloudNoAccount": "Not logged into an iCloud account. Please log in via device settings.",
            "iCloudRestricted": "iCloud account is restricted.",
            "iCloudCouldNotDetermine": "Could not determine iCloud account status.",
            "iCloudTempUnavailable": "iCloud service is temporarily unavailable. Please try again later.",
            "iCloudUnknownStatus": "Unknown iCloud account status.",
            "iCloudFetchUserFailed": "Failed to fetch user identity",
            "iCloudNoUserIdentity": "Failed to retrieve user identity.",
            "iCloudParseProfileErrorExisting": "Failed to parse user information (existing record).",
            "iCloudLoadProfileErrorFetch": "Failed to load user details (fetch error)",
            "iCloudLoadProfileErrorQuery": "Failed to load user information (query error)",
            "defaultPlayerName": "Klotski Player",
            "iCloudCreateProfileErrorSave": "Failed to create user profile (save error)",
            "iCloudParseProfileErrorNew": "Failed to parse user profile after creation.",
            "iCloudUnavailableCannotSave": "iCloud not available. Cannot save user profile.",
            "iCloudUserIdentityIncomplete": "User identity information is incomplete. Cannot save.",
            "iCloudSaveProfileErrorFetch": "Failed to save profile (error fetching existing)",
            "iCloudSaveProfileErrorWrite": "Failed to save user profile (write error)",
            "loggedOutMessage": "You have been signed out from the app.",
            "iCloudCheckingStatus": "Checking iCloud Status...",
            "iCloudUser": "iCloud User",
            "iCloudNoAccountDetailed": "Not logged into iCloud. Go to device settings to enable cloud features.",
            "iCloudConnectionError": "Cannot connect to iCloud.",
            "iCloudSyncError": "iCloud available, but app could not sync user data.",
            "iCloudLoginPrompt": "iCloud features require login. Check settings.",
            "iCloudDisabledInSettings": "iCloud sync is currently unavailable.", // Reworded
            "storeKitErrorUnknown": "An unknown App Store error occurred.",
            "storeKitErrorProductIDsEmpty": "No product identifiers were provided.",
            "storeKitErrorProductsNotFound": "Products not found in the App Store.",
            "storeKitErrorPurchaseFailed": "Purchase failed",
            "storeKitErrorPurchaseCancelled": "Purchase was cancelled.",
            "storeKitErrorPurchasePending": "Purchase is pending.",
            "storeKitErrorTransactionVerificationFailed": "Transaction verification failed.",
            "storeKitErrorFailedToLoadEntitlements": "Failed to load current purchases",
            "storeKitErrorUserCannotMakePayments": "This account cannot make payments.",
            "tryTheme": "Try",
            "startTrialTitle": "Have a Try", "startTrialMessage": "You will have 10 seconds to experience this theme, unlimited times.",
            "trialEnded": "Try Ended", "trialEndedMessage": "Want to buy this theme?",
            "boardSizeError": "Error: Board size calculation is abnormal.",
            "noLevelSelected": "No level selected.",
            "iCloudSynced": "iCloud Synced",
            "iCloudNotSynced": "iCloud Not Synced",
            "levelCategoryClassic": "Classic",
            "levelCategoryEasy": "Easy",
            "levelCategoryMedium": "Medium",
            "levelCategoryHard": "Hard",
            "comingSoon": "Coming Soon...",
            "statusNotCompleted": "Not Completed",
            "bestScoreFormat": "Best: %d moves", // %d 将被替换为步数
            "loadingLeaderboards": "Loading Leaderboards...",
            "loadingFailed": "Failed to Load",
            "noLeaderboards": "No Leaderboards Available",
            "leaderboardSetupNote": "Please configure leaderboards in App Store Connect.",
            "gameCenterLoginRequired": "Game Center Login Required",
            "gameCenterLoginPrompt": "Log in to view global leaderboards.",
            "goToSettings": "Go to Settings",
            "settingsGeneral": "General",
            "settingsAudioHaptics": "Audio & Haptics",
            "settingsGameData": "Game Data",
            "settingsDeveloper": "Developer Options",
            "settingsICloudStatus": "iCloud Sync Status",
            "resetICloudPurchases": "Reset iCloud Purchased Themes",
            "statusLoggedIn": "Logged In",
            "statusNotLoggedIn": "Not Logged In",
            "iCloudSyncDescription": "Your game progress and purchased items are synced with iCloud.",
            "default": "Classic Light",
            "dark": "Deep Night",
            "forest": "Fresh Green",
            "auroraGlass": "Amethyst Moon",
            "memphisPop": "Memphis Pop",
            "woodcut": "Wooden Charm",
            "mechanism": "Crimson Rock",
            "restorePurchases_description": "If you have purchased themes on other devices, you can restore them here",
            "settingsAboutSupport": "About & Support",
            "settingsContact": "Contact the author",
            "settingsRateApp": "Rate on the App Store",
            "settingsPrivacyPolicy": "Privacy policy",
            "settingsVersion": "Version",
            "settingsDataManagement": "Data management",
            "levelCategoryMore": "More levels",
            "leaderBoardInfo": "There is a delay in data update, please be patient"
        ],
        "zh": [
            "gameTitle": "华容道", "startGame": "开始游戏", "continueGame": "继续游戏",
            "selectLevel": "选择关卡", "themes": "主题", "leaderboard": "排行榜",
            "settings": "设置", "login": "登录", "register": "注册", "logout": "注销", "confirm": "确认",
            "loggedInAs": "已登录:", "email": "邮箱", "password": "密码",
            "displayName": "昵称", "forgotPassword": "忘记密码?",
            "signInWithApple": "通过Apple登录", "cancel": "取消", "level": "关卡",
            "moves": "步数", "bestMoves":"最佳", "time": "时间","bestTime": "最佳", "noLevels": "暂无可用关卡。",
            "themeStore": "主题商店", "applyTheme": "应用", "purchase": "购买",
            "restorePurchases": "恢复购买", "language": "语言",
            "chinese": "简体中文", "english": "English (英文)",
            "soundEffects": "音效", "music": "音乐", "haptics": "触感反馈",
            "resetProgress": "重置进度",
            "areYouSureReset": "您确定要重置所有游戏进度吗？此操作无法撤销。",
            "reset": "重置", "pause": "暂停", "resume": "继续",
            "backToMenu": "返回主菜单", "victoryTitle": "恭喜获胜!",
            "victoryMessage": "成功过关!", "confirmPassword": "确认密码",
            "passwordsDoNotMatch": "两次输入的密码不一致！",
            "iCloudSectionTitle": "iCloud与账户",
            "iCloudLoginDisabledMessage": "此功能需要iCloud登录。",
            "openSettings": "打开设置",
            "iCloudEnableInstructionTitle": "为“华容道”启用iCloud",
            "iCloudEnableInstructionMessage": "要使用iCloud功能，请确保在您的iPhone设置中允许“华容道”使用iCloud：\n\n1. 前往 设置 > [您的姓名] > iCloud。\n2. 向下滚动到“使用ICLOUD的应用”，并轻点“显示全部”。\n3. 找到“华容道”并确保其开关已打开。",
            "iCloudNoAccount": "未登录iCloud账户。请在设备设置中登录。",
            "iCloudRestricted": "iCloud账户受限。",
            "iCloudCouldNotDetermine": "无法确定iCloud账户状态。",
            "iCloudTempUnavailable": "iCloud服务暂时不可用，请稍后再试。",
            "iCloudUnknownStatus": "未知的iCloud账户状态。",
            "iCloudFetchUserFailed": "获取用户身份失败",
            "iCloudNoUserIdentity": "未能检索到用户身份。",
            "iCloudParseProfileErrorExisting": "解析用户信息失败（已存在记录）。",
            "iCloudLoadProfileErrorFetch": "加载用户详情失败（获取错误）",
            "iCloudLoadProfileErrorQuery": "加载用户信息失败（查询错误）",
            "defaultPlayerName": "华容道玩家",
            "iCloudCreateProfileErrorSave": "创建用户配置失败（保存错误）",
            "iCloudParseProfileErrorNew": "创建后解析用户配置失败。",
            "iCloudUnavailableCannotSave": "iCloud不可用。无法保存用户配置。",
            "iCloudUserIdentityIncomplete": "用户身份信息不完整。无法保存。",
            "iCloudSaveProfileErrorFetch": "保存配置失败（获取现有配置错误）",
            "iCloudSaveProfileErrorWrite": "保存用户配置失败（写入错误）",
            "loggedOutMessage": "您已从此应用注销。",
            "iCloudCheckingStatus": "正在检查iCloud状态...",
            "iCloudUser": "iCloud用户",
            "iCloudNoAccountDetailed": "未登录iCloud账户。请前往设备设置登录以使用云功能。",
            "iCloudConnectionError": "无法连接到iCloud。",
            "iCloudSyncError": "iCloud可用，但应用未能同步用户数据。",
            "iCloudLoginPrompt": "iCloud功能需要登录。请检查设置。",
            "iCloudDisabledInSettings": "iCloud同步功能当前不可用。",
            "storeKitErrorUnknown": "发生未知App Store错误。",
            "storeKitErrorProductIDsEmpty": "未提供产品ID。",
            "storeKitErrorProductsNotFound": "在App Store中未找到产品。",
            "storeKitErrorPurchaseFailed": "购买失败",
            "storeKitErrorPurchaseCancelled": "购买已取消。",
            "storeKitErrorPurchasePending": "购买待处理。",
            "storeKitErrorTransactionVerificationFailed": "交易验证失败。",
            "storeKitErrorFailedToLoadEntitlements": "加载当前购买项目失败",
            "storeKitErrorUserCannotMakePayments": "此账户无法进行支付。",
            "tryTheme": "试用",
            "startTrialTitle": "开始试用", "startTrialMessage": "您将有10秒钟体验此主题，次数不限",
            "trialEnded": "试用结束", "trialEndedMessage": "是否购买该主题？",
            "boardSizeError": "错误：棋盘尺寸计算异常。",
            "noLevelSelected": "未选择关卡。",
            "iCloudSynced": "iCloud已同步",
            "iCloudNotSynced": "iCloud未同步",
            "levelCategoryClassic": "最经典",
            "levelCategoryEasy": "简单",
            "levelCategoryMedium": "中等",
            "levelCategoryHard": "困难",
            "comingSoon": "敬请期待...",
            "statusNotCompleted": "未完成",
            "bestScoreFormat": "最佳: %d 步", // %d 将被替换为步数
            "loadingLeaderboards": "正在加载排行榜...",
            "loadingFailed": "加载失败",
            "noLeaderboards": "暂无排行榜",
            "leaderboardSetupNote": "请在 App Store Connect 中配置排行榜。",
            "gameCenterLoginRequired": "需要登录 Game Center",
            "gameCenterLoginPrompt": "登录后即可查看全球玩家排行榜。",
            "goToSettings": "前往手机设置",
            "settingsGeneral": "通用设置",
            "settingsAudioHaptics": "音频与触感",
            "settingsGameData": "游戏数据",
            "settingsDeveloper": "开发者选项",
            "settingsICloudStatus": "iCloud 同步状态",
            "resetICloudPurchases": "重置 iCloud 已购主题",
            "statusLoggedIn": "已登录",
            "statusNotLoggedIn": "未登录",
            "iCloudSyncDescription": "你的游戏进度和已购项目已开启云同步。",
            "default": "经典浅色",
            "dark": "深邃暗黑",
            "forest": "清新绿意",
            "auroraGlass": "琉璃月色",
            "memphisPop": "孟菲斯波普",
            "woodcut": "沉香木韵",
            "mechanism": "热烈砂岩",
            "restorePurchases_description": "如果您在其他设备上购买过主题，可在此恢复",
            "settingsAboutSupport": "关于与支持",
            "settingsContact": "联系作者",
            "settingsRateApp": "在 App Store 上评分",
            "settingsPrivacyPolicy": "隐私政策",
            "settingsVersion": "版本号",
            "settingsDataManagement": "数据管理",
            "levelCategoryMore": "更多关卡",
            "leaderBoardInfo": "数据更新有延迟，请耐心等待",

        ]
    ]

    func localizedString(forKey key: String) -> String {
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }
}

struct SoundManager {
    private static var audioPlayer: AVAudioPlayer?
    private static let hapticNotificationGenerator = UINotificationFeedbackGenerator()
    private static let hapticImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    static func playSound(named soundName: String, type: String = "mp3", settings: SettingsManager) {
        guard settings.soundEffectsEnabled else { return }
        debugLog("SoundManager: Playing sound '\(soundName)' (if enabled and sound file exists)")
    }

    static func playHapticNotification(type: UINotificationFeedbackGenerator.FeedbackType, settings: SettingsManager) {
        guard settings.hapticsEnabled else { return }
        hapticNotificationGenerator.prepare()
        hapticNotificationGenerator.notificationOccurred(type)
        debugLog("SoundManager: Playing haptic notification \(type) (if enabled)")
    }

    static func playImpactHaptic(settings: SettingsManager) {
        guard settings.hapticsEnabled else { return }
        hapticImpactGenerator.prepare()
        hapticImpactGenerator.impactOccurred()
        debugLog("SoundManager: Playing impact haptic (if enabled)")
    }
}

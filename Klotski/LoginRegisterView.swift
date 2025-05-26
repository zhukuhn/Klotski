//
//  LoginRegisterView.swift
//  Klotski
//
//  Created by zhukun on 2025/5/18.
//

import SwiftUI
import AuthenticationServices

// Common UI for Login and Register text fields
struct AuthTextFieldStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager // 从环境中获取主题管理器

    func body(content: Content) -> some View {
        content // TextField 或 SecureField
           .padding(12) // 内边距
           .background(themeManager.currentTheme.boardBackgroundColor.color.opacity(0.5)) // 使用主题背景色的半透明版本作为输入框背景
           .cornerRadius(8) // 圆角
           .overlay(
                // 添加边框
                RoundedRectangle(cornerRadius: 8)
                   .stroke(themeManager.currentTheme.sliderColor.color.opacity(0.3), lineWidth: 1)
            )
           .foregroundColor(themeManager.currentTheme.sliderTextColor.color) // 输入文字的颜色
           .accentColor(themeManager.currentTheme.sliderColor.color) // 光标和选择高亮颜色
    }
}


// MARK: - LoginView (登录视图)
struct LoginView: View {
    // MARK: Environment Objects & State
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss // 用于关闭当前视图 (sheet)

    @State private var email = ""    // 存储用户输入的邮箱
    @State private var password = "" // 存储用户输入的密码
    // internalIsLoading 可以移除，直接依赖 authManager.isLoading

    // MARK: Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) { // 主垂直堆栈
                // 登录标题
                Text(settingsManager.localizedString(forKey: "login"))
                   .font(.system(size: 32, weight: .bold, design: .rounded))
                   .padding(.bottom, 30)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)

                // 邮箱输入框
                TextField(settingsManager.localizedString(forKey: "email"), text: $email)
                   .keyboardType(.emailAddress) // 设置键盘类型为邮箱地址
                   .autocapitalization(.none)   // 关闭自动大写
                   .textContentType(.emailAddress) // 帮助密码管理器填充
                   .modifier(AuthTextFieldStyle()) // 应用统一样式

                // 密码输入框
                SecureField(settingsManager.localizedString(forKey: "password"), text: $password)
                   .textContentType(.password) // 帮助密码管理器填充
                   .modifier(AuthTextFieldStyle())
                
                // 登录按钮
                Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    // authManager.isLoading 会在 authManager 内部的异步操作开始时设置为 true
                    authManager.login(email: email, pass: password)
                }) {
                    if authManager.isLoading { // 直接使用 authManager.isLoading
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.backgroundColor.color))
                            .frame(height: 20) // 给 ProgressView 一个固定高度，避免按钮跳动
                    } else {
                        Text(settingsManager.localizedString(forKey: "login"))
                    }
                }
               .buttonStyle(MenuButtonStyle(themeManager: themeManager)) // 使用主菜单按钮样式
               .disabled(email.isEmpty || password.isEmpty || authManager.isLoading) // 使用 authManager.isLoading
                
                // "忘记密码?" 按钮 (功能待实现)
                Button(settingsManager.localizedString(forKey: "forgotPassword")) {
                    // TODO: 实现忘记密码流程 (例如，显示另一个 sheet 或导航到新视图)
                    print("“忘记密码”被点击")
                }
               .font(.caption)
               .tint(themeManager.currentTheme.sliderColor.color)
                
                Divider().padding(.vertical) // 分隔线
                
                // "通过 Apple 登录" 按钮
                SignInWithAppleButton(
                    onRequest: { request in
                        let appleRequest = authManager.createAppleSignInRequest()
                        request.requestedScopes = appleRequest.requestedScopes
                        request.nonce = appleRequest.nonce
                    },
                    onCompletion: { result in
                        switch result {
                            case .success(let authorization):
                            authManager.handleAppleSignIn(authorization: authorization)
                            case .failure(let error):
                            authManager.handleAppleSignInError(error: error)
                        }
                    }
                )
                .signInWithAppleButtonStyle(themeManager.currentTheme.swiftUIScheme == .dark ? .white : .black) // 根据主题调整按钮样式
                .frame(height: 50) // 设置按钮高度
                .frame(maxWidth: 280) // 与其他按钮宽度一致
                .cornerRadius(12) // 保持与其他按钮一致的圆角
                .disabled(authManager.isLoading) // 认证进行中时禁用

                // 显示错误信息
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                        // 错误信息显示后一段时间自动清除，或用户开始输入时清除
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // 5秒后清除
                                if authManager.errorMessage == errorMessage { // 仅当还是同一个错误时清除
                                    authManager.errorMessage = nil
                                }
                            }
                        }
                }
                Spacer() // 将内容推向顶部
            }
           .padding(30) // 内容区域的内边距
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea()) // 背景色
           .navigationTitle(settingsManager.localizedString(forKey: "login")) // 导航栏标题
           .navigationBarTitleDisplayMode(.inline) // 标题显示模式
           .toolbar {
                // 导航栏右侧的“取消”按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsManager.localizedString(forKey: "cancel")) {
                        SoundManager.playImpactHaptic(settings: settingsManager)
                        dismiss() // 关闭 sheet
                    }
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
           // 监听登录状态的变化，如果登录成功，则关闭 sheet
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
               if newValue { // 如果 isLoggedIn 变为 true (登录成功)
                    dismiss()     // 关闭登录视图
                }
            }
           .onAppear {
               authManager.errorMessage = nil // 视图出现时清除可能残留的错误信息
           }
        }
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme) // 应用主题
    }
}

// MARK: - RegisterView (注册视图)
struct RegisterView: View {
    // MARK: Environment Objects & State
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = "" // 添加确认密码字段

    // 计算属性，检查密码是否匹配且不为空
    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    // 计算属性，检查所有必填字段是否已填写
    private var allFieldsFilled: Bool {
        !email.isEmpty && !displayName.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }

    // MARK: Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(settingsManager.localizedString(forKey: "register"))
                   .font(.system(size: 32, weight: .bold, design: .rounded))
                   .padding(.bottom,30)
                   .foregroundColor(themeManager.currentTheme.sliderColor.color)

                // 昵称输入框
                TextField(settingsManager.localizedString(forKey: "displayName"), text: $displayName)
                   .textContentType(.nickname) // 帮助密码管理器
                   .modifier(AuthTextFieldStyle())

                // 邮箱输入框
                TextField(settingsManager.localizedString(forKey: "email"), text: $email)
                   .keyboardType(.emailAddress)
                   .autocapitalization(.none)
                   .textContentType(.emailAddress)
                   .modifier(AuthTextFieldStyle())

                // 密码输入框
                SecureField(settingsManager.localizedString(forKey: "password"), text: $password)
                   .textContentType(.newPassword) // 提示这是新密码
                   .modifier(AuthTextFieldStyle())
                
                // 确认密码输入框
                SecureField(settingsManager.localizedString(forKey: "confirmPassword"), text: $confirmPassword)
                   .textContentType(.newPassword)
                   .modifier(AuthTextFieldStyle())
                
                // 如果密码不匹配且确认密码框非空，显示提示
                if !passwordsMatch && !confirmPassword.isEmpty && !password.isEmpty {
                    Text(settingsManager.localizedString(forKey: "passwordsDoNotMatch"))
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 注册按钮
                Button(action: {
                    SoundManager.playImpactHaptic(settings: settingsManager)
                    authManager.register(email: email, pass: password, displayName: displayName)
                }) {
                    if authManager.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.backgroundColor.color))
                            .frame(height: 20)
                    } else {
                        Text(settingsManager.localizedString(forKey: "register"))
                    }
                }
               .buttonStyle(MenuButtonStyle(themeManager: themeManager))
               // 禁用条件：字段未填满 或 密码不匹配 或 正在加载
               .disabled(!allFieldsFilled || !passwordsMatch || authManager.isLoading)

                // 显示错误信息
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                if authManager.errorMessage == errorMessage {
                                    authManager.errorMessage = nil
                                }
                            }
                        }
                }
                Spacer()
            }
           .padding(30)
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .background(themeManager.currentTheme.backgroundColor.color.ignoresSafeArea())
           .navigationTitle(settingsManager.localizedString(forKey: "register"))
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsManager.localizedString(forKey: "cancel")) {
                        SoundManager.playImpactHaptic(settings: settingsManager)
                        dismiss()
                    }
                   .tint(themeManager.currentTheme.sliderColor.color)
                }
            }
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
                if newValue { // 注册并登录成功
                    dismiss()
                }
            }
           .onAppear {
               authManager.errorMessage = nil // 视图出现时清除错误信息
           }
        }
        .preferredColorScheme(themeManager.currentTheme.swiftUIScheme)
    }
}

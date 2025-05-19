//
//  LoginRegisterView.swift
//  Klotski
//
//  Created by zhukun on 2025/5/18.
//

import SwiftUI

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
           .onChange(of: authManager.isLoggedIn) { oldValue, newValue in //这里正常没有报错
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

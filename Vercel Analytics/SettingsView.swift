import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var api: VercelAPIService
    @State private var showLogoutConfirm = false
    @State private var newToken = ""
    @State private var isEditingToken = false
    @State private var showLicense = false
    @AppStorage("useLightTheme") private var useLightTheme = false

    var scheme: ColorScheme { useLightTheme ? .light : .dark }

    var maskedToken: String {
        let t = api.token
        if t.count <= 8 { return String(repeating: "*", count: t.count) }
        return String(t.prefix(6)) + String(repeating: "*", count: t.count - 10) + String(t.suffix(4))
    }

    var rowBg: Color { useLightTheme ? Color.black.opacity(0.04) : Color.white.opacity(0.05) }
    var textColor: Color { useLightTheme ? .black : .white }
    var subColor: Color { useLightTheme ? Color.black.opacity(0.4) : Color.white.opacity(0.4) }
    var bgColor: Color { useLightTheme ? Color(red: 0.95, green: 0.95, blue: 0.97) : .black }
    var headerColor: Color { useLightTheme ? Color.black.opacity(0.35) : Color.white.opacity(0.3) }

    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()

                List {
                    // Account
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(useLightTheme ? Color.black : Color.white)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "triangle.fill")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(useLightTheme ? .white : .black)
                                    .offset(y: 1)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vercel Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(textColor)
                                Text("\(api.projects.count) project\(api.projects.count == 1 ? "" : "s") connected")
                                    .font(.system(size: 13))
                                    .foregroundColor(subColor)
                            }
                            Spacer()
                            Circle()
                                .fill(Color(red: 0.3, green: 0.9, blue: 0.5))
                                .frame(width: 8, height: 8)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(rowBg)
                    } header: { sectionHeader("ACCOUNT") }

                    // Token
                    Section {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14))
                                .foregroundColor(subColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("API Token")
                                    .font(.system(size: 15))
                                    .foregroundColor(textColor)
                                Text(maskedToken)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(subColor)
                            }
                            Spacer()
                            Button("Update") { isEditingToken = true }
                                .font(.system(size: 13))
                                .foregroundColor(subColor)
                        }
                        .listRowBackground(rowBg)
                    } header: { sectionHeader("TOKEN") }

                    // Preferences
                    Section {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 14))
                                .foregroundColor(subColor)
                                .frame(width: 24)
                            Text("Light Theme")
                                .font(.system(size: 15))
                                .foregroundColor(textColor)
                            Spacer()
                            Toggle("", isOn: $useLightTheme)
                                .labelsHidden()
                                .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                        }
                        .listRowBackground(rowBg)
                    } header: { sectionHeader("PREFERENCES") }

                    // About
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(subColor)
                                .frame(width: 24)
                            Text("Version")
                                .font(.system(size: 15))
                                .foregroundColor(textColor)
                            Spacer()
                            Text("1.0.0")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(subColor)
                        }
                        .listRowBackground(rowBg)

                        HStack {
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 14))
                                .foregroundColor(subColor)
                                .frame(width: 24)
                            Text("Made by Kayan Shah")
                                .font(.system(size: 15))
                                .foregroundColor(textColor)
                            Spacer()
                            Link("GitHub", destination: URL(string: "https://github.com/kayanshah")!)
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1))
                        }
                        .listRowBackground(rowBg)

                        Button(action: { showLicense = true }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(subColor)
                                    .frame(width: 24)
                                Text("License")
                                    .font(.system(size: 15))
                                    .foregroundColor(textColor)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(subColor)
                            }
                        }
                        .listRowBackground(rowBg)
                    } header: { sectionHeader("ABOUT") }

                    // Sign out
                    Section {
                        Button(action: { showLogoutConfirm = true }) {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(red: 1, green: 0.2, blue: 0.2).opacity(0.08))
                    }

                    // Copyright footer
                    Section {
                        HStack {
                            Spacer()
                            Text("© \(Calendar.current.component(.year, from: Date())) Kayan Shah. All rights reserved.")
                                .font(.system(size: 12))
                                .foregroundColor(subColor)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(scheme)
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) { api.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your API token will be removed from this device.")
            }
            .sheet(isPresented: $isEditingToken) {
                UpdateTokenView(token: $newToken, isDark: !useLightTheme) {
                    if !newToken.isEmpty {
                        api.setToken(newToken)
                        newToken = ""
                    }
                    isEditingToken = false
                }
            }
            .sheet(isPresented: $showLicense) {
                LicenseView(isDark: !useLightTheme)
            }
        }
        .preferredColorScheme(scheme)
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(headerColor)
            .kerning(1.5)
    }
}

struct LicenseView: View {
    let isDark: Bool
    @Environment(\.dismiss) var dismiss

    let licenseText = """
MIT License

Copyright © 2026 Kayan Shah
GitHub: https://github.com/kayanshah

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

1. Attribution Requirement
Any use, modification, distribution, or incorporation of this Software — in whole or in part — must include clear and prominent attribution to the original author:

    Kayan Shah
    GitHub: https://github.com/kayanshah

This attribution must appear in all copies, substantial portions of the Software, documentation, and any derivative works.

2. The above copyright notice, this attribution requirement, and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

    var body: some View {
        ZStack {
            (isDark ? Color(red: 0.07, green: 0.07, blue: 0.07) : Color(red: 0.95, green: 0.95, blue: 0.97))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("License")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isDark ? .white : .black)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                ScrollView {
                    Text(licenseText)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.65))
                        .lineSpacing(5)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

struct UpdateTokenView: View {
    @Binding var token: String
    let isDark: Bool
    let onSave: () -> Void

    var body: some View {
        ZStack {
            (isDark ? Color(red: 0.07, green: 0.07, blue: 0.07) : Color(red: 0.95, green: 0.95, blue: 0.97))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("Update API Token")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isDark ? .white : .black)

                SecureField("", text: $token,
                    prompt: Text("Paste new token here")
                        .foregroundColor(isDark ? Color.white.opacity(0.2) : Color.black.opacity(0.25)))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(isDark ? .white : .black)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.12), lineWidth: 1))
                    )

                Button(action: onSave) {
                    Text("Save Token")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isDark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(isDark ? Color.white : Color.black))
                }

                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }
}

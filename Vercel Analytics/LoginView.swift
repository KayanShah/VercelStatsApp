import SwiftUI

struct LoginView: View {
    @EnvironmentObject var api: VercelAPIService
    @State private var token = ""
    @State private var showingHelp = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Subtle grid
            GeometryReader { geo in
                Canvas { ctx, size in
                    let spacing: CGFloat = 40
                    ctx.opacity = 0.04
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo area
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.black)
                            .offset(y: 2)
                    }
                    
                    Text("Vercel Analytics")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Connect your account to view\nlive analytics for all your projects.")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer().frame(height: 52)
                
                // Token input
                VStack(alignment: .leading, spacing: 12) {
                    Text("API TOKEN")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.4))
                        .kerning(1.5)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.3))
                        
                        SecureField("", text: $token, prompt: Text("vercel_XXXXXXXXXXXXXXXX").foregroundColor(Color.white.opacity(0.2)))
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(token.isEmpty ? 0.1 : 0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 16)
                
                // Help text
                Button(action: { showingHelp = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("How to get your API token")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color.white.opacity(0.35))
                }
                
                Spacer().frame(height: 32)
                
                // Connect button
                Button(action: {
                    let trimmed = token.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    api.setToken(trimmed)
                }) {
                    HStack(spacing: 10) {
                        if api.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        Text(api.isLoading ? "Connecting..." : "Connect Account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(token.isEmpty ? Color.white.opacity(0.3) : Color.white)
                    )
                }
                .disabled(token.isEmpty || api.isLoading)
                .padding(.horizontal, 24)
                
                if let error = api.error {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Footer
                Text("Your token is stored locally and never shared.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.2))
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingHelp) {
            TokenHelpView()
        }
    }
}

struct TokenHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Getting Your API Token")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.white))
                            
                            Text(step)
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Text("vercel.com/account/tokens")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.6))
                    )
                    .frame(height: 44)
                
                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }
    
    let steps = [
        "Go to vercel.com and sign in to your account.",
        "Click your profile picture, then go to Account Settings.",
        "Select the Tokens tab from the left sidebar.",
        "Click Create Token, give it a name, and select Full Account scope.",
        "Copy the token and paste it into the app."
    ]
}

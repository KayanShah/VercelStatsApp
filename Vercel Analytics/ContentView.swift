import SwiftUI

struct ContentView: View {
    @StateObject private var api = VercelAPIService()
    @AppStorage("useLightTheme") private var useLightTheme = false

    var body: some View {
        Group {
            if api.isAuthenticated {
                MainTabView()
                    .environmentObject(api)
            } else {
                LoginView()
                    .environmentObject(api)
            }
        }
        .onAppear {
            api.loadSavedToken()
        }
        .preferredColorScheme(useLightTheme ? .light : .dark)
    }
}

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var api: VercelAPIService
    
    var body: some View {
        TabView {
            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
            
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "square.stack.3d.up.fill")
                }
            
            DeploymentsView()
                .tabItem {
                    Label("Deployments", systemImage: "arrow.up.circle.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
    }
}

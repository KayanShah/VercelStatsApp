import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var api: VercelAPIService
    @State private var searchText = ""
    
    var filtered: [VercelProject] {
        if searchText.isEmpty { return api.projects }
        return api.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if api.projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 40))
                            .foregroundColor(Color.white.opacity(0.15))
                        Text("No projects found")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                } else {
                    List {
                        ForEach(filtered) { project in
                            ProjectRowView(project: project)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search projects")
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Projects")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                api.fetchProjects()
            }
        }
    }
}

struct ProjectRowView: View {
    @EnvironmentObject var api: VercelAPIService
    let project: VercelProject
    
    var latestDeployment: Deployment? {
        project.latestDeployments?.first
    }
    
    var body: some View {
        Button(action: {
            api.selectedProject = project
            api.fetchAnalytics(for: project, period: "7d")
        }) {
            HStack(spacing: 14) {
                // Project icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Text(String(project.name.prefix(1).uppercased()))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if api.selectedProject?.id == project.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.5))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if let fw = project.framework {
                            Text(fw)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        
                        if let dep = latestDeployment {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(stateColor(dep.stateEnum))
                                    .frame(width: 6, height: 6)
                                Text(dep.stateEnum.label)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(api.selectedProject?.id == project.id ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                api.selectedProject?.id == project.id ? Color.white.opacity(0.2) : Color.white.opacity(0.07),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    func stateColor(_ state: DeploymentState) -> Color {
        switch state {
        case .ready: return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .error: return Color(red: 1, green: 0.35, blue: 0.35)
        case .building: return Color(red: 1, green: 0.75, blue: 0.2)
        default: return Color.white.opacity(0.3)
        }
    }
}

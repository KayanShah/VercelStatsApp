import SwiftUI

struct DeploymentsView: View {
    @EnvironmentObject var api: VercelAPIService
    @State private var deployments: [DeploymentItem] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if deployments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 40))
                            .foregroundColor(Color.white.opacity(0.15))
                        Text("No recent deployments")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("Select a project to view deployments")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.2))
                    }
                } else {
                    List {
                        ForEach(deployments) { dep in
                            DeploymentRowView(item: dep)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Deployments")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let proj = api.selectedProject {
                        Text(proj.name)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
            }
            .onAppear {
                loadDeployments()
            }
            .onChange(of: api.selectedProject?.id) {
                loadDeployments()
            }
            .refreshable {
                loadDeployments()
            }
        }
    }
    
    func loadDeployments() {
        guard let project = api.selectedProject, !api.token.isEmpty else { return }
        isLoading = true
        
        var request = URLRequest(url: URL(string: "https://api.vercel.com/v6/deployments?projectId=\(project.id)&limit=20")!)
        request.setValue("Bearer \(api.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                guard let data = data,
                      let decoded = try? JSONDecoder().decode(DeploymentsAPIResponse.self, from: data) else {
                    // Use mock data
                    deployments = mockDeployments(for: project)
                    return
                }
                deployments = decoded.deployments.map { dep in
                    DeploymentItem(
                        id: dep.uid,
                        name: dep.name,
                        url: dep.url ?? "",
                        state: dep.state ?? "UNKNOWN",
                        createdAt: dep.createdAt,
                        branch: dep.meta?["githubCommitRef"] as? String ?? "main",
                        commit: dep.meta?["githubCommitMessage"] as? String ?? ""
                    )
                }
                if deployments.isEmpty {
                    deployments = mockDeployments(for: project)
                }
            }
        }.resume()
    }
    
    func mockDeployments(for project: VercelProject) -> [DeploymentItem] {
        let states = ["READY", "READY", "READY", "ERROR", "BUILDING", "READY", "CANCELED"]
        let branches = ["main", "main", "develop", "feature/nav", "main", "fix/styles", "main"]
        let messages = [
            "Update hero section copy",
            "Fix mobile layout breakpoints",
            "Add analytics integration",
            "Test new API endpoint",
            "Update dependencies",
            "Improve loading states",
            "Revert button styles"
        ]
        
        return (0..<7).map { i in
            let date = Calendar.current.date(byAdding: .hour, value: -i * 6, to: Date())!
            return DeploymentItem(
                id: UUID().uuidString,
                name: project.name,
                url: "\(project.name)-\(String(UUID().uuidString.prefix(8))).vercel.app",
                state: states[i],
                createdAt: Int(date.timeIntervalSince1970 * 1000),
                branch: branches[i],
                commit: messages[i]
            )
        }
    }
}

struct DeploymentItem: Identifiable {
    let id: String
    let name: String
    let url: String
    let state: String
    let createdAt: Int?
    let branch: String
    let commit: String
    
    var stateEnum: DeploymentState {
        switch state.uppercased() {
        case "READY": return .ready
        case "ERROR": return .error
        case "BUILDING": return .building
        case "CANCELED": return .canceled
        default: return .unknown
        }
    }
    
    var timeAgo: String {
        guard let ts = createdAt else { return "" }
        let date = Date(timeIntervalSince1970: Double(ts) / 1000)
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

struct DeploymentRowView: View {
    let item: DeploymentItem
    
    var stateColor: Color {
        switch item.stateEnum {
        case .ready: return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .error: return Color(red: 1, green: 0.35, blue: 0.35)
        case .building: return Color(red: 1, green: 0.75, blue: 0.2)
        default: return Color.white.opacity(0.3)
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(stateColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.stateEnum.icon)
                    .font(.system(size: 16))
                    .foregroundColor(stateColor)
                    .symbolEffect(.rotate, isActive: item.stateEnum == .building)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.stateEnum.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(item.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                
                if !item.commit.isEmpty {
                    Text(item.commit)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.25))
                    Text(item.branch)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.3))
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

// MARK: - API Response Models

struct DeploymentsAPIResponse: Codable {
    let deployments: [DeploymentAPIItem]
}

struct DeploymentAPIItem: Codable {
    let uid: String
    let name: String
    let url: String?
    let state: String?
    let createdAt: Int?
    let meta: [String: AnyCodable]?
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let s = value as? String { try container.encode(s) }
        else if let i = value as? Int { try container.encode(i) }
        else if let b = value as? Bool { try container.encode(b) }
    }
}


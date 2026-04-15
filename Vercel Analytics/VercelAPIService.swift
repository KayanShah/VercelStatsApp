import Foundation
import Combine

// MARK: - Models

struct VercelProject: Identifiable, Codable {
    let id: String
    let name: String
    let framework: String?
    let latestDeployments: [Deployment]?

    enum CodingKeys: String, CodingKey {
        case id, name, framework, latestDeployments
    }
}

struct Deployment: Identifiable, Codable {
    let id: String
    let url: String?
    let state: String?
    let createdAt: Int?
    let readyAt: Int?

    var stateEnum: DeploymentState {
        switch state?.uppercased() {
        case "READY": return .ready
        case "ERROR": return .error
        case "BUILDING": return .building
        case "CANCELED": return .canceled
        default: return .unknown
        }
    }
}

enum DeploymentState {
    case ready, error, building, canceled, unknown

    var label: String {
        switch self {
        case .ready: return "Ready"
        case .error: return "Error"
        case .building: return "Building"
        case .canceled: return "Canceled"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .building: return "arrow.triangle.2.circlepath"
        case .canceled: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

struct ProjectsResponse: Codable {
    let projects: [VercelProject]
}

// MARK: - Analytics Summary

struct AnalyticsSummary {
    var totalVisits: Int = 0
    var uniqueVisitors: Int = 0
    var pageViews: Int = 0
    var bounceRate: Double = 0
    var topPages: [PageStat] = []
    var topCountries: [CountryStat] = []
    var visitsByDay: [DayStat] = []
    var topDevices: [SimpleStat] = []
    var topBrowsers: [SimpleStat] = []
    var topOS: [SimpleStat] = []
}

struct PageStat: Identifiable {
    let id = UUID()
    let path: String
    let visits: Int
    let percentage: Double
}

struct CountryStat: Identifiable {
    let id = UUID()
    let country: String
    let flag: String
    let visits: Int
    let percentage: Double
}

struct DayStat: Identifiable {
    let id = UUID()
    let date: String
    let visits: Int
}

struct SimpleStat: Identifiable {
    let id = UUID()
    let label: String
    let visits: Int
    let percentage: Double
}

// MARK: - API Response Models

// Overview: {"total":202,"devices":11,"bounceRate":27}
struct OverviewResponse: Codable {
    let total: Int?
    let devices: Int?
    let bounceRate: Double?
}

// Timeseries: {"data":{"groups":{"all":[...]}}}
struct TimeseriesResponse: Codable {
    let data: TimeseriesData?
}
struct TimeseriesData: Codable {
    let groups: TimeseriesGroups?
}
struct TimeseriesGroups: Codable {
    let all: [TimeseriesPoint]?
}
struct TimeseriesPoint: Codable {
    let key: String?
    let total: Int?
    let devices: Int?
}

// Stats: {"data":[{"key":"...","total":0,"devices":0}]}
struct StatsResponse: Codable {
    let data: [StatItem]?
}
struct StatItem: Codable {
    let key: String?
    let total: Int?
    let devices: Int?
}

// MARK: - API Service

class VercelAPIService: ObservableObject {
    @Published var projects: [VercelProject] = []
    @Published var selectedProject: VercelProject?
    @Published var analyticsSummary: AnalyticsSummary = AnalyticsSummary()
    @Published var isLoading = false
    @Published var error: String?
    @Published var isAuthenticated = false

    var token: String = ""

    private let teamId = "team_ph89eTYAm8vbkQvENuvEgOPT"
    private let baseURL = "https://api.vercel.com"
    private let analyticsBase = "https://vercel.com/api/web-analytics"

    func setToken(_ token: String) {
        self.token = token
        UserDefaults.standard.set(token, forKey: "vercel_token")
        fetchProjects()
    }

    func loadSavedToken() {
        if let saved = UserDefaults.standard.string(forKey: "vercel_token"), !saved.isEmpty {
            token = saved
            isAuthenticated = true
            fetchProjects()
        }
    }

    func logout() {
        token = ""
        UserDefaults.standard.removeObject(forKey: "vercel_token")
        projects = []
        selectedProject = nil
        isAuthenticated = false
    }

    func fetchProjects() {
        guard !token.isEmpty else { return }
        isLoading = true
        error = nil

        var request = URLRequest(url: URL(string: "\(baseURL)/v9/projects?limit=20&teamId=\(teamId)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, err in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let err = err { self?.error = err.localizedDescription; return }
                guard let data = data else { return }
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
                    self?.error = "Error \(httpResp.statusCode). Please check your token."
                    self?.isAuthenticated = false
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(ProjectsResponse.self, from: data)
                    self?.projects = decoded.projects
                    self?.isAuthenticated = true
                    if self?.selectedProject == nil {
                        self?.selectedProject = decoded.projects.first
                    }
                } catch {
                    self?.error = "Failed to parse: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func fetchAnalytics(for project: VercelProject, period: String = "7d") {
        guard !token.isEmpty else { return }
        isLoading = true

        let (fromStr, toStr) = dateRange(for: period)
        let projectId = project.name
        let tz = TimeZone.current.identifier
        let group = DispatchGroup()
        var summary = AnalyticsSummary()

        // Overview
        group.enter()
        fetchOverview(projectId: projectId, from: fromStr, to: toStr, tz: tz) { overview in
            if let o = overview {
                summary.pageViews = o.total ?? 0
                summary.totalVisits = o.total ?? 0
                summary.uniqueVisitors = o.devices ?? 0
                summary.bounceRate = Double(o.bounceRate ?? 0) / 100.0
            }
            group.leave()
        }

        // Timeseries - group hourly into days
        group.enter()
        fetchTimeseries(projectId: projectId, from: fromStr, to: toStr, tz: tz) { points in
            let isoFmt = ISO8601DateFormatter()
            isoFmt.formatOptions = [.withInternetDateTime]
            let displayFmt = DateFormatter()
            displayFmt.dateFormat = "MMM d"

            var grouped: [String: Int] = [:]
            var orderedKeys: [String] = []
            for point in (points ?? []) {
                guard let key = point.key, let total = point.total else { continue }
                var label = key
                if let date = isoFmt.date(from: key) {
                    label = displayFmt.string(from: date)
                }
                if grouped[label] == nil { orderedKeys.append(label) }
                grouped[label, default: 0] += total
            }
            summary.visitsByDay = orderedKeys.map { DayStat(date: $0, visits: grouped[$0] ?? 0) }
            group.leave()
        }

        // Top pages - use devices (visitors) for percentage, matching Vercel dashboard
        group.enter()
        fetchStats(projectId: projectId, from: fromStr, to: toStr, tz: tz, type: "path") { items in
            let total = items?.reduce(0) { $0 + ($1.devices ?? 0) } ?? 1
            summary.topPages = (items ?? []).prefix(8).compactMap { item in
                guard let path = item.key, let visits = item.devices else { return nil }
                return PageStat(path: path, visits: visits, percentage: Double(visits) / Double(max(total, 1)))
            }
            group.leave()
        }

        // Top countries - use devices (visitors)
        group.enter()
        fetchStats(projectId: projectId, from: fromStr, to: toStr, tz: tz, type: "country") { items in
            let total = items?.reduce(0) { $0 + ($1.devices ?? 0) } ?? 1
            summary.topCountries = (items ?? []).prefix(5).compactMap { item in
                guard let code = item.key, let visits = item.devices else { return nil }
                let name = countryName(for: code)
                return CountryStat(
                    country: name,
                    flag: flagEmoji(for: code),
                    visits: visits,
                    percentage: Double(visits) / Double(max(total, 1))
                )
            }
            group.leave()
        }

        // Devices - use devices (visitors)
        group.enter()
        fetchStats(projectId: projectId, from: fromStr, to: toStr, tz: tz, type: "device_type") { items in
            let total = items?.reduce(0) { $0 + ($1.devices ?? 0) } ?? 1
            summary.topDevices = (items ?? []).compactMap { item in
                guard let key = item.key, let visits = item.devices else { return nil }
                return SimpleStat(label: key.capitalized, visits: visits, percentage: Double(visits) / Double(max(total, 1)))
            }
            group.leave()
        }

        // Browsers - use devices (visitors)
        group.enter()
        fetchStats(projectId: projectId, from: fromStr, to: toStr, tz: tz, type: "client_name") { items in
            let total = items?.reduce(0) { $0 + ($1.devices ?? 0) } ?? 1
            summary.topBrowsers = (items ?? []).prefix(5).compactMap { item in
                guard let key = item.key, let visits = item.devices else { return nil }
                return SimpleStat(label: key, visits: visits, percentage: Double(visits) / Double(max(total, 1)))
            }
            group.leave()
        }

        // OS - use devices (visitors)
        group.enter()
        fetchStats(projectId: projectId, from: fromStr, to: toStr, tz: tz, type: "os_name") { items in
            let total = items?.reduce(0) { $0 + ($1.devices ?? 0) } ?? 1
            summary.topOS = (items ?? []).prefix(5).compactMap { item in
                guard let key = item.key, let visits = item.devices else { return nil }
                return SimpleStat(label: key, visits: visits, percentage: Double(visits) / Double(max(total, 1)))
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.analyticsSummary = summary
            self?.isLoading = false
        }
    }

    // MARK: - Private Helpers

    private func fetchOverview(projectId: String, from: String, to: String, tz: String, completion: @escaping (OverviewResponse?) -> Void) {
        var comps = URLComponents(string: "\(analyticsBase)/overview")!
        comps.queryItems = [
            .init(name: "environment", value: "production"),
            .init(name: "filter", value: "{}"),
            .init(name: "from", value: from),
            .init(name: "projectId", value: projectId),
            .init(name: "teamId", value: teamId),
            .init(name: "to", value: to),
            .init(name: "tz", value: tz),
            .init(name: "withBounceRate", value: "true")
        ]
        guard let url = comps.url else { completion(nil); return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { completion(nil); return }
            print("OVERVIEW:", String(data: data, encoding: .utf8) ?? "nil")
            completion(try? JSONDecoder().decode(OverviewResponse.self, from: data))
        }.resume()
    }

    private func fetchTimeseries(projectId: String, from: String, to: String, tz: String, completion: @escaping ([TimeseriesPoint]?) -> Void) {
        var comps = URLComponents(string: "\(analyticsBase)/timeseries")!
        comps.queryItems = [
            .init(name: "environment", value: "production"),
            .init(name: "filter", value: "{}"),
            .init(name: "from", value: from),
            .init(name: "projectId", value: projectId),
            .init(name: "teamId", value: teamId),
            .init(name: "to", value: to),
            .init(name: "tz", value: tz)
        ]
        guard let url = comps.url else { completion(nil); return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(TimeseriesResponse.self, from: data)
            else { completion(nil); return }
            print("TIMESERIES points:", decoded.data?.groups?.all?.count ?? 0)
            completion(decoded.data?.groups?.all)
        }.resume()
    }

    private func fetchStats(projectId: String, from: String, to: String, tz: String, type: String, completion: @escaping ([StatItem]?) -> Void) {
        var comps = URLComponents(string: "\(analyticsBase)/stats")!
        comps.queryItems = [
            .init(name: "environment", value: "production"),
            .init(name: "filter", value: "{}"),
            .init(name: "from", value: from),
            .init(name: "projectId", value: projectId),
            .init(name: "teamId", value: teamId),
            .init(name: "to", value: to),
            .init(name: "tz", value: tz),
            .init(name: "type", value: type)
        ]
        guard let url = comps.url else { completion(nil); return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { completion(nil); return }
            print("STATS (\(type)):", String(data: data, encoding: .utf8) ?? "nil")
            let decoded = try? JSONDecoder().decode(StatsResponse.self, from: data)
            completion(decoded?.data)
        }.resume()
    }

    private func dateRange(for period: String) -> (String, String) {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = Date()
        let cal = Calendar.current
        let to = fmt.string(from: now)
        let from: String
        switch period {
        case "24h": from = fmt.string(from: cal.date(byAdding: .hour, value: -24, to: now)!)
        case "30d": from = fmt.string(from: cal.date(byAdding: .day, value: -30, to: now)!)
        default:    from = fmt.string(from: cal.date(byAdding: .day, value: -7, to: now)!)
        }
        return (from, to)
    }
}

// MARK: - Country helpers (ISO codes)

func countryName(for code: String) -> String {
    let map: [String: String] = [
        "GB": "United Kingdom", "US": "United States", "DE": "Germany",
        "FR": "France", "CA": "Canada", "AU": "Australia", "IN": "India",
        "JP": "Japan", "CN": "China", "BR": "Brazil", "NL": "Netherlands",
        "ES": "Spain", "IT": "Italy", "SE": "Sweden", "NO": "Norway",
        "DK": "Denmark", "FI": "Finland", "PL": "Poland", "RU": "Russia",
        "KR": "South Korea", "SG": "Singapore", "IE": "Ireland",
        "CH": "Switzerland", "PT": "Portugal", "BE": "Belgium", "MX": "Mexico",
        "PK": "Pakistan", "BD": "Bangladesh", "NG": "Nigeria", "ZA": "South Africa",
        "NZ": "New Zealand", "AR": "Argentina", "CL": "Chile", "CO": "Colombia",
        "TR": "Turkey", "SA": "Saudi Arabia", "AE": "UAE", "EG": "Egypt",
        "PH": "Philippines", "MY": "Malaysia", "TH": "Thailand", "ID": "Indonesia",
        "VN": "Vietnam", "UA": "Ukraine", "RO": "Romania", "CZ": "Czech Republic",
        "HU": "Hungary", "GR": "Greece", "AT": "Austria", "IL": "Israel"
    ]
    return map[code] ?? code
}

func flagEmoji(for code: String) -> String {
    let map: [String: String] = [
        "GB": "🇬🇧", "US": "🇺🇸", "DE": "🇩🇪", "FR": "🇫🇷", "CA": "🇨🇦",
        "AU": "🇦🇺", "IN": "🇮🇳", "JP": "🇯🇵", "CN": "🇨🇳", "BR": "🇧🇷",
        "NL": "🇳🇱", "ES": "🇪🇸", "IT": "🇮🇹", "SE": "🇸🇪", "NO": "🇳🇴",
        "DK": "🇩🇰", "FI": "🇫🇮", "PL": "🇵🇱", "RU": "🇷🇺", "KR": "🇰🇷",
        "SG": "🇸🇬", "IE": "🇮🇪", "CH": "🇨🇭", "PT": "🇵🇹", "BE": "🇧🇪",
        "MX": "🇲🇽", "PK": "🇵🇰", "BD": "🇧🇩", "NG": "🇳🇬", "ZA": "🇿🇦",
        "NZ": "🇳🇿", "AR": "🇦🇷", "CL": "🇨🇱", "CO": "🇨🇴", "TR": "🇹🇷",
        "SA": "🇸🇦", "AE": "🇦🇪", "EG": "🇪🇬", "PH": "🇵🇭", "MY": "🇲🇾",
        "TH": "🇹🇭", "ID": "🇮🇩", "VN": "🇻🇳", "UA": "🇺🇦", "RO": "🇷🇴",
        "CZ": "🇨🇿", "HU": "🇭🇺", "GR": "🇬🇷", "AT": "🇦🇹", "IL": "🇮🇱"
    ]
    return map[code] ?? "🌍"
}

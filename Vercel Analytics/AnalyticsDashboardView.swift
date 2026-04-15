import SwiftUI
import Combine

struct AnalyticsDashboardView: View {
    @EnvironmentObject var api: VercelAPIService
    @State private var selectedPeriod = "7d"
    @State private var hasLoaded = false
    
    let periods = ["24h", "7d", "30d"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if api.isLoading && !hasLoaded {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            if !api.projects.isEmpty {
                                ProjectSelectorCard()
                            }
                            
                            PeriodPickerView(selected: $selectedPeriod, periods: periods) {
                                if let project = api.selectedProject {
                                    api.fetchAnalytics(for: project, period: selectedPeriod)
                                }
                            }
                            
                            StatsGridView()
                            VisitChartCard()
                            TopPagesCard()
                            TopCountriesCard()
                            
                            SimpleStatCard(
                                title: "DEVICES",
                                items: api.analyticsSummary.topDevices,
                                accentColor: Color(red: 0.6, green: 0.4, blue: 1)
                            )
                            
                            SimpleStatCard(
                                title: "BROWSERS",
                                items: api.analyticsSummary.topBrowsers,
                                accentColor: Color(red: 1, green: 0.6, blue: 0.2)
                            )
                            
                            SimpleStatCard(
                                title: "OPERATING SYSTEMS",
                                items: api.analyticsSummary.topOS,
                                accentColor: Color(red: 0.3, green: 0.8, blue: 0.6)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        if let project = api.selectedProject {
                            api.fetchAnalytics(for: project, period: selectedPeriod)
                        } else {
                            api.fetchProjects()
                        }
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: 26, height: 26)
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.black)
                                .offset(y: 1)
                        }
                        Text(api.selectedProject?.name ?? "Analytics")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if api.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.75)
                    }
                }
            }
        }
        .onAppear {
            if !hasLoaded {
                if api.projects.isEmpty {
                    api.fetchProjects()
                } else if let project = api.selectedProject {
                    api.fetchAnalytics(for: project, period: selectedPeriod)
                    hasLoaded = true
                }
            }
        }
        .onChange(of: api.selectedProject?.id) {
            if let project = api.selectedProject {
                api.fetchAnalytics(for: project, period: selectedPeriod)
                hasLoaded = true
            }
        }
        .onChange(of: api.projects.count) {
            if api.projects.count > 0 && !hasLoaded {
                api.selectedProject = api.projects.first
            }
        }
    }
}

struct LoadingView: View {
    @State private var dots = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                Image(systemName: "triangle.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
                    .offset(y: 1)
            }
            Text("Loading\(String(repeating: ".", count: dots))")
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .onReceive(timer) { _ in
            dots = (dots + 1) % 4
        }
    }
}

// MARK: - Project Selector

struct ProjectSelectorCard: View {
    @EnvironmentObject var api: VercelAPIService
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(api.selectedProject?.name.prefix(1).uppercased() ?? "?"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(api.selectedProject?.name ?? "Select Project")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    if let fw = api.selectedProject?.framework {
                        Text(fw.capitalized)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
            )
        }
        .confirmationDialog("Select Project", isPresented: $showPicker) {
            ForEach(api.projects) { project in
                Button(project.name) { api.selectedProject = project }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Period Picker

struct PeriodPickerView: View {
    @Binding var selected: String
    let periods: [String]
    let onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(periods, id: \.self) { period in
                Button(action: { selected = period; onChange() }) {
                    Text(period)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(selected == period ? .black : Color.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selected == period ? Color.white : Color.white.opacity(0.06))
                        )
                }
            }
            Spacer()
        }
    }
}

// MARK: - Stats Grid

struct StatsGridView: View {
    @EnvironmentObject var api: VercelAPIService
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(label: "VISITS", value: api.analyticsSummary.totalVisits.formatted(), icon: "eye.fill", color: .white)
            StatCard(label: "UNIQUE VISITORS", value: api.analyticsSummary.uniqueVisitors.formatted(), icon: "person.fill", color: Color(red: 0.4, green: 0.8, blue: 1))
            StatCard(label: "PAGE VIEWS", value: api.analyticsSummary.pageViews.formatted(), icon: "doc.text.fill", color: Color(red: 0.6, green: 0.9, blue: 0.5))
            StatCard(label: "BOUNCE RATE", value: "\(Int((api.analyticsSummary.bounceRate * 100).rounded()))%", icon: "arrow.uturn.backward", color: Color(red: 1, green: 0.75, blue: 0.3))
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.35))
                .kerning(1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

// MARK: - Visit Chart

struct VisitChartCard: View {
    @EnvironmentObject var api: VercelAPIService
    
    var maxVisits: Int { api.analyticsSummary.visitsByDay.map { $0.visits }.max() ?? 1 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("VISITS OVER TIME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.4))
                    .kerning(1.5)
                Spacer()
                Text("7 days").font(.system(size: 12)).foregroundColor(Color.white.opacity(0.3))
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(api.analyticsSummary.visitsByDay) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.white, Color.white.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                            .frame(height: max(4, CGFloat(day.visits) / CGFloat(maxVisits) * 100))
                        Text(day.date.components(separatedBy: " ").last ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

// MARK: - Top Pages

struct TopPagesCard: View {
    @EnvironmentObject var api: VercelAPIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TOP PAGES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.4))
                .kerning(1.5)
            ForEach(api.analyticsSummary.topPages) { page in
                VStack(spacing: 6) {
                    HStack {
                        Text(page.path).font(.system(size: 14, design: .monospaced)).foregroundColor(.white)
                        Spacer()
                        Text(page.visits.formatted()).font(.system(size: 13, weight: .medium)).foregroundColor(Color.white.opacity(0.6))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.08)).frame(height: 3)
                            RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.5)).frame(width: geo.size.width * page.percentage, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

// MARK: - Top Countries

struct TopCountriesCard: View {
    @EnvironmentObject var api: VercelAPIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TOP COUNTRIES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.4))
                .kerning(1.5)
            ForEach(api.analyticsSummary.topCountries) { country in
                HStack(spacing: 12) {
                    Text(country.flag).font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(country.country).font(.system(size: 14)).foregroundColor(.white)
                            Spacer()
                            Text("\(Int((country.percentage * 100).rounded()))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.5))
                            
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.08)).frame(height: 3)
                                RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.4, green: 0.8, blue: 1).opacity(0.7)).frame(width: geo.size.width * country.percentage, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

// MARK: - Simple Stat Card

struct SimpleStatCard: View {
    let title: String
    let items: [SimpleStat]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.4))
                .kerning(1.5)
            if items.isEmpty {
                Text("No data")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.25))
            } else {
                ForEach(items) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.label).font(.system(size: 14)).foregroundColor(.white)
                            Spacer()
                            Text("\(Int((item.percentage * 100).rounded()))%") .font(.system(size: 13, weight: .medium)).foregroundColor(Color.white.opacity(0.5))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.08)).frame(height: 3)
                                RoundedRectangle(cornerRadius: 2).fill(accentColor.opacity(0.7)).frame(width: geo.size.width * item.percentage, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

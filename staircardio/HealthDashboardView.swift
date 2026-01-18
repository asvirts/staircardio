import SwiftData
import SwiftUI
import Charts

struct HealthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct HealthDashboardView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var vo2MaxRecords: [VO2MaxRecord]
    @Query private var restingHeartRateRecords: [RestingHeartRateRecord]
    @State private var selectedTimeRange: TimeRange = .thirty
    @State private var vo2MaxData: [HealthDataPoint] = []
    @State private var restingHeartRateData: [HealthDataPoint] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                timeRangePicker

                if vo2MaxData.isEmpty && restingHeartRateData.isEmpty {
                    Text("No health data available yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Text("Key Health Metrics")
                            .font(.headline)

                        metricsGrid
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if !vo2MaxData.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VO₂ Max Trend")
                                .font(.headline)

                            vo2MaxChart
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if !restingHeartRateData.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Resting Heart Rate Trend")
                                .font(.headline)

                            restingHeartRateChart
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if !vo2MaxData.isEmpty && !restingHeartRateData.isEmpty {
                        healthInsightsSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Health")
        .task {
            await loadHealthData()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            Task {
                await loadHealthData()
            }
        }
    }

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach([TimeRange.seven, .fourteen, .thirty], id: \.self) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .accessibilityLabel("Time range selector")
        .accessibilityHint("Select time range for health data display")
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            if let latestVO2Max = vo2MaxData.first {
                StatsCard(
                    icon: "lungs.fill",
                    value: String(format: "%.1f", latestVO2Max.value),
                    label: "VO₂ Max (ml/kg·min)",
                    trend: vo2MaxTrendDirection(),
                    trendLabel: vo2MaxTrendLabel()
                )
            }

            if let latestRHR = restingHeartRateData.first {
                StatsCard(
                    icon: "heart.fill",
                    value: String(format: "%.0f", latestRHR.value),
                    label: "Resting HR (bpm)",
                    trend: restingHeartRateTrendDirection(),
                    trendLabel: restingHeartRateTrendLabel()
                )
            }

            StatsCard(
                icon: "figure.stairs",
                value: String(format: "%.1f", averageCircuitsPerWorkout),
                label: "Avg Circuits/Day"
            )

            StatsCard(
                icon: "chart.line.uptrend.xyaxis",
                value: healthTrendLabel,
                label: "Health Trend"
            )
        }
    }

    private var vo2MaxChart: some View {
        Chart(vo2MaxData) { data in
            LineMark(
                x: .value("Date", data.date),
                y: .value("VO₂ Max", data.value)
            )
            .foregroundStyle(.purple)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", data.date),
                y: .value("VO₂ Max", data.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple.opacity(0.3), .purple.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private var restingHeartRateChart: some View {
        Chart(restingHeartRateData) { data in
            LineMark(
                x: .value("Date", data.date),
                y: .value("RHR", data.value)
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", data.date),
                y: .value("RHR", data.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.red.opacity(0.3), .red.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private var healthInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Insights")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "VO₂ Max Correlation",
                    description: vo2MaxInsight
                )

                insightCard(
                    icon: "heart.text.square",
                    title: "Heart Rate Trend",
                    description: rhrInsight
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var vo2MaxInsight: String {
        guard vo2MaxData.count >= 2 else {
            return "Need more VO₂ max data to analyze trends."
        }

        let first = vo2MaxData.last?.value ?? 0
        let last = vo2MaxData.first?.value ?? 0
        let change = ((last - first) / first) * 100

        if change > 5 {
            return "Your VO₂ max has improved by \(String(format: "%.1f", change))%. Great progress!"
        } else if change < -5 {
            return "Your VO₂ max has decreased by \(String(format: "%.1f", abs(change)))%. Keep up your workouts!"
        } else {
            return "Your VO₂ max has remained stable. Consistency is key!"
        }
    }

    private var rhrInsight: String {
        guard restingHeartRateData.count >= 2 else {
            return "Need more resting heart rate data to analyze trends."
        }

        let first = restingHeartRateData.last?.value ?? 0
        let last = restingHeartRateData.first?.value ?? 0
        let change = first - last

        if change > 3 {
            return "Your resting heart rate has improved by \(String(format: "%.0f", change)) bpm. Lower RHR indicates better cardiovascular health."
        } else if change < -3 {
            return "Your resting heart rate has increased by \(String(format: "%.0f", abs(change))) bpm. Consider consulting a healthcare provider."
        } else {
            return "Your resting heart rate has remained stable."
        }
    }

    private var averageCircuitsPerWorkout: Double {
        guard !vo2MaxData.isEmpty else { return 0 }
        return Double(vo2MaxData.count) / Double(max(1, selectedTimeRange.days))
    }

    private var healthTrendLabel: String {
        let vo2MaxTrend = vo2MaxTrendDirection()
        let rhrTrend = restingHeartRateTrendDirection()

        if vo2MaxTrend == .up && (rhrTrend == .down || rhrTrend == .flat) {
            return "Improving"
        } else if vo2MaxTrend == .down && rhrTrend == .up {
            return "Declining"
        } else {
            return "Stable"
        }
    }

    private func vo2MaxTrendDirection() -> TrendDirection {
        guard vo2MaxData.count >= 2 else { return .flat }
        let first = vo2MaxData.last?.value ?? 0
        let last = vo2MaxData.first?.value ?? 0
        if last > first * 1.05 { return .up }
        if last < first * 0.95 { return .down }
        return .flat
    }

    private func vo2MaxTrendLabel() -> String {
        guard vo2MaxData.count >= 2 else { return "—" }
        let first = vo2MaxData.last?.value ?? 0
        let last = vo2MaxData.first?.value ?? 0
        let change = ((last - first) / first) * 100
        return "\(change > 0 ? "+" : "")\(String(format: "%.1f", change))%"
    }

    private func restingHeartRateTrendDirection() -> TrendDirection {
        guard restingHeartRateData.count >= 2 else { return .flat }
        let first = restingHeartRateData.last?.value ?? 0
        let last = restingHeartRateData.first?.value ?? 0
        if last < first * 0.97 { return .up }
        if last > first * 1.03 { return .down }
        return .flat
    }

    private func restingHeartRateTrendLabel() -> String {
        guard restingHeartRateData.count >= 2 else { return "—" }
        let first = restingHeartRateData.last?.value ?? 0
        let last = restingHeartRateData.first?.value ?? 0
        let change = first - last
        return "\(change > 0 ? "+" : "")\(String(format: "%.0f", change)) bpm"
    }

    private func insightCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadHealthData() async {
        let vo2MaxTuples = await healthKitManager.fetchVO2MaxSamples(limit: selectedTimeRange.days)
        vo2MaxData = vo2MaxTuples.map { HealthDataPoint(date: $0.date, value: $0.value) }

        let rhrTuples = await healthKitManager.fetchRestingHeartRateSamples(limit: selectedTimeRange.days)
        restingHeartRateData = rhrTuples.map { HealthDataPoint(date: $0.date, value: $0.value) }
    }
}

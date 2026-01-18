import SwiftUI

enum TrendDirection {
    case up
    case down
    case flat

    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .flat: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .flat: return .secondary
        }
    }
}

struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    var trend: TrendDirection?
    var trendLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Spacer()

                if let trend, let trendLabel {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trendLabel)
                            .font(.caption)
                    }
                    .foregroundColor(trend.color)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("StatsCard") {
    HStack(spacing: 12) {
        StatsCard(
            icon: "flame.fill",
            value: "7",
            label: "Current Streak",
            trend: .up,
            trendLabel: "+2"
        )
        StatsCard(
            icon: "star.fill",
            value: "156",
            label: "Total Circuits",
            trend: .up,
            trendLabel: "+12%"
        )
    }
    .padding()
}

#Preview("StatsCard Flat") {
    HStack(spacing: 12) {
        StatsCard(
            icon: "figure.walk",
            value: "8.2",
            label: "Avg/Day"
        )
        StatsCard(
            icon: "target",
            value: "85%",
            label: "Goal Rate",
            trend: .flat,
            trendLabel: "0%"
        )
    }
    .padding()
}

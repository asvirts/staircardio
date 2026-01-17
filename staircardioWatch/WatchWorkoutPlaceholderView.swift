import SwiftUI

struct WatchWorkoutPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Workout Mode")
                .font(.headline)

            Text("Coming in v0.4")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    WatchWorkoutPlaceholderView()
}

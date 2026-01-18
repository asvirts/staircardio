import Combine
import Foundation

@MainActor
final class TabSelectionManager: ObservableObject {
    @Published var selectedTab = 0
}

import SwiftUI

@main
struct PULSE21App: App {
    @StateObject private var health = HealthStore()
    @StateObject private var activities = ActivityStore()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(health)
                .environmentObject(activities)
                .preferredColorScheme(.dark)
        }
    }
}

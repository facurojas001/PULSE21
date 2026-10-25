
import SwiftUI

struct MainTabView: View {
    @StateObject private var health = HealthStore()

    var body: some View {
        TabView {
            DashboardView(health: health)
                .tabItem {
                    Label("Today", systemImage: PulseTab.today.symbol)
                }
                .tag(PulseTab.today)

            SleepView(health: health)
                .tabItem {
                    Label("Sleep", systemImage: PulseTab.sleep.symbol)
                }
                .tag(PulseTab.sleep)

            StrainView(health: health)
                .tabItem {
                    Label("Strain", systemImage: PulseTab.strain.symbol)
                }
                .tag(PulseTab.strain)

            RecoveryView(health: health)
                .tabItem {
                    Label("Recovery", systemImage: PulseTab.recovery.symbol)
                }
                .tag(PulseTab.recovery)
        }
        .tint(Color.pulseBlue)
    }
}

#Preview {
    MainTabView()
}

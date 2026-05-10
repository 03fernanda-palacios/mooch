import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        LiveMapView()
            .onAppear {
                appState.loadFarms()
                if appState.activeFarm == nil {
                    appState.loadDemoData()
                }
            }
    }
}

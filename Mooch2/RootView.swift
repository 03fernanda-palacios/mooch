import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.activeFarm != nil {
                LiveMapView()
            } else {
                FarmSetupView()
            }
        }
        .onAppear {
            appState.loadFarms()
        }
    }
}

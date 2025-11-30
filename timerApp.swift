import SwiftUI
import GoogleMobileAds

@main
struct CircularTimerApp: App {
    
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

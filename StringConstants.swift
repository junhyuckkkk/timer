import Foundation

struct AppStrings {
    static var modeTimer: String { NSLocalizedString("mode_timer", comment: "Timer mode") }
    static var modeClock: String { NSLocalizedString("mode_clock", comment: "Clock mode") }
    static var modeStopwatch: String { NSLocalizedString("mode_stopwatch", comment: "Stopwatch mode") }
    
    static var statusComplete: String { NSLocalizedString("status_complete", comment: "Timer complete") }
    static var statusRunning: String { NSLocalizedString("status_running", comment: "Timer running") }
    static var statusWaiting: String { NSLocalizedString("status_waiting", comment: "Timer waiting") }
    static var statusMeasuring: String { NSLocalizedString("status_measuring", comment: "Stopwatch measuring") }
    static var statusCurrentTime: String { NSLocalizedString("status_current_time", comment: "Current time") }
    
    static var lap: String { NSLocalizedString("lap", comment: "Lap time prefix") }
    static var settingsTitle: String { NSLocalizedString("settings_title", comment: "Settings sheet title") }
    static var minutes: String { NSLocalizedString("minutes", comment: "Minutes label") }
    static var seconds: String { NSLocalizedString("seconds", comment: "Seconds label") }
    static var setButton: String { NSLocalizedString("set_button", comment: "Set button title") }
    static var lapButton: String { NSLocalizedString("lap_button", comment: "Lap button title") }
}

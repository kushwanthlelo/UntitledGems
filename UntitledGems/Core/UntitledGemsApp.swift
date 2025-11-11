import SwiftUI
import Combine
import AVFoundation

@main
struct UntitledGemsApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var themeManager = ThemeManager()

    init() {
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(library)
                .environmentObject(themeManager)
                .preferredColorScheme(colorSchemeForTheme(themeManager.selectedTheme))
        }
    }

    private func colorSchemeForTheme(_ theme: ThemeManager.Theme) -> ColorScheme? {
        switch theme {
        case .system: return nil       // follow system
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
}

//
//  ThemeManager.swift
//  UntitledGems
//
//  Created by Kushwanth Reddy on 11/10/25.

import SwiftUI
import Combine
import AVFoundation

class ThemeManager: ObservableObject {
    enum Theme: String, CaseIterable, Identifiable {
        case system = "System"
        case light  = "Light"
        case dark   = "Dark"

        var id: String { rawValue }
    }

    @Published var selectedTheme: Theme = .system
}

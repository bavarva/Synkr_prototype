//
//  Platform.swift
//  Synkr
//
//  Created by Arnav on 28/07/25.
//

import SwiftUICore

enum Platform: String, CaseIterable {
    case spotify = "Spotify"
    case youtube = "YouTube"
    case text = "Text"

    var logoName: String {
        switch self {
        case .spotify: return "SpotifyLogo"
        case .youtube: return "YoutubeLogo"
        case .text: return "TextLogo"
        }
    }

    var color: Color {
        switch self {
        case .spotify: return Color(red: 255/255, green: 242/255, blue: 224/255)
        case .youtube: return Color(red: 255/255, green: 242/255, blue: 224/255)
        case .text: return Color(red: 255/255, green: 242/255, blue: 224/255)
        }
    }
}

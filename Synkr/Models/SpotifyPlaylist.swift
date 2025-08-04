//
//  SpotifyPlaylist.swift
//  Synkr
//
//  Created by Arnav on 30/07/25.
//

import Foundation

struct SpotifyPlaylistResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Identifiable, Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

    extension SpotifyPlaylist {
        var thumbnailURL: URL? {
            guard let urlString = images?.first?.url else { return nil }
            return URL(string: urlString)
        }
    }


//
//  SpotifyTrack.swift
//  Synkr
//
//  Created by Arnav on 30/07/25.
//

import Foundation

struct SpotifyTrackResponse: Decodable {
    let items: [SpotifyTrackItem]
}

struct SpotifyTrackItem: Decodable {
    let track: SpotifyTrack
}

struct SpotifyTrack: Decodable {
    let name: String
    let artists: [SpotifyArtist]
}

struct SpotifyArtist: Decodable {
    let name: String
}

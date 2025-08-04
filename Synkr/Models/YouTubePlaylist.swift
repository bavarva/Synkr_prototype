//
//  YouTubePlaylist.swift
//  Synkr
//
//  Created by Arnav on 30/07/25.
//

import Foundation

struct YouTubePlaylistResponse: Decodable {
    let items: [YouTubePlaylist]
}

struct YouTubePlaylist: Decodable, Identifiable {
    let id: String
    let snippet: Snippet

    struct Snippet: Decodable {
        let title: String
        let thumbnails: Thumbnails
    }

    struct Thumbnails: Decodable {
        let medium: Thumbnail?
        let high: Thumbnail?
        let standard: Thumbnail?

        struct Thumbnail: Decodable {
            let url: String
        }
    }
}

extension YouTubePlaylist {
    func thumbnailURL() -> URL? {
        if let urlString =
            snippet.thumbnails.high?.url ??
            snippet.thumbnails.medium?.url ??
            snippet.thumbnails.standard?.url {
            return URL(string: urlString)
        }
        return nil
    }
}

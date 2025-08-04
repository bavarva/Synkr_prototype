//
//  SpotifyToYouTubeView.swift
//  Synkr
//
//  Created by Arnav on 31/07/25.
//

import SwiftUI

struct SpotifyToYouTubeView: View {
    let spotifyToken: String
    let youtubeToken: String
    let selectedPlaylist: SpotifyPlaylist

    @Environment(\.dismiss) var dismiss
    @State private var statusMessage = "Preparing transfer..."
    @State private var isLoading = true

    var body: some View {

        VStack(spacing: 20) {
            Text("Transferring to YouTube")
                .font(.title2)
                .bold()

            Text(selectedPlaylist.name)
                .foregroundColor(.gray)

            AsyncImage(url: selectedPlaylist.thumbnailURL) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 180, height: 180)
            .cornerRadius(10)

            if isLoading {
                ProgressView()
            }

            Text(statusMessage)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onAppear {
            transferToYouTube()
        }
    }

    private func transferToYouTube() {
        statusMessage = "Fetching Spotify tracks..."
        SpotifyService.shared.fetchTracksFromPlaylist(token: spotifyToken, playlistID: selectedPlaylist.id) { songs in
            print(" Songs to transfer:", songs)
            if songs.isEmpty {
                statusMessage = "No songs found in this Spotify playlist."
                isLoading = false
                return
            }

            statusMessage = "Searching on YouTube..."
            YouTubeService.shared.searchYouTubeVideos(token: youtubeToken, queries: songs) { videoIDs in
                statusMessage = "Creating YouTube playlist..."
                YouTubeService.shared.createYouTubePlaylist(token: youtubeToken, title: selectedPlaylist.name) { playlistID in
                    guard let playlistID = playlistID else {
                        statusMessage = " Failed to create YouTube playlist"
                        isLoading = false
                        return
                    }

                    statusMessage = "Adding \(videoIDs.count) videos..."
                    YouTubeService.shared.addVideosToYouTubePlaylist(token: youtubeToken, playlistID: playlistID, videoIDs: videoIDs) { success in
                        isLoading = false
                        statusMessage = success ? " Transfer complete!" : " Some videos may not have been added"
                    }
                }
            }
        }
    }
}


#Preview {
    SpotifyToYouTubeView(
        spotifyToken: "dummy",
        youtubeToken: "dummy",
        selectedPlaylist: SpotifyPlaylist(
            id: "123",
            name: "Preview Playlist",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273d1d63cf063c7d94f1fa5c38b", height: 300, width: 300)]
        )
    )
}

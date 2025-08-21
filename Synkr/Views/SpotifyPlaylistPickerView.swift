//
//  PlaylistSectorView.swift
//  Synkr
//
//  Created by Arnav on 28/07/25.
//

import SwiftUI

struct SpotifyPlaylistPickerView: View {
    @Environment(\.dismiss) var dismiss
    let token: String
    let spotifyToken: String
    let youtubeToken: String
    let onSelect: (SpotifyPlaylist) -> Void
    
    @State private var playlists: [SpotifyPlaylist] = []
    @State private var selectedPlaylist: SpotifyPlaylist?

    var body: some View {
        ZStack {
      
            Color.clear
                .background(.black.gradient)
                .ignoresSafeArea()

            List(playlists) { playlist in
                Button(action: {
                    selectedPlaylist = playlist
                    print("Spotify Playlist selected: \(playlist.name)")
                }) {
                    HStack {
                        AsyncImage(url: playlist.thumbnailURL) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)

                        Text(playlist.name)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden) 
        }
        .sheet(item: $selectedPlaylist) { playlist in
            SpotifyToYouTubeView(
                spotifyToken: spotifyToken,
                youtubeToken: youtubeToken,
                selectedPlaylist: playlist
            )
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select Spotify Playlist")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            SpotifyService.shared.fetchUserPlaylists(token: token) { result in
                playlists = result
            }
        }
    }
}



#Preview {
    SpotifyPlaylistPickerView(
        token: "dummy_token",
        spotifyToken: "dummy_token",
        youtubeToken: "dummy_token"
    ) { playlist in
        print("Selected:", playlist.name)
    }
}



//
//  YouTubeToSpotifyView.swift
//  Synkr
//
//  Created by Arnav on 30/07/25.


import SwiftUI

struct YouTubeToSpotifyView: View {
    let youtubeToken: String
    let spotifyToken: String
    let selectedPlaylist: YouTubePlaylist
    
    @Environment(\.dismiss) var dismiss
    @State private var videoTitles: [String] = []
    @State private var isLoading = true
    @State private var statusMessage: String?
    @State private var transferComplete = false
    
  
    var body: some View {
        
            VStack() {
               
                
                Text("Playlist: \(selectedPlaylist.snippet.title)")
                    .foregroundColor(.gray)
                
                Text(" YouTube → Spotify")
                    .font(.largeTitle)
                    .bold()
                
                Text("Selected: \(selectedPlaylist.snippet.title)")
                    .font(.headline)
                
                if isLoading {
                    ProgressView("Fetching videos...")
                } else if transferComplete {
                    Text(statusMessage ?? "✅ Playlist created successfully!")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Button("Transfer to Spotify") {
                        transferPlaylist()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    
                    if let message = statusMessage {
                        Text(message)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    List(videoTitles, id: \.self) { title in
                        Text(title)
                    }
                }
            }
            .padding()
            .onAppear {
                fetchVideoTitles()
            }
        }
    
    private func fetchVideoTitles() {
        YouTubeService.shared.fetchVideoTitlesFromPlaylist(
            token: youtubeToken,
            playlistID: selectedPlaylist.id
        ) { titles in
            DispatchQueue.main.async {
                self.videoTitles = titles
                self.isLoading = false
            }
        }
    }

    private func transferPlaylist() {
        statusMessage = "Transferring..."

        SpotifyService.shared.createPlaylistFromText(
            token: spotifyToken,
            name: selectedPlaylist.snippet.title,
            songs: videoTitles
        ) { result in
            DispatchQueue.main.async {
                self.statusMessage = result
                self.transferComplete = result.contains("successfully")
            }
        }
    }
}


#Preview {

        YouTubeToSpotifyView(
            youtubeToken: "dummy_token",
            spotifyToken: "dummy_token",
            selectedPlaylist: YouTubePlaylist(
                id: "preview123",
                snippet: YouTubePlaylist.Snippet(
                    title: "Mock YouTube Playlist",
                    thumbnails: YouTubePlaylist.Thumbnails(
                        medium: YouTubePlaylist.Thumbnails.Thumbnail(url: "https://i.ytimg.com/vi/VIDEO_ID/mqdefault.jpg"),
                        high: YouTubePlaylist.Thumbnails.Thumbnail(url: "https://i.ytimg.com/vi/VIDEO_ID/hqdefault.jpg"),
                        standard: nil
                    )
                )
            )
        )
    }











    
    


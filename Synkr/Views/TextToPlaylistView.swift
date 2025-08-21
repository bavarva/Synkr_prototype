//
//  TextToPlaylistView.swift
//  Synkr
//
//  Created by Arnav on 28/07/25.
//

import SwiftUI

struct TextToPlaylistView: View {
    let spotifyToken: String
    
    @Environment(\.dismiss) var dismiss

    @State private var playlistName: String = ""
    @State private var songList: String = ""
    @State private var statusMessage: String?

    var body: some View {
        ZStack {
         
            Color.clear
                .background(.black.gradient)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Create Spotify Playlist from Text")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                TextField("Playlist Name", text: $playlistName)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $songList)
                    .border(Color.gray, width: 1)
                    .frame(height: 200)
                    .overlay(
                        Text("Enter songs, one per line")
                            .foregroundColor(.black.opacity(0.3))
                            .opacity(songList.isEmpty ? 1 : 0)
                            .padding(.top, 8)
                            .padding(.horizontal, 4),
                        alignment: .topLeading
                    )
                    .foregroundColor(.black)
                
                Button(action: {
                    let songs = songList
                        .split(separator: "\n")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    SpotifyService.shared.createPlaylistFromText(
                        token: spotifyToken,
                        name: playlistName,
                        songs: songs
                    ) { message in
                        DispatchQueue.main.async {
                            self.statusMessage = message
                        }
                    }
                }) {
                    Text("Create Playlist")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
                
                if let message = statusMessage {
                    Text(message)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    TextToPlaylistView(spotifyToken: "dummy")
}



#Preview {
    TextToPlaylistView(spotifyToken: "dummy")
}

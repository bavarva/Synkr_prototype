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
        VStack(spacing: 20) {
            Text("Create Spotify Playlist from Text")
                .font(.title2)
                .bold()

            TextField("Playlist Name", text: $playlistName)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $songList)
                .border(Color.gray, width: 1)
                .frame(height: 200)
                .overlay(Text("Enter songs, one per line")
                    .opacity(songList.isEmpty ? 0.3 : 0)
                    .padding(.top, 8)
                    .padding(.horizontal, 4), alignment: .topLeading)

            Button("Create Playlist") {
                let songs = songList
                    .split(separator: "\n")
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                SpotifyService.shared.createPlaylistFromText(token: spotifyToken, name: playlistName, songs: songs) { message in
                    DispatchQueue.main.async {
                        self.statusMessage = message
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            if let message = statusMessage {
                Text(message)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
//        .toolbarRole(.editor)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    dismiss()
//                }) {
//                    Label("Back", systemImage: "chevron.left")
//                }
//            }
//
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("Logout") {
//                   
//                }
//            }
//        }
    }
}


#Preview {
    TextToPlaylistView(spotifyToken: "dummy")
}

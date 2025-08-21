//
//  YouTubePlaylistPickerView.swift
//  Synkr
//
//  Created by Arnav on 30/07/25.
//
import SwiftUI

struct YouTubePlaylistPickerView: View {
    
    let token: String
    let onSelect: (YouTubePlaylist) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var playlists: [YouTubePlaylist] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
   
                Color.clear
                    .background(.black.gradient)
                    .ignoresSafeArea()

                VStack {
                    if isLoading {
                        ProgressView("Loading playlists...")
                            .tint(.white)
                            .foregroundColor(.white)
                            .padding()
                    }

                    List(playlists, id: \.id) { playlist in
                        Button(action: {
                            onSelect(playlist)
                        }) {
                            HStack {
                                AsyncImage(url: playlist.thumbnailURL()) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                        .tint(.white)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(playlist.snippet.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Playlist")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                isLoading = true
                YouTubeService.shared.fetchUserPlaylists(token: token) { playlists in
                    DispatchQueue.main.async {
                        self.playlists = playlists
                        self.isLoading = false
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) 
    }
}

#Preview {
    YouTubePlaylistPickerView(token: "dummy") { playlist in
        print("Selected:", playlist.snippet.title)
    }
}


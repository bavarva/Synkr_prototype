import SwiftUI

struct TextToYouTubeView: View {
    @State private var playlistName = ""
    @State private var rawText = ""
    @State private var statusMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss

    let youtubeToken: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Text ➝ YouTube Playlist")
                .font(.title)
                .bold()

            TextField("Playlist Name", text: $playlistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextEditor(text: $rawText)
                .frame(height: 200)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5)))

            Button(action: createPlaylist) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Create YouTube Playlist")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }

    func createPlaylist() {
        let songs = rawText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !playlistName.isEmpty, !songs.isEmpty else {
            statusMessage = "Enter playlist name and at least one song."
            return
        }

        isLoading = true
        statusMessage = "Searching YouTube videos..."

        YouTubeService.shared.searchYouTubeVideos(token: youtubeToken, queries: songs) { videoIDs in
            DispatchQueue.main.async {
                self.statusMessage = "Creating YouTube playlist..."
            }

            YouTubeService.shared.createYouTubePlaylist(token: youtubeToken, title: playlistName) { playlistID in
                guard let playlistID = playlistID else {
                    DispatchQueue.main.async {
                        self.statusMessage = "❌ Failed to create playlist."
                        self.isLoading = false
                    }
                    return
                }

                YouTubeService.shared.addVideosToYouTubePlaylist(token: youtubeToken, playlistID: playlistID, videoIDs: videoIDs) { success in
                    DispatchQueue.main.async {
                        self.statusMessage = success ? "✅ Playlist created on YouTube!" : "❌ Failed to add some videos."
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    TextToYouTubeView(youtubeToken: "dummy")
}

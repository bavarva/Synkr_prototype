import SwiftUI

enum FlowStep {
    case login
    case source
    case destination
    case ready
}

struct ContentView: View {
    
    @State private var selectedYouTubePlaylist: YouTubePlaylist?
    @State private var showYouTubeToSpotifyView = false
    @State private var isYouTubePlaylistSelected = false
    @State private var spotifyToken: String?
    @State private var youtubeToken: String?
    @State private var source: Platform?
    @State private var destination: Platform?
    @State private var step: FlowStep = .login
    @State private var showYouTubeToSpotifySheet = false
    @State private var selectedSpotifyPlaylist: SpotifyPlaylist?

    
    var body: some View {
        NavigationStack {
            
            contentForStep()
                .toolbar {
                    if step != .login {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Logout") {
                                logout()
                            }
                        }
                    }
                    if step != .login && step != .source {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                step = .source
                            }) {
                                Label("Back", systemImage: "chevron.left")
                            }
                        }
                    }
                }
        }.sheet(isPresented: $showYouTubeToSpotifySheet) {
            if let playlist = selectedYouTubePlaylist {
                YouTubeToSpotifyView(
                    youtubeToken: youtubeToken!,
                    spotifyToken: spotifyToken!,
                    selectedPlaylist: playlist
                )
            }
        }
    }
    
    @ViewBuilder
    private func contentForStep() -> some View {
        switch step {
        case .login:
            loginView
            
        case .source:
            PlatformPickerView(title: "Select Source Platform", exclude: []) { selected in
                ensureLogin(for: selected) { success in
                    if success {
                        
                        selectedYouTubePlaylist = nil
                        selectedSpotifyPlaylist = nil
                        showYouTubeToSpotifyView = false
                        
                        source = selected
                        step = .destination
                    }
                }
            }

            
            
        case .destination:
            
            let exclude: [Platform] = {
                switch source {
                case .spotify:
                    return [.spotify, .text]
                case .youtube:
                    return [.youtube, .text]
                case .text:
                    return [.text]
                case .none:
                    return []
                }
            }()
            
            PlatformPickerView(title: "Select Destination Platform", exclude: exclude) { selected in
                ensureLogin(for: selected) { success in
                    if success {
                        destination = selected
                        step = .ready
                    }
                }
            }

        case .ready:
           

            if source == .text && destination == .spotify, let token = spotifyToken {
                TextToPlaylistView(spotifyToken: token)
            }
            else if source == .youtube && destination == .spotify {
                Group {
                    if let playlist = selectedYouTubePlaylist, showYouTubeToSpotifyView {
                        YouTubeToSpotifyView(
                            youtubeToken: youtubeToken!,
                            spotifyToken: spotifyToken!,
                            selectedPlaylist: playlist
                        )
                    } else {
                        YouTubePlaylistPickerView(token: youtubeToken!) { selected in
                            print("📦 Playlist selected: \(selected.snippet.title)")
                            selectedYouTubePlaylist = selected
                            showYouTubeToSpotifyView = true
                        }
                    }
                }
            }

            else if source == .text && destination == .youtube {
                TextToYouTubeView(youtubeToken: youtubeToken!)
            }
            else if source == .spotify && destination == .youtube,
                    let spotifyToken = spotifyToken,
                    let youtubeToken = youtubeToken {
                
                SpotifyPlaylistPickerView(
                    token: spotifyToken,
                    spotifyToken: spotifyToken,
                    youtubeToken: youtubeToken
                ) { selectedPlaylist in
                    
                    SpotifyService.shared.fetchTracksFromPlaylist(
                        token: spotifyToken,
                        playlistID: selectedPlaylist.id
                    ) { songs in
                        print("🎵 Songs to transfer to YouTube:", songs)
                        
                        YouTubeService.shared.searchYouTubeVideos(token: youtubeToken, queries: songs) { videoIDs in
                            YouTubeService.shared.createYouTubePlaylist(token: youtubeToken, title: selectedPlaylist.name) { playlistID in
                                guard let playlistID = playlistID else {
                                    print(" Failed to create YouTube playlist")
                                    return
                                }
                                
                                YouTubeService.shared.addVideosToYouTubePlaylist(token: youtubeToken, playlistID: playlistID, videoIDs: videoIDs) { success in
                                    print(success ? " Transfer complete!" : " Failed to transfer some videos")
                                }
                            }
                        }
                    }
                }
            }

                else {
                VStack(spacing: 20) {
                    Text("Ready to transfer!")
                        .font(.title)
                        .bold()
                    Text("From \(source!.rawValue) → \(destination!.rawValue)")
                        .font(.title2)

                    Button("Start Over") {
                        source = nil
                        destination = nil
                        step = .login
                    }
                    .foregroundColor(.red)
                    .padding()
                }
            }


            
      
            
        }
    }
    
    
    var loginView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    Image("SynkrLogo") // Make sure this is in your Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                    
                    Text("Synkr")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }

            
 
            VStack(spacing: 12) {
                if youtubeToken == nil {
                    loginButton(for: .youtube)
                }
                if spotifyToken == nil {
                    loginButton(for: .spotify)
                }

                if spotifyToken != nil || youtubeToken != nil {
                    Button(action: {
                        withAnimation {
                            step = .source
                        }
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }.padding(.horizontal)
                }
            }
            .padding(.horizontal)
    
            Text("Transfer playlists across platforms effortlessly.")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Text("Powered by XYZ")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }

    
    func loginButton(for platform: Platform) -> some View {
        Button(action: {
            withAnimation {
                if platform == .spotify {
                    SpotifyService.shared.startLogin { code in
                        guard let code = code else { return }
                        SpotifyService.shared.exchangeCodeForToken(code: code) { token in
                            DispatchQueue.main.async {
                                spotifyToken = token
                            }
                        }
                    }
                } else {
                    YouTubeService.shared.startLogin { token in
                        DispatchQueue.main.async {
                            youtubeToken = token
                        }
                    }
                }
            }
        }) {
            HStack {
                Image(platform.logoName)
                    .resizable()
                    .frame(width: 24, height: 24)

                Text("Login with \(platform.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(platform.color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .shadow(color: platform.color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }

    
    func logout() {
        spotifyToken = nil
        youtubeToken = nil
        source = nil
        destination = nil
        step = .login
        
        SpotifyService.shared.logout()
        YouTubeService.shared.logout()
    }
    
    func ensureLogin(for platform: Platform, completion: @escaping (Bool) -> Void) {
        switch platform {
        case .spotify:
            if spotifyToken == nil {
                SpotifyService.shared.startLogin { code in
                    guard let code = code else {
                        completion(false)
                        return
                    }
                    SpotifyService.shared.exchangeCodeForToken(code: code) { token in
                        DispatchQueue.main.async {
                            if let token = token {
                                spotifyToken = token
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                    }
                }
            } else {
                completion(true)
            }

        case .youtube:
            if youtubeToken == nil {
                YouTubeService.shared.startLogin { token in
                    DispatchQueue.main.async {
                        if let token = token {
                            youtubeToken = token
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                }
            } else {
                completion(true)
            }

        case .text:
            completion(true)
        }
    }

}

#Preview{
    ContentView()
}

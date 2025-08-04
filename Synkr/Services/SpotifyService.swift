//
//  SpotifyService.swift
//  Synkr
//
//  Created by Arnav on 28/07/25.
//
import Foundation
import AuthenticationServices

class SpotifyService: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    static let shared = SpotifyService()

    private let clientID = "166b6737531d404c93bba4297db3f5fb"
    private let clientSecret = "cc32b205f16d47078a80b369dd11e5c5"
    private let redirectURI = "synkr://callback"

    private var session: ASWebAuthenticationSession?


    func startLogin(completion: @escaping (String?) -> Void) {
        let scope = "user-read-private playlist-read-private playlist-modify-public"
        let state = UUID().uuidString

        let authURL = URL(string:
            "https://accounts.spotify.com/authorize" +
            "?client_id=\(clientID)" +
            "&response_type=code" +
            "&redirect_uri=\(redirectURI)" +
            "&scope=\(scope)" +
            "&state=\(state)" +
            "&show_dialog=true"
        )!

        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "synkr"
        ) { callbackURL, error in
            guard
                error == nil,
                let callbackURL = callbackURL,
                let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
                let code = queryItems.first(where: { $0.name == "code" })?.value
            else {
                print("Login failed.")
                completion(nil)
                return
            }

            completion(code)
        }

        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = true
        session?.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func exchangeCodeForToken(code: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let params = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "client_secret": clientSecret
        ]

        let body = params.map { "\($0.key)=\($0.value)" }
                         .joined(separator: "&")
                         .data(using: .utf8)

        request.httpBody = body
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let accessToken = json?["access_token"] as? String
                completion(accessToken)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    func logout() {
        HTTPCookieStorage.shared.cookies?.forEach {
            HTTPCookieStorage.shared.deleteCookie($0)
        }
        URLCache.shared.removeAllCachedResponses()
    }


    func createPlaylistFromText(token: String, name: String, songs: [String], completion: @escaping (String) -> Void) {
        fetchUserID(token: token) { userID in
            guard let userID = userID else {
                completion("Failed to get user ID")
                return
            }

            self.createPlaylist(token: token, userID: userID, name: name) { playlistID in
                guard let playlistID = playlistID else {
                    completion("Failed to create playlist")
                    return
                }

                self.searchTracks(token: token, songs: songs) { uris in
                    guard !uris.isEmpty else {
                        completion("No tracks found.")
                        return
                    }

                    self.addTracks(token: token, playlistID: playlistID, trackURIs: uris) { success in
                        completion(success ? "Playlist created successfully!" : "Failed to add tracks.")
                    }
                }
            }
        }
    }


    private func performRequest<T: Decodable>(
        url: URL,
        method: String = "GET",
        token: String,
        body: Data? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else {
                completion(.failure(error ?? URLError(.badServerResponse)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    struct SpotifyUser: Decodable {
        let id: String
    }

    private func fetchUserID(token: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me")!
        performRequest(url: url, token: token, responseType: SpotifyUser.self) { result in
            switch result {
            case .success(let user):
                completion(user.id)
            case .failure(let error):
                print("User ID error:", error)
                completion(nil)
            }
        }
    }

    struct CreatedPlaylist: Decodable {
        let id: String
    }

    private func createPlaylist(token: String, userID: String, name: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/users/\(userID)/playlists")!
        let body = ["name": name, "description": "Created via Synkr", "public": true] as [String : Any]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        performRequest(
            url: url,
            method: "POST",
            token: token,
            body: jsonData,
            responseType: CreatedPlaylist.self
        ) { result in
            switch result {
            case .success(let playlist):
                completion(playlist.id)
            case .failure(let error):
                print("Create playlist error:", error)
                completion(nil)
            }
        }
    }


    private func addTracks(token: String, playlistID: String, trackURIs: [String], completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")!
        let body = ["uris": trackURIs]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }

    private func searchTracks(token: String, songs: [String], completion: @escaping ([String]) -> Void) {
        let group = DispatchGroup()
        var uris: [String] = []

        for song in songs {
            group.enter()
            let query = song.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let url = URL(string: "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, _ in
                defer { group.leave() }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tracks = json["tracks"] as? [String: Any],
                      let items = tracks["items"] as? [[String: Any]],
                      let uri = items.first?["uri"] as? String else {
                    return
                }

                uris.append(uri)
            }.resume()
        }

        group.notify(queue: .main) {
            completion(uris)
        }
    }
    
    func fetchUserPlaylists(token: String, completion: @escaping ([SpotifyPlaylist]) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me/playlists")!

        performRequest(
            url: url,
            token: token,
            responseType: SpotifyPlaylistResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(response.items)
            case .failure(let error):
                print("Error fetching playlists:", error)
                completion([])
            }
        }
    }
    
    func fetchTracksFromPlaylist(token: String, playlistID: String, completion: @escaping ([String]) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")!

        performRequest(url: url, token: token, responseType: SpotifyTrackResponse.self) { result in
            switch result {
            case .success(let response):
                let songs = response.items.compactMap { item in
                    let trackName = item.track.name
                    let artistNames = item.track.artists.map { $0.name }.joined(separator: ", ")
                    return "\(trackName) - \(artistNames)"
                }
                completion(songs)

            case .failure(let error):
                print("Failed to fetch tracks:", error)
                completion([])
            }
        }
    }


}

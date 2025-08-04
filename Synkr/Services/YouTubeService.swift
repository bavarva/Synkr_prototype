//
//  YouTubeSevice.swift
//  Synkr
//
//  Created by Arnav on 28/07/25.
//

import Foundation
import AuthenticationServices
import CryptoKit

class YouTubeService: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    static let shared = YouTubeService()

    private let clientID = "659476832888-jtgrpr75euqa77lf18leurim8q6vifj3"
    private let redirectURI = "com.googleusercontent.apps.659476832888-jtgrpr75euqa77lf18leurim8q6vifj3:/oauthredirect"
    private let scope = "https://www.googleapis.com/auth/youtube.force-ssl"


    
    private var session: ASWebAuthenticationSession?
    private var codeVerifier: String?

    func startLogin(completion: @escaping (String?) -> Void) {
       
        let verifier = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        codeVerifier = verifier
        let challenge = codeChallenge(from: verifier)
        
        

        let state = UUID().uuidString

        let authURL = URL(string:
            "https://accounts.google.com/o/oauth2/v2/auth" +
            "?client_id=\(clientID)" +
            "&redirect_uri=\(redirectURI)" +
            "&response_type=code" +
            "&scope=\(scope)" +
            "&code_challenge=\(challenge)" +
            "&code_challenge_method=S256" +
            "&access_type=offline" +
            "&prompt=consent" +
            "&state=\(state)"
        )!


        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "com.googleusercontent.apps.464218347656-mgsbr0k0h4m0rpgunf7ipfrmu2ph7aq2"
        ) { callbackURL, error in
            guard
                error == nil,
                let callbackURL = callbackURL,
                let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
                let code = queryItems.first(where: { $0.name == "code" })?.value
            else {
                print("YouTube Login failed.")
                completion(nil)
                return
            }

            print("Received YouTube Auth Code:", code)
            self.exchangeCodeForToken(code: code, completion: completion)
        }

        session?.presentationContextProvider = self
        session?.start()
    }

    private func exchangeCodeForToken(code: String, completion: @escaping (String?) -> Void) {
        guard let verifier = codeVerifier else {
            completion(nil)
            return
        }

        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let params = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": verifier
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
                print("YouTube Access Token:", accessToken ?? "nil")
                completion(accessToken)
            } catch {
                print("Failed to decode YouTube token response")
                completion(nil)
            }
        }.resume()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    private func codeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        let challenge = Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return challenge
    }
    
    func logout() {
            HTTPCookieStorage.shared.cookies?.forEach {
                HTTPCookieStorage.shared.deleteCookie($0)
            }
            URLCache.shared.removeAllCachedResponses()
        }
    
    func searchYouTubeVideos(token: String, queries: [String], completion: @escaping ([String]) -> Void) {
        let group = DispatchGroup()
        var videoIDs: [String] = []

        for query in queries {
            group.enter()
            let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(queryEncoded)&type=video&maxResults=1")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, _ in
                defer { group.leave() }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let items = json["items"] as? [[String: Any]],
                      let idInfo = items.first?["id"] as? [String: Any],
                      let videoId = idInfo["videoId"] as? String else {
                    return
                }

                videoIDs.append(videoId)
            }.resume()
        }

        group.notify(queue: .main) {
            completion(videoIDs)
        }
    }

    
    func createYouTubePlaylist(token: String, title: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://www.googleapis.com/youtube/v3/playlists?part=snippet,status")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "snippet": [
                "title": title,
                "description": "Created by Synkr"
            ],
            "status": [
                "privacyStatus": "private"
            ]
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code:", httpResponse.statusCode)
            }

            guard let data = data else {
                print("No data in response")
                completion(nil)
                return
            }

            if let jsonStr = String(data: data, encoding: .utf8) {
                print("Raw YouTube Response:", jsonStr)
            }

            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let id = json?["id"] as? String
            completion(id)
        }.resume()

    }

    
    func addVideosToYouTubePlaylist(token: String, playlistID: String, videoIDs: [String], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var success = true

        for (index, videoID) in videoIDs.enumerated() {
            group.enter()

           
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(index)) {
                print("Adding video ID: \(videoID) to playlist \(playlistID)")
                
                let url = URL(string: "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "snippet": [
                        "playlistId": playlistID,
                        "resourceId": [
                            "kind": "youtube#video",
                            "videoId": videoID
                        ]
                    ]
                ]
                let jsonData = try? JSONSerialization.data(withJSONObject: body)
                request.httpBody = jsonData

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("Add Video Status Code:", httpResponse.statusCode)
                        
                        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                            success = false
                        }

                        if let data = data, let body = String(data: data, encoding: .utf8) {
                            print("YouTube Add Video Error Body:", body)
                        }
                    }

                    group.leave()
                }.resume()
            }
        }

        group.notify(queue: .main) {
            completion(success)
        }
    }
    
    
    func fetchUserPlaylists(token: String, completion: @escaping ([YouTubePlaylist]) -> Void) {
        let url = URL(string: "https://www.googleapis.com/youtube/v3/playlists?part=snippet&mine=true&maxResults=50")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONDecoder().decode(YouTubePlaylistResponse.self, from: data) else {
                completion([])
                return
            }

            completion(json.items)
        }.resume()
    }

    func fetchVideoTitlesFromPlaylist(token: String, playlistID: String, completion: @escaping ([String]) -> Void) {
        var titles: [String] = []
        var nextPageToken: String?

        func fetchPage() {
            var urlStr = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=\(playlistID)"
            if let token = nextPageToken {
                urlStr += "&pageToken=\(token)"
            }

            var request = URLRequest(url: URL(string: urlStr)!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let items = json["items"] as? [[String: Any]] else {
                    completion(titles)
                    return
                }

                for item in items {
                    if let snippet = item["snippet"] as? [String: Any],
                       let title = snippet["title"] as? String {
                        titles.append(title)
                    }
                }

                nextPageToken = json["nextPageToken"] as? String
                if nextPageToken != nil {
                    fetchPage()
                } else {
                    completion(titles)
                }
            }.resume()
        }

        fetchPage()
    }



}

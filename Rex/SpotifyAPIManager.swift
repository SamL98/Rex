import Foundation
import OAuthSwift
//import Locksmith

class SpotifyAPIManager {
    
    // Callback response typealias
    typealias spotify_track_response = ([Song]?, NSError?) -> Void
    typealias spotify_playlist_response = ([Playlist]?, NSError?) -> Void
    
    // MARK: Constants
    fileprivate struct Constants {
        struct Keys {
            static let client_id = "d74ef5930c9e493a8f3100eebd3704eb"
            static let client_secret = "e9511d54ebb04fee8e7989fd52f0aa82"
        }
        struct Components {
            static let response_type = "code"
            static let content_type = "JSON"
            static let scopes = "user-library-read user-library-modify playlist-read-private playlist-read-collaborative playlist-modify-public playlist-modify-private"
            static let state = generateStateWithLength(20) as String
            static let grant_type = "refresh_token"
        }
    }
    
    fileprivate struct URLs {
        static let authorize_url = "https://accounts.spotify.com/authorize"
        static let access_token_url = "https://accounts.spotify.com/api/token"
        static let redirect_uri = URL(string: "rexapp://oauth-callback/spotify")!
        static let user_url = "https://api.spotify.com/v1/me"
        static let user_library_url = "https://api.spotify.com/v1/me/tracks"
        static let user_playlist_url = "https://api.spotify.com/v1/me/playlists"
        static let playlist_url = "https://api.spotify.com/v1/users/"
        static let recommendation_url = "https://api.spotify.com/v1/recommendations"
    }
    
    // MARK: Properties
    static let sharedInstance = SpotifyAPIManager()
    let defaults = UserDefaults.standard
    let webView = WebView()
    let auth = OAuth2Swift(consumerKey: Constants.Keys.client_id, consumerSecret: Constants.Keys.client_secret, authorizeUrl: URLs.authorize_url, accessTokenUrl: URLs.access_token_url, responseType: Constants.Components.response_type, contentType: Constants.Components.content_type)
    
    // MARK: Authentication
    func login(_ onCompletion: @escaping () -> Void) {
        print("logging in to spotify")
        auth.authorize_url_handler = webView
        auth.authorizeWithCallbackURL(URLs.redirect_uri, scope: Constants.Components.scopes, state: Constants.Components.state, success: { (credential, response, parameters) in
            print("login successful")
            self.fetchUserID()
            self.defaults.set(true, forKey: "loggedIn")
            UserDefaults.standard.set(parameters["refresh_token"], forKey: "refreshToken")
            self.startTokenCounter()
            
            onCompletion()
            }, failure: { error in
                print("error while logging into spotify: \(error)")
        })
    }
    
    func refreshAuthToken(_ onCompletion: @escaping () -> Void) {
        print("refreshing oauth token")
        
        guard let refreshToken = UserDefaults.standard.object(forKey: "refreshToken") else {
            print("unable to retrieve refresh token from defaults")
            return
        }
            
        auth.client.post(URLs.access_token_url, parameters: [
            "grant_type":Constants.Components.grant_type,
            "refresh_token":refreshToken
            ], headers: ["Authorization":createRefreshTokenAuthorizationHeader()], success: { (data, response) in
                    
                print("oauth refresh successful")
                let access_token = self.parseJSON(data)
                self.auth.client.credential.oauth_token = access_token
                self.fetchUserID()
                self.startTokenCounter()
                    
                onCompletion()
            }, failure: { error in
                print("error while refreshing oauth token: \(error)")
        })
    }
    
    func createRefreshTokenAuthorizationHeader() -> String {
        let str = "\(Constants.Keys.client_id):\(Constants.Keys.client_secret)"
        let utf8String = str.data(using: String.Encoding.utf8)
        
        if let base64Encoded = utf8String?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) {
            return "Basic \(base64Encoded)"
        } else {
            print("unable to refresh token header")
            return ""
        }
    }
    
    func unauthenticateUser() {
        URLCache.shared.removeAllCachedResponses()
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        defaults.set(false, forKey: "loggedIn")
        defaults.synchronize()
        
        auth.client.credential.oauth_token = ""
        auth.client.credential.oauth_token_secret = ""
        auth.client.credential.oauth_refresh_token = ""
    }
    
    // MARK: Data Fetching
    func fetchUserID() {
        print("fetching user id")
        auth.client.get(URLs.user_url, success: { (data, response) in
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                let id = json["id"] as! String
                UserDefaults.standard.set(id, forKey: "user_id")
            } catch let error as NSError {
                print("error while serializing user id: \(error)")
            }
            }, failure: { error in
                print("failure to fetch user id: \(error)")
        })
    }
    
    func fetchLibrary(_ extraParameters: [String:AnyObject]?, onCompletion: @escaping spotify_track_response) {
        print("fetching library")
        var params = [String:AnyObject]()
        if let extraParams = extraParameters {
            for (key, value) in extraParams {
                params[key] = value
            }
        }
        params["limit"] = 50 as AnyObject?
        
        auth.client.get(URLs.user_library_url, parameters: params, headers: nil, success: { (data, response) in
            self.parseSongs(data) { songs, error in
                guard error == nil else {
                    print("error while parsing library: \(error)")
                    onCompletion(nil, error)
                    return
                }
                
                onCompletion(songs, nil)
            }
            }, failure: { error in
                print("error while fetching library: \(error)")
        })
    }
    
    func fetchRecommendations(_ track: Song, extraParameters: [String:AnyObject]?, onCompletion: @escaping spotify_track_response) {
        print("fetching recommendations")
        var params = [String:AnyObject]()
        if let extraParams = extraParameters {
            for (key, value) in extraParams {
                params[key] = value
            }
        }
        params["seed_tracks"] = track.trackID as AnyObject?
        params["limit"] = 50 as AnyObject?
        
        auth.client.get(URLs.recommendation_url, parameters: params, headers: nil, success: { (data, response) in
            self.parseRecs(data) { songs, error in
                guard error == nil else {
                    print("error while parsing recommendations: \(error)")
                    onCompletion(nil, error)
                    return
                }
                
                onCompletion(songs, nil)
            }
            }, failure: { error in
                print("error while fetching recommendations: \(error)")
        })
    }
    
    func fetchPlaylists(_ onCompletion: @escaping spotify_playlist_response) {
        print("fetching user playlists")
        auth.client.get(URLs.user_playlist_url, success: { (data, response) in
            self.parsePlaylists(data) { playlists, error in
                guard playlists != nil else {
                    print("error while parsing playlists: \(error)")
                    onCompletion(nil, error)
                    return
                }
                
                onCompletion(playlists, nil)
            }
            }, failure: { error in
                print("error while fetching playlists: \(error)")
        })
    }
    
    func fetchPlaylistTracks(_ playlist: Playlist, extraParameters: [String:AnyObject]?, onCompletion: @escaping spotify_track_response) {
        print("fetching tracks for playlist")
        var params = [String:AnyObject]()
        if let extraParams = extraParameters {
            for (key, value) in extraParams {
                params[key] = value
            }
        }
        params["limit"] = 50 as AnyObject?
        
        let targetURL = URLs.playlist_url + (UserDefaults.standard.object(forKey: "user_id") as! String) + "/playlists/" + playlist.id + "/tracks"
        auth.client.get(targetURL, parameters: params, headers: nil, success: { (data, response) in
            self.parseSongs(data, onCompletion: { (songs, error) in
                guard error == nil else {
                    print("error while parsing tracks for playlist: \(error)")
                    onCompletion(nil, error)
                    return
                }
                
                onCompletion(songs, nil)
            })
            }, failure: { error in
                print("error while fetching tracks for playlist: \(error)")
        })
    }
    
    // Data Posting/Deleting
    func saveTrack(_ track: Song, onCompletion: @escaping () -> Void) {
        print("saving track")
        var url = URLComponents(string: URLs.user_library_url)
        url?.queryItems = [URLQueryItem(name: "ids", value: track.trackID)]
        let request = NSMutableURLRequest(url: (url?.url)!)
        
        request.httpMethod = "PUT"
        request.addValue("Bearer \(auth.client.credential.oauth_token)", forHTTPHeaderField: "Authorization")
            
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil else {
                print("error while saving track: \(error)")
                return
            }
            
            guard (response as! HTTPURLResponse).statusCode == 200 else {
                print("save failed. http status code: \((response as! HTTPURLResponse).statusCode))")
                return
            }
                
            print("successfully saved track")
            onCompletion()
        }) 
        task.resume()
    }
    
    func saveToPlaylist(_ track: Song, playlist: Playlist, onCompletion: @escaping () -> Void) {
        print("saving track to playlist")
        let urlString = URLs.playlist_url + (UserDefaults.standard.object(forKey: "user_id") as! String) + "/playlists/" + playlist.id + "/tracks"
        var url = URLComponents(string: urlString)
        url?.queryItems = [URLQueryItem(name: "uris", value: "spotify:track:\(track.trackID)")]

        let request = NSMutableURLRequest(url: (url?.url)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(auth.client.credential.oauth_token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil else {
                print("save to playlist failed: \(error)")
                return
            }

            print("http status code: \((response as! HTTPURLResponse).statusCode)")
            print("successfully saved track to playlist")
            onCompletion()
        }) 
        task.resume()
    }
    
    // MARK: JSON Parsing
    func parseJSON(_ data: Data) -> String {
        print("parsing JSON")
        do {
            let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            let token = jsonDictionary["access_token"] as! String
            return token
        } catch let error as NSError {
            print("error while serializing auth JSON: \(error)")
            return ""
        }
    }
    
    func parseRecs(_ data: Data, onCompletion: spotify_track_response) {
        print("parsings recommendations")
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            let tracks = jsonObject["tracks"] as! NSArray
            
            var songs = [Song]()
            for track in tracks {
                if let title = track["name"] as? String,
                    let id = track["id"] as? String,
                    let artist = ((track["artists"] as! [[String:AnyObject]])[0])["name"] as? String,
                    let urlString = (((track["album"] as! [String:AnyObject])["images"] as! [[String:AnyObject]])[0])["url"] as? String,
                    let url = URL(string: urlString),
                    let previewString = track["preview_url"] as? String,
                    let previewURL = URL(string: previewString) {
                
                    let song = Song(title: title, artist: artist, trackID: id, imageURL: url, image: nil, preview: previewURL)
                    songs.append(song)
                }
            }
            onCompletion(songs, nil)
            
        } catch let error as NSError {
            print("error while serializing recommendation JSON")
            onCompletion(nil, error)
        }
    }
    
    func parseSongs(_ data: Data, onCompletion: spotify_track_response) {
        print("parsing songs")
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            let tracks = jsonObject["items"] as! [[String:AnyObject]]
            
            var songs = [Song]()
            for item in tracks {
                if let track = item["track"] as? [String:AnyObject],
                    let title = track["name"] as? String,
                    let id = track["id"] as? String,
                    let artist = ((track["artists"] as! [[String:AnyObject]])[0])["name"] as? String,
                    let urlString = (((track["album"] as! [String:AnyObject])["images"] as! [[String:AnyObject]])[0])["url"] as? String,
                    let url = URL(string: urlString) {
                    
                    let song = Song(title: title, artist: artist, trackID: id, imageURL: url, image: nil, preview: nil)
                    songs.append(song)
                }
            }
            onCompletion(songs, nil)
            
        } catch {
            print("error while serializing song JSON")
            onCompletion(nil, NSError(domain: "Spotify", code: 420, userInfo: nil))
        }
    }
    
    func parsePlaylists(_ data: Data, onCompletion: spotify_playlist_response) {
        print("parsing playlists")
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            let items = jsonObject["items"] as! [[String:AnyObject]]
            
            var playlists = [Playlist]()
            for playlist in items {
                if let title = playlist["name"] as? String, let id = playlist["id"] as? String {
                    let list = Playlist(title: title, id: id)
                    playlists.append(list)
                }
            }
            onCompletion(playlists, nil)
            
        } catch let error as NSError {
            print("error while serializing playlist JSON: \(error)")
            onCompletion(nil, error)
        }
    }
    
}

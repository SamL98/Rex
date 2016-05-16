import Foundation

class Playlist {
    
    var title: String!
    var id: String!
    var trackList: [Song]!
    
    init(title: String, id: String) {
        self.title = title
        self.id = id
    }
    
    func tracks() {
        SpotifyAPIManager.sharedInstance.fetchPlaylistTracks(self, extraParameters: nil) { (songs, error) in
            guard error == nil else {
                print("unable to populate track list: \(error)")
                return
            }
            
            self.trackList = songs
        }
    }
    
}

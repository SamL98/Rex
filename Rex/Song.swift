import UIKit

class Song {
    
    var title: String
    var artist: String
    var albumImageURL: NSURL
    var trackID: String
    var image: UIImage?
    var previewURL: NSURL?
    
    init(title: String, artist: String, trackID: String, imageURL: NSURL, image: UIImage?, preview: NSURL?) {
        self.title = title
        self.artist = artist
        self.trackID = trackID
        self.albumImageURL = imageURL
        self.image = image
        self.previewURL = preview
    }
    
}

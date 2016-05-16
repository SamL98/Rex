import UIKit

class SongTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet var albumImageView: UIImageView!
    @IBOutlet var songTitle: UILabel!
    @IBOutlet var artistName: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var song: Song! {
        didSet {
            setUpCell()
        }
    }
    
    // MARK: Actions
    func updateImage(image: UIImage?) {
        if let imageToDisplay = image {
            spinner.stopAnimating()
            albumImageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            albumImageView.image = nil
        }
    }
    
    func setUpCell() {
        songTitle.text = song.title
        artistName.text = song.artist
        
        if song.image != nil {
            albumImageView.image = song.image
        } else {
            updateImage(nil)
            albumImageView.downloadedFrom(song.albumImageURL) { (image, error) in
                guard error == nil else {
                    print("error while fetching image: \(error)")
                    return
                }
                
                if let albumCover = image {
                    self.updateImage(albumCover)
                    self.song.image = albumCover
                    self.spinner.hidden = true
                }
            }
        }
    }

}

// MARK: UIImageView Extension
extension UIImageView {
    func downloadedFrom(targetURL: NSURL, onCompletion: (UIImage?, NSError?) -> Void) {
        print("downloading image")
        SpotifyAPIManager.sharedInstance.auth.client.get(targetURL.absoluteString, success: { (data, response) in
            print("successfully downloaded image")
            guard (response as NSHTTPURLResponse).statusCode == 200 else  {
                print("error in http response. status code: \((response as NSHTTPURLResponse).statusCode)")
                return
            }
            
            let image = UIImage(data: data)
            onCompletion(image, nil)
            }, failure: { error in
                print("error while downloading image: \(error)")
                onCompletion(nil, error)
        })
    }
}

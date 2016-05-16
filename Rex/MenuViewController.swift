import UIKit

class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: Properties
    @IBOutlet var tableView: UITableView!
    var playlists: [Playlist]!
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: Data Service
    func populatePlaylists() {
        SpotifyAPIManager.sharedInstance.fetchPlaylists { (playlists, error) in
            guard error == nil else {
                print("unable to populate playlists: \(error)")
                return
            }
            
            self.playlists = playlists
            
            var i = 0
            while i < self.playlists.count - 1 {
                if self.playlists[i].title == "Discover Weekly" { self.playlists.removeAtIndex(i); break }
                i += 1
            }
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (playlists != nil ? playlists.count + 1 : 1)
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 35.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistCell")!
        let title = cell.viewWithTag(69) as! UILabel
        
        if indexPath.row == 0 {
            title.text = "Library"
        } else {
            guard playlists != nil else {
                return cell
            }
            
            title.text = playlists[indexPath.row - 1].title
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let container = self.parentViewController as! ContainerViewController
        container.toggleMenu()
        let children = container.childViewControllers
        var vc = ViewController()
        
        for child in children {
            if let nc = child as? UINavigationController {
                vc = nc.viewControllers.first as! ViewController
                break
            }
        }
        
        vc.timeAd()
        
        if indexPath.row == 0 {
            vc.isLibrary = true
            vc.populateTracks()
            vc.navigationItem.title = "Your Music"
        } else {
            vc.isLibrary = false
            vc.playlist = playlists[indexPath.row - 1]
            vc.tracks = nil
            vc.isSearching = false
            vc.searchText = ""
            
            vc.populateTracks()
            vc.navigationItem.title = playlists[indexPath.row - 1].title
        }
    }

}

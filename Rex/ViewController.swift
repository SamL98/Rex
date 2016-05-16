import UIKit
import SwiftyTimer
import GoogleMobileAds

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, GADInterstitialDelegate {
    
    // MARK: Properties
    //// Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var hamburgerButton: UIBarButtonItem!
    
    //// Track Variables
    var tracks: [Song]!
    var searchResults = [Song]()
    var playlist: Playlist!
    var selectedTrack: Song!
    
    //// Flags
    var shouldPresentError = false
    var loadedTracks = false
    var isLibrary = true
    var isSearching = false
    var canRefresh = false
    
    //// Ad Properties
    var interstitialAd: GADInterstitial!
    
    //// Custom Views
    var loadingView = LoadingView(frame: CGRectZero)
    var loginButton: UIButton!
    var infoLabel = UILabel()
    
    //// Search Variables
    var searchText = ""
    
    //// Utility
    var offsetCount = 0
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkNetworkStatus()
        
        self.navigationItem.titleView?.alpha = 0.7
        tableView.hidden = true
        
        loadingView.frame = CGRect(x: view.bounds.width/3, y: 2*view.bounds.height/5, width: view.bounds.width/3, height: view.bounds.width/3)
        view.addSubview(loadingView)
        
        interstitialAd = createAd()
        
        var loginClosure: () -> Void
        
        if !self.defaults.boolForKey("loggedIn") {
            loginClosure = {
                if self.shouldPresentError {
                    self.presentErrorMessage()
                } else {
                    self.addLoginButton()
                    self.addLoginInfo()
                    self.view.addSubview(self.loginButton)
                }
            }
        } else {
            SpotifyAPIManager.sharedInstance.refreshAuthToken() {
                self.populateTracks()
            }
            loginClosure = {
                if self.shouldPresentError { self.presentErrorMessage() }
                else { self.tableView.hidden = false }
            }
        }
        
        loadingView.addTriangle(loginClosure)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: Network Availability
    func checkNetworkStatus() {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            print("Not connected")
            shouldPresentError = true
            let alert = UIAlertController(title: "No internet connection", message: "Please turn on Wifi or Cellular Data to be able to use Rex.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        case .Online(.WWAN):
            print("Connected via WWAN")
        case .Online(.WiFi):
            print("Connected via WiFi")
        }
    }
    
    func presentErrorMessage() {
        let error = UILabel(frame: CGRectMake(0, view.bounds.height/3, view.bounds.width, 200.0))
        error.text = "Sorry"
        error.textAlignment = .Center
        error.font = UIFont(name: "Avenir Next", size: 75.0)
        error.textColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        view.addSubview(error)
        
        let message = UILabel(frame: CGRectMake(0, view.bounds.height/3 + 200.0, view.bounds.width, 200.0))
        message.numberOfLines = 0
        message.text = "Try connecting to wifi or data and refreshing Rex."
        message.textAlignment = .Center
        message.textColor = UIColor.lightGrayColor()
        message.font = UIFont(name: "Avenir Next", size: 35.0)
        view.addSubview(message)
    }
    
    // MARK: Data Service
    func loginButtonTapped() {
        SpotifyAPIManager.sharedInstance.login() {
            self.tableView.hidden = false
            self.infoLabel.removeFromSuperview()
            self.loginButton.removeFromSuperview()
            self.populateTracks()
        }
    }
    
    func populateTracks() {
        print("populating track list")
        if isLibrary {
            SpotifyAPIManager.sharedInstance.fetchLibrary(nil) { songs, error in
                guard error == nil else {
                    print("error while populating track list: \(error)")
                    return
                }
                
                if let results = songs {
                    print("successfully populated track list")
                    self.loadedTracks = true
                    self.tracks = results
                    
                    self.tableView.reloadData()
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
                }
            }
        } else {
            SpotifyAPIManager.sharedInstance.fetchPlaylistTracks(playlist, extraParameters: nil) { songs, error in
                guard error == nil else {
                    print("error while populating track list: \(error)")
                    return
                }
                
                if let results = songs {
                    print("successfully populated track list")
                    self.loadedTracks = true
                    self.tracks = results
                    
                    self.tableView.reloadData()
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
                }
            }
        }
    }
    
    func refresh() {
        offsetCount += 1
        
        if isLibrary {
            SpotifyAPIManager.sharedInstance.fetchLibrary(["offset":(50*offsetCount)]) { songs, error in
                guard error == nil else {
                    print("error while refreshing track list: \(error)")
                    return
                }
            
                if let results = songs {
                    print("successfully refreshed track list")
                    self.tracks.appendContentsOf(results)
                    
                    if !self.isSearching { self.tableView.reloadData() }
                    else { self.updateSearchResults() }
                    
                    self.canRefresh = false
                }
            }
        } else {
            SpotifyAPIManager.sharedInstance.fetchPlaylistTracks(playlist, extraParameters: ["offset":(50*offsetCount)]) { songs, error in
                guard error == nil else {
                    print("error while refreshing playlist track list: \(error)")
                    return
                }
                
                if let results = songs {
                    print("successfully refreshed playlist track list")
                    self.tracks.appendContentsOf(results)
                    
                    if !self.isSearching { self.tableView.reloadData() }
                    else { self.updateSearchResults() }
                        
                    self.canRefresh = false
                }
            }
        }
    }
    
    // MARK: AdMob
    func timeAd() {
        NSTimer.after(3.0.seconds) { self.displayAd() }
    }
    
    func createAd() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-1966629303185292/7887414963")
        let request = GADRequest()
        request.testDevices = ["2077ef9a63d2b398840261c8221a0c9b"]
        interstitial.loadRequest(request)
        return interstitial
    }
    
    func displayAd() {
        if interstitialAd.isReady {
            interstitialAd.presentFromRootViewController(self)
        }
    }
    
    // MARK: GADInterstitialDelegate
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        interstitialAd = createAd()
    }
    
    // MARK: Searching
    func updateSearchResults() {
        print("searching for matches")
        if searchText != "" {
            searchResults.removeAll()
            searchText = searchText.lowercaseString
            for track in tracks {
                if track.title.lowercaseString.containsString(searchText) {
                    searchResults.append(track)
                } else if track.artist.lowercaseString.containsString(searchText) {
                    searchResults.append(track)
                }
            }
            isSearching = true
            tableView.reloadData()
        } else {
            isSearching = false
            tableView.reloadData()
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadedTracks {
            if isSearching { return searchResults.count + 2 }
            else { return tracks.count + 1 }
        }
        
        return 0
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isSearching {
            if indexPath.row == searchResults.count + 1 { return 100.0 }
        }
        
        if indexPath.row == 0 { return 40.0 }
        else { return 75.0 }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard indexPath.row != 0 else {
            let cell = tableView.dequeueReusableCellWithIdentifier("searchCell")!
            let searchBar = (cell.viewWithTag(420) as! UISearchBar)
            searchBar.text = searchText == "" ? nil : searchText
            searchBar.enablesReturnKeyAutomatically = false
            searchBar.delegate = self
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("songCell") as! SongTableViewCell
        
        if isSearching {
            if indexPath.row == searchResults.count + 1 {
                let errorCell = tableView.dequeueReusableCellWithIdentifier("errorCell")!
                (errorCell.viewWithTag(666) as! UIButton).addTarget(self, action: #selector(ViewController.refresh), forControlEvents: .TouchUpInside)
                return errorCell
            }
            
            cell.song = searchResults[indexPath.row - 1]
        } else {
            if indexPath.row == tracks.count - 1 { canRefresh = true }
            cell.song = tracks[indexPath.row - 1]
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedTrack = tracks[indexPath.row]
        performSegueWithIdentifier("showRecs", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if canRefresh {
            if tableView.contentOffset.y + tableView.frame.size.height >= tableView.contentSize.height {
                canRefresh = false
                refresh()
            }
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let text = searchBar.text {
            searchText = text
            updateSearchResults()
        }
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showRecs" {
            let rvc = segue.destinationViewController as! RecommendationTableViewController
            rvc.playlist = playlist
            rvc.isPlaylist = !isLibrary
            rvc.seed = selectedTrack
        }
    }
    
    // MARK: View Initialization
    func addLoginButton() {
        loginButton = UIButton(frame: CGRectMake(view.bounds.width/3 + 5.0, view.bounds.height/2 - 20.0, view.bounds.width/3 - 10.0, 40.0))
        loginButton.addTarget(self, action: #selector(ViewController.loginButtonTapped), forControlEvents: .TouchUpInside)
    
        loginButton.backgroundColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        loginButton.layer.cornerRadius = 10.0
    
        loginButton.setTitle("Log In", forState: .Normal)
        loginButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }
    
    func addLoginInfo() {
        infoLabel.frame = CGRectMake(view.bounds.width/6, view.bounds.height/4, 2*view.bounds.width/3, 125.0)
        infoLabel.textAlignment = .Center
        infoLabel.textColor = UIColor.darkGrayColor()
        infoLabel.font = UIFont(name: "Avenir Next", size: 20.0)
        infoLabel.numberOfLines = 0
        infoLabel.text = "Rex uses your Spotify account to provide recommendations. Please login to Spotify to use Rex."
        view.addSubview(infoLabel)
    }
    
    // MARK: Actions
    @IBAction func logout(sender: UIBarButtonItem) {
        infoLabel.alpha = 0
        addLoginInfo()
        
        addLoginButton()
        loginButton.alpha = 0.0
        view.addSubview(loginButton)
        
        SpotifyAPIManager.sharedInstance.unauthenticateUser()
        
        UIView.animateWithDuration(0.5, animations: {
            self.infoLabel.alpha = 1.0
            self.loginButton.alpha = 1.0
            self.tableView.alpha = 0.0
        }) {_ in
            self.tableView.hidden = true
            self.tableView.alpha = 1.0
        }
    }
    
}


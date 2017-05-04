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
    var loadingView = LoadingView(frame: CGRect.zero)
    var loginButton: UIButton!
    var infoLabel = UILabel()
    
    //// Search Variables
    var searchText = ""
    
    //// Utility
    var offsetCount = 0
    let defaults = UserDefaults.standard
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkNetworkStatus()
        
        self.navigationItem.titleView?.alpha = 0.7
        tableView.isHidden = true
        
        loadingView.frame = CGRect(x: view.bounds.width/3, y: 2*view.bounds.height/5, width: view.bounds.width/3, height: view.bounds.width/3)
        view.addSubview(loadingView)
        
        interstitialAd = createAd()
        
        var loginClosure: () -> Void
        
        if !self.defaults.bool(forKey: "loggedIn") {
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
                else { self.tableView.isHidden = false }
            }
        }
        
        loadingView.addTriangle(loginClosure)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedTrack = nil
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Network Availability
    func checkNetworkStatus() {
        let status = Reach().connectionStatus()
        switch status {
        case .unknown, .offline:
            print("Not connected")
            shouldPresentError = true
            let alert = UIAlertController(title: "No internet connection", message: "Please turn on Wifi or Cellular Data to be able to use Rex.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        case .online(.wwan):
            print("Connected via WWAN")
        case .online(.wiFi):
            print("Connected via WiFi")
        }
    }
    
    func presentErrorMessage() {
        let error = UILabel(frame: CGRect(x: 0, y: view.bounds.height/3, width: view.bounds.width, height: 200.0))
        error.text = "Sorry"
        error.textAlignment = .center
        error.font = UIFont(name: "Avenir Next", size: 75.0)
        error.textColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        view.addSubview(error)
        
        let message = UILabel(frame: CGRect(x: 0, y: view.bounds.height/3 + 200.0, width: view.bounds.width, height: 200.0))
        message.numberOfLines = 0
        message.text = "Try connecting to wifi or data and refreshing Rex."
        message.textAlignment = .center
        message.textColor = UIColor.lightGray
        message.font = UIFont(name: "Avenir Next", size: 35.0)
        view.addSubview(message)
    }
    
    // MARK: Data Service
    func loginButtonTapped() {
        SpotifyAPIManager.sharedInstance.login() {
            self.tableView.isHidden = false
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
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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
                    self.tracks.append(contentsOf: results)
                    
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
                    self.tracks.append(contentsOf: results)
                    
                    if !self.isSearching { self.tableView.reloadData() }
                    else { self.updateSearchResults() }
                        
                    self.canRefresh = false
                }
            }
        }
    }
    
    // MARK: AdMob
    func timeAd() {
        Timer.after(3.0.seconds) { self.displayAd() }
    }
    
    func createAd() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-1966629303185292/7887414963")
        let request = GADRequest()
        request.testDevices = ["2077ef9a63d2b398840261c8221a0c9b"]
        interstitial.load(request)
        return interstitial
    }
    
    func displayAd() {
        if interstitialAd.isReady {
            interstitialAd.present(fromRootViewController: self)
        }
    }
    
    // MARK: GADInterstitialDelegate
    func interstitialDidDismissScreen(_ ad: GADInterstitial!) {
        interstitialAd = createAd()
    }
    
    // MARK: Searching
    func updateSearchResults() {
        print("searching for matches")
        if searchText != "" {
            searchResults.removeAll()
            searchText = searchText.lowercased()
            for track in tracks {
                if track.title.lowercased().contains(searchText) {
                    searchResults.append(track)
                } else if track.artist.lowercased().contains(searchText) {
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadedTracks {
            if isSearching { return searchResults.count + 2 }
            else { return tracks.count + 1 }
        }
        
        return 0
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching {
            if indexPath.row == searchResults.count + 1 { return 100.0 }
        }
        
        if indexPath.row == 0 { return 40.0 }
        else { return 75.0 }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row != 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell")!
            let searchBar = (cell.viewWithTag(420) as! UISearchBar)
            searchBar.text = searchText == "" ? nil : searchText
            searchBar.enablesReturnKeyAutomatically = false
            searchBar.delegate = self
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell") as! SongTableViewCell
        
        if isSearching {
            if indexPath.row == searchResults.count + 1 {
                let errorCell = tableView.dequeueReusableCell(withIdentifier: "errorCell")!
                (errorCell.viewWithTag(666) as! UIButton).addTarget(self, action: #selector(ViewController.refresh), for: .touchUpInside)
                return errorCell
            }
            
            cell.song = searchResults[indexPath.row - 1]
        } else {
            if indexPath.row == tracks.count - 1 { canRefresh = true }
            cell.song = tracks[indexPath.row - 1]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isSearching {
            selectedTrack = tracks[indexPath.row - 1]
        } else {
            if indexPath.row != searchResults.count + 1 {
                selectedTrack = searchResults[indexPath.row - 1]
            }
        }
        performSegue(withIdentifier: "showRecs", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canRefresh {
            if tableView.contentOffset.y + tableView.frame.size.height >= tableView.contentSize.height {
                canRefresh = false
                refresh()
            }
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            searchText = text
            updateSearchResults()
        }
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRecs" {
            let rvc = segue.destination as! RecommendationTableViewController
            rvc.playlist = playlist
            rvc.isPlaylist = !isLibrary
            rvc.seed = selectedTrack
        }
    }
    
    // MARK: View Initialization
    func addLoginButton() {
        loginButton = UIButton(frame: CGRect(x: view.bounds.width/3 + 5.0, y: view.bounds.height/2 - 20.0, width: view.bounds.width/3 - 10.0, height: 40.0))
        loginButton.addTarget(self, action: #selector(ViewController.loginButtonTapped), for: .touchUpInside)
    
        loginButton.backgroundColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        loginButton.layer.cornerRadius = 10.0
    
        loginButton.setTitle("Log In", for: UIControlState())
        loginButton.setTitleColor(UIColor.white, for: UIControlState())
    }
    
    func addLoginInfo() {
        infoLabel.frame = CGRect(x: view.bounds.width/6, y: view.bounds.height/5 - 25.0, width: 2*view.bounds.width/3, height: 175.0)
        infoLabel.textAlignment = .center
        infoLabel.textColor = UIColor.darkGray
        infoLabel.font = UIFont(name: "Avenir Next", size: 20.0)
        infoLabel.numberOfLines = 0
        infoLabel.text = "Rex uses your Spotify account to provide recommendations. Please login to Spotify to use Rex."
        view.addSubview(infoLabel)
    }
    
    // MARK: Actions
    @IBAction func logout(_ sender: UIBarButtonItem) {
        infoLabel.alpha = 0
        addLoginInfo()
        
        addLoginButton()
        loginButton.alpha = 0.0
        view.addSubview(loginButton)
        
        SpotifyAPIManager.sharedInstance.unauthenticateUser()
        
        UIView.animate(withDuration: 0.5, animations: {
            self.infoLabel.alpha = 1.0
            self.loginButton.alpha = 1.0
            self.tableView.alpha = 0.0
        }, completion: {_ in
            self.tableView.isHidden = true
            self.tableView.alpha = 1.0
        }) 
    }
    
}


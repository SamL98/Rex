import UIKit
import AVFoundation
import SwiftyTimer
import GoogleMobileAds

class RecommendationTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GADInterstitialDelegate {

    // MARK: Properties
    @IBOutlet var tableView: UITableView!
    
    //// Custom Views
    var playButton: UIView!
    var pauseButton: UIView!
    var uploadButton: UIView!
    var checkmark: UIView!
    
    //// Loading Flags
    var loadedRecs = false
    
    //// Timer Flags
    var shouldUpdate = false
    var shouldFade = false
    
    //// Cell Flags
    var isPlaying: [Bool]!
    var isUploaded: [Bool]!
    
    //// Ad Properties
    var interstitialAd: GADInterstitial!
    
    //// Timers
    var timer: NSTimer!
    var fadeTimer: NSTimer!
    
    //// Time Keepers
    var time: Int = 0
    var fadeOutTime: Float = 0.0
    
    //// Track Properties
    var seed: Song!
    var recommendations: [Song]!
    
    //// Playlist Properties
    var playlist: Playlist!
    var isPlaylist = false
    
    //// Refresh Properties
    var canRefresh = false
    var offsetCount: Int = 0
    
    //// Utility
    var tapIndex: Int!
    var player: AVPlayer!
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Recommendations"
        self.navigationItem.titleView?.alpha = 0.7
        self.navigationItem.titleView?.frame.size.height = 44.0
        
        timer = NSTimer.new(every: 1.seconds) { self.updateTime() }
        timer.start()
        
        interstitialAd = createAd()
        
        let session = AVAudioSession()
        do {
            try session.setActive(true)
        } catch let error {
            print("error while initializing audio session: \(error)")
        }
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error {
            print("error while initializing audio session: \(error)")
        }

        populateRecommendations()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSTimer.after(3.0) { self.displayAd() }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        time = 0
        fadeOutTime = 0.0
        
        shouldFade = false
        shouldUpdate = false
        
        if player != nil { player.pause() }
        if fadeTimer != nil { fadeTimer.invalidate() }
        
        timer.invalidate()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: Data Service
    func populateRecommendations() {
        print("populating recommendations")
        guard seed != nil else {
            print("no seed track available")
            return
        }
        
        SpotifyAPIManager.sharedInstance.fetchRecommendations(seed, extraParameters: nil) { results, error in
            guard error == nil else {
                print("unable to populate recommendations")
                return
            }
            
            if let tracks = results {
                print("successfully populated recommendations")
                self.recommendations = tracks
                
                self.isPlaying = Array(count: self.recommendations.count, repeatedValue: false)
                self.isUploaded = Array(count: self.recommendations.count, repeatedValue: false)
                
                self.loadedRecs = true
                self.tableView.reloadData()
            }
        }
    }
    
    func refresh() {
        print("refreshing recommendations")
        offsetCount += 1
        SpotifyAPIManager.sharedInstance.fetchRecommendations(seed, extraParameters: ["offset":(50*offsetCount)]) { results, error in
            guard error == nil else {
                print("unable to refresh recommendations")
                return
            }
            
            if let tracks = results {
                print("successfully refreshed recommendations")
                let notPlaying = Array(count: tracks.count, repeatedValue: false)
                let notUploaded = Array(count: tracks.count, repeatedValue: false)
                
                self.isPlaying.appendContentsOf(notPlaying)
                self.isUploaded.appendContentsOf(notUploaded)
                
                self.recommendations.appendContentsOf(tracks)
                
                self.canRefresh = false
                self.tableView.reloadData()
            }
        }
    }
    
    func uploadSong(sender: UITapGestureRecognizer) {
        print("uploading song")
        
        tapIndex = (sender.view?.tag)! - 500
        let indexPath = NSIndexPath(forRow: tapIndex, inSection: 0)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SongTableViewCell
        let song = cell.song
        
        SpotifyAPIManager.sharedInstance.saveTrack(song, onCompletion: {
            self.isUploaded[self.tapIndex] = true
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        })
    }
    
    func uploadToPlaylist(sender: UITapGestureRecognizer) {
        print("saving to playlist")
        
        tapIndex = (sender.view?.tag)! - 500
        let indexPath = NSIndexPath(forRow: tapIndex, inSection: 0)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SongTableViewCell
        let song = cell.song
        
        SpotifyAPIManager.sharedInstance.saveToPlaylist(song, playlist: playlist) {
            self.isUploaded[self.tapIndex] = true
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: AdMob
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

    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadedRecs {
            return recommendations.count
        }
        
        return 0
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("recCell", forIndexPath: indexPath) as! SongTableViewCell
        let recommendation = recommendations[indexPath.row]
        
        let buttonWidth = cell.contentView.frame.height/2 - 5.0
        let primaryFrame = CGRect(x: 3*cell.contentView.frame.width/4 + 5.0, y: cell.contentView.bounds.origin.y + cell.contentView.frame.height/4 + 10.0, width: buttonWidth, height: buttonWidth)
        
        pauseButton = createPlaybackButton(primaryFrame, index: indexPath.row, type: "pause")
        playButton = createPlaybackButton(primaryFrame, index: indexPath.row, type: "play")
        
        if isPlaying[indexPath.row] {
            cell.addSubview(playButton)
            cell.insertSubview(pauseButton, aboveSubview: playButton)
        } else {
            cell.addSubview(pauseButton)
            cell.insertSubview(playButton, aboveSubview: pauseButton)
        }
        
        let secondaryFrame = CGRectMake(playButton.frame.maxX + 5.0, playButton.frame.origin.y, playButton.frame.size.width, playButton.frame.size.height)
        
        uploadButton = createUploadButtons(secondaryFrame, index: indexPath.row, type: "upload")
        checkmark = createUploadButtons(secondaryFrame, index: indexPath.row, type: "checkmark")
        
        if isUploaded[indexPath.row] {
            cell.addSubview(uploadButton)
            cell.insertSubview(checkmark, aboveSubview: uploadButton)
        } else {
            cell.addSubview(checkmark)
            cell.insertSubview(uploadButton, aboveSubview: checkmark)
        }
        
        if indexPath.row == recommendations.count - 1 { canRefresh = true }
        
        cell.song = recommendation
        
        return cell
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if canRefresh {
            if tableView.contentOffset.y + tableView.frame.size.height >= tableView.contentSize.height {
                canRefresh = false
                refresh()
            }
        }
    }
    
    // MARK: Playback
    func playPreview(sender: UITapGestureRecognizer) {
        tapIndex = sender.view!.tag - 200
        let indexPath = NSIndexPath(forRow: tapIndex, inSection: 0)
        
        setToPlaying(indexPath)
        tableView.reloadData()
    
        let rec = recommendations[tapIndex]
        let url = rec.previewURL!
        
        let playerItem = AVPlayerItem(URL: url)
        player = AVPlayer(playerItem: playerItem)
        player.volume = 1.0
        player.play()
        
        fadeOutTime = 0.0
        time = 0
        
        shouldFade = false
        shouldUpdate = true
    }
    
    func pausePreview(sender: UITapGestureRecognizer) {
        player.pause()
    
        shouldUpdate = false
        
        tapIndex = sender.view!.tag - 200
        let indexPath = NSIndexPath(forRow: tapIndex, inSection: 0)
        isPlaying[indexPath.row] = false
        
        tableView.reloadData()
    }
    
    // MARK: Audio
    @objc func updateTime() {
        if shouldUpdate {
            time += 1
            if time == 25 {
                shouldFade = true
                fadeTimer = NSTimer.new(every: 0.1.seconds) { self.fadeOut() }
                fadeTimer.start()
            } else if time == 30 {
                player.pause()
                time = 0
            }
        }
    }
    
    @objc func fadeOut() {
        if shouldFade {
            fadeOutTime += 0.1
            let newVolume: Float = 1/(2*(fadeOutTime+0.5))
        
            if newVolume <= 0.01 {
                fadeOutTime = 0.0
                time = 0
                
                player.pause()
                shouldUpdate = false
                shouldFade = false
            }
        
            player.volume = newVolume
        }
    }
    
    // MARK: View Initialization
    func createPlaybackButton(frame: CGRect, index: Int, type: String) -> UIView {
        let button = type == "play" ? PlayView(frame: frame) : PauseView(frame: frame)
        button.backgroundColor = UIColor.clearColor()
        button.tag = index + 200
        
        let selector = type == "play" ? #selector(RecommendationTableViewController.playPreview(_:)) : #selector(RecommendationTableViewController.pausePreview(_:))
        let recognizer = UITapGestureRecognizer(target: self, action: selector)
        button.addGestureRecognizer(recognizer)
        
        return button
    }
    
    func createUploadButtons(frame: CGRect, index: Int, type: String) -> UIView {
        let button = type == "upload" ? UploadView(frame: frame) : CheckView(frame: frame)
        button.backgroundColor = UIColor.clearColor()
        
        if type == "upload" {
            button.tag = index + 500
            let selector = isPlaylist ? #selector(RecommendationTableViewController.uploadToPlaylist(_:)) : #selector(RecommendationTableViewController.uploadSong(_:))
            let recognizer = UITapGestureRecognizer(target: self, action: selector)
            button.addGestureRecognizer(recognizer)
        }
        
        return button
    }
    
    // MARK: Utility
    func setToPlaying(indexPath: NSIndexPath) {
        isPlaying = Array(count: recommendations.count, repeatedValue: false)
        isPlaying[indexPath.row] = true
    }

}

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
    var timer: Timer!
    var fadeTimer: Timer!
    
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
    let defaults = UserDefaults.standard
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Recommendations"
        self.navigationItem.titleView?.alpha = 0.7
        self.navigationItem.titleView?.frame.size.height = 44.0
        
        timer = Timer.new(every: 1.seconds) { self.updateTime() }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Timer.after(3.0) { self.displayAd() }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        time = 0
        fadeOutTime = 0.0
        
        shouldFade = false
        shouldUpdate = false
        
        if player != nil { player.pause() }
        if fadeTimer != nil { fadeTimer.invalidate() }
        
        timer.invalidate()
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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
                
                self.isPlaying = Array(repeating: false, count: self.recommendations.count)
                self.isUploaded = Array(repeating: false, count: self.recommendations.count)
                
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
                let notPlaying = Array(repeating: false, count: tracks.count)
                let notUploaded = Array(repeating: false, count: tracks.count)
                
                self.isPlaying.append(contentsOf: notPlaying)
                self.isUploaded.append(contentsOf: notUploaded)
                
                self.recommendations.append(contentsOf: tracks)
                
                self.canRefresh = false
                self.tableView.reloadData()
            }
        }
    }
    
    func uploadSong(_ sender: UITapGestureRecognizer) {
        print("uploading song")
        
        tapIndex = (sender.view?.tag)! - 500
        let indexPath = IndexPath(row: tapIndex, section: 0)
        
        let cell = tableView.cellForRow(at: indexPath) as! SongTableViewCell
        let song = cell.song
        
        SpotifyAPIManager.sharedInstance.saveTrack(song, onCompletion: {
            self.isUploaded[self.tapIndex] = true
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        })
    }
    
    func uploadToPlaylist(_ sender: UITapGestureRecognizer) {
        print("saving to playlist")
        
        tapIndex = (sender.view?.tag)! - 500
        let indexPath = IndexPath(row: tapIndex, section: 0)
        
        let cell = tableView.cellForRow(at: indexPath) as! SongTableViewCell
        let song = cell.song
        
        SpotifyAPIManager.sharedInstance.saveToPlaylist(song, playlist: playlist) {
            self.isUploaded[self.tapIndex] = true
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: AdMob
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

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadedRecs {
            return recommendations.count
        }
        
        return 0
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recCell", for: indexPath) as! SongTableViewCell
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
        
        let secondaryFrame = CGRect(x: playButton.frame.maxX + 5.0, y: playButton.frame.origin.y, width: playButton.frame.size.width, height: playButton.frame.size.height)
        
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canRefresh {
            if tableView.contentOffset.y + tableView.frame.size.height >= tableView.contentSize.height {
                canRefresh = false
                refresh()
            }
        }
    }
    
    // MARK: Playback
    func playPreview(_ sender: UITapGestureRecognizer) {
        tapIndex = sender.view!.tag - 200
        let indexPath = IndexPath(row: tapIndex, section: 0)
        
        setToPlaying(indexPath)
        tableView.reloadData()
    
        let rec = recommendations[tapIndex]
        let url = rec.previewURL!
        
        let playerItem = AVPlayerItem(url: url as URL)
        player = AVPlayer(playerItem: playerItem)
        player.volume = 1.0
        player.play()
        
        fadeOutTime = 0.0
        time = 0
        
        shouldFade = false
        shouldUpdate = true
    }
    
    func pausePreview(_ sender: UITapGestureRecognizer) {
        player.pause()
    
        shouldUpdate = false
        
        tapIndex = sender.view!.tag - 200
        let indexPath = IndexPath(row: tapIndex, section: 0)
        isPlaying[indexPath.row] = false
        
        tableView.reloadData()
    }
    
    // MARK: Audio
    @objc func updateTime() {
        if shouldUpdate {
            time += 1
            if time == 25 {
                shouldFade = true
                fadeTimer = Timer.new(every: 0.1.seconds) { self.fadeOut() }
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
    func createPlaybackButton(_ frame: CGRect, index: Int, type: String) -> UIView {
        let button = type == "play" ? PlayView(frame: frame) : PauseView(frame: frame)
        button.backgroundColor = UIColor.clear
        button.tag = index + 200
        
        let selector = type == "play" ? #selector(RecommendationTableViewController.playPreview(_:)) : #selector(RecommendationTableViewController.pausePreview(_:))
        let recognizer = UITapGestureRecognizer(target: self, action: selector)
        button.addGestureRecognizer(recognizer)
        
        return button
    }
    
    func createUploadButtons(_ frame: CGRect, index: Int, type: String) -> UIView {
        let button = type == "upload" ? UploadView(frame: frame) : CheckView(frame: frame)
        button.backgroundColor = UIColor.clear
        
        if type == "upload" {
            button.tag = index + 500
            let selector = isPlaylist ? #selector(RecommendationTableViewController.uploadToPlaylist(_:)) : #selector(RecommendationTableViewController.uploadSong(_:))
            let recognizer = UITapGestureRecognizer(target: self, action: selector)
            button.addGestureRecognizer(recognizer)
        }
        
        return button
    }
    
    // MARK: Utility
    func setToPlaying(_ indexPath: IndexPath) {
        isPlaying = Array(repeating: false, count: recommendations.count)
        isPlaying[indexPath.row] = true
    }

}

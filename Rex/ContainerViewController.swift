import UIKit

class ContainerViewController: UIViewController {

    // MARK: Properties
    let menuWidth: CGFloat = 100.0
    let animationTime: TimeInterval = 0.5
    var isOpening = false
    
    var menuVC: UIViewController!
    var centerVC: UIViewController!
    
    // MARK: Initializers
    init(menu: UIViewController, center: UIViewController) {
        menuVC = menu
        centerVC = center
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init has not been implemented")
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(false, forKey: "loadedPlaylists")
        
        addChildViewController(centerVC)
        view.addSubview(centerVC.view)
        centerVC.didMove(toParentViewController: self)
        
        addChildViewController(menuVC)
        view.addSubview(menuVC.view)
        menuVC.didMove(toParentViewController: self)
        
        let menuButton = ((centerVC as! UINavigationController).viewControllers.first as? ViewController)?.hamburgerButton
        menuButton?.action = #selector(ContainerViewController.toggleMenu)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePan(_:)))
        view.addGestureRecognizer(pan)
        
        menuVC.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.frame.height)
        setToPercent(0.0)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Actions
    func handlePan(_ sender: UIPanGestureRecognizer) {
        if !UserDefaults.standard.bool(forKey: "loadedPlaylists") {
            (menuVC as! MenuViewController).populatePlaylists()
            UserDefaults.standard.set(true, forKey: "loadedPlaylists")
        }
        
        let translation = sender.translation(in: sender.view!.superview)
        var progress = translation.x / menuWidth * (isOpening ? 1.0 : -1.0)
        progress = min(max(progress, 0.0), 1.0)
        
        switch sender.state {
        case .began:
            let isOpen = floor(centerVC.view.frame.origin.x/menuWidth)
            isOpening = isOpen == 1.0 ? false: true
        case .changed:
            self.setToPercent(isOpening ? progress: (1.0 - progress))
        case .ended: fallthrough
        case .cancelled: fallthrough
        case .failed:
            var targetProgress: CGFloat
            if (isOpening) {
                targetProgress = progress < 0.5 ? 0.0 : 1.0
            } else {
                targetProgress = progress < 0.5 ? 1.0 : 0.0
            }
            UIView.animate(withDuration: animationTime, animations: { self.setToPercent(targetProgress) })
        default: break
        }
    }
    
    func toggleMenu() {
        if !UserDefaults.standard.bool(forKey: "loadedPlaylists") {
            (menuVC as! MenuViewController).populatePlaylists()
            UserDefaults.standard.set(true, forKey: "loadedPlaylists")
        }
        
        let isOpen = floor(centerVC.view.frame.origin.x/menuWidth)
        let target: CGFloat = isOpen == 1.0 ? 0.0 : 1.0
        
        UIView.animate(withDuration: animationTime, animations: { self.setToPercent(target) })
    }
    
    func setToPercent(_ percent: CGFloat) {
        centerVC.view.frame.origin.x = menuWidth * CGFloat(percent)
        menuVC.view.transform = menuTransform(percent)
        menuVC.view.alpha = CGFloat(max(0.2, percent))
    }
    
    func menuTransform(_ percent: CGFloat) -> CGAffineTransform {
        let identity = CGAffineTransform.identity
        let distance = menuWidth * percent
        return identity.translatedBy(x: distance, y: 0.0)
    }

}

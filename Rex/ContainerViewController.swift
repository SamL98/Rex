import UIKit

class ContainerViewController: UIViewController {

    // MARK: Properties
    let menuWidth: CGFloat = 100.0
    let animationTime: NSTimeInterval = 0.5
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
        
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "loadedPlaylists")
        
        addChildViewController(centerVC)
        view.addSubview(centerVC.view)
        centerVC.didMoveToParentViewController(self)
        
        addChildViewController(menuVC)
        view.addSubview(menuVC.view)
        menuVC.didMoveToParentViewController(self)
        
        let menuButton = ((centerVC as! UINavigationController).viewControllers.first as? ViewController)?.hamburgerButton
        menuButton?.action = #selector(ContainerViewController.toggleMenu)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePan(_:)))
        view.addGestureRecognizer(pan)
        
        menuVC.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.frame.height)
        setToPercent(0.0)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: Actions
    func handlePan(sender: UIPanGestureRecognizer) {
        if !NSUserDefaults.standardUserDefaults().boolForKey("loadedPlaylists") {
            (menuVC as! MenuViewController).populatePlaylists()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "loadedPlaylists")
        }
        
        let translation = sender.translationInView(sender.view!.superview)
        var progress = translation.x / menuWidth * (isOpening ? 1.0 : -1.0)
        progress = min(max(progress, 0.0), 1.0)
        
        switch sender.state {
        case .Began:
            let isOpen = floor(centerVC.view.frame.origin.x/menuWidth)
            isOpening = isOpen == 1.0 ? false: true
        case .Changed:
            self.setToPercent(isOpening ? progress: (1.0 - progress))
        case .Ended: fallthrough
        case .Cancelled: fallthrough
        case .Failed:
            var targetProgress: CGFloat
            if (isOpening) {
                targetProgress = progress < 0.5 ? 0.0 : 1.0
            } else {
                targetProgress = progress < 0.5 ? 1.0 : 0.0
            }
            UIView.animateWithDuration(animationTime, animations: { self.setToPercent(targetProgress) })
        default: break
        }
    }
    
    func toggleMenu() {
        if !NSUserDefaults.standardUserDefaults().boolForKey("loadedPlaylists") {
            (menuVC as! MenuViewController).populatePlaylists()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "loadedPlaylists")
        }
        
        let isOpen = floor(centerVC.view.frame.origin.x/menuWidth)
        let target: CGFloat = isOpen == 1.0 ? 0.0 : 1.0
        
        UIView.animateWithDuration(animationTime, animations: { self.setToPercent(target) })
    }
    
    func setToPercent(percent: CGFloat) {
        centerVC.view.frame.origin.x = menuWidth * CGFloat(percent)
        menuVC.view.transform = menuTransform(percent)
        menuVC.view.alpha = CGFloat(max(0.2, percent))
    }
    
    func menuTransform(percent: CGFloat) -> CGAffineTransform {
        let identity = CGAffineTransformIdentity
        let distance = menuWidth * percent
        return CGAffineTransformTranslate(identity, distance, 0.0)
    }

}

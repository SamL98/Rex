import UIKit

class LoadingView: UIView {

    let triangleLayer = TriangleLayer()
    let arcLayer = ArcLayer()
    var label: UILabel!
    
    var completionHandler: (() -> Void)!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func addTriangle(onCompletion: () -> Void) {
        triangleLayer.parentFrame = self.frame
        triangleLayer.bounds = CGRectMake(0, 0, self.bounds.width, self.bounds.height)
        triangleLayer.position = CGPointMake(self.frame.width/2, self.frame.height/2)
        
        arcLayer.parentFrame = self.frame
        arcLayer.bounds = CGRectMake(0, 0, self.bounds.width, self.bounds.height)
        arcLayer.position = CGPointMake(self.frame.width/2, self.frame.height/2)
        
        layer.addSublayer(triangleLayer)
        layer.addSublayer(arcLayer)
        
        addLabel()
        completionHandler = onCompletion
        
        triangleLayer.expand()
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(LoadingView.animateLayer), userInfo: nil, repeats: false)
    }
    
    func animateLayer() {
        triangleLayer.animate()
        arcLayer.animateArc(triangleLayer.count)
        if triangleLayer.count == 1 {
            UIView.animateWithDuration(0.6, animations: { self.label.frame.origin.y = 2*self.frame.height/5 })
        } else {
            UIView.animateWithDuration(0.6, animations: { self.label.frame.origin.y = self.frame.height/3 })
        }
        
        triangleLayer.count += 1
        if triangleLayer.count < 5 {
            NSTimer.scheduledTimerWithTimeInterval(0.85, target: self, selector: #selector(LoadingView.animateLayer), userInfo: nil, repeats: false)
        } else {
            NSTimer.scheduledTimerWithTimeInterval(0.85, target: self, selector: #selector(LoadingView.finishAnimation), userInfo: nil, repeats: false)
        }
    }
    
    func finishAnimation() {
        triangleLayer.expandAndFade()
        UIView.animateWithDuration(1.5, animations: {
            self.label.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5, 1.5)
            }, completion: {_ in
                UIView.animateWithDuration(0.5, animations: { self.label.text = "Re"; self.label.sizeToFit() }, completion: {_ in
                    self.arcLayer.removeFromSuperlayer()
                    UIView.animateWithDuration(0.5, animations: { self.label.text = "Rex"; self.label.sizeToFit() })
                })
                UIView.animateWithDuration(1.0, delay: 1.5, options: [], animations: { self.label.alpha = 0.0 }, completion: {_ in
                    self.completionHandler()
                    self.removeFromSuperview()
                })
        })
    }
    
    func addLabel() {
        label = UILabel(frame: CGRectMake(self.frame.width/5, 2*self.frame.height/5, 3*self.frame.width/5, 2*self.frame.height/5))
        label.backgroundColor = UIColor.clearColor()
        label.text = "R"
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center
        label.font = UIFont(name: "Avenir Next", size: 55.0)
        self.addSubview(label)
    }

}

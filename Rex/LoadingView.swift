import UIKit

class LoadingView: UIView {

    let triangleLayer = TriangleLayer()
    let arcLayer = ArcLayer()
    var label: UILabel!
    
    var completionHandler: (() -> Void)!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func addTriangle(_ onCompletion: @escaping () -> Void) {
        triangleLayer.parentFrame = self.frame
        triangleLayer.bounds = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        triangleLayer.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        
        arcLayer.parentFrame = self.frame
        arcLayer.bounds = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        arcLayer.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        
        layer.addSublayer(triangleLayer)
        layer.addSublayer(arcLayer)
        
        addLabel()
        completionHandler = onCompletion
        
        triangleLayer.expand()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(LoadingView.animateLayer), userInfo: nil, repeats: false)
    }
    
    func animateLayer() {
        triangleLayer.animate()
        arcLayer.animateArc(triangleLayer.count)
        if triangleLayer.count == 1 {
            UIView.animate(withDuration: 0.6, animations: { self.label.frame.origin.y = 2*self.frame.height/5 })
        } else {
            UIView.animate(withDuration: 0.6, animations: { self.label.frame.origin.y = self.frame.height/3 })
        }
        
        triangleLayer.count += 1
        if triangleLayer.count < 5 {
            Timer.scheduledTimer(timeInterval: 0.85, target: self, selector: #selector(LoadingView.animateLayer), userInfo: nil, repeats: false)
        } else {
            Timer.scheduledTimer(timeInterval: 0.85, target: self, selector: #selector(LoadingView.finishAnimation), userInfo: nil, repeats: false)
        }
    }
    
    func finishAnimation() {
        triangleLayer.expandAndFade()
        UIView.animate(withDuration: 1.5, animations: {
            self.label.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            }, completion: {_ in
                UIView.animate(withDuration: 0.5, animations: { self.label.text = "Re"; self.label.sizeToFit() }, completion: {_ in
                    self.arcLayer.removeFromSuperlayer()
                    UIView.animate(withDuration: 0.5, animations: { self.label.text = "Rex"; self.label.sizeToFit() })
                })
                UIView.animate(withDuration: 1.0, delay: 1.5, options: [], animations: { self.label.alpha = 0.0 }, completion: {_ in
                    self.completionHandler()
                    self.removeFromSuperview()
                })
        })
    }
    
    func addLabel() {
        label = UILabel(frame: CGRect(x: self.frame.width/5, y: 2*self.frame.height/5, width: 3*self.frame.width/5, height: 2*self.frame.height/5))
        label.backgroundColor = UIColor.clear
        label.text = "R"
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont(name: "Avenir Next", size: 55.0)
        self.addSubview(label)
    }

}

import UIKit

class ArcLayer: CAShapeLayer {

    var parentFrame: CGRect!
    var previousAngle: CGFloat!
    
    override init() {
        super.init()
        fillColor = UIColor.clearColor().CGColor
        strokeColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).CGColor
        lineWidth = 7.0
        lineCap = kCALineCapRound
        lineJoin = kCALineJoinRound
        path = arcPath0.CGPath
    }
    
    override init(layer: AnyObject) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var arcPath0: UIBezierPath {
        let center = CGPointMake(self.frame.width/2, self.frame.height/2)
        let endAngle: CGFloat = CGFloat((-M_PI_2) + 0*(M_PI/2.5))
        
        let arcPath = UIBezierPath()
        arcPath.addArcWithCenter(center, radius: self.frame.width/2 + 35.0, startAngle: -CGFloat(M_PI_2), endAngle: endAngle, clockwise: true)
        return arcPath
    }
    
    var arcPath1: UIBezierPath {
        let center = CGPointMake(self.parentFrame.width/2, self.parentFrame.height/2)
        let endAngle: CGFloat = CGFloat((-M_PI_2) + (M_PI/2.5))
        
        let arcPath = UIBezierPath()
        arcPath.addArcWithCenter(center, radius: self.parentFrame.width/2 + 35.0, startAngle: -CGFloat(M_PI_2), endAngle: endAngle, clockwise: true)
        return arcPath
    }
    
    var arcPath2: UIBezierPath {
        let endAngle: CGFloat = CGFloat((-M_PI_2) + 2*(M_PI/2.5))
        let center = CGPointMake(self.parentFrame.width/2, self.parentFrame.height/2)
        
        let arcPath = UIBezierPath()
        arcPath.addArcWithCenter(center, radius: self.parentFrame.width/2 + 35.0, startAngle: -CGFloat(M_PI_2), endAngle: endAngle, clockwise: true)
        return arcPath
    }
    
    var arcPath3: UIBezierPath {
        let endAngle: CGFloat = CGFloat((-M_PI_2) + 3*(M_PI/2.5))
        let center = CGPointMake(self.parentFrame.width/2, self.parentFrame.height/2)
        
        let arcPath = UIBezierPath()
        arcPath.addArcWithCenter(center, radius: self.parentFrame.width/2 + 35.0, startAngle: -CGFloat(M_PI_2), endAngle: endAngle, clockwise: true)
        return arcPath
    }
    
    var arcPath4: UIBezierPath {
        let endAngle: CGFloat = CGFloat((-M_PI_2) + 4*(M_PI/2.5))
        let center = CGPointMake(self.parentFrame.width/2, self.parentFrame.height/2)
        
        let arcPath = UIBezierPath()
        arcPath.addArcWithCenter(center, radius: self.parentFrame.width/2 + 35.0, startAngle: -CGFloat(M_PI_2), endAngle: endAngle, clockwise: true)
        return arcPath
    }
    
    var arcPath5: UIBezierPath {
        let endAngle: CGFloat = CGFloat((-M_PI_2) + 5*(M_PI/2.5))
        let center = CGPointMake(self.parentFrame.width/2, self.parentFrame.height/2)
        
        let arcPath = UIBezierPath()
        arcPath.addArcWithCenter(center, radius: self.parentFrame.width/2 + 35.0, startAngle: -CGFloat(M_PI_2), endAngle: endAngle, clockwise: true)
        return arcPath
    }
    
    func animateArc(index: Int) {
        let arcPaths = [arcPath0, arcPath1, arcPath2, arcPath3, arcPath4, arcPath5]
        let nextPath = arcPaths[index+1]
        
        path = nextPath.CGPath
        let stroke = CABasicAnimation(keyPath: "strokeEnd")
        stroke.fromValue = CGFloat(1.0 - 1.0/(Double(index)+1.0))
        stroke.toValue = 1.0
        stroke.beginTime = 0.0
        stroke.duration = 0.325
        stroke.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        stroke.fillMode = kCAFillModeForwards
        stroke.removedOnCompletion = false
        addAnimation(stroke, forKey: nil)
    }
    
}

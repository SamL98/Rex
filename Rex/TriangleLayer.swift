import UIKit

class TriangleLayer: CAShapeLayer {

    var count = 0
    var isForward = true
    var parentFrame: CGRect!
    
    var rotationAnimation: CABasicAnimation = {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = CGFloat(M_PI * 2.0)
        rotationAnimation.beginTime = 0.0
        rotationAnimation.duration = 0.75
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rotationAnimation.removedOnCompletion = true
        return rotationAnimation
    }()
    
    var backRotationAnimation: CABasicAnimation = {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = -CGFloat(M_PI * 2.0)
        rotationAnimation.beginTime = 0.0
        rotationAnimation.duration = 0.75
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rotationAnimation.removedOnCompletion = true
        return rotationAnimation
    }()
    
    override init() {
        super.init()
        fillColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).CGColor
        strokeColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).CGColor
        lineWidth = 7.0
        lineCap = kCALineCapRound
        lineJoin = kCALineJoinRound
        path = zeroPath.CGPath
    }
    
    override init(layer: AnyObject) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var zeroPath: UIBezierPath {
        let path = UIBezierPath()
        return path
    }
    
    var trianglePath: UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(0, parentFrame.height))
        path.addLineToPoint(CGPoint(x: parentFrame.width, y: parentFrame.height))
        path.addLineToPoint(CGPoint(x: parentFrame.width/2, y: 0))
        path.closePath()
        return path
    }
    
    var squarePath: UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: parentFrame.width/10, y: 9*parentFrame.height/10))
        path.addLineToPoint(CGPoint(x: 9*parentFrame.width/10, y: 9*parentFrame.height/10))
        path.addLineToPoint(CGPoint(x: 9*parentFrame.width/10, y: parentFrame.width/10))
        path.addLineToPoint(CGPoint(x: parentFrame.width/10, y: parentFrame.width/10))
        path.closePath()
        return path
    }
    
    var pentagonPath: UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: parentFrame.width/5, y: parentFrame.height))
        path.addLineToPoint(CGPoint(x: 4*parentFrame.width/5, y: parentFrame.height))
        path.addLineToPoint(CGPoint(x: parentFrame.width, y: 2*parentFrame.height/5))
        path.addLineToPoint(CGPoint(x: parentFrame.width/2, y: 0))
        path.addLineToPoint(CGPointMake(0, 2*parentFrame.height/5))
        path.closePath()
        return path
    }
    
    var hexagonPath: UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: parentFrame.width/5, y: 13*parentFrame.height/15))
        path.addLineToPoint(CGPoint(x: 4*parentFrame.width/5, y: 13*parentFrame.height/15))
        path.addLineToPoint(CGPoint(x: parentFrame.width, y: parentFrame.height/2))
        path.addLineToPoint(CGPointMake(4*parentFrame.width/5, 2*parentFrame.height/15))
        path.addLineToPoint(CGPointMake(parentFrame.width/5, 2*parentFrame.height/15))
        path.addLineToPoint(CGPointMake(0, parentFrame.height/2))
        path.closePath()
        return path
    }
    
    var octagonPath: UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: parentFrame.width/4, y: parentFrame.height))
        path.addLineToPoint(CGPoint(x: 3*parentFrame.width/4, y: parentFrame.height))
        path.addLineToPoint(CGPoint(x: parentFrame.width, y: 3*parentFrame.height/4))
        path.addLineToPoint(CGPointMake(parentFrame.width, parentFrame.height/4))
        path.addLineToPoint(CGPointMake(3*parentFrame.width/4, 0))
        path.addLineToPoint(CGPointMake(parentFrame.width/4, 0))
        path.addLineToPoint(CGPointMake(0, parentFrame.height/4))
        path.addLineToPoint(CGPointMake(0, 3*parentFrame.height/4))
        path.closePath()
        return path
    }
    
    var circlePath: UIBezierPath {
        return UIBezierPath(ovalInRect: frame)
    }
    
    func expand() {
        let expandAnimation = CABasicAnimation(keyPath: "path")
        expandAnimation.fromValue = zeroPath.CGPath
        expandAnimation.toValue = trianglePath.CGPath
        expandAnimation.beginTime = 0.25
        expandAnimation.duration = 0.2
        expandAnimation.fillMode = kCAFillModeForwards
        expandAnimation.removedOnCompletion = false
        addAnimation(expandAnimation, forKey: nil)
    }
    
    func animate() {        
        let paths: [CGPath] = [trianglePath.CGPath, squarePath.CGPath, pentagonPath.CGPath, hexagonPath.CGPath, octagonPath.CGPath, circlePath.CGPath]
        let currentPath = paths[count]
        let nextPath = paths[count+1]
        
        let transformAnimation = CABasicAnimation(keyPath: "path")
        transformAnimation.fromValue = currentPath
        transformAnimation.toValue = nextPath
        transformAnimation.beginTime = rotationAnimation.beginTime + 0.3
        transformAnimation.duration = rotationAnimation.duration - 0.3
        
        let direction = isForward ? rotationAnimation : backRotationAnimation
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [direction, transformAnimation]
        animationGroup.duration = transformAnimation.beginTime + transformAnimation.duration
        animationGroup.fillMode = kCAFillModeForwards
        animationGroup.removedOnCompletion = false
        addAnimation(animationGroup, forKey: nil)
        
        isForward = !isForward
    }
    
    func expandAndFade() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.toValue = 6.0
        scaleAnimation.duration = 1.0
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        scaleAnimation.fillMode = kCAFillModeForwards
        scaleAnimation.removedOnCompletion = false
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue = 0.0
        fadeAnimation.beginTime = scaleAnimation.duration + 3.0
        fadeAnimation.duration = 1.5
        fadeAnimation.fillMode = kCAFillModeForwards
        fadeAnimation.removedOnCompletion = false

        let scaleAndFade = CAAnimationGroup()
        scaleAndFade.animations = [scaleAnimation, fadeAnimation]
        scaleAndFade.duration = fadeAnimation.beginTime + fadeAnimation.duration
        scaleAndFade.fillMode = kCAFillModeForwards
        scaleAndFade.removedOnCompletion = false
        addAnimation(scaleAndFade, forKey: nil)
    }

}

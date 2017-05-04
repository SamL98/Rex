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
        rotationAnimation.isRemovedOnCompletion = true
        return rotationAnimation
    }()
    
    var backRotationAnimation: CABasicAnimation = {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = -CGFloat(M_PI * 2.0)
        rotationAnimation.beginTime = 0.0
        rotationAnimation.duration = 0.75
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rotationAnimation.isRemovedOnCompletion = true
        return rotationAnimation
    }()
    
    override init() {
        super.init()
        fillColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        strokeColor = UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        lineWidth = 7.0
        lineCap = kCALineCapRound
        lineJoin = kCALineJoinRound
        path = zeroPath.cgPath
    }
    
    override init(layer: Any) {
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
        path.move(to: CGPoint(x: 0, y: parentFrame.height))
        path.addLine(to: CGPoint(x: parentFrame.width, y: parentFrame.height))
        path.addLine(to: CGPoint(x: parentFrame.width/2, y: 0))
        path.close()
        return path
    }
    
    var squarePath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: parentFrame.width/10, y: 9*parentFrame.height/10))
        path.addLine(to: CGPoint(x: 9*parentFrame.width/10, y: 9*parentFrame.height/10))
        path.addLine(to: CGPoint(x: 9*parentFrame.width/10, y: parentFrame.width/10))
        path.addLine(to: CGPoint(x: parentFrame.width/10, y: parentFrame.width/10))
        path.close()
        return path
    }
    
    var pentagonPath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: parentFrame.width/5, y: parentFrame.height))
        path.addLine(to: CGPoint(x: 4*parentFrame.width/5, y: parentFrame.height))
        path.addLine(to: CGPoint(x: parentFrame.width, y: 2*parentFrame.height/5))
        path.addLine(to: CGPoint(x: parentFrame.width/2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 2*parentFrame.height/5))
        path.close()
        return path
    }
    
    var hexagonPath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: parentFrame.width/5, y: parentFrame.height))
        path.addLine(to: CGPoint(x: 4*parentFrame.width/5, y: parentFrame.height))
        path.addLine(to: CGPoint(x: parentFrame.width, y: parentFrame.height/2))
        path.addLine(to: CGPoint(x: 4*parentFrame.width/5, y: 0))
        path.addLine(to: CGPoint(x: parentFrame.width/5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: parentFrame.height/2))
        path.close()
        return path
    }
    
    var octagonPath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: parentFrame.width/4, y: parentFrame.height))
        path.addLine(to: CGPoint(x: 3*parentFrame.width/4, y: parentFrame.height))
        path.addLine(to: CGPoint(x: parentFrame.width, y: 3*parentFrame.height/4))
        path.addLine(to: CGPoint(x: parentFrame.width, y: parentFrame.height/4))
        path.addLine(to: CGPoint(x: 3*parentFrame.width/4, y: 0))
        path.addLine(to: CGPoint(x: parentFrame.width/4, y: 0))
        path.addLine(to: CGPoint(x: 0, y: parentFrame.height/4))
        path.addLine(to: CGPoint(x: 0, y: 3*parentFrame.height/4))
        path.close()
        return path
    }
    
    var circlePath: UIBezierPath {
        return UIBezierPath(ovalIn: frame)
    }
    
    func expand() {
        let expandAnimation = CABasicAnimation(keyPath: "path")
        expandAnimation.fromValue = zeroPath.cgPath
        expandAnimation.toValue = trianglePath.cgPath
        expandAnimation.beginTime = 0.25
        expandAnimation.duration = 0.2
        expandAnimation.fillMode = kCAFillModeForwards
        expandAnimation.isRemovedOnCompletion = false
        add(expandAnimation, forKey: nil)
    }
    
    func animate() {        
        let paths: [CGPath] = [trianglePath.cgPath, squarePath.cgPath, pentagonPath.cgPath, hexagonPath.cgPath, octagonPath.cgPath, circlePath.cgPath]
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
        animationGroup.isRemovedOnCompletion = false
        add(animationGroup, forKey: nil)
        
        isForward = !isForward
    }
    
    func expandAndFade() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.toValue = 6.0
        scaleAnimation.duration = 1.0
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        scaleAnimation.fillMode = kCAFillModeForwards
        scaleAnimation.isRemovedOnCompletion = false
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue = 0.0
        fadeAnimation.beginTime = scaleAnimation.duration + 3.0
        fadeAnimation.duration = 1.5
        fadeAnimation.fillMode = kCAFillModeForwards
        fadeAnimation.isRemovedOnCompletion = false

        let scaleAndFade = CAAnimationGroup()
        scaleAndFade.animations = [scaleAnimation, fadeAnimation]
        scaleAndFade.duration = fadeAnimation.beginTime + fadeAnimation.duration
        scaleAndFade.fillMode = kCAFillModeForwards
        scaleAndFade.isRemovedOnCompletion = false
        add(scaleAndFade, forKey: nil)
    }

}

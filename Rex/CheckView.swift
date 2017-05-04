import UIKit

@IBDesignable
class CheckView: UIView {

    override func draw(_ rect: CGRect) {
        let background = UIBezierPath(ovalIn: rect)
        UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        background.fill()
        
        let checkPath = UIBezierPath()
        checkPath.lineWidth = rect.width/9
        checkPath.lineCapStyle = CGLineCap.round
        checkPath.lineJoinStyle = CGLineJoin.round
        
        checkPath.move(to: CGPoint(x: 3*rect.width/10, y: 3*rect.height/5))
        checkPath.addLine(to: CGPoint(x: 4.5*rect.width/10, y: 4*rect.height/5))
        checkPath.addLine(to: CGPoint(x: 7*rect.width/10, y: 3*rect.height/10))
        
        UIColor.white.setStroke()
        checkPath.stroke()
    }

}

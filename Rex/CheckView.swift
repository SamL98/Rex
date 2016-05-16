import UIKit

@IBDesignable
class CheckView: UIView {

    override func drawRect(rect: CGRect) {
        let background = UIBezierPath(ovalInRect: rect)
        UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        background.fill()
        
        let checkPath = UIBezierPath()
        checkPath.lineWidth = rect.width/9
        checkPath.lineCapStyle = CGLineCap.Round
        checkPath.lineJoinStyle = CGLineJoin.Round
        
        checkPath.moveToPoint(CGPointMake(3*rect.width/10, 3*rect.height/5))
        checkPath.addLineToPoint(CGPointMake(4.5*rect.width/10, 4*rect.height/5))
        checkPath.addLineToPoint(CGPointMake(7*rect.width/10, 3*rect.height/10))
        
        UIColor.whiteColor().setStroke()
        checkPath.stroke()
    }

}

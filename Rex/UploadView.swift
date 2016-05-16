import UIKit

@IBDesignable
class UploadView: UIView {

    override func drawRect(rect: CGRect) {
        let background = UIBezierPath(ovalInRect: rect)
        UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        background.fill()
        
        let arrowPath = UIBezierPath()
        arrowPath.lineWidth = rect.width/9
        arrowPath.lineCapStyle = CGLineCap.Round
        arrowPath.lineJoinStyle = CGLineJoin.Round
        
        arrowPath.moveToPoint(CGPointMake(rect.width/2, 3*rect.height/4))
        arrowPath.addLineToPoint(CGPointMake(rect.width/2, rect.height/4))
        arrowPath.addLineToPoint(CGPointMake(3*rect.width/10, 2*rect.height/5))
        arrowPath.addLineToPoint(CGPointMake(rect.width/2, rect.height/4))
        arrowPath.addLineToPoint(CGPointMake(7*rect.width/10, 2*rect.height/5))
        
        UIColor.whiteColor().setStroke()
        arrowPath.stroke()
    }

}

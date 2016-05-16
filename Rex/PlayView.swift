import UIKit

@IBDesignable
class PlayView: UIView {

    override func drawRect(rect: CGRect) {
        let background = UIBezierPath(ovalInRect: rect)
        UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        background.fill()
        
        let arrow = UIBezierPath()
        arrow.moveToPoint(CGPoint(x: 4*rect.width/10, y: 3*rect.height/10))
        arrow.addLineToPoint(CGPoint(x: 4*rect.width/10, y: 7*rect.height/10))
        arrow.addLineToPoint(CGPoint(x: 7*rect.width/10, y: rect.height/2))
        arrow.closePath()
        
        UIColor.whiteColor().setFill()
        arrow.fill()
    }

}

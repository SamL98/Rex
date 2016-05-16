import UIKit

@IBDesignable
class NextView: UIView {

    override func drawRect(rect: CGRect) {
        let background = UIBezierPath(ovalInRect: rect)
        UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        background.fill()
        
        let stick = UIBezierPath(rect: CGRect(x: 3*rect.width/10, y: rect.height/4, width: rect.width/7, height: rect.height/2))
        let arrow = UIBezierPath()
        
        arrow.moveToPoint(CGPoint(x: 5.5*rect.width/10, y: rect.height/4))
        arrow.addLineToPoint(CGPoint(x: 5.5*rect.width/10, y: 3*rect.height/4))
        arrow.addLineToPoint(CGPoint(x: 8*rect.width/10, y: rect.height/2))
        arrow.closePath()
        
        UIColor.whiteColor().setFill()
        stick.fill()
        arrow.fill()
    }

}

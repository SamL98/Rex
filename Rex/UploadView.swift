import UIKit

@IBDesignable
class UploadView: UIView {

    override func draw(_ rect: CGRect) {
        let background = UIBezierPath(ovalIn: rect)
        UIColor(red: 104.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        background.fill()
        
        let arrowPath = UIBezierPath()
        arrowPath.lineWidth = rect.width/9
        arrowPath.lineCapStyle = CGLineCap.round
        arrowPath.lineJoinStyle = CGLineJoin.round
        
        arrowPath.move(to: CGPoint(x: rect.width/2, y: 3*rect.height/4))
        arrowPath.addLine(to: CGPoint(x: rect.width/2, y: rect.height/4))
        arrowPath.addLine(to: CGPoint(x: 3*rect.width/10, y: 2*rect.height/5))
        arrowPath.addLine(to: CGPoint(x: rect.width/2, y: rect.height/4))
        arrowPath.addLine(to: CGPoint(x: 7*rect.width/10, y: 2*rect.height/5))
        
        UIColor.white.setStroke()
        arrowPath.stroke()
    }

}

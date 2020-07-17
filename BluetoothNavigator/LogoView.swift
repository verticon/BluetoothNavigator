
import UIKit
import VerticonsToolbox

// TODO: If the orientation is changed to landscape and then back to portrait then the logo is no longer centered.
class LogoView : GradientView {

    private class LogoLayer : CALayer {
        
        var upperText: String? {
            didSet { setNeedsDisplay() }
        }
        var lowerText: String? {
            didSet { setNeedsDisplay() }
        }
        
        
        override func draw(in context: CGContext) {

            print("Drawing Logo Layer in \(bounds)")

            var lineWidth: CGFloat = 0
            var hypotenuse: CGFloat = 0
            var side: CGFloat = 0

            func setDimensions() {
                let minDimension = bounds.width < bounds.height ? bounds.width : bounds.height
                let inset = minDimension / 8
                let length = minDimension - 2 * inset
                
                lineWidth = length / 15
                hypotenuse = length / 2 - lineWidth // Adjusting for the line width keeps us in the box. We need more than half due to the mitering
                side = sqrt((hypotenuse * hypotenuse) / 2)
            }
            
            func move(to: CGPoint, whileDrawing: Bool, andShiftOrigin: Bool) {
                if (whileDrawing) { context.addLine(to: to) }
                else { context.move(to: to) }
                
                if andShiftOrigin { context.translateBy(x: to.x, y: to.y) }
            }
            
            func moveTo(x: CGFloat, y: CGFloat, whileDrawing: Bool, andShiftOrigin: Bool) {
                move(to: CGPoint(x: x, y: y), whileDrawing: whileDrawing, andShiftOrigin: andShiftOrigin)
            }
            
            // Draw the triangular bluetooth symbol. Upon completion the context's origin will be located at the center of the logo square.
            func drawSymbol() {
                
                // Upon completion the pen, and perhaps the origin, will be at the new end point.
                func drawLine(withLength: CGFloat, atAngle: Double, andShiftOrigin: Bool) {
                    let radians = atAngle * Double.pi / 180
                    moveTo(x: withLength * CGFloat(cos(radians)), y: -withLength * CGFloat(sin(radians)), whileDrawing: true, andShiftOrigin: andShiftOrigin)
                }
                
                // Upon completion the pen and the origin will be back at their original position.
                func drawIsoscelesRightTriangle(withHypotenuse hypotenuse: CGFloat, andSide side: CGFloat) {
                    context.setLineJoin(.miter)
                    
                    drawLine(withLength: side, atAngle: 45, andShiftOrigin: true)
                    drawLine(withLength: side, atAngle: 135, andShiftOrigin: true)
                    drawLine(withLength: hypotenuse, atAngle: 270, andShiftOrigin: true)
                    
                    drawLine(withLength: side/2, atAngle: 45, andShiftOrigin: false) // Draw past the third vertex so that it will be mitered ...
                    moveTo(x: 0, y: 0, whileDrawing: false, andShiftOrigin: false) // and then move back.
                }
                
                // Move the pen and the origin to the point that is hypotenuse distance down from the center of the box
                moveTo(x: bounds.midX, y: bounds.midY+hypotenuse, whileDrawing: false, andShiftOrigin: true)
                
                // Draw the lower triangle.
                drawIsoscelesRightTriangle(withHypotenuse: hypotenuse, andSide: side)
                
                // Move the pen and the origin to the center of the box
                moveTo(x: 0, y: -hypotenuse, whileDrawing: false, andShiftOrigin: true)
                
                // Draw the upper triangle.
                drawIsoscelesRightTriangle(withHypotenuse: hypotenuse, andSide: side)
                
                // Draw the tail to the upper left
                drawLine(withLength: side, atAngle: 135, andShiftOrigin: false)
                
                // Move back to the center of the box
                moveTo(x: 0, y: 0, whileDrawing: false, andShiftOrigin: false)
                
                // Draw the tail to the lower left
                drawLine(withLength: side, atAngle: 225, andShiftOrigin: false)
                
                context.setStrokeColor(UIColor.bluetoothBlue.cgColor)
                context.setLineWidth(lineWidth)
                context.setShadow(offset: CGSize(width: lineWidth/4, height: lineWidth/4), blur: 5)
                context.strokePath()
            }
            
            // **********************************************************************************************************
            
            var borderRect: CGRect {
                let borderRectWidth = 2 * (side + side / 4)
                let borderRectHeight = 2 * (hypotenuse + 2 * lineWidth)
                return CGRect(x: -borderRectWidth/2, y: -borderRectHeight/2, width: borderRectWidth, height: borderRectHeight)
            }
            var radius: CGFloat { return borderRect.width/2 }
            var upperArcCenter: CGPoint { return CGPoint(x: borderRect.midX, y: borderRect.minY + radius) }
            var lowerArcCenter: CGPoint { return CGPoint(x: borderRect.midX, y: borderRect.maxY - radius) }
            
            // Draw a rounded rect around the symbol. The context's origin is assummed to be located at the center of the logo square.
            func drawBorder() {
                let upperArc =  UIBezierPath(arcCenter: upperArcCenter, radius: radius, startAngle: CGFloat(toRadians(degrees: 180)), endAngle: CGFloat(toRadians(degrees: 0)), clockwise: true)
                context.addPath(upperArc.cgPath)
                
                let lowerArc =  UIBezierPath(arcCenter: lowerArcCenter, radius: radius, startAngle: CGFloat(toRadians(degrees: 180)), endAngle: CGFloat(toRadians(degrees: 0)), clockwise: false)
                context.addPath(lowerArc.cgPath)
                
                // Connect the arc end points with vertical lines
                moveTo(x: upperArcCenter.x - radius, y: upperArcCenter.y, whileDrawing: false, andShiftOrigin: false)
                moveTo(x: upperArcCenter.x - radius, y: lowerArcCenter.y, whileDrawing: true, andShiftOrigin: false)
                moveTo(x: lowerArcCenter.x + radius, y: lowerArcCenter.y, whileDrawing: false, andShiftOrigin: false)
                moveTo(x: lowerArcCenter.x + radius, y: upperArcCenter.y, whileDrawing: true, andShiftOrigin: false)
                
                context.setStrokeColor(UIColor.white.cgColor)
                context.setLineWidth(2)
                context.setShadow(offset: CGSize(width: 2, height: 2), blur: 0)
                context.strokePath()
            }
            
            func drawText() {
                let font = UIFont(name: "Helvetica", size: CGFloat(28))!
                let attributes = [NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.textEffect : NSAttributedString.TextEffectStyle.letterpressStyle as NSString]
                
                if let text = upperText {
                    let string = NSAttributedString(string: text, attributes: attributes)
                    let upperArc =  UIBezierPath(arcCenter: upperArcCenter, radius: radius + 15, startAngle: CGFloat(toRadians(degrees: 180)), endAngle: CGFloat(toRadians(degrees: 0)), clockwise: true)
                    Bezier(path: upperArc.cgPath).draw(attributed: string, to: context)
                }
                
                if let text = lowerText {
                    let string = NSAttributedString(string: text, attributes: attributes)
                    let lowerArc =  UIBezierPath(arcCenter: lowerArcCenter, radius: radius + 20, startAngle: CGFloat(toRadians(degrees: 180)), endAngle: CGFloat(toRadians(degrees: 0)), clockwise: false)
                    Bezier(path: lowerArc.cgPath).draw(attributed: string, to: context)
                }
            }
            
            // **********************************************************************************************************
            
            setDimensions()
            drawSymbol()
            drawBorder()
            drawText()
        }
    }

    private var logoLayer: LogoLayer { return layer.sublayers![0] as! LogoLayer }

    // ************************************************************************************

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        let logoLayer = LogoLayer()
        layer.addSublayer(logoLayer)
        logoLayer.setNeedsDisplay()
    }

    // ************************************************************************************
    
    var logoIsHidden: Bool {
        get { return logoLayer.isHidden }
        set { logoLayer.isHidden = newValue }
    }
    
    var upperText: String? {
        didSet { logoLayer.upperText = upperText }
    }
    var lowerText: String? {
        didSet { logoLayer.lowerText = lowerText }
    }
    
    // ************************************************************************************

    private var relativeSize: CGFloat = 1
    private var animate = false
    private var rotate = false
    private var rotationDuration: TimeInterval = 1
    private var rotationRepeatCount = 2
    private var animationComplete: () -> () = {}

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if animate {
            print("LogoView - animating logo layer layout; relative size = \(relativeSize)")
            animateLogoLayout(relativeSize: relativeSize, rotate: rotate, rotationDuration: rotationDuration, rotationRepeatCount: rotationRepeatCount, animationComplete: animationComplete)
            animate = false
        } else {
            print("LogoView - laying out logo layer; relative size = \(relativeSize)")
            layoutLogo(relativeSize: relativeSize)
            logoLayer.setNeedsDisplay()
        }
    }

    func updateLogo(relativeSize: CGFloat, animate: Bool = false, rotate: Bool = false, rotationDuration: TimeInterval = 1, rotationRepeatCount: Int = 1, animationComplete: @escaping () -> () = {}) {
        if rotate {
            print("LogoView - animating logo layer; relative size = \(relativeSize)")
            animateLogoLayout(relativeSize: relativeSize, rotate: rotate, rotationDuration: rotationDuration, rotationRepeatCount: rotationRepeatCount, animationComplete: animationComplete)
        } else {
            self.relativeSize = relativeSize
            print("LogoView - setting needs layout; relative size = \(relativeSize)")
            setNeedsLayout()
        }
    }
    
    private func layoutLogo(relativeSize ratio: CGFloat) { // 0.0 -> 1.0
        relativeSize = ratio
        if !(0 ... 1).contains(relativeSize) { relativeSize = relativeSize > 1.0 ? 1.0 : 0 }
        
        logoLayer.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        logoLayer.bounds.size = relativeSize * layer.bounds.size
    }

    private func animateLogoLayout(relativeSize: CGFloat, rotate: Bool, rotationDuration: TimeInterval, rotationRepeatCount: Int, animationComplete: @escaping () -> ()) {
        
        CATransaction.setDisableActions(true)
        let initialSize = logoLayer.bounds.size
        let initialPosition = logoLayer.position
        layoutLogo(relativeSize: relativeSize)
        let finalSize = logoLayer.bounds.size
        let finalPosition = logoLayer.position

        CATransaction.begin()
        
        let rotationAnimationKey = "rotation"
        let sizeAnimationKey = "size"
        let positionAnimationKey = "position"

        CATransaction.setCompletionBlock {
            self.logoLayer.transform = CATransform3DIdentity
            animationComplete()
            
            //            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            //                self.logoLayer.upperText = "Bluetooth LE"
            //                self.logoLayer.lowerText = "Navigator"
            //
            //                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            //                    UIView.animate(withDuration: 2, delay: 1, options: .curveEaseOut,
            //                                   animations: { self.alpha = 0 },
            //                                   completion: { _ in self.removeFromSuperview() })
            //                }
            //            }
        }
        
        let sizeAnimation = CABasicAnimation(keyPath: "bounds.size")
        sizeAnimation.fromValue = initialSize
        sizeAnimation.toValue = finalSize
        sizeAnimation.repeatCount = 1
        sizeAnimation.duration = CFTimeInterval(rotationRepeatCount) * rotationDuration
        logoLayer.add(sizeAnimation, forKey: sizeAnimationKey)
        
        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.fromValue = initialPosition
        positionAnimation.toValue = finalPosition
        positionAnimation.repeatCount = 1
        positionAnimation.duration = CFTimeInterval(rotationRepeatCount) * rotationDuration
        logoLayer.add(positionAnimation, forKey: positionAnimationKey)
        
        if rotate {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
            rotationAnimation.fromValue = 0
            rotationAnimation.toValue = 2.0 * .pi
            rotationAnimation.repeatCount = Float(rotationRepeatCount)
            rotationAnimation.duration = rotationDuration
            logoLayer.add(rotationAnimation, forKey: rotationAnimationKey)

            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500;
            logoLayer.transform = transform
        }
        
        CATransaction.commit()
    }
}

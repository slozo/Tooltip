//
//  Tooltip.swift
//  Tooltip
//
//  Created by Lasha Efremidze on 2/20/18.
//  Copyright © 2018 Lasha Efremidze. All rights reserved.
//

import UIKit

struct Tooltip {}

public typealias EmptyClosure = () -> Void

open class TooltipView: UIView {
    
    // Position
    public enum ArrowPosition {
        case top, bottom, right, left
        static let all = [top, bottom, right, left]
    }
    
    public struct Preferences {
        public struct Styling {
            public var cornerRadius        = CGFloat(4)
            public var arrowHeight         = CGFloat(4)
            public var arrowWidth          = CGFloat(8)
            public var foregroundColor     = UIColor.white
            public var backgroundColor     = UIColor.blue
            public var arrowPosition       = ArrowPosition.bottom
            public var textAlignment       = NSTextAlignment.center
            public var borderWidth         = CGFloat(0)
            public var borderColor         = UIColor.clear
            public var font                = UIFont.preferredFont(forTextStyle: .body)
        }
        
        public struct Positioning {
            // bubbleInset
            // textInset
            public var bubbleHInset         = CGFloat(2)
            public var bubbleVInset         = CGFloat(2)
            public var textHInset           = CGFloat(8)
            public var textVInset           = CGFloat(8)
            public var maxWidth             = CGFloat(200)
        }
        
        public struct Animating {
            public var dismissTransform     = CGAffineTransform(scaleX: 0.1, y: 0.1)
            public var showInitialTransform = CGAffineTransform(scaleX: 0, y: 0)
            public var showFinalTransform   = CGAffineTransform.identity
            public var springDamping        = CGFloat(0.7)
            public var springVelocity       = CGFloat(0.7)
            public var showInitialAlpha     = CGFloat(0)
            public var dismissFinalAlpha    = CGFloat(0)
            public var showDuration         = 0.7
            public var dismissDuration      = 0.7
            public var dismissOnTap         = true
        }
        
        public var drawing      = Styling()
        public var positioning  = Positioning()
        public var animating    = Animating()
        public var hasBorder: Bool {
            return drawing.borderWidth > 0 && drawing.borderColor != UIColor.clear
        }
        
        public init() {}
    }
    
    override open var backgroundColor: UIColor? {
        didSet {
            guard let color = backgroundColor
                , color != UIColor.clear else {return}
            
            preferences.drawing.backgroundColor = color
            backgroundColor = UIColor.clear
        }
    }
    
    weak var presentingView: UIView?
    var arrowTip = CGPoint.zero
    internal(set) open var preferences: Preferences
    open let text: String
    
    lazy var textSize: CGSize = { [unowned self] in
        var attributes = [NSAttributedStringKey.font : self.preferences.drawing.font]
        var textSize = self.text.boundingRect(with: CGSize(width: self.preferences.positioning.maxWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil).size
        textSize.width = ceil(textSize.width)
        textSize.height = ceil(textSize.height)
        if textSize.width < self.preferences.drawing.arrowWidth {
            textSize.width = self.preferences.drawing.arrowWidth
        }
        return textSize
    }()
    
    lazy var contentSize: CGSize = { [unowned self] in
        return CGSize(width: self.textSize.width + self.preferences.positioning.textHInset * 2 + self.preferences.positioning.bubbleHInset * 2, height: self.textSize.height + self.preferences.positioning.textVInset * 2 + self.preferences.positioning.bubbleVInset * 2 + self.preferences.drawing.arrowHeight)
    }()
    
    // MARK:- Initializer -
    
    public init(text: String, preferences: Preferences) {
        self.text = text
        self.preferences = preferences
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: .main) { [weak self] notification in
            guard let `self` = self, let superview = self.superview, self.presentingView != nil else { return }
            UIView.animate(withDuration: 0.3) {
                self.arrange(withinSuperview: superview)
                self.setNeedsDisplay()
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: -
    
    @IBAction func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard preferences.animating.dismissOnTap else { return }
        dismiss()
    }
    
    // MARK: - Private methods -
    
    func computeFrame(arrowPosition position: ArrowPosition, refViewFrame: CGRect, superviewFrame: CGRect) -> CGRect {
        var xOrigin: CGFloat = 0
        var yOrigin: CGFloat = 0
        
        switch position {
        case .top:
            xOrigin = refViewFrame.center.x - contentSize.width / 2
            yOrigin = refViewFrame.y + refViewFrame.height
        case .bottom:
            xOrigin = refViewFrame.center.x - contentSize.width / 2
            yOrigin = refViewFrame.y - contentSize.height
        case .right:
            xOrigin = refViewFrame.x - contentSize.width
            yOrigin = refViewFrame.center.y - contentSize.height / 2
        case .left:
            xOrigin = refViewFrame.x + refViewFrame.width
            yOrigin = refViewFrame.y - contentSize.height / 2
        }
        
        var frame = CGRect(x: xOrigin, y: yOrigin, width: contentSize.width, height: contentSize.height)
        adjustFrame(&frame, forSuperviewFrame: superviewFrame)
        return frame
    }
    
    func adjustFrame(_ frame: inout CGRect, forSuperviewFrame superviewFrame: CGRect) {
        // adjust horizontally
        if frame.x < 0 {
            frame.x =  0
        } else if frame.maxX > superviewFrame.width {
            frame.x = superviewFrame.width - frame.width
        }
        
        //adjust vertically
        if frame.y < 0 {
            frame.y = 0
        } else if frame.maxY > superviewFrame.maxY {
            frame.y = superviewFrame.height - frame.height
        }
    }
    
    func isFrameValid(_ frame: CGRect, forRefViewFrame: CGRect, withinSuperviewFrame: CGRect) -> Bool {
        return !frame.intersects(forRefViewFrame)
    }
    
    func arrange(withinSuperview superview: UIView) {
        
        var position = preferences.drawing.arrowPosition
        
        let refViewFrame = presentingView!.convert(presentingView!.bounds, to: superview);
        
        let superviewFrame: CGRect
        if let scrollview = superview as? UIScrollView {
            superviewFrame = CGRect(origin: scrollview.frame.origin, size: scrollview.contentSize)
        } else {
            superviewFrame = superview.frame
        }
        
        var frame = computeFrame(arrowPosition: position, refViewFrame: refViewFrame, superviewFrame: superviewFrame)
        
        if !isFrameValid(frame, forRefViewFrame: refViewFrame, withinSuperviewFrame: superviewFrame) {
            for value in ArrowPosition.all where value != position {
                let newFrame = computeFrame(arrowPosition: value, refViewFrame: refViewFrame, superviewFrame: superviewFrame)
                if isFrameValid(newFrame, forRefViewFrame: refViewFrame, withinSuperviewFrame: superviewFrame) {
                    print("[TooltipView - Info] The arrow position you chose <\(position)> could not be applied. Instead, position <\(value)> has been applied!")
                    frame = newFrame
                    position = value
                    preferences.drawing.arrowPosition = value
                    break
                }
            }
        }
        
        var arrowTipXOrigin: CGFloat
        switch position {
        case .bottom, .top:
            if frame.width < refViewFrame.width {
                arrowTipXOrigin = contentSize.width / 2
            } else {
                arrowTipXOrigin = abs(frame.x - refViewFrame.x) + refViewFrame.width / 2
            }
            
            arrowTip = CGPoint(x: arrowTipXOrigin, y: position == .bottom ? contentSize.height - preferences.positioning.bubbleVInset :  preferences.positioning.bubbleVInset)
        case .right, .left:
            if frame.height < refViewFrame.height {
                arrowTipXOrigin = contentSize.height / 2
            } else {
                arrowTipXOrigin = abs(frame.y - refViewFrame.y) + refViewFrame.height / 2
            }
            
            arrowTip = CGPoint(x: preferences.drawing.arrowPosition == .left ? preferences.positioning.bubbleVInset : contentSize.width - preferences.positioning.bubbleVInset, y: arrowTipXOrigin)
        }
        self.frame = frame
    }
    
    
    // MARK:- Drawing -
    
    override open func draw(_ rect: CGRect) {
        let arrowPosition = preferences.drawing.arrowPosition
        let bubbleWidth: CGFloat
        let bubbleHeight: CGFloat
        let bubbleXOrigin: CGFloat
        let bubbleYOrigin: CGFloat
        switch arrowPosition {
        case .bottom, .top:
            
            bubbleWidth = contentSize.width - 2 * preferences.positioning.bubbleHInset
            bubbleHeight = contentSize.height - 2 * preferences.positioning.bubbleVInset - preferences.drawing.arrowHeight
            
            bubbleXOrigin = preferences.positioning.bubbleHInset
            bubbleYOrigin = arrowPosition == .bottom ? preferences.positioning.bubbleVInset : preferences.positioning.bubbleVInset + preferences.drawing.arrowHeight
            
        case .left, .right:
            
            bubbleWidth = contentSize.width - 2 * preferences.positioning.bubbleHInset - preferences.drawing.arrowHeight
            bubbleHeight = contentSize.height - 2 * preferences.positioning.bubbleVInset
            
            bubbleXOrigin = arrowPosition == .right ? preferences.positioning.bubbleHInset : preferences.positioning.bubbleHInset + preferences.drawing.arrowHeight
            bubbleYOrigin = preferences.positioning.bubbleVInset
            
        }
        let bubbleFrame = CGRect(x: bubbleXOrigin, y: bubbleYOrigin, width: bubbleWidth, height: bubbleHeight)
        
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState ()
        
        drawBubble(bubbleFrame, arrowPosition: preferences.drawing.arrowPosition, context: context)
        drawText(bubbleFrame, context: context)
        
        context.restoreGState()
    }
    
    func drawBubble(_ bubbleFrame: CGRect, arrowPosition: ArrowPosition,  context: CGContext) {
        let arrowWidth = preferences.drawing.arrowWidth
        let arrowHeight = preferences.drawing.arrowHeight
        let cornerRadius = preferences.drawing.cornerRadius
        
        let contourPath = CGMutablePath()
        
        contourPath.move(to: CGPoint(x: arrowTip.x, y: arrowTip.y))
        
        switch arrowPosition {
        case .bottom, .top:
            
            contourPath.addLine(to: CGPoint(x: arrowTip.x - arrowWidth / 2, y: arrowTip.y + (arrowPosition == .bottom ? -1 : 1) * arrowHeight))
            if arrowPosition == .bottom {
                drawBubbleShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath, arrowPosition: .bottom)
            } else {
                drawBubbleShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath, arrowPosition: .top)
            }
            contourPath.addLine(to: CGPoint(x: arrowTip.x + arrowWidth / 2, y: arrowTip.y + (arrowPosition == .bottom ? -1 : 1) * arrowHeight))
            
        case .right, .left:
            
            contourPath.addLine(to: CGPoint(x: arrowTip.x + (arrowPosition == .right ? -1 : 1) * arrowHeight, y: arrowTip.y - arrowWidth / 2))
            
            if arrowPosition == .right {
                drawBubbleShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath, arrowPosition: .right)
            } else {
                drawBubbleShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath, arrowPosition: .left)
            }
            
            contourPath.addLine(to: CGPoint(x: arrowTip.x + (arrowPosition == .right ? -1 : 1) * arrowHeight, y: arrowTip.y + arrowWidth / 2))
        }
        
        contourPath.closeSubpath()
        context.addPath(contourPath)
        context.clip()
        
        context.setFillColor(preferences.drawing.backgroundColor.cgColor)
        context.fill(bounds)

        if preferences.hasBorder {
            context.addPath(contourPath)
            context.setStrokeColor(preferences.drawing.borderColor.cgColor)
            context.setLineWidth(preferences.drawing.borderWidth)
            context.strokePath()
        }
    }
    
    func drawBubbleShape(_ frame: CGRect, cornerRadius: CGFloat, path: CGMutablePath, arrowPosition: ArrowPosition) {
        switch arrowPosition {
        case .top:
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y), tangent2End: CGPoint(x: frame.x, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x, y:  frame.y + frame.height), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y), tangent2End: CGPoint(x: frame.x, y: frame.y), radius: cornerRadius)
        case .bottom:
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x, y: frame.y), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x, y: frame.y + frame.height), radius: cornerRadius)
        case .left:
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x, y: frame.y), radius: cornerRadius)
        case .right:
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y), tangent2End: CGPoint(x: frame.x, y: frame.y), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y), tangent2End: CGPoint(x: frame.x, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), radius: cornerRadius)
            path.addArc(tangent1End: CGPoint(x: frame.x + frame.width, y: frame.y + frame.height), tangent2End: CGPoint(x: frame.x + frame.width, y: frame.height), radius: cornerRadius)
        }
    }
    
    func drawText(_ bubbleFrame: CGRect, context : CGContext) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = preferences.drawing.textAlignment
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        let textRect = CGRect(x: bubbleFrame.origin.x + (bubbleFrame.size.width - textSize.width) / 2, y: bubbleFrame.origin.y + (bubbleFrame.size.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        text.draw(in: textRect, withAttributes: [.font : preferences.drawing.font, .foregroundColor : preferences.drawing.foregroundColor, .paragraphStyle : paragraphStyle])
    }
    
}

public extension TooltipView {
    func show(animated: Bool = true, forView view: UIView, withinSuperview superview: UIView? = nil) {
        precondition(superview == nil || view.hasSuperview(superview!), "The supplied superview <\(superview!)> is not a direct nor an indirect superview of the supplied reference view <\(view)>. The superview passed to this method should be a direct or an indirect superview of the reference view. To display the tooltip within the main window, ignore the superview parameter.")
        
        let superview = superview ?? UIApplication.shared.windows.first!
        
        let initialTransform = preferences.animating.showInitialTransform
        let finalTransform = preferences.animating.showFinalTransform
        let initialAlpha = preferences.animating.showInitialAlpha
        let damping = preferences.animating.springDamping
        let velocity = preferences.animating.springVelocity
        
        presentingView = view
        arrange(withinSuperview: superview)
        
        transform = initialTransform
        alpha = initialAlpha
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        superview.addSubview(self)
        
        let animations: EmptyClosure = {
            self.transform = finalTransform
            self.alpha = 1
        }
        
        if animated {
            UIView.animate(withDuration: preferences.animating.showDuration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [.curveEaseInOut], animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    func dismiss(completion: EmptyClosure? = nil){
        let damping = preferences.animating.springDamping
        let velocity = preferences.animating.springVelocity
        
        UIView.animate(withDuration: preferences.animating.dismissDuration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [.curveEaseInOut], animations: {
            self.transform = self.preferences.animating.dismissTransform
            self.alpha = self.preferences.animating.dismissFinalAlpha
        }, completion: { finished in
            completion?()
            self.removeFromSuperview()
            self.transform = CGAffineTransform.identity
        })
    }
}

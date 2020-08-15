//
//  PencilKitSignatureView.swift
//  Pods
//
//  Created by Alankar Avinash Misra on 16/05/20.
//

import UIKit
import PencilKit

@available(iOS 13.0, *)
open class PencilKitSignatureView: UIView, ISignatureView {

    private var viewReady: Bool = false

    private lazy var canvas: PKCanvasView = PKCanvasView(frame: CGRect.zero)

    // MARK: Public Properties

    open weak var delegate: SwiftSignatureViewDelegate?

    /**
    The maximum stroke width.
    */
    open var maximumStrokeWidth: CGFloat = 4 {
        didSet {
            resetTool()
        }
    }

    /**
    The minimum stroke width (ignored in PencilKit)
    */
    open var minimumStrokeWidth: CGFloat = 1

    /**
    The stroke color.
    */
    open var strokeColor: UIColor = UIColor.black {
        didSet {
            resetTool()
        }
    }

    /**
    The stroke alpha. 
    */
    open var strokeAlpha: CGFloat = 1

    /**
    The UIImage representation of the signature. Read/write.
    */
    open var signature: UIImage? {
        get {
            canvas.drawing.image(from: bounds, scale: 1.0)
        }

        set {
            guard let data = newValue?.pngData(), let drawing = try? PKDrawing(data: data) else {
                return
            }
            canvas.drawing = drawing
        }
    }

    open func getCroppedSignature() -> UIImage? {
        return autoreleasepool {
            let fullRender = canvas.drawing.image(from: canvas.bounds, scale: 1.0)
            let bounds = self.scale(canvas.drawing.bounds.insetBy(dx: -maximumStrokeWidth/2, dy: -maximumStrokeWidth/2), byFactor: fullRender.scale)
            guard let imageRef = fullRender.cgImage?.cropping(to: bounds) else { return nil }
            return UIImage(cgImage: imageRef)
        }
    }

    open var isEmpty: Bool {
        get {
            canvas.drawing.bounds.isEmpty
        }
    }

    open func clear(cache: Bool) {
        canvas.drawing = PKDrawing()
    }

    open func undo() {
        canvas.undoManager?.undo()
    }

    open func redo() {
        canvas.undoManager?.redo()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    override open func updateConstraintsIfNeeded() {
        super.updateConstraintsIfNeeded()
        if viewReady {
            return
        }
        viewReady = true
        addConstraint(NSLayoutConstraint(item: canvas, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: canvas, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: canvas, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: canvas, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
    }

    private func initialize() {
        self.backgroundColor = UIColor.black
        canvas.allowsFingerDrawing = true
        canvas.translatesAutoresizingMaskIntoConstraints = false
        addSubview(canvas)
        resetTool()
        configGestureRecognizer()
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
    }

    private func resetTool() {
        canvas.tool = PKInkingTool(.pen, color: strokeColor.withAlphaComponent(strokeAlpha), width: maximumStrokeWidth)
    }

    private func configGestureRecognizer() {
        addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(PencilKitSignatureView.gesture(_:))))
    }

    @objc private func gesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.swiftSignatureViewDidTapInside(self)
        case .failed, .ended, .cancelled:
            delegate?.swiftSignatureViewDidPanInside(self, gesture)
        @unknown default:
            break
        }
    }

    fileprivate func scale(_ rect: CGRect, byFactor factor: CGFloat) -> CGRect {
        var scaledRect = rect
        scaledRect.origin.x *= factor
        scaledRect.origin.y *= factor
        scaledRect.size.width *= factor
        scaledRect.size.height *= factor
        return scaledRect
    }

}

//
//  RatingView.swift
//  Eco
//
//  Created by DU on 6/15/19.
//  Copyright © 2019 studio4. All rights reserved.
//

import UIKit

public protocol RatingViewDelegate: NSObjectProtocol {
    func ratingView(_ ratingView: RatingView, didUpdate rating: Double)
    func ratingView(_ ratingView: RatingView, isUpdating rating: Double)
}

@IBDesignable open class RatingView: UIView {
    
    // MARK: Properties
    public weak var delegate: RatingViewDelegate?
    
    // List normal rating images (empty)
    private var normalImageViews: [UIImageView] = []
    
    // List filled rating images
    private var filledImageViews: [UIImageView ] = []
    
    // Defines images content mode, defaults is scaleAspectFit
    public var imageContentMode: UIView.ContentMode = .scaleAspectFit
    
    // Defines minimum rating image size
    @IBInspectable open var minImageSize: CGSize = CGSize(width: 5.0, height: 5.0)
    
    // Sets whether or not the rating view can be changed by panning.
    @IBInspectable open var editable: Bool = true
    
    // Default rating type
    public var type: RatingViewType = .fullRating
    
    // Sets the normal rating image (e.g. a star outline)
    @IBInspectable open var normalImage: UIImage? {
        didSet {
            for imageView in normalImageViews {
                imageView.image = normalImage
            }
            refreshImageViews()
        }
    }
    
    // Sets the filled image that is overlayed on top of the empty image.
    // Should be same size and shape as the empty image.
    @IBInspectable open var fullImage: UIImage? {
        didSet {
            // Update full image views
            for imageView in filledImageViews {
                imageView.image = fullImage
            }
            refreshImageViews()
        }
    }
    
    // Set the minimum rating value
    @IBInspectable open var minRatingValue: Int = 0 {
        didSet {
            // Update current rating if needed
            if currentRatingValue < Double(minRatingValue) {
                currentRatingValue = Double(minRatingValue)
                refreshImageViews()
            }
        }
    }
    
    // Set the maximum rating value
    @IBInspectable open var maxRatingValue: Int = 5 {
        didSet {
            if maxRatingValue != oldValue {
                removeImageViews()
                initImageViews()
                setNeedsLayout()
                refreshImageViews()
            }
        }
    }
    
    // Set the current rating value
    // we'll comparing the percent of currentRatingValue and maxRatingValue,
    // e.g: max: 5 <-> current: 2.5, So, our rating result's 50% filled and 50% outline.
    @IBInspectable open var currentRatingValue: Double = 0 {
        didSet {
            if currentRatingValue != oldValue {
                refreshImageViews()
            }
        }
    }
    
    // MARK: RatingViewType
    // Defines the type of rating view
    public enum RatingViewType: Int {
        case fullRating
        case halfRating
        case floatRating
        // Returns true if rating can contain decimal places
        func supportsFractions() -> Bool {
            return self == .halfRating || self == .floatRating
        }
    }
    
    // MARK: Initializations
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        initImageViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initImageViews()
    }
    
    // MARK: Helper methods
    private func initImageViews() {
        guard normalImageViews.isEmpty && filledImageViews.isEmpty else {
            return
        }
        
        // Add new image views
        for _ in 0..<maxRatingValue {
            let normalImageView = UIImageView()
            normalImageView.contentMode = imageContentMode
            normalImageView.image = normalImage
            normalImageViews.append(normalImageView)
            addSubview(normalImageView)
            let fullImageView = UIImageView()
            fullImageView.contentMode = imageContentMode
            fullImageView.image = fullImage
            filledImageViews.append(fullImageView)
            addSubview(fullImageView)
        }
    }
    
    private func removeImageViews() {
        // Remove old image views
        for i in 0..<normalImageViews.count {
            var imageView = normalImageViews[i]
            imageView.removeFromSuperview()
            imageView = filledImageViews[i]
            imageView.removeFromSuperview()
        }
        normalImageViews.removeAll(keepingCapacity: false)
        filledImageViews.removeAll(keepingCapacity: false)
    }
    
    // refreshImageViews hides or shows full images
    private func refreshImageViews() {
        for i in 0..<filledImageViews.count {
            let imageView = filledImageViews[i]
            
            if currentRatingValue >= Double(i+1) {
                imageView.layer.mask = nil
                imageView.isHidden = false
            } else if currentRatingValue > Double(i) && currentRatingValue < Double(i+1) {
                // Set mask layer for full image
                let maskLayer = CALayer()
                maskLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(currentRatingValue-Double(i))*imageView.frame.size.width, height: imageView.frame.size.height)
                maskLayer.backgroundColor = UIColor.black.cgColor
                imageView.layer.mask = maskLayer
                imageView.isHidden = false
            } else {
                imageView.layer.mask = nil
                imageView.isHidden = true
            }
        }
    }
    
    // Calculates the ideal ImageView size in a given CGSize
    private func sizeForImage(_ image: UIImage, inSize size: CGSize) -> CGSize {
        let imageRatio = image.size.width / image.size.height
        let viewRatio = size.width / size.height
        
        if imageRatio < viewRatio {
            let scale = size.height / image.size.height
            let width = scale * image.size.width
            
            return CGSize(width: width, height: size.height)
        } else {
            let scale = size.width / image.size.width
            let height = scale * image.size.height
            
            return CGSize(width: size.width, height: height)
        }
    }
    
    // Calculates new rating based on touch location in view
    private func updateLocation(_ touch: UITouch) {
        guard editable else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        var newRating: Double = 0
        for i in stride(from: (maxRatingValue-1), through: 0, by: -1) {
            let imageView = normalImageViews[i]
            guard touchLocation.x > imageView.frame.origin.x else {
                continue
            }
            
            // Find touch point in image view
            let newLocation = imageView.convert(touchLocation, from: self)
            
            // Find decimal value for float or half rating
            if imageView.point(inside: newLocation, with: nil) && (type.supportsFractions()) {
                let decimalNum = Double(newLocation.x / imageView.frame.size.width)
                // New rating for float type
                newRating = Double(i) + decimalNum
                if type == .halfRating {
                    // New rating for half type
                    newRating = Double(i) + (decimalNum > 0.75 ? 1 : (decimalNum > 0.25 ? 0.5 : 0))
                }
            } else {
                // New rating for full type
                newRating = Double(i) + 1.0
            }
            break
        }
        
        // Check min rating
        currentRatingValue = newRating < Double(minRatingValue) ? Double(minRatingValue) : newRating
        
        // Update delegate
        delegate?.ratingView(self, isUpdating: currentRatingValue)
    }
    
    // Override to calculate ImageView frames
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        guard let normalImage = normalImage else {
            return
        }
        
        let desiredImageWidth = frame.size.width / CGFloat(normalImageViews.count)
        let maxImageWidth = max(minImageSize.width, desiredImageWidth)
        let maxImageHeight = max(minImageSize.height, frame.size.height)
        let imageViewSize = sizeForImage(normalImage, inSize: CGSize(width: maxImageWidth, height: maxImageHeight))
        let imageXOffset = (frame.size.width - (imageViewSize.width * CGFloat(normalImageViews.count))) /
            CGFloat((normalImageViews.count - 1))
        
        for i in 0..<maxRatingValue {
            let imageFrame = CGRect(x: i == 0 ? 0 : CGFloat(i)*(imageXOffset+imageViewSize.width), y: 0, width: imageViewSize.width, height: imageViewSize.height)
            
            var imageView = normalImageViews[i]
            imageView.frame = imageFrame
            
            imageView = filledImageViews[i]
            imageView.frame = imageFrame
        }
        refreshImageViews()
    }
    
    // MARK: - Touch events
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        updateLocation(touch)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        updateLocation(touch)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.ratingView(self, didUpdate: currentRatingValue)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.ratingView(self, didUpdate: currentRatingValue)
    }
}


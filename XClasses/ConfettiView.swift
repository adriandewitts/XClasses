//
//  ConfettiView.swift
//  Bookbot
//
//  Created by ductran on 1/25/19.
//  Copyright © 2019 Bookbot. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ConfettiView: UIView {
    /**
     Set images name in IB with format [image1, images2, ..]
     */
    @IBInspectable var imagesNames: String = ""
    var colors: [UIColor] = [.red, .green, .blue, .magenta]
    var velocities = [100, 200, 300, 400]
    @IBInspectable var scale: CGFloat = 0.15
    @IBInspectable var scaleRange: CGFloat = 0.25
    
    private var images: [String]!
    private var dimension: Int!
    private let rootLayer = CALayer()
    private let confettiViewEmitterLayer = CAEmitterLayer()
    private let confettiViewEmitterCell = CAEmitterCell()
    
    // MARK: - Initializers
    override public init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        guard imagesNames.isNotEmpty else {
            return
        }
        
        dimension = colors.count
        images = imagesNames.components(separatedBy:",").map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        layer.addSublayer(rootLayer)
        setupRootLayer()
        setupConfettiEmitterLayer()
        
        confettiViewEmitterLayer.emitterCells = generateConfettiEmitterCells()
        rootLayer.addSublayer(confettiViewEmitterLayer)
    }
    
    // MARK: - Setup Layers
    private func setupRootLayer() {
        rootLayer.backgroundColor = UIColor.white.cgColor
    }
    
    private func setupConfettiEmitterLayer() {
        confettiViewEmitterLayer.emitterSize = CGSize(width: frame.size.width, height: 1)
        confettiViewEmitterLayer.emitterShape = CAEmitterLayerEmitterShape.line
        confettiViewEmitterLayer.emitterPosition = CGPoint(x: frame.size.width / 2.0, y: 0)
    }
    
    // MARK: - Generator
    private func generateConfettiEmitterCells() -> [CAEmitterCell] {
        var cells = [CAEmitterCell]()
        for index in 0..<images.count {
            let cell = CAEmitterCell()
            cell.color = nextColor(i: index)
            cell.contents = nextImage(i: index)
            cell.birthRate = 4.0
            cell.lifetime = 14.0
            cell.lifetimeRange = 0
            cell.velocity = CGFloat(Double(randomVelocity))
            cell.velocityRange = 0
            cell.emissionLongitude = CGFloat(Double.pi)
            cell.emissionRange = CGFloat(Double.pi / 4)
            cell.spin = 3.5
            cell.spinRange = 1
            cell.scale = scale
            cell.scaleRange = scaleRange
            cells.append(cell)
        }
        
        return cells
    }
    
    // MARK: - Helpers
    var randomNumber: Int {
        return Int(arc4random_uniform(UInt32(dimension)))
    }
    
    var randomVelocity: Int {
        return velocities[randomNumber]
    }
    
    private func nextColor(i: Int) -> CGColor {
        return colors[i % dimension].cgColor
    }
    
    private func nextImage(i: Int) -> CGImage? {
        let image = UIImage(named:images[i % dimension])
        return image?.cgImage
    }
}

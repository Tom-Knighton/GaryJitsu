//
//  SKLabelNode+Stroke.swift
//  JitsuGame
//
//  Created by Tom Knighton on 16/03/2026.
//

import SpriteKit
import UIKit

extension SKLabelNode {
    
    func addStroke(color:UIColor, width: CGFloat) {
        
        guard let labelText = self.text, let fontName = fontName else { return }
        
        let font = UIFont(name: fontName, size: self.fontSize)
        
        let attributedString:NSMutableAttributedString
        if let labelAttributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        guard let font, let fontColor = self.fontColor else { return }
        
        let attributes:[NSAttributedString.Key:Any] = [.strokeColor: color, .strokeWidth: -width, .font: font, .foregroundColor: fontColor]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
}

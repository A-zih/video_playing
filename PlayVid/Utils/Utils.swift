//
//  Utils.swift
//  PlayVid
//
//  Created by Zih on 2024/6/21.
//

import Foundation
import UIKit

class Utils {
    static func convertSecondToTimeString(seconds: Int) -> String {
        var time = seconds
        if seconds < 3600 {
            let minStr = String(format: "%02d", time / 60)
            time %= 60
            let secStr = String(format: "%02d", time)
            return minStr + ":" + secStr
        } else {
            let hrStr = String(time / 3600)
            time %= 3600
            let minStr = String(format: "%02d", time / 60)
            time %= 60
            let secStr = String(format: "%02d", time)
            return hrStr + ":" + minStr + ":" + secStr
        }
    }
    static func flipIcon(iconName: String) -> UIImage? {
        if let image = UIImage(systemName: iconName) {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            
            let context = UIGraphicsGetCurrentContext()
            
            context?.translateBy(x: image.size.width, y: 0)
            context?.scaleBy(x: -1.0, y: 1.0)
            
            image.draw(at: CGPoint.zero)
            
            let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            if let flippedImage = flippedImage {
                let templateImage = flippedImage.withRenderingMode(.alwaysTemplate)
                return templateImage
            }
        }
        return nil
    }
}

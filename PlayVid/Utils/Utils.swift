//
//  Utils.swift
//  PlayVid
//
//  Created by Zih on 2024/6/21.
//

import Foundation
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
}

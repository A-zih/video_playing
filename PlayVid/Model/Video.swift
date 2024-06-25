//
//  Video.swift
//  PlayVid
//
//  Created by 陳冠志 on 2024/6/24.
//

import Foundation

class Video {
    var title: String
    var url: String
    var duration: String
    
    init(title: String, url: String, duration: String) {
        self.title = title
        self.url = url
        self.duration = duration
    }
}

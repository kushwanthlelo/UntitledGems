//
//  Song.swift
//  UntitledGems
//
//  Created by Kushwanth Reddy on 11/10/25.
//

import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var filePath: String
    var artworkPath: String?  

    init(id: UUID = UUID(),
         title: String,
         artist: String,
         filePath: String,
         artworkPath: String? = nil,) {
        self.id = id
        self.title = title
        self.artist = artist
        self.filePath = filePath
        self.artworkPath = artworkPath
    }
}

//
//  SongArtworkView.swift
//  UntitledGems
//
//  Created by Kushwanth Reddy on 11/10/25.
//

import SwiftUI
import UIKit

struct SongArtworkView: View {
    let song: Song

    var body: some View {
        Group {
            if let image = loadArtwork() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                    )
            }
        }
    }

    private func loadArtwork() -> UIImage? {
        guard let artworkPath = song.artworkPath else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documents.appendingPathComponent(artworkPath)
        return UIImage(contentsOfFile: url.path)
    }
}

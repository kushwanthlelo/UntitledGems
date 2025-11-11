//
//  NowPlayingManager.swift
//  UntitledGems
//
//  Created by Kushwanth Reddy on 11/10/25.
//

import Foundation
import MediaPlayer
import UIKit

final class NowPlayingManager {
    static let shared = NowPlayingManager()
    private init() {}

    /// Set up metadata when a new track is loaded.
    func configureNowPlaying(
        title: String,
        artist: String,
        duration: TimeInterval,
        artwork: UIImage?
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            MPNowPlayingInfoPropertyPlaybackRate: 0
        ]

        if let artwork {
            let art = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            info[MPMediaItemPropertyArtwork] = art
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        print("NowPlaying configured:", title, "-", artist, "duration:", duration)
    }

    /// Update elapsed time + play/pause state (call this periodically and on toggle).
    func updatePlayback(currentTime: TimeInterval, isPlaying: Bool) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}


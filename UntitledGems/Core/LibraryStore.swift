//
//  LibraryStore.swift
//  UntitledGems
//
//  Created by Kushwanth Reddy on 11/10/25.
//

import Foundation
import Combine

class LibraryStore: ObservableObject {
    @Published var songs: [Song] = []

    private let fileName = "songs.json"

    init() {
        load()
    }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var jsonURL: URL {
        documentsURL.appendingPathComponent(fileName)
    }

    func load() {
        guard FileManager.default.fileExists(atPath: jsonURL.path) else { return }
        do {
            let data = try Data(contentsOf: jsonURL)
            let decoded = try JSONDecoder().decode([Song].self, from: data)
            self.songs = decoded
        } catch {
            print("Error loading songs.json:", error)
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: jsonURL)
        } catch {
            print("Error saving songs.json:", error)
        }
    }

    func addSong(_ song: Song) {
        songs.append(song)
        save()
    }

    func updateSong(_ song: Song) {
        if let idx = songs.firstIndex(where: { $0.id == song.id }) {
            songs[idx] = song
            save()
        }
    }

    func deleteSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        save()
    }
}

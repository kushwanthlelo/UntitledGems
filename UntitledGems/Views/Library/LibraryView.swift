//
//  LibraryView.swift
//  UntitledGems
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var isImporting = false
    @State private var selectedSong: Song?

    var body: some View {
        NavigationView {
            Group {
                if library.songs.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(library.songs) { song in
                            Button {
                                selectedSong = song
                            } label: {
                                rowView(for: song)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Songs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    themeMenu
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedSong) { song in
                NavigationStack {
                    PlayerView(song: song)
                        .environmentObject(library)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
        }
    }

    // MARK: - Row + empty state

    private func rowView(for song: Song) -> some View {
        HStack(spacing: 14) {
            SongArtworkView(song: song)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No songs yet")
                .font(.title3.weight(.semibold))

            Text("Tap the + button to import audio files from Files and start building your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Theme menu

    private var themeMenu: some View {
        Menu {
            Picker("Theme", selection: $themeManager.selectedTheme) {
                ForEach(ThemeManager.Theme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
        } label: {
            Image(systemName: "circle.lefthalf.filled")
        }
        .accessibilityLabel("Theme")
    }

    // MARK: - Actions

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let song = library.songs[index]
            library.deleteSong(song)
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else {
                print("No URL returned from fileImporter")
                return
            }

            let shouldStopAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documents.appendingPathComponent(sourceURL.lastPathComponent)

                // Avoid overwriting existing files with same name
                var finalURL = destinationURL
                var counter = 1
                while FileManager.default.fileExists(atPath: finalURL.path) {
                    let name = sourceURL.deletingPathExtension().lastPathComponent
                    let ext = sourceURL.pathExtension
                    finalURL = documents.appendingPathComponent("\(name)_\(counter).\(ext)")
                    counter += 1
                }

                // Copy file into our sandbox
                try FileManager.default.copyItem(at: sourceURL, to: finalURL)
                print("Copied audio to:", finalURL)

                let newSong = Song(
                    title: finalURL.deletingPathExtension().lastPathComponent,
                    artist: "Unknown Artist",
                    filePath: finalURL.lastPathComponent
                )

                library.addSong(newSong)
                print("Added song:", newSong.title)

            } catch {
                print("Import failed:", error)
            }

        case .failure(let error):
            print("File importer error:", error)
        }
    }
}

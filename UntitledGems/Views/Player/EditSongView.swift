//
//  EditSongView.swift
//  UntitledGems
//

import SwiftUI
import PhotosUI
import UIKit

struct EditSongView: View {
    @Environment(\.dismiss) var dismiss

    @State private var workingSong: Song
    @State private var photosPickerItem: PhotosPickerItem?

    // For cropping
    @State private var cropSourceImage: UIImage?
    @State private var isShowingCropper = false

    let onSave: (Song) -> Void

    init(song: Song, onSave: @escaping (Song) -> Void) {
        _workingSong = State(initialValue: song)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $workingSong.title)
                    TextField("Artist", text: $workingSong.artist)
                }

                Section("Artwork") {
                    HStack(spacing: 16) {
                        SongArtworkView(song: workingSong)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }
                }
            }
            .navigationTitle("Edit Song")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(workingSong)
                        dismiss()
                    }
                }
            }
            .onChange(of: photosPickerItem) { newItem in
                loadImageForCropping(from: newItem)
            }
            .sheet(isPresented: $isShowingCropper) {
                if let cropSourceImage {
                    ArtworkCropView(image: cropSourceImage) { cropped in
                        saveCroppedArtwork(cropped)
                    }
                }
            }
        }
    }

    // MARK: - Load image to crop

    private func loadImageForCropping(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.cropSourceImage = uiImage
                        self.isShowingCropper = true
                    }
                }
            } catch {
                print("Error loading image for cropping:", error)
            }
        }
    }

    // MARK: - Save cropped artwork

    private func saveCroppedArtwork(_ image: UIImage) {
        do {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "artwork_\(workingSong.id).jpg"
            let destinationURL = documents.appendingPathComponent(fileName)

            if let jpegData = image.jpegData(compressionQuality: 0.9) {
                try jpegData.write(to: destinationURL, options: .atomic)
                workingSong.artworkPath = fileName
            }
        } catch {
            print("Error saving cropped artwork:", error)
        }
    }
}

// MARK: - ArtworkCropView (slider-based crop)

struct ArtworkCropView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var zoom: Double = 1.0       // 1 = full image, >1 = zoomed in
    @State private var horizontal: Double = 0.5 // 0 = left, 1 = right
    @State private var vertical: Double = 0.5   // 0 = top, 1 = bottom
    @State private var preview: UIImage

    init(image: UIImage, onSave: @escaping (UIImage) -> Void) {
        self.image = image
        self.onSave = onSave
        _preview = State(initialValue: ArtworkCropView.crop(
            image: image,
            zoom: 1.0,
            horizontal: 0.5,
            vertical: 0.5
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 8)

                Text("Adjust zoom and position to choose the square crop.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Square preview
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("Zoom")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $zoom, in: 1...4)
                    }

                    Group {
                        Text("Horizontal")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $horizontal, in: 0...1)
                    }

                    Group {
                        Text("Vertical")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $vertical, in: 0...1)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Crop Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(preview)
                        dismiss()
                    }
                }
            }
            .onChange(of: zoom)       { _ in updatePreview() }
            .onChange(of: horizontal) { _ in updatePreview() }
            .onChange(of: vertical)   { _ in updatePreview() }
        }
    }

    private func updatePreview() {
        preview = ArtworkCropView.crop(
            image: image,
            zoom: zoom,
            horizontal: horizontal,
            vertical: vertical
        )
    }

    // MARK: - Cropping logic

    static func crop(image: UIImage, zoom: Double, horizontal: Double, vertical: Double) -> UIImage {
        let original = image
        let imgSize = original.size

        let baseSide = min(imgSize.width, imgSize.height)
        let zoomFactor = max(1.0, zoom)
        let side = baseSide / CGFloat(zoomFactor)

        let maxX = max(imgSize.width  - side, 0)
        let maxY = max(imgSize.height - side, 0)

        let x = maxX * CGFloat(horizontal)
        let y = maxY * CGFloat(vertical)

        let rect = CGRect(x: x, y: y, width: side, height: side).integral

        guard let cg = original.cgImage?.cropping(to: rect) else {
            return original
        }

        return UIImage(
            cgImage: cg,
            scale: original.scale,
            orientation: original.imageOrientation
        )
    }
}

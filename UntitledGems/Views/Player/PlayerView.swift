//
//  PlayerView.swift
//  UntitledGems
//

import SwiftUI
import AVFoundation
import MediaPlayer
import AVKit
import CoreImage

// MARK: - System controls

struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.tintColor = .white
        view.showsRouteButton = false
        return view
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

struct SystemRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView(frame: .zero)
        picker.activeTintColor = .white
               picker.tintColor = .white
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Average color helper

extension UIImage {
    /// Rough average color of the image using CIAreaAverage.
    func averageColor() -> UIColor? {
        guard let ciImage = CIImage(image: self) else { return nil }

        let extentVector = CIVector(
            x: ciImage.extent.origin.x,
            y: ciImage.extent.origin.y,
            z: ciImage.extent.size.width,
            w: ciImage.extent.size.height
        )

        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [
                                        kCIInputImageKey: ciImage,
                                        kCIInputExtentKey: extentVector
                                    ]),
              let outputImage = filter.outputImage
        else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])

        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: 1
        )
    }
}

// MARK: - PlayerView

struct PlayerView: View {
    @EnvironmentObject var library: LibraryStore
    @Environment(\.dismiss) var dismiss

    @State var song: Song

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingEdit = false

    // dynamic background colors based on artwork
    @State private var backgroundTopColor: Color = .black
    @State private var backgroundBottomColor: Color = .black

    var body: some View {
        ZStack {
            // Dynamic gradient background based on artwork color
            LinearGradient(
                colors: [backgroundTopColor, backgroundBottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                // Top bar: close + edit
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(8)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }

                    Spacer()

                    Button {
                        showingEdit = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .padding(8)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer(minLength: 8)

                // Artwork
                artworkView
                    .padding(.horizontal, 20)

                // Extra space between photo and title
                Spacer().frame(height: 32)

                // Title + artist
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)

                // Progress + time
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { currentTime },
                            set: { newValue in
                                currentTime = newValue
                                player?.currentTime = newValue
                                updateNowPlayingPlaybackState()
                            }
                        ),
                        in: 0...(player?.duration ?? 1)
                    )
                    .tint(.white)

                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(player?.duration ?? 0))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 28)

                // Playback controls
                HStack(spacing: 60) {
                    Button { skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Button { togglePlayback() } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .frame(width: 70, height: 70)
                            .background(Color.white, in: Circle())
                            .shadow(radius: 6, y: 3)
                            .foregroundColor(.black)
                    }

                    Button { skipForward() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 8)

                // System volume + route picker
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.white.opacity(0.9))
                    SystemVolumeSlider()
                        .frame(height: 30)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.white.opacity(0.9))
                    SystemRoutePicker()
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditSongView(song: song) { updatedSong in
                song = updatedSong
                library.updateSong(updatedSong)
                updateBackgroundColors()      // new artwork → new gradient
                refreshNowPlayingMetadata()   // update lock-screen info
            }
        }
        .onAppear {
            preparePlayer()
            updateBackgroundColors()
            startPlaybackIfNeeded()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Artwork

    private var artworkView: some View {
        Group {
            if let image = loadArtworkImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(radius: 16)
            } else {
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 320)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
        }
    }

    // MARK: - Dynamic background from artwork

    private func updateBackgroundColors() {
        if let image = loadArtworkImage(), let avg = image.averageColor() {
            // make a top color = average, bottom = darker version
            var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
            if avg.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha) {
                let dark = UIColor(hue: hue,
                                   saturation: sat,
                                   brightness: max(bri * 0.35, 0.08),
                                   alpha: 1.0)
                backgroundTopColor = Color(avg)
                backgroundBottomColor = Color(dark)
            } else {
                backgroundTopColor = Color(avg)
                backgroundBottomColor = .black
            }
        } else {
            backgroundTopColor = .black
            backgroundBottomColor = .black
        }
    }

    // MARK: - Player logic

    private func preparePlayer() {
        do {
            let documents = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documents.appendingPathComponent(song.filePath)
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.prepareToPlay()
            currentTime = 0
            startTimer()
        } catch {
            print("Error creating player:", error)
        }
    }

    private func startPlaybackIfNeeded() {
        guard let player = player else { return }
        if !player.isPlaying {
            player.play()
            isPlaying = true
            refreshNowPlayingMetadata()
            updateNowPlayingPlaybackState()
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }

        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
            refreshNowPlayingMetadata()
        }
        updateNowPlayingPlaybackState()
    }

    private func skipForward() {
        guard let player = player else { return }
        player.currentTime = min(player.currentTime + 10, player.duration)
        currentTime = player.currentTime
        updateNowPlayingPlaybackState()
    }

    private func skipBackward() {
        guard let player = player else { return }
        player.currentTime = max(player.currentTime - 10, 0)
        currentTime = player.currentTime
        updateNowPlayingPlaybackState()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let player = player {
                currentTime = player.currentTime
                updateNowPlayingPlaybackState()
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Now Playing integration

    private func refreshNowPlayingMetadata() {
        guard let player = player else { return }
        let artworkImage = loadArtworkImage()
        NowPlayingManager.shared.configureNowPlaying(
            title: song.title,
            artist: song.artist,
            duration: player.duration,
            artwork: artworkImage
        )
        NowPlayingManager.shared.updatePlayback(
            currentTime: player.currentTime,
            isPlaying: isPlaying
        )
    }

    private func updateNowPlayingPlaybackState() {
        guard let player = player else { return }
        NowPlayingManager.shared.updatePlayback(
            currentTime: player.currentTime,
            isPlaying: isPlaying
        )
    }

    private func loadArtworkImage() -> UIImage? {
        guard let artworkPath = song.artworkPath else { return nil }
        let documents = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documents.appendingPathComponent(artworkPath)
        return UIImage(contentsOfFile: url.path)
    }
}

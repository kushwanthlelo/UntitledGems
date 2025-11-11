# 🎵 UntitledGems – Offline iOS Music Player

**UntitledGems** is a SwiftUI-based offline music player app designed to let users import, organize, and play their own songs — all without internet connectivity or external hosting.  
Built purely for personal use, it focuses on simplicity, persistence, and elegant light/dark theming.

---

## ✨ Features

- 🎶 **Offline Playback** — import audio files and listen without network access  
- 🖼 **Custom Artwork** — set or change song cover images  
- ✍️ **Edit Metadata** — modify title, artist, and lyrics directly in-app  
- 💾 **Persistent Library** — songs and changes saved to `songs.json` in the app’s Documents directory  
- 🌗 **Theme Toggle** — switch between Light and Dark mode manually or use system preference  
- 🔊 **Background Audio** — music keeps playing even when the app is minimized or screen is locked  
- 📁 **File Importer Integration** — easily add new tracks from Files app  
- 🧭 **Minimal UI** — clean, white design with system adaptive colors (no gradients)

---

## 🧩 Tech Stack

| Component | Description |
|------------|-------------|
| **Language** | Swift |
| **Framework** | SwiftUI |
| **Audio Engine** | AVFoundation (AVAudioPlayer) |
| **Image Picker** | PhotosUI |
| **Data Storage** | JSON persistence (FileManager + Codable) |
| **Theme Handling** | ObservableObject + UserDefaults |
| **Environment** | Xcode (iOS 17+, Swift 5.9) |

---

## 📂 Project Structure

```plaintext
UntitledGems/
├── UntitledGemsApp.swift      # App entry point
├── LibraryStore.swift         # Handles loading/saving songs
├── LibraryView.swift          # Displays all songs
├── PlayerView.swift           # Main player with controls
├── EditSongView.swift         # Edit screen for song metadata
├── Song.swift                 # Model definition
├── SongArtworkView.swift      # Artwork display helper
└── ThemeManager.swift         # Light/Dark theme handling
```


---

## 🚀 Setup & Usage

1. Open the project in **Xcode**.
2. Enable background playback:
   - Go to **Signing & Capabilities → + Capability → Background Modes**
   - Check **Audio, AirPlay, and Picture in Picture**
3. Build and run on a physical iPhone or Simulator.
4. Tap ➕ to **import audio files** (from the Files app).
5. Tap a song to open the **Player View**.
6. Use the **Edit** button to change artwork, title, artist, or lyrics.
7. Changes are automatically saved and persist between launches.

---

## 📸 Screenshots (optional)

> Add images here later — e.g. `![PlayerView Screenshot](Screenshots/player.png)`

---

## 🧠 Future Plans

- Playlist support  
- Shuffle & repeat modes  
- Lyrics synchronization  
- iCloud backup for metadata  
- Mini player widget  

---

## 🧑‍💻 Author

**Kushwanth Reddy Puchakayala**  
📍 University of Massachusetts Lowell  
📧 [GitHub: @kushwanthlelo](https://github.com/kushwanthlelo)

---

## ⚖️ License

This project is for **personal and educational use only**.  
Not intended for distribution on the App Store or commercial resale.

---



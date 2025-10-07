import Foundation
import AVFoundation
import MediaPlayer

final class AudioService: NSObject {
    static let shared = AudioService()

    private var player: AVPlayer?
    private var currentBookId: Int = 0
    private var currentChapter: Int = 0
    private var observers: [NSObjectProtocol] = []
    private var timeObserver: Any?
    private var isStarting: Bool = false
    private var lastToggleAt: Date = .distantPast

    private override init() {
        super.init()
        setupAudioSession()
        setupNotifications()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioError, object: nil, userInfo: ["message": "Audio session failed: \(error.localizedDescription)"])
            }
        }
    }

    private func setupNotifications() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notif in
            guard let info = notif.userInfo,
                  let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
            if type == .began {
                self?.player?.pause()
            } else if type == .ended {
                if let optRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt,
                   AVAudioSession.InterruptionOptions(rawValue: optRaw).contains(.shouldResume) {
                    self?.player?.play()
                }
            }
        })

        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            // Ensure we remain active after route changes (e.g., Bluetooth connect/disconnect)
            self?.setupAudioSession()
        })
    }

    func togglePlay(book: BibleBook, chapter: Int) {
        // Debounce rapid taps
        if Date().timeIntervalSince(lastToggleAt) < 0.4 { return }
        lastToggleAt = Date()

        if isPlaying && currentBookId == book.id && currentChapter == chapter {
            player?.pause()
            updateNowPlaying(isPlaying: false)
            return
        }

        currentBookId = book.id
        currentChapter = chapter

        guard let url = souerURL(forBookName: book.name, chapter: chapter) else { return }
        print("[Audio] Attempting: \(url.absoluteString)")
        isStarting = true

        // Start playback immediately; avoid HEAD preflight which may time out (-1001)
        play(url: url)
    }

    private func play(url: URL) {
        let item = AVPlayerItem(url: url)
        // Observe item status to surface errors
        item.addObserver(self, forKeyPath: "status", options: [.initial, .new], context: nil)
        if player == nil { player = AVPlayer(playerItem: item) } else { player?.replaceCurrentItem(with: item) }
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.volume = 1.0
        player?.play()
        configureRemoteCommands()
        updateNowPlaying(isPlaying: true)
        // Load duration asynchronously using modern API to avoid deprecation
        Task {
            do {
                let duration = try await item.asset.load(.duration)
                await MainActor.run { self.updateNowPlaying(duration: CMTimeGetSeconds(duration)) }
            } catch {
                // Ignore duration load failures
            }
        }
        addPeriodicTimeObserver()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "status", let item = object as? AVPlayerItem else { return }
        switch item.status {
        case .readyToPlay:
            isStarting = false
        case .failed:
            let msg = item.error?.localizedDescription ?? "Audio failed to load."
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioError, object: nil, userInfo: ["message": msg])
            }
            isStarting = false
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func addPeriodicTimeObserver() {
        guard let player else { return }
        timeObserver.map { player.removeTimeObserver($0) }
        let interval = CMTime(seconds: 1, preferredTimescale: 2)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateNowPlaying(elapsed: CMTimeGetSeconds(time))
        }
    }

    private func configureRemoteCommands() {
        let r = MPRemoteCommandCenter.shared()
        r.playCommand.isEnabled = true
        r.pauseCommand.isEnabled = true
        r.togglePlayPauseCommand.isEnabled = true
        r.playCommand.addTarget { [weak self] _ in self?.player?.play(); self?.updateNowPlaying(isPlaying: true); return .success }
        r.pauseCommand.addTarget { [weak self] _ in self?.player?.pause(); self?.updateNowPlaying(isPlaying: false); return .success }
        r.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let s = self else { return .commandFailed }
            if s.isPlaying { s.player?.pause(); s.updateNowPlaying(isPlaying: false) } else { s.player?.play(); s.updateNowPlaying(isPlaying: true) }
            return .success
        }
    }

    private func updateNowPlaying(isPlaying: Bool? = nil, duration: Double? = nil, elapsed: Double? = nil) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = titleForNowPlaying()
        if let duration { info[MPMediaItemPropertyPlaybackDuration] = duration }
        if let elapsed { info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed }
        if let isPlaying { info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0 }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func titleForNowPlaying() -> String {
        let name = BibleService.shared.getBookName(byId: currentBookId) ?? ""
        return name.isEmpty ? "BSB Audio" : "\(name) \(currentChapter) — BSB"
    }

    var isPlaying: Bool {
        guard let p = player else { return false }
        return p.timeControlStatus == .playing
    }

    func isPlaying(book: BibleBook, chapter: Int) -> Bool {
        return isPlaying && currentBookId == book.id && currentChapter == chapter
    }

    // MARK: - OpenBible Souer URL builder
    // Pattern: https://openbible.com/audio/souer/BSB_XX_Abbr_CCC.mp3
    private func souerURL(forBookName name: String, chapter: Int) -> URL? {
        guard let id = BibleService.shared.canonicalBookId(for: name) else { return nil }
        let abbr = souerAbbreviation(for: name)
        let id2 = String(format: "%02d", id)
        let chap3 = String(format: "%03d", chapter)
        let urlString = "https://openbible.com/audio/souer/BSB_\(id2)_\(abbr)_\(chap3).mp3"
        return URL(string: urlString)
    }

    private func souerAbbreviation(for name: String) -> String {
        let map: [String: String] = [
            "Genesis": "Gen", "Exodus": "Exo", "Leviticus": "Lev", "Numbers": "Num", "Deuteronomy": "Deu",
            "Joshua": "Jos", "Judges": "Jdg", "Ruth": "Rut", "1 Samuel": "1Sa", "2 Samuel": "2Sa",
            "1 Kings": "1Ki", "2 Kings": "2Ki", "1 Chronicles": "1Ch", "2 Chronicles": "2Ch",
            "Ezra": "Ezr", "Nehemiah": "Neh", "Esther": "Est", "Job": "Job", "Psalms": "Psa",
            "Proverbs": "Pro", "Ecclesiastes": "Ecc", "Song of Solomon": "Sng", "Isaiah": "Isa",
            "Jeremiah": "Jer", "Lamentations": "Lam", "Ezekiel": "Eze", "Daniel": "Dan",
            "Hosea": "Hos", "Joel": "Joe", "Amos": "Amo", "Obadiah": "Oba", "Jonah": "Jon",
            "Micah": "Mic", "Nahum": "Nah", "Habakkuk": "Hab", "Zephaniah": "Zep", "Haggai": "Hag",
            "Zechariah": "Zec", "Malachi": "Mal",
            "Matthew": "Mat", "Mark": "Mar", "Luke": "Luk", "John": "Joh", "Acts": "Act",
            "Romans": "Rom", "1 Corinthians": "1Co", "2 Corinthians": "2Co", "Galatians": "Gal",
            "Ephesians": "Eph", "Philippians": "Php", "Colossians": "Col", "1 Thessalonians": "1Th",
            "2 Thessalonians": "2Th", "1 Timothy": "1Ti", "2 Timothy": "2Ti", "Titus": "Tit",
            "Philemon": "Phm", "Hebrews": "Heb", "James": "Jas", "1 Peter": "1Pe", "2 Peter": "2Pe",
            "1 John": "1Jn", "2 John": "2Jn", "3 John": "3Jn", "Jude": "Jud", "Revelation": "Rev"
        ]
        return map[name] ?? name
    }
}



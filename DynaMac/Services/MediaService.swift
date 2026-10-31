import Foundation
import AppKit
import Combine

// MARK: - MediaRemote Bridge (macOS Control Center / Denetim Merkezi "Şu An Çalınan")
public final class MediaRemoteBridge {
    public static let shared = MediaRemoteBridge()
    
    private var handle: UnsafeMutableRawPointer?
    
    private typealias MRMediaRemoteRegisterFn = @convention(c) (DispatchQueue) -> Void
    private typealias MRMediaRemoteGetInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    private typealias MRMediaRemoteGetIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRMediaRemoteSendCommandFn = @convention(c) (UInt32, AnyObject?) -> Bool
    
    private var registerFn: MRMediaRemoteRegisterFn?
    private var getInfoFn: MRMediaRemoteGetInfoFn?
    private var getIsPlayingFn: MRMediaRemoteGetIsPlayingFn?
    private var sendCommandFn: MRMediaRemoteSendCommandFn?
    
    public private(set) var isAvailable: Bool = false
    
    private init() {
        if let h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) {
            self.handle = h
            
            if let regSym = dlsym(h, "MRMediaRemoteRegisterForNowPlayingNotifications"),
               let getSym = dlsym(h, "MRMediaRemoteGetNowPlayingInfo"),
               let isPlayingSym = dlsym(h, "MRMediaRemoteGetNowPlayingApplicationIsPlaying"),
               let cmdSym = dlsym(h, "MRMediaRemoteSendCommand") {
                
                self.registerFn = unsafeBitCast(regSym, to: MRMediaRemoteRegisterFn.self)
                self.getInfoFn = unsafeBitCast(getSym, to: MRMediaRemoteGetInfoFn.self)
                self.getIsPlayingFn = unsafeBitCast(isPlayingSym, to: MRMediaRemoteGetIsPlayingFn.self)
                self.sendCommandFn = unsafeBitCast(cmdSym, to: MRMediaRemoteSendCommandFn.self)
                
                self.isAvailable = true
                self.registerFn?(DispatchQueue.main)
            }
        }
    }
    
    public func fetchNowPlayingInfo(completion: @escaping ([String: Any]?) -> Void) {
        guard isAvailable, let getInfoFn = getInfoFn else {
            completion(nil)
            return
        }
        getInfoFn(DispatchQueue.main, completion)
    }
    
    public func fetchIsPlaying(completion: @escaping (Bool) -> Void) {
        guard isAvailable, let getIsPlayingFn = getIsPlayingFn else {
            completion(false)
            return
        }
        getIsPlayingFn(DispatchQueue.main, completion)
    }
    
    public func sendCommand(_ command: UInt32) -> Bool {
        guard isAvailable, let sendCommandFn = sendCommandFn else { return false }
        return sendCommandFn(command, nil)
    }
}

// MARK: - MediaService (Control Center + Safari YouTube + Spotify/Music Fallback)
public final class MediaService: ObservableObject {
    public static let shared = MediaService()
    
    @Published public private(set) var currentTrack: MediaTrack = .empty
    @Published public private(set) var isPlaying: Bool = false
    public let audioLevels: [CGFloat] = [0.05, 0.05, 0.05, 0.05, 0.05]
    
    private var pollTimer: Timer?
    private let mrBridge = MediaRemoteBridge.shared
    
    /// Serial background queue for all AppleScript / network work.
    /// Apple Events and artwork downloads block for tens to hundreds of milliseconds
    /// (or longer when the target app is busy), so they must never run on the main thread.
    private let scriptQueue = DispatchQueue(label: "com.reuzen.DynaMac.media-scripts", qos: .utility)
    /// Main-thread only. Prevents fallback probes from piling up if a target app is slow to respond.
    private var isFallbackInFlight = false
    /// scriptQueue only. Artwork is re-fetched only when the track (or its artwork URL) changes.
    private var artworkCacheKey: String = ""
    private var artworkCacheImage: NSImage?
    
    // Wall-clock interpolation state for live elapsed time updates
    private var anchorDate: Date = Date()
    private var anchorElapsed: Double = 0
    private var currentTrackId: String = ""
    private var tickCounter: Int = 0
    
    private init() {
        setupObservers()
        updatePlaybackState()
        
        // Lightweight tick for live time progress and periodic playback check
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.pollTimer = timer
    }
    
    deinit {
        pollTimer?.invalidate()
    }
    
    private func handleTimerTick() {
        if isPlaying {
            tickPlaybackProgress()
        }
        
        tickCounter += 1
        let threshold = isPlaying ? 4 : 8 // 2s refresh when playing, 4s when idle
        if tickCounter >= threshold {
            tickCounter = 0
            updatePlaybackState()
        }
    }
    
    private func tickPlaybackProgress() {
        guard isPlaying, !currentTrack.title.isEmpty else { return }
        let now = Date()
        let delta = now.timeIntervalSince(anchorDate)
        var liveElapsed = max(0, anchorElapsed + delta)
        
        if currentTrack.duration > 0 {
            liveElapsed = min(currentTrack.duration, liveElapsed)
        }
        
        self.currentTrack.elapsedTime = liveElapsed
    }
    
    private func setupObservers() {
        // 1. Listen for Control Center (MediaRemote) system notifications
        let nc = NotificationCenter.default
        nc.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        
        nc.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        
        nc.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        
        // 2. Distributed notifications for Apple Music and Spotify
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        
        dnc.addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
    }
    
    public func updatePlaybackState() {
        // Priority 1: Check System-Wide Control Center (Denetim Merkezi) Now Playing
        if mrBridge.isAvailable {
            mrBridge.fetchNowPlayingInfo { [weak self] info in
                guard let self = self else { return }
                
                if let dict = info,
                   let title = dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String,
                   !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    
                    let artist = dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                    let album = dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                    let duration = (dict["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? (dict["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0)
                    let elapsed = (dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? (dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0)
                    let rate = (dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? (dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double)
                    
                    var artworkImage: NSImage? = nil
                    if let artData = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                        artworkImage = NSImage(data: artData)
                    }
                    
                    self.mrBridge.fetchIsPlaying { isPlayingApp in
                        // PlaybackRate is the absolute ground truth:
                        // In Safari / YouTube, rate is 0.0 when paused, even if isPlayingApp is still true.
                        let playing: Bool
                        if let r = rate {
                            playing = r > 0.01
                        } else {
                            playing = isPlayingApp
                        }
                        
                        let trackId = "\(title)|\(artist)|\(Int(duration))"
                        let isNewTrack = (trackId != self.currentTrackId)
                        let now = Date()
                        
                        if isNewTrack {
                            self.currentTrackId = trackId
                            self.anchorDate = now
                            if elapsed > 0 && (duration <= 0 || elapsed < duration) {
                                self.anchorElapsed = elapsed
                            } else {
                                self.anchorElapsed = 0
                            }
                        } else {
                            // Same track: if the user scrubbed in the browser/player, re-anchor to new position
                            let currentEstimated = self.anchorElapsed + (self.isPlaying ? now.timeIntervalSince(self.anchorDate) : 0)
                            if elapsed > 0 && abs(elapsed - currentEstimated) > 2.5 {
                                self.anchorElapsed = elapsed
                                self.anchorDate = now
                            }
                        }
                        
                        // Play/Pause state transition
                        if playing != self.isPlaying {
                            if playing {
                                // Resumed
                                self.anchorElapsed = self.currentTrack.elapsedTime
                                self.anchorDate = now
                            } else {
                                // Paused
                                let delta = now.timeIntervalSince(self.anchorDate)
                                self.anchorElapsed = max(0, self.anchorElapsed + delta)
                                self.anchorDate = now
                            }
                        }
                        
                        let computedElapsed: Double
                        if playing {
                            let delta = now.timeIntervalSince(self.anchorDate)
                            let live = self.anchorElapsed + delta
                            computedElapsed = duration > 0 ? min(duration, max(0, live)) : max(0, live)
                        } else {
                            computedElapsed = self.anchorElapsed
                        }
                        
                        let track = MediaTrack(
                            title: title,
                            artist: artist.isEmpty ? "Control Center" : artist,
                            album: album,
                            artwork: artworkImage,
                            isPlaying: playing,
                            duration: duration,
                            elapsedTime: computedElapsed,
                            appName: "Control Center"
                        )
                        self.applyTrack(track)
                    }
                    return
                } else {
                    // Fallback to Safari YouTube / Spotify / Apple Music
                    self.fallbackPlaybackState()
                }
            }
        } else {
            fallbackPlaybackState()
        }
    }
    
    private func fallbackPlaybackState() {
        guard !isFallbackInFlight else { return }
        isFallbackInFlight = true
        
        scriptQueue.async { [weak self] in
            guard let self = self else { return }
            let track = self.probeFallbackSources()
            
            DispatchQueue.main.async {
                self.isFallbackInFlight = false
                if let track = track {
                    // Re-anchor the wall-clock interpolation to the position reported by the player.
                    self.currentTrackId = "\(track.title)|\(track.artist)|\(Int(track.duration))"
                    self.anchorElapsed = track.elapsedTime
                    self.anchorDate = Date()
                    self.currentTrack = track
                    self.isPlaying = track.isPlaying
                } else if self.currentTrack.isPlaying || !self.currentTrack.title.isEmpty {
                    self.currentTrack = .empty
                    self.isPlaying = false
                }
            }
        }
    }
    
    /// Runs on `scriptQueue`. Queries Safari (YouTube), Spotify and Apple Music in priority order.
    private func probeFallbackSources() -> MediaTrack? {
        // Fallback 1: Dedicated Safari YouTube inspection
        if let safariTrack = fetchSafariYouTubeInfo() {
            return safariTrack
        }
        
        // Fallback 2: Spotify
        if isAppRunning("com.spotify.client") {
            if let track = fetchSpotifyInfo(), track.isPlaying || !track.title.isEmpty {
                return track
            }
        }
        
        // Fallback 3: Apple Music
        if isAppRunning("com.apple.Music") {
            if let track = fetchAppleMusicInfo(), track.isPlaying || !track.title.isEmpty {
                return track
            }
        }
        
        return nil
    }
    
    /// Runs on `scriptQueue`. Returns the cached artwork for `key`, loading it only when the key changes.
    private func cachedArtwork(forKey key: String, loader: () -> NSImage?) -> NSImage? {
        if key == artworkCacheKey {
            return artworkCacheImage
        }
        let image = loader()
        artworkCacheKey = key
        artworkCacheImage = image
        return image
    }
    
    private func applyTrack(_ track: MediaTrack) {
        DispatchQueue.main.async {
            self.currentTrack = track
            self.isPlaying = track.isPlaying
        }
    }
    
    private func isAppRunning(_ bundleId: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).isEmpty
    }
    
    // MARK: - Playback Controls (Control Center MediaRemote + Browser fallback)
    public func togglePlayPause() {
        if mrBridge.isAvailable {
            let sent = mrBridge.sendCommand(2) // MRMediaRemoteCommandTogglePlayPause
            if sent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    self?.updatePlaybackState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                    self?.updatePlaybackState()
                }
                return
            }
        }
        
        // Fallback
        if isAppRunning("com.spotify.client") {
            runScriptInBackground("tell application \"Spotify\" to playpause")
        } else if isAppRunning("com.apple.Music") {
            runScriptInBackground("tell application \"Music\" to playpause")
        } else if isAppRunning("com.apple.Safari") {
            scriptQueue.async { [weak self] in self?.toggleSafariVideo() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updatePlaybackState()
        }
    }
    
    public func nextTrack() {
        if mrBridge.isAvailable {
            let sent = mrBridge.sendCommand(4) // MRMediaRemoteCommandNextTrack
            if sent {
                self.anchorElapsed = 0
                self.anchorDate = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    self?.updatePlaybackState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.updatePlaybackState()
                }
                return
            }
        }
        
        // Fallback
        if isAppRunning("com.spotify.client") {
            runScriptInBackground("tell application \"Spotify\" to next track")
        } else if isAppRunning("com.apple.Music") {
            runScriptInBackground("tell application \"Music\" to next track")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updatePlaybackState()
        }
    }
    
    public func previousTrack() {
        if mrBridge.isAvailable {
            let sent = mrBridge.sendCommand(5) // MRMediaRemoteCommandPreviousTrack
            if sent {
                self.anchorElapsed = 0
                self.anchorDate = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    self?.updatePlaybackState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.updatePlaybackState()
                }
                return
            }
        }
        
        // Fallback
        if isAppRunning("com.spotify.client") {
            runScriptInBackground("tell application \"Spotify\" to previous track")
        } else if isAppRunning("com.apple.Music") {
            runScriptInBackground("tell application \"Music\" to previous track")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updatePlaybackState()
        }
    }
    
    // MARK: - Direct Safari YouTube Detection Fallback
    private func fetchSafariYouTubeInfo() -> MediaTrack? {
        guard isAppRunning("com.apple.Safari") else { return nil }
        let script = """
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    set u to URL of t
                    if u contains "youtube.com/watch" then
                        set n to name of t
                        set vidInfo to ""
                        try
                            set vidInfo to (do JavaScript "var v = document.querySelector('video'); if (v) { (!v.paused && !v.ended && v.readyState > 2) + '|||' + Math.floor(v.currentTime) + '|||' + Math.floor(v.duration); } else { 'false|||0|||0'; }" in t)
                        end try
                        return n & "|||" & u & "|||" & vidInfo
                    end if
                end repeat
            end repeat
        end tell
        """
        guard let output = runAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 2 else { return nil }
        
        var title = parts[0]
        if title.hasSuffix(" - YouTube") {
            title = String(title.dropLast(10))
        }
        let urlString = parts[1]
        
        var isPlaying = false
        var currentTime: Double = 0
        var duration: Double = 0
        
        if parts.count >= 5 {
            isPlaying = parts[2].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
            currentTime = Double(parts[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            duration = Double(parts[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        }
        
        // Extract video id for thumbnail (downloaded once per video, never on the main thread)
        var artwork: NSImage? = nil
        if let url = URL(string: urlString),
           let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoId = comps.queryItems?.first(where: { $0.name == "v" })?.value,
           let thumbUrl = URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg") {
            artwork = cachedArtwork(forKey: "yt:\(videoId)") { downloadArtwork(from: thumbUrl) }
        }
        
        return MediaTrack(
            title: title,
            artist: "YouTube",
            album: "Safari",
            artwork: artwork,
            isPlaying: isPlaying,
            duration: duration,
            elapsedTime: currentTime,
            appName: "Safari"
        )
    }
    
    private func toggleSafariVideo() {
        let script = """
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "youtube.com" then
                        tell t to do JavaScript "var v = document.querySelector('video'); if (v) { v.paused ? v.play() : v.pause(); }"
                        return
                    end if
                end repeat
            end repeat
        end tell
        """
        runAppleScript(script)
    }
    
    // MARK: - Fallback AppleScript Helpers
    private func fetchSpotifyInfo() -> MediaTrack? {
        let script = """
        tell application "Spotify"
            if it is running then
                set pState to player state as string
                set tName to name of current track
                set tArtist to artist of current track
                set tAlbum to album of current track
                set tDuration to (duration of current track) / 1000.0
                set tPos to player position
                set artUrl to artwork url of current track
                return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPos & "|||" & artUrl
            end if
        end tell
        """
        guard let output = runAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let isPlaying = parts[0].lowercased().contains("playing")
        let title = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let duration = Double(parts[4]) ?? 0
        let elapsed = Double(parts[5]) ?? 0
        
        var artwork: NSImage? = nil
        if parts.count >= 7, let url = URL(string: parts[6]), !parts[6].isEmpty {
            artwork = cachedArtwork(forKey: "spotify:\(parts[6])") { downloadArtwork(from: url) }
        }
        
        return MediaTrack(
            title: title,
            artist: artist,
            album: album,
            artwork: artwork,
            isPlaying: isPlaying,
            duration: duration,
            elapsedTime: elapsed,
            appName: "Spotify"
        )
    }
    
    private func fetchAppleMusicInfo() -> MediaTrack? {
        let script = """
        tell application "Music"
            if it is running then
                set pState to player state as string
                set tName to name of current track
                set tArtist to artist of current track
                set tAlbum to album of current track
                set tDuration to duration of current track
                set tPos to player position
                return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPos
            end if
        end tell
        """
        guard let output = runAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let isPlaying = parts[0].lowercased().contains("playing")
        let title = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let duration = Double(parts[4]) ?? 0
        let elapsed = Double(parts[5]) ?? 0
        
        let artwork = cachedArtwork(forKey: "music:\(title)|\(artist)|\(album)") { fetchAppleMusicArtwork() }
        
        return MediaTrack(
            title: title,
            artist: artist,
            album: album,
            artwork: artwork,
            isPlaying: isPlaying,
            duration: duration,
            elapsedTime: elapsed,
            appName: "Apple Music"
        )
    }
    
    private func fetchAppleMusicArtwork() -> NSImage? {
        let script = """
        tell application "Music"
            if it is running then
                try
                    tell current track
                        if (count of artworks) > 0 then
                            return raw data of artwork 1
                        end if
                    end tell
                end try
            end if
        end tell
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            let data = result.data
            if !data.isEmpty {
                return NSImage(data: data)
            }
        }
        return nil
    }
    
    /// Fire-and-forget AppleScript on the serial script queue (keeps the main thread responsive).
    private func runScriptInBackground(_ script: String) {
        scriptQueue.async { [weak self] in
            self?.runAppleScript(script)
        }
    }
    
    @discardableResult
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            return result.stringValue
        }
        return nil
    }
    
    private func downloadArtwork(from url: URL) -> NSImage? {
        if let data = try? Data(contentsOf: url) {
            return NSImage(data: data)
        }
        return nil
    }
}

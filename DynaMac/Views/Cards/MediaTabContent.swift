import SwiftUI

public struct MediaTabContent: View {
    @ObservedObject var mediaService = MediaService.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Album Artwork or App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.pink.opacity(0.85), Color.purple.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 46, height: 46)
                    
                    if let artwork = mediaService.currentTrack.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 46, height: 46)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: .pink.opacity(0.35), radius: 6, x: 0, y: 2)
                
                // Track Info with optical tracking
                VStack(alignment: .leading, spacing: 2) {
                    Text(mediaService.currentTrack.title.isEmpty ? l10n.t("no_track") : mediaService.currentTrack.title)
                        .font(.system(size: 13, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(mediaService.currentTrack.artist.isEmpty ? l10n.t("open_music_app") : mediaService.currentTrack.artist)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    if !mediaService.currentTrack.album.isEmpty {
                        Text(mediaService.currentTrack.album)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // GPU-accelerated animated sound spectrum (0% CPU)
                EqualizerView(
                    barCount: 5,
                    isPlaying: mediaService.isPlaying,
                    color: Color.pink.opacity(0.9),
                    width: 3,
                    minHeight: 4,
                    maxHeight: 20
                )
                .frame(height: 20)
                .opacity(mediaService.currentTrack.title.isEmpty ? 0 : 1)
            }
            
            // Progress Bar
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(geo.size.width * CGFloat(mediaService.currentTrack.progress), geo.size.width)), height: 4)
                            .animation(.linear(duration: 0.5), value: mediaService.currentTrack.progress)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text(formatTime(mediaService.currentTrack.elapsedTime))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.55))
                    
                    Spacer()
                    
                    Text(mediaService.currentTrack.duration > 0 ? formatTime(mediaService.currentTrack.duration) : "--:--")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            
            // Playback Controls with fluid press & haptic response
            HStack(spacing: 28) {
                Button(action: {
                    HapticService.play(.tap)
                    mediaService.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.fluidPress(scale: 0.88))
                
                Button(action: {
                    HapticService.play(.tap)
                    mediaService.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: mediaService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .offset(x: mediaService.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.fluidPress(scale: 0.92))
                
                Button(action: {
                    HapticService.play(.tap)
                    mediaService.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.fluidPress(scale: 0.88))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

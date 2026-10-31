import Foundation
import AppKit

public struct MediaTrack: Equatable {
    public var title: String
    public var artist: String
    public var album: String
    public var artwork: NSImage?
    public var isPlaying: Bool
    public var duration: TimeInterval
    public var elapsedTime: TimeInterval
    public var appName: String
    
    public static let empty = MediaTrack(
        title: "",
        artist: "",
        album: "",
        artwork: nil,
        isPlaying: false,
        duration: 0,
        elapsedTime: 0,
        appName: ""
    )
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(elapsedTime / duration, 0), 1)
    }
}

public struct ShelfItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public let name: String
    public let sizeString: String
    public let icon: NSImage
    public let dateAdded: Date
    
    public init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.dateAdded = Date()
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        
        var sizeStr = "--"
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        self.sizeString = sizeStr
    }
    
    public static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}


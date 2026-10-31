import Foundation
import AppKit
import Combine

public final class ShelfService: ObservableObject {
    public static let shared = ShelfService()
    
    @Published public private(set) var items: [ShelfItem] = []
    
    private init() {}
    
    public func addFiles(urls: [URL]) {
        for url in urls {
            // Avoid duplicates
            if !items.contains(where: { $0.url == url }) {
                items.insert(ShelfItem(url: url), at: 0)
            }
        }
    }
    
    public func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }
    
    public func clearAll() {
        items.removeAll()
    }
    
    public func revealInFinder(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
    
    public func copyPath(_ item: ShelfItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.url.path, forType: .string)
    }
}


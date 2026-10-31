import SwiftUI

public struct ShelfTabContent: View {
    @ObservedObject var shelfService = ShelfService.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    public var body: some View {
        VStack(spacing: 8) {
            if shelfService.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 26))
                        .foregroundColor(.cyan.opacity(0.85))
                    
                    Text(l10n.t("shelf_title"))
                        .font(.system(size: 13, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(.white)
                    
                    Text(l10n.t("shelf_empty_sub"))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 14)
            } else {
                HStack {
                    Text(String(format: l10n.t("shelf_items_count"), shelfService.items.count))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    
                    Spacer()
                    
                    Button(l10n.t("clear_all")) {
                        HapticService.play(.snap)
                        shelfService.clearAll()
                    }
                    .buttonStyle(.fluidPress)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red.opacity(0.85))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(shelfService.items) { item in
                            VStack(spacing: 6) {
                                Image(nsImage: item.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                
                                Text(item.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 68)
                                
                                Text(item.sizeString)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                            .contextMenu {
                                Button(l10n.t("reveal_finder")) {
                                    shelfService.revealInFinder(item)
                                }
                                Button(l10n.t("copy_path")) {
                                    shelfService.copyPath(item)
                                }
                                Divider()
                                Button(l10n.t("remove"), role: .destructive) {
                                    HapticService.play(.tap)
                                    shelfService.removeItem(item)
                                }
                            }
                            .onDrag {
                                NSItemProvider(object: item.url as NSURL)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
            }
        }
        .frame(minHeight: 115)
    }
}


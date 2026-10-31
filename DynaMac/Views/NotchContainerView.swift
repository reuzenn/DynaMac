import SwiftUI
import UniformTypeIdentifiers

public struct NotchContainerView: View {
    @ObservedObject var viewModel = NotchViewModel.shared
    @ObservedObject var notchManager = NotchManager.shared
    @ObservedObject var settings = NotchSettings.shared
    @ObservedObject var mediaService = MediaService.shared
    @ObservedObject var shelfService = ShelfService.shared
    @ObservedObject var batteryService = BatteryService.shared
    @ObservedObject var timerService = TimerService.shared
    @ObservedObject var l10n = LocalizationManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var isPointerDown: Bool = false
    
    private var geom: NotchGeometry {
        notchManager.currentGeometry
    }
    
    private var islandSize: CGSize {
        IslandLayout.size(
            state: viewModel.state,
            compact: viewModel.compactActivity,
            hovering: viewModel.isHovering,
            stretch: viewModel.stretch,
            geometry: geom
        )
    }
    
    private var bottomRadius: CGFloat {
        IslandLayout.bottomRadius(
            state: viewModel.state,
            compact: viewModel.compactActivity,
            geometry: geom
        )
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Morphing Dynamic Island Capsule
            // Locked strictly to y = 0 (top screen bezel), expands purely downward!
            ZStack(alignment: .top) {
                // Background: Jet black OLED capsule with flat top edge against MacBook bezel
                DynamicIslandShape(
                    bottomCornerRadius: bottomRadius,
                    isFloating: geom.isFloating,
                    topCornerRadius: 0
                )
                .fill(Color.black)
                .shadow(
                    color: Color.black.opacity(viewModel.state.isExpanded ? 0.70 : (viewModel.state == .collapsed ? 0.30 : 0.45)),
                    radius: viewModel.state.isExpanded ? 24 : 4,
                    x: 0,
                    y: viewModel.state.isExpanded ? 12 : 2
                )
                
                // Specular light edge along the curved sides and bottom (faded out at top bezel)
                DynamicIslandShape(
                    bottomCornerRadius: bottomRadius,
                    isFloating: geom.isFloating,
                    topCornerRadius: 0
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(viewModel.state.isExpanded ? 0.20 : 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                
                // Hardware calibration guide (Orange outline when active in Settings)
                if settings.showCalibrationOverlay {
                    DynamicIslandShape(
                        bottomCornerRadius: bottomRadius,
                        isFloating: geom.isFloating,
                        topCornerRadius: 0
                    )
                    .stroke(Color.orange, lineWidth: 2)
                }
                
                // Dynamic Island Content Hierarchy
                Group {
                    switch viewModel.state {
                    case .collapsed:
                        collapsedCompactEarsView
                            .transition(.opacity)
                        
                    case .hud(let hudType):
                        HUDView(hud: hudType)
                            .transition(.opacity)
                        
                    case .dropping:
                        DroppingOverlayView()
                            .transition(.opacity)
                        
                    case .expanded(let activeTab):
                        expandedDynamicIslandView(activeTab: activeTab)
                            .transition(IslandMotion.content(reduceMotion))
                    }
                }
            }
            .frame(width: islandSize.width, height: islandSize.height, alignment: .top)
            .scaleEffect(isPointerDown ? 0.98 : 1.0, anchor: .top)
            .animation(viewModel.state.isExpanded ? IslandMotion.expand : IslandMotion.collapse, value: islandSize)
        }
        .frame(width: IslandLayout.panelSize.width, height: IslandLayout.panelSize.height, alignment: .top)
        .contentShape(Rectangle())
        .onHover { isHovered in
            viewModel.handleHoverChanged(isHovered)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPointerDown && !viewModel.state.isExpanded {
                        withAnimation(IslandMotion.press) {
                            isPointerDown = true
                        }
                    }
                }
                .onEnded { _ in
                    if isPointerDown {
                        withAnimation(IslandMotion.press) {
                            isPointerDown = false
                        }
                    }
                }
        )
        .onTapGesture {
            if settings.isClickToExpandEnabled {
                HapticService.play(.tap)
                viewModel.toggleExpandCollapse()
            }
        }
        .onDrop(
            of: [UTType.fileURL.identifier, UTType.item.identifier],
            isTargeted: Binding(
                get: { viewModel.isDropTargeted },
                set: { targeted in viewModel.handleDropTargetChanged(targeted) }
            )
        ) { providers in
            handleDroppedProviders(providers)
            return true
        }
    }
    
    // MARK: - iPhone Dynamic Island Compact Activity (Flanking the MacBook Notch)
    @ViewBuilder
    private var collapsedCompactEarsView: some View {
        if let activity = viewModel.compactActivity {
            HStack(spacing: 0) {
                // Leading Ear (Left of the notch)
                HStack {
                    switch activity {
                    case .media:
                        if let artwork = mediaService.currentTrack.artwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.pink)
                        }
                    case .timer:
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    case .shelf:
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    case .battery:
                        Image(systemName: batteryService.isCharging ? "bolt.fill" : "battery.25")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(batteryService.isCharging ? .green : .red)
                    }
                }
                .frame(width: IslandLayout.earWidth(activity), alignment: .center)
                
                // Hardware Notch Gap (Camera & Sensors rest here - strict clear gap)
                Color.clear
                    .frame(width: geom.width, height: geom.height)
                
                // Trailing Ear (Right of the notch)
                HStack {
                    switch activity {
                    case .media:
                        // Animated 3-bar sound spectrum
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(0..<3, id: \.self) { idx in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
                                    .frame(width: 2.5, height: max(3, mediaService.audioLevels[idx] * 12))
                                    .animation(.spring(response: 0.16, dampingFraction: 0.65), value: mediaService.audioLevels[idx])
                            }
                        }
                    case .timer:
                        Text(timerService.formattedTime)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.orange)
                    case .shelf:
                        Text("\(shelfService.items.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    case .battery:
                        Text("\(batteryService.percentage)%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(batteryService.isCharging ? .green : .white.opacity(0.85))
                    }
                }
                .frame(width: IslandLayout.earWidth(activity), alignment: .center)
            }
            .frame(height: geom.height)
        }
    }
    
    // MARK: - iPhone Pro Max Dynamic Island Expanded Layout (Distributed Around Physical Notch)
    private func expandedDynamicIslandView(activeTab: NotchTab) -> some View {
        VStack(spacing: 0) {
            // Top Ear Flanking Row (Distributed to the LEFT and RIGHT of the physical notch)
            HStack(spacing: 0) {
                // LEFT EAR: Müzik & Dosya (Never covered by physical notch!)
                HStack(spacing: 5) {
                    tabHeaderPill(for: .media, icon: "music.note", title: l10n.t("tab_music"), tint: .pink)
                    tabHeaderPill(
                        for: .shelf,
                        icon: "folder.fill",
                        title: "\(l10n.t("tab_shelf"))\(shelfService.items.isEmpty ? "" : " (\(shelfService.items.count))")",
                        tint: .cyan
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                
                // PHYSICAL HARDWARE NOTCH (Camera, sensor, LED area - ZERO pixels rendered here!)
                Color.clear
                    .frame(width: geom.width, height: geom.height)
                
                // RIGHT EAR: Sayaç & Pil + Kapatma (Never covered by physical notch!)
                HStack(spacing: 5) {
                    tabHeaderPill(
                        for: .timer,
                        icon: "timer",
                        title: "\(l10n.t("tab_timer"))\(timerService.isRunning ? " •" : "")",
                        tint: .orange
                    )
                    tabHeaderPill(
                        for: .battery,
                        icon: "bolt.battery.fill",
                        title: "\(batteryService.percentage)%",
                        tint: .green
                    )
                    
                    // Collapse button
                    Button(action: {
                        HapticService.play(.tap)
                        viewModel.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.fluidPress(scale: 0.90))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 10)
            }
            .frame(height: geom.height)
            .padding(.top, 2)
            
            // Main Live Activity Card (Positioned naturally below the notch hardware)
            Group {
                switch activeTab {
                case .media:
                    MediaTabContent()
                case .shelf:
                    ShelfTabContent()
                case .timer:
                    TimerTabContent()
                case .battery:
                    BatteryTabContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Pagination Dots (iPhone Dynamic Island subtle page dots)
            HStack(spacing: 6) {
                ForEach(viewModel.availableTabs) { tab in
                    Button(action: {
                        viewModel.selectTab(tab)
                    }) {
                        if viewModel.activeTab == tab {
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 14, height: 4)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.28))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 6)
        }
    }
    
    private func tabHeaderPill(for tab: NotchTab, icon: String, title: String, tint: Color) -> some View {
        Button(action: {
            viewModel.selectTab(tab)
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(viewModel.activeTab == tab ? tint : .white.opacity(0.6))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(-0.2)
                    .lineLimit(1)
            }
            .foregroundColor(viewModel.activeTab == tab ? .white : .white.opacity(0.65))
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(
                Capsule()
                    .fill(viewModel.activeTab == tab ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.fluidPress(scale: 0.92))
    }
    
    private func handleDroppedProviders(_ providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url, url.isFileURL {
                    urls.append(url)
                    group.leave()
                } else {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        defer { group.leave() }
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil), url.isFileURL {
                            urls.append(url)
                        } else if let url = item as? URL, url.isFileURL {
                            urls.append(url)
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                HapticService.play(.snap)
                viewModel.handleFilesDropped(urls)
            }
        }
    }
}

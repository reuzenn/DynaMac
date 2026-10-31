import SwiftUI

public enum SettingsTab: Int, CaseIterable, Identifiable {
    case general = 0
    case calibration = 1
    case features = 2
    case language = 3
    case about = 4
    
    public var id: Int { rawValue }
    
    public func title(using l10n: LocalizationManager) -> String {
        switch self {
        case .general: return l10n.t("nav_general")
        case .calibration: return l10n.t("nav_calibration")
        case .features: return l10n.t("nav_features")
        case .language: return l10n.t("nav_language")
        case .about: return l10n.t("nav_about")
        }
    }
    
    public var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .calibration: return "ruler.fill"
        case .features: return "slider.horizontal.3"
        case .language: return "globe"
        case .about: return "info.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var l10n = LocalizationManager.shared
    @State private var selectedTab: SettingsTab = .general
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Modern macOS Native Tab Bar
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.title(using: l10n))
                                .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            selectedTab == tab
                                ? Capsule().fill(Color.accentColor)
                                : Capsule().fill(Color.primary.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // Active Tab Container (Zero lag, strictly loads only the active tab)
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsTab()
                case .calibration:
                    CalibrationSettingsTab()
                case .features:
                    FeaturesSettingsTab()
                case .language:
                    LanguageSettingsTab()
                case .about:
                    AboutSettingsTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
        .frame(width: 560, height: 440)
    }
}

// MARK: - Reusable High-Performance Settings Card
@ViewBuilder
func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 0) {
        content()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
    )
    .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
    )
}

// MARK: - General Tab
struct GeneralSettingsTab: View {
    @ObservedObject var settings = NotchSettings.shared
    @ObservedObject var notchManager = NotchManager.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    private let solidColors: [CalibrationColorMode] = [
        .orange, .cyan, .green, .purple, .red, .yellow, .white
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                settingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(l10n.t("hardware_profile"))
                            .font(.headline)
                        
                        Picker(l10n.t("preset_label"), selection: $settings.preset) {
                            ForEach(MacBookNotchPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "display")
                                .foregroundColor(.accentColor)
                            Text(String(format: l10n.t("current_display"), notchManager.detectedDeviceName))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Notch Çerçevesi (Border & RGB Chroma)
                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.t("notch_border_title"))
                                .font(.headline)
                            Text(l10n.t("notch_border_sub"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle(l10n.t("show_notch_border"), isOn: $settings.showCalibrationOverlay)
                            .padding(.top, 2)
                        
                        if settings.showCalibrationOverlay {
                            Divider()
                                .padding(.vertical, 2)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(l10n.t("outline_color_mode"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    // Solid Color Swatches
                                    ForEach(solidColors) { mode in
                                        Button(action: {
                                            HapticService.play(.tap)
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                settings.calibrationColor = mode
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(mode.color)
                                                    .frame(width: 22, height: 22)
                                                
                                                if settings.calibrationColor == mode {
                                                    Circle()
                                                        .strokeBorder(Color.white, lineWidth: 2)
                                                        .frame(width: 26, height: 26)
                                                    
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(mode == .white || mode == .yellow ? .black : .white)
                                                }
                                            }
                                            .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Spacer(minLength: 8)
                                    
                                    // RGB Smooth Rainbow Mode Swatch & Pill
                                    Button(action: {
                                        HapticService.play(.tap)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            settings.calibrationColor = .rgb
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        AngularGradient(
                                                            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
                                                            center: .center
                                                        )
                                                    )
                                                    .frame(width: 22, height: 22)
                                                
                                                if settings.calibrationColor == .rgb {
                                                    Circle()
                                                        .strokeBorder(Color.white, lineWidth: 2)
                                                        .frame(width: 26, height: 26)
                                                    
                                                    Image(systemName: "sparkles")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .frame(width: 28, height: 28)
                                            
                                            Text(l10n.t("rgb_cycle"))
                                                .font(.caption)
                                                .fontWeight(settings.calibrationColor == .rgb ? .semibold : .regular)
                                                .foregroundColor(settings.calibrationColor == .rgb ? .primary : .secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(settings.calibrationColor == .rgb ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(
                                                    settings.calibrationColor == .rgb ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // RGB Speed Segmented Picker
                                if settings.calibrationColor == .rgb {
                                    HStack(spacing: 12) {
                                        Text(l10n.t("rgb_speed"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 120, alignment: .leading)
                                        
                                        Picker("", selection: $settings.calibrationRGBSpeed) {
                                            Text(l10n.t("speed_slow")).tag(RGBCycleSpeed.slow)
                                            Text(l10n.t("speed_normal")).tag(RGBCycleSpeed.normal)
                                            Text(l10n.t("speed_fast")).tag(RGBCycleSpeed.fast)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(maxWidth: 220)
                                    }
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                }
                
                settingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(l10n.t("launch_login"), isOn: $settings.launchAtLogin)
                        Divider()
                        Toggle(l10n.t("ears_status"), isOn: $settings.showCollapsedEars)
                        Divider()
                        Toggle(l10n.t("feat_haptics"), isOn: $settings.isHapticsEnabled)
                    }
                }
                
                settingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(l10n.t("interaction_trigger"))
                            .font(.headline)
                        
                        Toggle(l10n.t("click_to_expand"), isOn: $settings.isClickToExpandEnabled)
                        Divider()
                        Toggle(l10n.t("hover_to_expand"), isOn: $settings.isHoverToExpandEnabled)
                        if settings.isHoverToExpandEnabled {
                            Text(l10n.t("hover_suppress_tip"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 18)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Calibration Tab
struct CalibrationSettingsTab: View {
    @ObservedObject var settings = NotchSettings.shared
    @ObservedObject var notchManager = NotchManager.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                settingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.t("calibration_title"))
                            .font(.headline)
                        Text(l10n.t("calibration_sub"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle(l10n.t("show_notch_border"), isOn: $settings.showCalibrationOverlay)
                            .padding(.top, 4)
                    }
                }
                
                settingsCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(l10n.t("width"))
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $settings.customWidth, in: 140...260, step: 1)
                            Text("\(Int(settings.customWidth)) pt")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Text(l10n.t("height"))
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $settings.customHeight, in: 24...48, step: 1)
                            Text("\(Int(settings.customHeight)) pt")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Text(l10n.t("corner_radius"))
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $settings.customCornerRadius, in: 4...24, step: 1)
                            Text("\(Int(settings.customCornerRadius)) pt")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Text(l10n.t("y_offset"))
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $settings.customYOffset, in: -15...15, step: 1)
                            Text("\(Int(settings.customYOffset)) pt")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }
                        
                        Button(l10n.t("reset_defaults")) {
                            HapticService.play(.snap)
                            let defaults = settings.preset.defaultDimensions
                            settings.customWidth = defaults.width
                            settings.customHeight = defaults.height
                            settings.customCornerRadius = defaults.cornerRadius
                            settings.customYOffset = 0
                            notchManager.updateGeometry()
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Features Tab
struct FeaturesSettingsTab: View {
    @ObservedObject var settings = NotchSettings.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                settingsCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.t("features_title"))
                            .font(.headline)
                        Text(l10n.t("features_sub"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $settings.isMediaWidgetEnabled) {
                            Label(l10n.t("feat_music"), systemImage: "music.note")
                        }
                        Divider()
                        Toggle(isOn: $settings.isDropShelfEnabled) {
                            Label(l10n.t("feat_shelf"), systemImage: "tray.and.arrow.down.fill")
                        }
                        Divider()
                        Toggle(isOn: $settings.isVolumeHUDEnabled) {
                            Label(l10n.t("feat_volume"), systemImage: "speaker.wave.2.fill")
                        }
                        Divider()
                        Toggle(isOn: $settings.isBatteryAlertsEnabled) {
                            Label(l10n.t("feat_battery"), systemImage: "bolt.battery.fill")
                        }
                        Divider()
                        Toggle(isOn: $settings.isFocusTimerEnabled) {
                            Label(l10n.t("feat_timer"), systemImage: "timer")
                        }
                        Divider()
                        Toggle(isOn: $settings.isHapticsEnabled) {
                            Label(l10n.t("feat_haptics"), systemImage: "hand.tap.fill")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Language Tab
struct LanguageSettingsTab: View {
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("lang_select"))
                        .font(.headline)
                    Text(l10n.t("lang_sub"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: {
                        HapticService.play(.tap)
                        l10n.currentLanguage = lang
                    }) {
                        HStack(spacing: 12) {
                            Text(lang.flag)
                                .font(.system(size: 22))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.displayName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(l10n.currentLanguage == lang ? .white : .primary)
                                
                                Text(lang.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(l10n.currentLanguage == lang ? .white.opacity(0.8) : .secondary)
                            }
                            
                            Spacer()
                            
                            if l10n.currentLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(l10n.currentLanguage == lang ? Color.accentColor : Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - About Tab
struct AboutSettingsTab: View {
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 42))
                .foregroundColor(.accentColor)
            
            Text("DynaMac v1.6")
                .font(.title2.bold())
                .tracking(-0.3)
            
            Text(l10n.t("about_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.horizontal, 40)
            
            settingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.t("about_item1"))
                        .font(.caption)
                    Text(l10n.t("about_item2"))
                        .font(.caption)
                    Text(l10n.t("about_item3"))
                        .font(.caption)
                    Text(l10n.t("about_item4"))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            Text(l10n.t("version_info"))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("made by reuzen with ❤️")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
}

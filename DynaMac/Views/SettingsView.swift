import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = NotchSettings.shared
    @ObservedObject var notchManager = NotchManager.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    @State private var selectedTab: Int = 0
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label(l10n.t("nav_general"), systemImage: "gearshape")
                }
                .tag(0)
            
            calibrationTab
                .tabItem {
                    Label(l10n.t("nav_calibration"), systemImage: "ruler")
                }
                .tag(1)
            
            featuresTab
                .tabItem {
                    Label(l10n.t("nav_features"), systemImage: "slider.horizontal.3")
                }
                .tag(2)
            
            languageTab
                .tabItem {
                    Label(l10n.t("nav_language"), systemImage: "globe")
                }
                .tag(3)
            
            aboutTab
                .tabItem {
                    Label(l10n.t("nav_about"), systemImage: "info.circle")
                }
                .tag(4)
        }
        .frame(width: 540, height: 420)
        .padding(20)
    }
    
    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
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
                            .foregroundColor(.blue)
                        Text(String(format: l10n.t("current_display"), notchManager.detectedDeviceName))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section {
                Toggle(l10n.t("launch_login"), isOn: $settings.launchAtLogin)
                Toggle(l10n.t("ears_status"), isOn: $settings.showCollapsedEars)
                Toggle(l10n.t("feat_haptics"), isOn: $settings.isHapticsEnabled)
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.t("interaction_trigger"))
                        .font(.subheadline.bold())
                    
                    Toggle(l10n.t("click_to_expand"), isOn: $settings.isClickToExpandEnabled)
                    
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
    
    // MARK: - Calibration Tab
    private var calibrationTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.t("calibration_title"))
                        .font(.headline)
                    Text(l10n.t("calibration_sub"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle(l10n.t("visual_outline"), isOn: $settings.showCalibrationOverlay)
                    .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            Section {
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
                    .buttonStyle(.fluidPress)
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Features Tab
    private var featuresTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("features_title"))
                        .font(.headline)
                    Text(l10n.t("features_sub"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.vertical, 6)
            
            Section {
                Toggle(isOn: $settings.isMediaWidgetEnabled) {
                    Label(l10n.t("feat_music"), systemImage: "music.note")
                }
                
                Toggle(isOn: $settings.isDropShelfEnabled) {
                    Label(l10n.t("feat_shelf"), systemImage: "tray.and.arrow.down.fill")
                }
                
                Toggle(isOn: $settings.isVolumeHUDEnabled) {
                    Label(l10n.t("feat_volume"), systemImage: "speaker.wave.2.fill")
                }
                
                Toggle(isOn: $settings.isBatteryAlertsEnabled) {
                    Label(l10n.t("feat_battery"), systemImage: "bolt.battery.fill")
                }
                
                Toggle(isOn: $settings.isFocusTimerEnabled) {
                    Label(l10n.t("feat_timer"), systemImage: "timer")
                }
                
                Toggle(isOn: $settings.isHapticsEnabled) {
                    Label(l10n.t("feat_haptics"), systemImage: "hand.tap.fill")
                }
            }
        }
    }
    
    // MARK: - Language Tab
    private var languageTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.t("lang_select"))
                    .font(.headline)
                Text(l10n.t("lang_sub"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: {
                        HapticService.play(.tap)
                        l10n.currentLanguage = lang
                    }) {
                        HStack(spacing: 12) {
                            Text(lang.flag)
                                .font(.system(size: 24))
                            
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
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(l10n.currentLanguage == lang ? Color.accentColor : Color.secondary.opacity(0.12))
                        )
                    }
                    .buttonStyle(.fluidPress)
                }
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44))
                .foregroundColor(.accentColor)
            
            Text("DynaMac")
                .font(.title2.bold())
                .tracking(-0.3)
            
            Text(l10n.t("about_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 7) {
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
            .padding(.horizontal, 20)
            
            Spacer()
            
            Text(l10n.t("version_info"))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("made by reuzen with ❤️")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
    }
}

import Foundation
import AppKit
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case turkish = "tr"
    case french = "fr"
    case italian = "it"
    case russian = "ru"
    case german = "de"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .russian: return "Русский"
        case .german: return "Deutsch"
        }
    }
    
    public var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .turkish: return "🇹🇷"
        case .french: return "🇫🇷"
        case .italian: return "🇮🇹"
        case .russian: return "🇷🇺"
        case .german: return "🇩🇪"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Auto detect from system preferred languages
            let pref = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if pref.starts(with: "tr") {
                self.currentLanguage = .turkish
            } else if pref.starts(with: "fr") {
                self.currentLanguage = .french
            } else if pref.starts(with: "it") {
                self.currentLanguage = .italian
            } else if pref.starts(with: "ru") {
                self.currentLanguage = .russian
            } else if pref.starts(with: "de") {
                self.currentLanguage = .german
            } else {
                self.currentLanguage = .english
            }
        }
    }
    
    public func t(_ key: String) -> String {
        guard let langDict = strings[currentLanguage], let val = langDict[key] else {
            return strings[.english]?[key] ?? key
        }
        return val
    }
    
    // Comprehensive dictionary for all 6 languages
    private let strings: [AppLanguage: [String: String]] = [
        // MARK: - English
        .english: [
            "tab_music": "Music",
            "tab_shelf": "Shelf",
            "tab_timer": "Timer",
            "tab_battery": "Battery",
            "no_track": "Nothing Playing",
            "music_sub": "Control Center & Media",
            "open_music_app": "Play audio from any app or browser",
            "shelf_title": "Notch Drop Shelf",
            "shelf_empty_sub": "Drag & drop files onto the Notch to stash them temporarily.",
            "shelf_items_count": "%d item(s) in shelf",
            "clear_all": "Clear All",
            "reveal_finder": "Reveal in Finder",
            "copy_path": "Copy File Path",
            "remove": "Remove",
            "drop_files_title": "Drop Files onto Notch",
            "drop_files_sub": "Store temporarily in shelf & drag anywhere later",
            "timer_focus": "Timer",
            "timer_in_progress": "Timer Running",
            "battery_charging": "Charging via MagSafe / USB-C",
            "battery_full_ac": "Power Adapter (Fully Charged)",
            "battery_on_battery": "Running on Battery Power",
            "battery_remaining": "%dh %dm remaining",
            "fast_charging": "Fast Charging Active",
            "ac_connected": "AC Connected",
            "on_battery": "On Battery",
            "magsafe_connected": "MagSafe Connected",
            "battery_status": "Battery Status",
            "charged": "%d%% Charged",
            "menu_active": "DynaMac • Dynamic Notch",
            "menu_expand": "Expand Notch",
            "menu_collapse": "Collapse Notch",
            "menu_settings": "Settings...",
            "menu_quit": "Quit DynaMac",
            "settings_title": "DynaMac Settings",
            "nav_general": "General",
            "nav_calibration": "Calibration",
            "nav_features": "Features",
            "nav_language": "Language",
            "nav_about": "About",
            "hardware_profile": "MacBook Notch Hardware Profile",
            "preset_label": "Preset:",
            "current_display": "Current Display: %@",
            "launch_login": "Launch DynaMac at Login",
            "ears_status": "Show Minimal Status in Collapsed Ears (Audio, Timer, Battery)",
            "interaction_trigger": "Interaction Trigger",
            "click_to_expand": "Click Notch to Expand / Collapse (Recommended)",
            "hover_to_expand": "Hover Cursor near Notch to Expand",
            "hover_suppress_tip": "• Suppresses expansion automatically while holding mouse / dragging windows.",
            "calibration_title": "Hardware Notch Alignment",
            "calibration_sub": "Fine-tune Dynamic Notch size down to single pixels to match your exact MacBook bezel or screen protector.",
            "visual_outline": "Show Visual Alignment Outline (Orange Border)",
            "width": "Width:",
            "height": "Height:",
            "corner_radius": "Corner Radius:",
            "y_offset": "Y Offset:",
            "reset_defaults": "Reset to Model Defaults",
            "features_title": "Interactive Island Modules",
            "features_sub": "Select which widgets and gestures are active in your Dynamic Notch.",
            "feat_music": "Now Playing (Apple Music & Spotify Controls)",
            "feat_shelf": "Drop Shelf (Drag files onto Notch to stash)",
            "feat_volume": "Volume HUD Replacement in Notch",
            "feat_battery": "MagSafe & Battery Charging Alerts",
            "feat_timer": "Timer",
            "feat_haptics": "Trackpad Haptic Feedback (Force Touch)",
            "lang_select": "App Interface Language",
            "lang_sub": "Choose your preferred display language for DynaMac.",
            "about_desc": "Context-aware Dynamic Island utility for Apple Silicon MacBooks",
            "about_item1": "• System-wide MediaRemote playback controls with live audio visualizer",
            "about_item2": "• Temporary drag-and-drop file shelf for fast desktop staging",
            "about_item3": "• Integrated countdown timer and real-time battery & hardware telemetry",
            "about_item4": "• Pixel-perfect notch alignment with zero window interference",
            "version_info": "Version 1.0 • Built with Swift & SwiftUI"
        ],
        
        // MARK: - Turkish (Türkçe)
        .turkish: [
            "tab_music": "Müzik",
            "tab_shelf": "Dosya",
            "tab_timer": "Sayaç",
            "tab_battery": "Pil",
            "no_track": "Şu Anda Çalınan Yok",
            "music_sub": "Denetim Merkezi & Medya",
            "open_music_app": "Herhangi bir uygulama veya tarayıcıdan ses açın",
            "shelf_title": "Çentik Dosya Rafı",
            "shelf_empty_sub": "Dosyaları geçici olarak tutmak için çentiğin üzerine sürükleyin.",
            "shelf_items_count": "Rafta %d öge var",
            "clear_all": "Tümünü Temizle",
            "reveal_finder": "Finder'da Göster",
            "copy_path": "Dosya Yolunu Kopyala",
            "remove": "Kaldır",
            "drop_files_title": "Dosyaları Çentiğe Bırakın",
            "drop_files_sub": "Geçici olarak saklayın ve dilediğiniz yere sürükleyin",
            "timer_focus": "Sayaç",
            "timer_in_progress": "Sayaç Çalışıyor",
            "battery_charging": "MagSafe / USB-C ile Şarj Ediliyor",
            "battery_full_ac": "Güç Adaptörü (Tam Dolu)",
            "battery_on_battery": "Pil Gücünde Çalışıyor",
            "battery_remaining": "%d sa %d dk kaldı",
            "fast_charging": "Hızlı Şarj Aktif",
            "ac_connected": "Priz Bağlı",
            "on_battery": "Pilde",
            "magsafe_connected": "MagSafe Bağlandı",
            "battery_status": "Pil Durumu",
            "charged": "%%%d Dolu",
            "menu_active": "DynaMac • Dinamik Çentik",
            "menu_expand": "Çentiği Genişlet",
            "menu_collapse": "Çentiği Daralt",
            "menu_settings": "Ayarlar...",
            "menu_quit": "DynaMac'ten Çık",
            "settings_title": "DynaMac Ayarları",
            "nav_general": "Genel",
            "nav_calibration": "Kalibrasyon",
            "nav_features": "Özellikler",
            "nav_language": "Dil / Language",
            "nav_about": "Hakkında",
            "hardware_profile": "MacBook Çentik Donanım Profili",
            "preset_label": "Önayarlar:",
            "current_display": "Mevcut Ekran: %@",
            "launch_login": "Girişte DynaMac'i Otomatik Başlat",
            "ears_status": "Kapalı Çentik Kulakçıklarında Mini Durum Göster (Ses, Sayaç, Pil)",
            "interaction_trigger": "Etkileşim Tetikleyicisi",
            "click_to_expand": "Çentiğe Tıklayınca Aç / Kapat (Önerilen)",
            "hover_to_expand": "Fareyi Çentiğe Yaklaştırınca Aç",
            "hover_suppress_tip": "• Pencereleri taşırken veya fare basılıyken açılmayı otomatik engeller.",
            "calibration_title": "Donanım Çentik Hizalama",
            "calibration_sub": "Dinamik Çentik boyutunu ekran koruyucunuza veya çentiğinize göre piksel piksel ayarlayın.",
            "visual_outline": "Görsel Hizalama Kılavuzunu Göster (Turuncu Çerçeve)",
            "width": "Genişlik:",
            "height": "Yükseklik:",
            "corner_radius": "Köşe Yuvarlama:",
            "y_offset": "Y Kaydırma:",
            "reset_defaults": "Model Varsayılanlarına Sıfırla",
            "features_title": "İnteraktif Çentik Modülleri",
            "features_sub": "Dinamik çentiğinizde hangi özelliklerin aktif olacağını seçin.",
            "feat_music": "Şu An Çalınan (Apple Music & Spotify Kontrolleri)",
            "feat_shelf": "Dosya Rafı (Çentiğe sürükle-bırak rafı)",
            "feat_volume": "Çentikte Modern Ses Seviyesi Göstergesi (HUD)",
            "feat_battery": "MagSafe & Pil Şarj Bildirimleri",
            "feat_timer": "Sayaç",
            "feat_haptics": "İzleme Dörtgeni Dokunsal Geri Bildirimi (Haptic Titreşim)",
            "lang_select": "Uygulama Arayüz Dili",
            "lang_sub": "DynaMac için tercih ettiğiniz dili seçin.",
            "about_desc": "Apple Silicon MacBook'lar için bağlama duyarlı Dinamik Çentik aracı",
            "about_item1": "• Canlı ses ekolayzırlı sistem geneli Denetim Merkezi medya kontrolleri",
            "about_item2": "• Hızlı masaüstü dosya yönetimi için geçici sürükle-bırak dosya rafı",
            "about_item3": "• Dahili geri sayım sayacı ve anlık pil & donanım telemetrisi",
            "about_item4": "• Sıfır pencere engellemesiyle tam piksel donanım çentiği uyumu",
            "version_info": "Sürüm 1.0 • Saf Swift & SwiftUI ile Geliştirildi"
        ],
        
        // MARK: - French (Français)
        .french: [
            "tab_music": "Musique",
            "tab_shelf": "Étagère",
            "tab_timer": "Minuteur",
            "tab_battery": "Batterie",
            "no_track": "Aucun titre en lecture",
            "music_sub": "Centre de contrôle & Médias",
            "open_music_app": "Lancez un média depuis n'importe quelle app",
            "shelf_title": "Étagère de l'Encoche",
            "shelf_empty_sub": "Glissez-déposez des fichiers sur l'encoche pour les stocker temporairement.",
            "shelf_items_count": "%d élément(s) dans l'étagère",
            "clear_all": "Tout effacer",
            "reveal_finder": "Afficher dans le Finder",
            "copy_path": "Copier le chemin",
            "remove": "Supprimer",
            "drop_files_title": "Déposez les fichiers sur l'encoche",
            "drop_files_sub": "Stockez temporairement et glissez n'importe où plus tard",
            "timer_focus": "Minuteur",
            "timer_in_progress": "Minuteur en cours",
            "battery_charging": "Recharge via MagSafe / USB-C",
            "battery_full_ac": "Adaptateur secteur (Complètement chargé)",
            "battery_on_battery": "Fonctionne sur batterie",
            "battery_remaining": "%d h %d min restantes",
            "fast_charging": "Charge rapide active",
            "ac_connected": "Secteur branché",
            "on_battery": "Sur batterie",
            "magsafe_connected": "MagSafe connecté",
            "battery_status": "État de la batterie",
            "charged": "%d%% Chargé",
            "menu_active": "DynaMac • Encoche Dynamique",
            "menu_expand": "Agrandir l'encoche",
            "menu_collapse": "Réduire l'encoche",
            "menu_settings": "Réglages...",
            "menu_quit": "Quitter DynaMac",
            "settings_title": "Réglages DynaMac",
            "nav_general": "Général",
            "nav_calibration": "Calibrage",
            "nav_features": "Fonctionnalités",
            "nav_language": "Langue",
            "nav_about": "À propos",
            "hardware_profile": "Profil matériel de l'encoche MacBook",
            "preset_label": "Préréglage :",
            "current_display": "Écran actuel : %@",
            "launch_login": "Lancer DynaMac à l'ouverture de session",
            "ears_status": "Afficher l'état minimal dans les coins de l'encoche",
            "interaction_trigger": "Déclencheur d'interaction",
            "click_to_expand": "Cliquer pour agrandir / réduire (Recommandé)",
            "hover_to_expand": "Survoler avec le curseur pour agrandir",
            "hover_suppress_tip": "• Désactive l'ouverture lors du déplacement des fenêtres.",
            "calibration_title": "Alignement matériel de l'encoche",
            "calibration_sub": "Ajustez la taille au pixel près pour correspondre à votre écran.",
            "visual_outline": "Afficher le contour d'alignement (Bordure orange)",
            "width": "Largeur :",
            "height": "Hauteur :",
            "corner_radius": "Rayon des angles :",
            "y_offset": "Décalage Y :",
            "reset_defaults": "Rétablir les valeurs par défaut",
            "features_title": "Modules interactifs",
            "features_sub": "Choisissez les widgets actifs sur votre encoche dynamique.",
            "feat_music": "À l'écoute (Commandes Apple Music & Spotify)",
            "feat_shelf": "Étagère de fichiers (Glisser-déposer)",
            "feat_volume": "Indicateur de volume moderne dans l'encoche",
            "feat_battery": "Alertes de recharge MagSafe & Batterie",
            "feat_timer": "Minuteur",
            "feat_haptics": "Retour haptique du trackpad (Force Touch)",
            "lang_select": "Langue de l'interface",
            "lang_sub": "Choisissez votre langue préférée pour DynaMac.",
            "about_desc": "Utilitaire Dynamic Island contextuel pour Mac Apple Silicon",
            "about_item1": "• Commandes de lecture MediaRemote avec visualiseur audio",
            "about_item2": "• Étagère temporaire de fichiers par glisser-déposer",
            "about_item3": "• Minuteur intégré et télémétrie de la batterie et du processeur",
            "about_item4": "• Alignement parfait sur l'encoche sans obstruction des fenêtres",
            "version_info": "Version 1.0 • Développé en Swift & SwiftUI"
        ],
        
        // MARK: - Italian (Italiano)
        .italian: [
            "tab_music": "Musica",
            "tab_shelf": "Ripiano",
            "tab_timer": "Timer",
            "tab_battery": "Batteria",
            "no_track": "Nessun brano in riproduzione",
            "music_sub": "Centro di Controllo & Media",
            "open_music_app": "Riproduci audio da qualsiasi app",
            "shelf_title": "Ripiano File del Notch",
            "shelf_empty_sub": "Trascina e rilascia i file sul notch per conservarli temporaneamente.",
            "shelf_items_count": "%d elemento/i nel ripiano",
            "clear_all": "Cancella tutto",
            "reveal_finder": "Mostra nel Finder",
            "copy_path": "Copia percorso",
            "remove": "Rimuovi",
            "drop_files_title": "Rilascia i file sul notch",
            "drop_files_sub": "Conserva temporaneamente e trascina ovunque dopo",
            "timer_focus": "Timer",
            "timer_in_progress": "Timer in corso",
            "battery_charging": "In carica tramite MagSafe / USB-C",
            "battery_full_ac": "Alimentatore (Carica completa)",
            "battery_on_battery": "In uso con batteria",
            "battery_remaining": "%d h %d min rimanenti",
            "fast_charging": "Ricarica rapida attiva",
            "ac_connected": "Alimentazione CA",
            "on_battery": "A batteria",
            "magsafe_connected": "MagSafe connesso",
            "battery_status": "Stato batteria",
            "charged": "%d%% Carica",
            "menu_active": "DynaMac • Notch Dinamico",
            "menu_expand": "Espandi Notch",
            "menu_collapse": "Comprimi Notch",
            "menu_settings": "Impostazioni...",
            "menu_quit": "Esci da DynaMac",
            "settings_title": "Impostazioni DynaMac",
            "nav_general": "Generale",
            "nav_calibration": "Calibrazione",
            "nav_features": "Funzioni",
            "nav_language": "Lingua",
            "nav_about": "Info",
            "hardware_profile": "Profilo hardware del notch MacBook",
            "preset_label": "Predefinito:",
            "current_display": "Schermo attuale: %@",
            "launch_login": "Avvia DynaMac all'accesso",
            "ears_status": "Mostra stato minimo nelle alette del notch chiuso",
            "interaction_trigger": "Attivazione interazione",
            "click_to_expand": "Clicca sul notch per espandere (Consigliato)",
            "hover_to_expand": "Passa con il cursore per espandere",
            "hover_suppress_tip": "• Impedisce l'apertura accidentale durante il trascinamento finestre.",
            "calibration_title": "Allineamento hardware del notch",
            "calibration_sub": "Regola le dimensioni al singolo pixel per adattarle al tuo schermo.",
            "visual_outline": "Mostra contorno di allineamento (Bordo arancione)",
            "width": "Larghezza:",
            "height": "Altezza:",
            "corner_radius": "Raggio angoli:",
            "y_offset": "Offset Y:",
            "reset_defaults": "Ripristina valori predefiniti",
            "features_title": "Moduli interattivi",
            "features_sub": "Seleziona i widget attivi nel tuo notch dinamico.",
            "feat_music": "In riproduzione (Controlli Apple Music & Spotify)",
            "feat_shelf": "Ripiano file (Trascina e rilascia)",
            "feat_volume": "HUD volume moderno nel notch",
            "feat_battery": "Avvisi di carica MagSafe e batteria",
            "feat_timer": "Timer",
            "feat_haptics": "Feedback aptico del trackpad (Force Touch)",
            "lang_select": "Lingua interfaccia",
            "lang_sub": "Scegli la tua lingua preferita per DynaMac.",
            "about_desc": "Utility Dynamic Island per Mac Apple Silicon",
            "about_item1": "• Controlli di riproduzione MediaRemote con visualizzatore audio",
            "about_item2": "• Ripiano temporaneo per file tramite trascina e rilascia",
            "about_item3": "• Timer con conto alla rovescia e telemetria hardware e batteria",
            "about_item4": "• Allineamento perfetto al notch senza ostacoli alle finestre",
            "version_info": "Versione 1.0 • Sviluppato in Swift & SwiftUI"
        ],
        
        // MARK: - Russian (Русский)
        .russian: [
            "tab_music": "Музыка",
            "tab_shelf": "Полка",
            "tab_timer": "Таймер",
            "tab_battery": "Батарея",
            "no_track": "Ничего не играет",
            "music_sub": "Пункт управления & Медиа",
            "open_music_app": "Включите звук в любом приложении",
            "shelf_title": "Полка файлов в вырезе",
            "shelf_empty_sub": "Перетащите файлы на вырез (notch), чтобы временно сохранить их.",
            "shelf_items_count": "Файлов на полке: %d",
            "clear_all": "Очистить всё",
            "reveal_finder": "Показать в Finder",
            "copy_path": "Скопировать путь к файлу",
            "remove": "Удалить",
            "drop_files_title": "Бросьте файлы на вырез",
            "drop_files_sub": "Временное хранилище с возможностью перетаскивания",
            "timer_focus": "Таймер",
            "timer_in_progress": "Таймер запущен",
            "battery_charging": "Зарядка через MagSafe / USB-C",
            "battery_full_ac": "Адаптер питания (Полный заряд)",
            "battery_on_battery": "Работа от аккумулятора",
            "battery_remaining": "Осталось: %d ч %d мин",
            "fast_charging": "Быстрая зарядка активна",
            "ac_connected": "Сеть подключена",
            "on_battery": "От батареи",
            "magsafe_connected": "MagSafe подключен",
            "battery_status": "Состояние батареи",
            "charged": "Заряжено: %d%%",
            "menu_active": "DynaMac • Динамический вырез",
            "menu_expand": "Развернуть вырез",
            "menu_collapse": "Свернуть вырез",
            "menu_settings": "Настройки...",
            "menu_quit": "Завершить DynaMac",
            "settings_title": "Настройки DynaMac",
            "nav_general": "Основные",
            "nav_calibration": "Калибровка",
            "nav_features": "Функции",
            "nav_language": "Язык",
            "nav_about": "О программе",
            "hardware_profile": "Профиль выреза MacBook",
            "preset_label": "Шаблон:",
            "current_display": "Текущий экран: %@",
            "launch_login": "Запускать DynaMac при входе в систему",
            "ears_status": "Показывать статус в уголках сложенного выреза",
            "interaction_trigger": "Способ открытия",
            "click_to_expand": "Нажатие на вырез для открытия (Рекомендуется)",
            "hover_to_expand": "Открытие при наведении курсора",
            "hover_suppress_tip": "• Автоматически блокирует открытие при перетаскивании окон.",
            "calibration_title": "Точная подгонка под вырез",
            "calibration_sub": "Настройте размер до пикселя под ваш экран или защитное стекло.",
            "visual_outline": "Показать оранжевую рамку выравнивания",
            "width": "Ширина:",
            "height": "Высота:",
            "corner_radius": "Радиус углов:",
            "y_offset": "Смещение по Y:",
            "reset_defaults": "Сбросить к заводским",
            "features_title": "Интерактивные модули",
            "features_sub": "Выберите активные виджеты для вашего динамического выреза.",
            "feat_music": "Сейчас играет (Управление Apple Music & Spotify)",
            "feat_shelf": "Полка файлов (Перетаскивание на вырез)",
            "feat_volume": "Современный индикатор громкости в вырезе",
            "feat_battery": "Оповещения зарядки MagSafe и батареи",
            "feat_timer": "Таймер",
            "feat_haptics": "Тактильный отклик трекпада (Force Touch Haptic)",
            "lang_select": "Язык интерфейса",
            "lang_sub": "Выберите удобный язык для DynaMac.",
            "about_desc": "Утилита Dynamic Island для Mac с чипами Apple Silicon",
            "about_item1": "• Управление воспроизведением MediaRemote с визуализатором звука",
            "about_item2": "• Временная полка файлов с поддержкой перетаскивания",
            "about_item3": "• Встроенный таймер и телеметрия батареи и процессора",
            "about_item4": "• Точная подгонка под вырез без перекрытия окон",
            "version_info": "Версия 1.0 • Написано на чистом Swift & SwiftUI"
        ],
        
        // MARK: - German (Deutsch)
        .german: [
            "tab_music": "Musik",
            "tab_shelf": "Ablage",
            "tab_timer": "Timer",
            "tab_battery": "Batterie",
            "no_track": "Keine Wiedergabe",
            "music_sub": "Kontrollzentrum & Medien",
            "open_music_app": "Audio in einer beliebigen App abspielen",
            "shelf_title": "Notch-Dateiablage",
            "shelf_empty_sub": "Dateien auf die Notch ziehen, um sie vorübergehend abzulegen.",
            "shelf_items_count": "%d Objekt(e) in der Ablage",
            "clear_all": "Alle löschen",
            "reveal_finder": "Im Finder anzeigen",
            "copy_path": "Dateipfad kopieren",
            "remove": "Entfernen",
            "drop_files_title": "Dateien auf Notch ablegen",
            "drop_files_sub": "Zwischenspeichern und später überall hinziehen",
            "timer_focus": "Timer",
            "timer_in_progress": "Timer läuft",
            "battery_charging": "Laden über MagSafe / USB-C",
            "battery_full_ac": "Netzteil (Vollständig geladen)",
            "battery_on_battery": "Batteriebetrieb",
            "battery_remaining": "%d Std. %d Min. verbleibend",
            "fast_charging": "Schnellladen aktiv",
            "ac_connected": "Netzteil angeschlossen",
            "on_battery": "Batterie",
            "magsafe_connected": "MagSafe verbunden",
            "battery_status": "Batteriestatus",
            "charged": "%d%% Geladen",
            "menu_active": "DynaMac • Dynamische Notch",
            "menu_expand": "Notch erweitern",
            "menu_collapse": "Notch einklappen",
            "menu_settings": "Einstellungen...",
            "menu_quit": "DynaMac beenden",
            "settings_title": "DynaMac Einstellungen",
            "nav_general": "Allgemein",
            "nav_calibration": "Kalibrierung",
            "nav_features": "Funktionen",
            "nav_language": "Sprache",
            "nav_about": "Über",
            "hardware_profile": "MacBook Notch Hardware-Profil",
            "preset_label": "Vorlage:",
            "current_display": "Aktueller Bildschirm: %@",
            "launch_login": "DynaMac beim Start automatisch öffnen",
            "ears_status": "Status in den Notch-Ecken anzeigen (Audio, Timer, Akku)",
            "interaction_trigger": "Interaktionsauslöser",
            "click_to_expand": "Klicken zum Erweitern / Einklappen (Empfohlen)",
            "hover_to_expand": "Mit Mauszeiger darüberfahren zum Erweitern",
            "hover_suppress_tip": "• Verhindert versehentliches Öffnen beim Bewegen von Fenstern.",
            "calibration_title": "Hardware Notch Ausrichtung",
            "calibration_sub": "Passen Sie die Notch-Größe pixelgenau an Ihren Bildschirm an.",
            "visual_outline": "Visuelle Hilfslinie anzeigen (Orangefarbener Rand)",
            "width": "Breite:",
            "height": "Höhe:",
            "corner_radius": "Eckenradius:",
            "y_offset": "Y-Versatz:",
            "reset_defaults": "Auf Standardwerte zurücksetzen",
            "features_title": "Interaktive Insel-Module",
            "features_sub": "Wählen Sie aktive Widgets für Ihre dynamische Notch.",
            "feat_music": "Aktuelle Wiedergabe (Apple Music & Spotify Steuerung)",
            "feat_shelf": "Dateiablage (Drag & Drop auf die Notch)",
            "feat_volume": "Moderne Lautstärkeanzeige in der Notch",
            "feat_battery": "MagSafe & Batterie-Ladehinweise",
            "feat_timer": "Timer",
            "feat_haptics": "Trackpad Haptisches Feedback (Force Touch)",
            "lang_select": "App-Sprache",
            "lang_sub": "Wählen Sie Ihre bevorzugte Sprache für DynaMac.",
            "about_desc": "Kontextbezogenes Dynamic Island Dienstprogramm für Apple Silicon MacBooks",
            "about_item1": "• Systemweite MediaRemote Wiedergabesteuerung mit Audio-Visualizer",
            "about_item2": "• Temporäre Dateiablage via Drag-and-Drop",
            "about_item3": "• Integrierter Timer und Echtzeit-Telemetrie für Batterie & CPU",
            "about_item4": "• Pixelgenaue Notch-Ausrichtung ohne Behinderung von Fenstern",
            "version_info": "Version 1.0 • Entwickelt mit Swift & SwiftUI"
        ]
    ]
}

extension Notification.Name {
    public static let languageDidChange = Notification.Name("dynaMac.languageDidChange")
}

/// Global convenience function for localization
public func loc(_ key: String) -> String {
    LocalizationManager.shared.t(key)
}


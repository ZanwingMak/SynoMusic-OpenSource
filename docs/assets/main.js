const baseTranslations = {
  "nav.features": "Features",
  "nav.screens": "Screens",
  "nav.pricing": "Full Access",
  "nav.privacy": "Privacy",
  "nav.download": "App Store",
  "language.label": "Language",
  "hero.eyebrow": "App Store version for Synology Audio Station",
  "hero.title": "Bring your NAS music library to iPhone.",
  "hero.lede": "SynoMusic turns your Synology Audio Station library into a native iOS music experience with lyrics, downloads, podcasts, radio, widgets, iCloud sync and a refined player.",
  "hero.primaryCta": "View on the App Store",
  "hero.secondaryCta": "See Full Access",
  "hero.metaOne": "iOS 17+",
  "hero.metaTwo": "3-day trial",
  "hero.metaThree": "Privacy-first",
  "hero.floatOne": "NAS streaming",
  "hero.floatTwo": "Live lyrics",
  "intro.kicker": "Built for serious listeners",
  "intro.title": "A commercial iPhone app for the library you already own.",
  "intro.body": "Use your own NAS instead of giving up your library to another cloud. SynoMusic keeps credentials in Keychain, downloads in the app sandbox, and playback in native iOS controls.",
  "features.kicker": "What you get",
  "features.title": "A complete music app around your Synology library.",
  "features.library.title": "NAS library",
  "features.library.body": "Browse albums, artists, genres, folders, server playlists and every song with fast native navigation.",
  "features.player.title": "Polished player",
  "features.player.body": "Square artwork or vinyl-style player, AirPlay, Lock Screen controls, Dynamic Island and background playback.",
  "features.lyrics.title": "Lyrics and metadata",
  "features.lyrics.body": "Synced lyrics, lyric editing, online lyric lookup, artwork search, and quick web searches for songs and artists.",
  "features.offline.title": "Downloads and imports",
  "features.offline.body": "Download songs, import local files, add music from links, and keep selected music available offline.",
  "features.discovery.title": "Podcasts and radio",
  "features.discovery.body": "Find podcasts by charts, language, category, country or region, and browse global radio stations.",
  "features.sync.title": "iCloud and widgets",
  "features.sync.body": "Sync selected settings with iCloud, customize widgets, and keep your favorite entry points close.",
  "screens.kicker": "Designed for daily listening",
  "screens.title": "Library, player, settings and editing screens that feel at home on iOS.",
  "screens.library": "Library",
  "screens.browse": "Browse",
  "screens.player": "Full player",
  "screens.settings": "Settings",
  "pricing.kicker": "Full Access",
  "pricing.title": "Start with a 3-day trial, then choose the plan that fits.",
  "pricing.body": "Subscriptions unlock the complete feature set while active. Lifetime unlock is a one-time purchase for long-term use.",
  "pricing.weekly.label": "Weekly",
  "pricing.weekly.title": "Short trial listening",
  "pricing.weekly.body": "Good for trying the full app quickly.",
  "pricing.yearly.label": "Yearly",
  "pricing.yearly.title": "Best for everyday listening",
  "pricing.yearly.body": "A balanced plan for a personal NAS library.",
  "pricing.lifetime.label": "Lifetime",
  "pricing.lifetime.title": "One purchase",
  "pricing.lifetime.body": "Unlock once for long-term ownership.",
  "privacy.kicker": "Private by design",
  "privacy.title": "Your NAS stays the source of truth.",
  "privacy.body": "SynoMusic connects directly to the server you add. Passwords are stored in iOS Keychain, downloads stay inside the app sandbox, and purchases are handled by Apple StoreKit.",
  "privacy.policyCta": "Privacy Policy",
  "privacy.termsCta": "Terms of Use",
  "states.loading.title": "Loading library",
  "states.loading.body": "Fetching albums from your NAS.",
  "states.empty.title": "No server yet",
  "states.empty.body": "Add your NAS when you are ready.",
  "states.error.title": "Connection needs attention",
  "states.error.body": "Update the address or sign in again.",
  "download.kicker": "Available on the App Store",
  "download.title": "Get SynoMusic for iPhone.",
  "download.body": "Install the commercial App Store version for TestFlight-ready updates, in-app purchases, restore purchases, redeem codes and localized legal pages.",
  "download.primaryCta": "Open App Store",
  "download.secondaryCta": "Feedback",
  "footer.note": "Commercial App Store version and open-source support site.",
  "footer.privacy": "Privacy",
  "footer.terms": "Terms",
  "footer.github": "Open source"
};

const translations = {
  en: baseTranslations,
  "zh-Hans": {
    ...baseTranslations,
    "nav.features": "功能",
    "nav.screens": "界面",
    "nav.pricing": "完整功能",
    "nav.privacy": "隐私",
    "nav.download": "App Store",
    "language.label": "语言",
    "hero.eyebrow": "适用于 Synology Audio Station 的 App Store 版本",
    "hero.title": "把你的 NAS 音乐库带到 iPhone。",
    "hero.lede": "SynoMusic 将你的群晖 Audio Station 音乐库变成原生 iOS 音乐体验，支持歌词、下载、播客、电台、小组件、iCloud 同步和精致播放器。",
    "hero.primaryCta": "在 App Store 查看",
    "hero.secondaryCta": "了解完整功能",
    "hero.metaTwo": "3 天试用",
    "hero.metaThree": "隐私优先",
    "hero.floatOne": "NAS 串流",
    "hero.floatTwo": "实时歌词",
    "intro.kicker": "为认真听歌的人打造",
    "intro.title": "为你已有音乐库准备的商业版 iPhone App。",
    "intro.body": "使用自己的 NAS，而不是把音乐库交给另一朵云。SynoMusic 将凭证保存在 Keychain，下载内容保存在 App 沙盒，播放使用 iOS 原生媒体控制。",
    "features.kicker": "你会得到什么",
    "features.title": "围绕群晖音乐库打造的完整音乐 App。",
    "features.library.title": "NAS 音乐库",
    "features.library.body": "快速浏览专辑、艺术家、流派、文件夹、服务器歌单和所有歌曲。",
    "features.player.title": "精致播放器",
    "features.player.body": "支持方形封面或黑胶播放器样式、AirPlay、锁屏控制、灵动岛和后台播放。",
    "features.lyrics.title": "歌词与元数据",
    "features.lyrics.body": "同步歌词、歌词编辑、在线歌词查询、封面搜索，以及歌曲和歌手的网页搜索。",
    "features.offline.title": "下载与导入",
    "features.offline.body": "下载歌曲、导入本地文件、从链接添加音乐，并让选定音乐离线可用。",
    "features.discovery.title": "播客与电台",
    "features.discovery.body": "按榜单、语言、分类、国家或地区查找播客，并浏览全球电台。",
    "features.sync.title": "iCloud 与小组件",
    "features.sync.body": "用 iCloud 同步部分设置，自定义小组件，让常用入口更顺手。",
    "screens.kicker": "为日常听歌设计",
    "screens.title": "资料库、播放器、设置和编辑界面都符合 iOS 使用习惯。",
    "screens.library": "资料库",
    "screens.browse": "浏览",
    "screens.player": "全屏播放器",
    "screens.settings": "设置",
    "pricing.title": "先试用 3 天，再选择适合你的方案。",
    "pricing.body": "订阅在有效期内解锁完整功能。终身解锁是一次性购买，适合长期使用。",
    "pricing.weekly.label": "周订阅",
    "pricing.weekly.title": "短期完整体验",
    "pricing.weekly.body": "适合快速试用完整 App。",
    "pricing.yearly.label": "年订阅",
    "pricing.yearly.title": "适合日常听歌",
    "pricing.yearly.body": "为个人 NAS 音乐库准备的平衡方案。",
    "pricing.lifetime.label": "终身",
    "pricing.lifetime.title": "一次购买",
    "pricing.lifetime.body": "一次解锁，长期使用。",
    "privacy.kicker": "隐私优先",
    "privacy.title": "你的 NAS 始终是数据源。",
    "privacy.body": "SynoMusic 直接连接你添加的服务器。密码保存在 iOS Keychain，下载内容保存在 App 沙盒，购买由 Apple StoreKit 处理。",
    "privacy.policyCta": "隐私政策",
    "privacy.termsCta": "服务条款",
    "states.loading.title": "正在加载音乐库",
    "states.loading.body": "正在从 NAS 获取专辑。",
    "states.empty.title": "还没有服务器",
    "states.empty.body": "准备好后添加你的 NAS。",
    "states.error.title": "连接需要处理",
    "states.error.body": "更新地址或重新登录。",
    "download.kicker": "已在 App Store 上架",
    "download.title": "获取 iPhone 版 SynoMusic。",
    "download.body": "安装商业 App Store 版本，获得 TestFlight 版本更新、内购、恢复购买、兑换码和本地化法律页面。",
    "download.primaryCta": "打开 App Store",
    "download.secondaryCta": "反馈问题",
    "footer.note": "商业 App Store 版本与开源支持站点。",
    "footer.privacy": "隐私",
    "footer.terms": "条款",
    "footer.github": "开源仓库"
  },
  "zh-Hant": {
    ...baseTranslations,
    "nav.features": "功能",
    "nav.screens": "介面",
    "nav.pricing": "完整功能",
    "nav.privacy": "隱私",
    "hero.eyebrow": "適用於 Synology Audio Station 的 App Store 版本",
    "hero.title": "把你的 NAS 音樂庫帶到 iPhone。",
    "hero.lede": "SynoMusic 將你的群暉 Audio Station 音樂庫變成原生 iOS 音樂體驗，支援歌詞、下載、Podcast、電台、小工具、iCloud 同步和精緻播放器。",
    "hero.primaryCta": "在 App Store 查看",
    "hero.secondaryCta": "了解完整功能",
    "hero.metaTwo": "3 天試用",
    "hero.metaThree": "隱私優先",
    "intro.title": "為你既有音樂庫準備的商業版 iPhone App。",
    "features.title": "圍繞群暉音樂庫打造的完整音樂 App。",
    "features.player.title": "精緻播放器",
    "features.discovery.title": "Podcast 與電台",
    "features.discovery.body": "按排行榜、語言、分類、國家或地區尋找 Podcast，並瀏覽全球電台。",
    "pricing.title": "先試用 3 天，再選擇適合你的方案。",
    "privacy.title": "你的 NAS 始終是資料來源。",
    "download.title": "取得 iPhone 版 SynoMusic。",
    "download.primaryCta": "打開 App Store",
    "download.secondaryCta": "回饋問題",
    "footer.github": "開源倉庫"
  },
  ja: {
    ...baseTranslations,
    "nav.features": "機能",
    "nav.screens": "画面",
    "nav.pricing": "フルアクセス",
    "nav.privacy": "プライバシー",
    "hero.title": "NAS の音楽ライブラリを iPhone へ。",
    "hero.lede": "SynoMusic は Synology Audio Station のライブラリを、歌詞、ダウンロード、ポッドキャスト、ラジオ、ウィジェット、iCloud 同期を備えたネイティブ iOS 体験にします。",
    "hero.primaryCta": "App Store で見る",
    "intro.title": "既に持っている音楽ライブラリのための商用 iPhone アプリ。",
    "features.title": "Synology ライブラリを中心にした完全な音楽アプリ。",
    "features.discovery.title": "ポッドキャストとラジオ",
    "pricing.title": "3日間の試用後、合うプランを選べます。",
    "download.title": "iPhone 版 SynoMusic を入手。"
  },
  ko: {
    ...baseTranslations,
    "nav.features": "기능",
    "nav.screens": "화면",
    "nav.pricing": "전체 접근",
    "nav.privacy": "개인정보",
    "hero.title": "NAS 음악 라이브러리를 iPhone으로.",
    "hero.lede": "SynoMusic은 Synology Audio Station 라이브러리를 가사, 다운로드, 팟캐스트, 라디오, 위젯, iCloud 동기화를 갖춘 네이티브 iOS 경험으로 바꿉니다.",
    "hero.primaryCta": "App Store에서 보기",
    "intro.title": "이미 보유한 음악 라이브러리를 위한 상용 iPhone 앱.",
    "features.title": "Synology 라이브러리를 중심으로 만든 완성형 음악 앱.",
    "features.discovery.title": "팟캐스트와 라디오",
    "pricing.title": "3일 체험 후 원하는 플랜을 선택하세요.",
    "download.title": "iPhone용 SynoMusic 받기."
  },
  de: {
    ...baseTranslations,
    "nav.features": "Funktionen",
    "nav.screens": "Ansichten",
    "nav.pricing": "Vollzugriff",
    "nav.privacy": "Datenschutz",
    "hero.title": "Bringe deine NAS-Musikbibliothek aufs iPhone.",
    "hero.lede": "SynoMusic macht deine Synology Audio Station Bibliothek zu einer nativen iOS-Musik-App mit Liedtexten, Downloads, Podcasts, Radio, Widgets und iCloud-Sync.",
    "hero.primaryCta": "Im App Store ansehen",
    "intro.title": "Eine kommerzielle iPhone-App für deine eigene Musikbibliothek.",
    "features.title": "Eine komplette Musik-App rund um deine Synology-Bibliothek.",
    "pricing.title": "Starte mit 3 Tagen Testphase und wähle danach deinen Plan.",
    "download.title": "SynoMusic für iPhone laden."
  },
  it: {
    ...baseTranslations,
    "nav.features": "Funzioni",
    "nav.screens": "Schermate",
    "nav.pricing": "Accesso completo",
    "nav.privacy": "Privacy",
    "hero.title": "Porta la tua libreria musicale NAS su iPhone.",
    "hero.lede": "SynoMusic trasforma la libreria Synology Audio Station in un'esperienza iOS nativa con testi, download, podcast, radio, widget e sincronizzazione iCloud.",
    "hero.primaryCta": "Apri su App Store",
    "intro.title": "Un'app commerciale per iPhone per la libreria che possiedi già.",
    "features.title": "Un'app musicale completa attorno alla tua libreria Synology.",
    "pricing.title": "Inizia con 3 giorni di prova, poi scegli il piano adatto.",
    "download.title": "Scarica SynoMusic per iPhone."
  },
  fr: {
    ...baseTranslations,
    "nav.features": "Fonctions",
    "nav.screens": "Écrans",
    "nav.pricing": "Accès complet",
    "nav.privacy": "Confidentialité",
    "hero.title": "Votre bibliothèque NAS, native sur iPhone.",
    "hero.lede": "SynoMusic transforme votre bibliothèque Synology Audio Station en expérience iOS native avec paroles, téléchargements, podcasts, radio, widgets et synchronisation iCloud.",
    "hero.primaryCta": "Voir sur l'App Store",
    "intro.title": "Une app iPhone commerciale pour la bibliothèque que vous possédez déjà.",
    "features.title": "Une app musicale complète autour de votre bibliothèque Synology.",
    "pricing.title": "Commencez par 3 jours d'essai, puis choisissez votre formule.",
    "download.title": "Obtenir SynoMusic pour iPhone."
  },
  es: {
    ...baseTranslations,
    "nav.features": "Funciones",
    "nav.screens": "Pantallas",
    "nav.pricing": "Acceso completo",
    "nav.privacy": "Privacidad",
    "hero.title": "Lleva tu biblioteca NAS al iPhone.",
    "hero.lede": "SynoMusic convierte tu biblioteca de Synology Audio Station en una experiencia iOS nativa con letras, descargas, podcasts, radio, widgets y sincronización iCloud.",
    "hero.primaryCta": "Ver en App Store",
    "intro.title": "Una app comercial para iPhone para la música que ya tienes.",
    "features.title": "Una app musical completa alrededor de tu biblioteca Synology.",
    "pricing.title": "Empieza con 3 días de prueba y elige tu plan.",
    "download.title": "Obtén SynoMusic para iPhone."
  },
  tr: {
    ...baseTranslations,
    "nav.features": "Özellikler",
    "nav.screens": "Ekranlar",
    "nav.pricing": "Tam Erişim",
    "nav.privacy": "Gizlilik",
    "hero.title": "NAS müzik arşivini iPhone'a taşı.",
    "hero.lede": "SynoMusic, Synology Audio Station arşivini şarkı sözleri, indirmeler, podcastler, radyo, araç takımları ve iCloud eşzamanlama ile yerel bir iOS deneyimine dönüştürür.",
    "hero.primaryCta": "App Store'da görüntüle",
    "intro.title": "Zaten sahip olduğun müzik arşivi için ticari bir iPhone uygulaması.",
    "features.title": "Synology arşivin etrafında eksiksiz bir müzik uygulaması.",
    "pricing.title": "3 günlük denemeyle başla, sonra uygun planı seç.",
    "download.title": "iPhone için SynoMusic'i indir."
  }
};

const languageAliases = {
  zh: "zh-Hans",
  "zh-CN": "zh-Hans",
  "zh-SG": "zh-Hans",
  "zh-TW": "zh-Hant",
  "zh-HK": "zh-Hant",
  "zh-MO": "zh-Hant",
  ja: "ja",
  ko: "ko",
  de: "de",
  it: "it",
  fr: "fr",
  es: "es",
  tr: "tr",
  en: "en"
};

const defaultLanguage = "en";

/**
 * Resolves the best supported language from local storage, URL query or browser preferences.
 */
function resolveInitialLanguage() {
  const params = new URLSearchParams(window.location.search);
  const requested = params.get("lang") || window.localStorage.getItem("synomusic-site-language");
  if (requested && translations[requested]) {
    return requested;
  }

  const browserLanguages = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language];
  for (const language of browserLanguages) {
    const normalized = languageAliases[language] || languageAliases[language.split("-")[0]];
    if (normalized && translations[normalized]) {
      return normalized;
    }
  }

  return defaultLanguage;
}

/**
 * Applies translated strings to all nodes marked with data-i18n.
 */
function applyLanguage(language) {
  const dictionary = translations[language] || translations[defaultLanguage];
  document.documentElement.lang = language;
  document.title = `SynoMusic - ${dictionary["hero.title"]}`;

  document.querySelectorAll("[data-i18n]").forEach((node) => {
    const key = node.getAttribute("data-i18n");
    if (key && dictionary[key]) {
      node.textContent = dictionary[key];
    }
  });

  window.localStorage.setItem("synomusic-site-language", language);
}

/**
 * Wires the language selector to update content without reloading the page.
 */
function setupLanguagePicker() {
  const picker = document.getElementById("languageSelect");
  if (!picker) {
    return;
  }

  const language = resolveInitialLanguage();
  picker.value = language;
  applyLanguage(language);

  picker.addEventListener("change", (event) => {
    applyLanguage(event.target.value);
  });
}

/**
 * Reveals sections as they enter the viewport, with a no-JS visible fallback handled by CSS reduction rules.
 */
function setupRevealAnimation() {
  const nodes = Array.from(document.querySelectorAll("[data-reveal]"));
  if (!("IntersectionObserver" in window)) {
    nodes.forEach((node) => node.classList.add("is-visible"));
    return;
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.18 });

  nodes.forEach((node) => observer.observe(node));
}

/**
 * Initializes the static marketing site once the DOM is ready.
 */
function initSite() {
  setupLanguagePicker();
  setupRevealAnimation();
}

document.addEventListener("DOMContentLoaded", initSite);

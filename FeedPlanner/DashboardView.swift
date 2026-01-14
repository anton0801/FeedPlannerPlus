import SwiftUI
import WebKit
import Combine

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showAddFlock = false
    @State private var showAddRecord = false
    @State private var selectedFlockId: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Stats
                        headerSection
                        
                        // Today's feeding
                        todaySection
                        
                        // Weekly chart
                        weeklyChartSection
                        
                        // Flocks list
                        flocksSection
                    }
                    .padding()
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFlock = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddFlock) {
                AddFlockSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddRecord) {
                if let flockId = selectedFlockId {
                    AddFeedRecordSheet(viewModel: viewModel, flockId: flockId)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            InfoCard(
                title: "Total Chickens",
                value: "\(viewModel.totalChickens)",
                icon: "bird.fill",
                color: .accentPrimary
            )
            
            InfoCard(
                title: "Daily Norm",
                value: String(format: "%.1f kg", viewModel.totalDailyNorm / 1000),
                icon: "scale.3d",
                color: .accentSecondary
            )
        }
        .frame(height: 100)
    }
    
    private var todaySection: some View {
        GlossyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today Given")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text(String(format: "%.1f kg of %.1f kg", viewModel.todayGiven / 1000, viewModel.totalDailyNorm / 1000))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.textSecondary.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.completionPercentage)
                            .stroke(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: viewModel.completionPercentage)
                        
                        Text("\(Int(viewModel.completionPercentage * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.textSecondary.opacity(0.2))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.accentPrimary, .golden],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * viewModel.completionPercentage, height: 20)
                            .animation(.spring(), value: viewModel.completionPercentage)
                    }
                }
                .frame(height: 20)
                
                if viewModel.remainingToday > 0 {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentSecondary)
                        
                        Text("Remaining: \(String(format: "%.1f kg", viewModel.remainingToday / 1000))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
    
    private var weeklyChartSection: some View {
        GlossyCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 7 Days")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                MiniBarChart(data: viewModel.weeklyData)
                    .frame(height: 120)
            }
        }
    }
    
    private var flocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Flocks")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
            
            if viewModel.flocks.isEmpty {
                GlossyCard {
                    VStack(spacing: 12) {
                        Image(systemName: "bird.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        
                        Text("No Flocks")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        Text("Add your first flock to get started")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.flocks) { flock in
                    FlockCard(flock: flock) {
                        selectedFlockId = flock.id
                        showAddRecord = true
                    }
                }
            }
        }
    }
}

struct FlockCard: View {
    let flock: ChickenFlock
    let onAddFeed: () -> Void
    
    var body: some View {
        GlossyCard(padding: 16) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flock.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "bird.fill")
                                    .font(.system(size: 12))
                                Text("\(flock.count) chickens")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.textSecondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 12))
                                Text("\(String(format: "%.0f", flock.feedPerChicken)) g/day")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onAddFeed) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.accentPrimary)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Daily Norm:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f kg", flock.totalDailyFeed / 1000))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

struct MiniBarChart: View {
    let data: [(date: Date, amount: Double)]
    
    var maxAmount: Double {
        data.map { $0.amount }.max() ?? 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.chartPoint, .chartLine],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: (geometry.size.height - 30) * (item.amount / maxAmount))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                        
                        // Date label
                        Text(dayLabel(for: item.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct AddFlockSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DashboardViewModel
    
    @State private var name = ""
    @State private var count = ""
    @State private var feedPerChicken = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.accentPrimary.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "bird.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentPrimary)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        CustomTextField(
                            title: "Flock Name",
                            text: $name,
                            placeholder: "e.g., Layers"
                        )
                        
                        CustomTextField(
                            title: "Number of Chickens",
                            text: $count,
                            placeholder: "0",
                            keyboardType: .numberPad
                        )
                        
                        CustomTextField(
                            title: "Feed per Chicken (grams/day)",
                            text: $feedPerChicken,
                            placeholder: "120",
                            keyboardType: .decimalPad
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    GlossyButton(title: "Add Flock", icon: "checkmark") {
                        guard let countInt = Int(count),
                              let feedDouble = Double(feedPerChicken),
                              !name.isEmpty else { return }
                        
                        viewModel.addFlock(name: name, count: countInt, feedPerChicken: feedDouble)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New Flock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

struct AddFeedRecordSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DashboardViewModel
    let flockId: String
    
    @State private var amount = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    ZStack {
                        Circle()
                            .fill(Color.accentSecondary.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "bag.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentSecondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Amount of Feed")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        CustomTextField(
                            title: "Kilograms",
                            text: $amount,
                            placeholder: "0.0",
                            keyboardType: .decimalPad
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    GlossyButton(title: "Record", icon: "checkmark.circle") {
                        guard let amountDouble = Double(amount) else { return }
                        
                        viewModel.addFeedRecord(amount: amountDouble * 1000, flockId: flockId)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)
                .keyboardType(keyboardType)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}

struct FeedDisplayView: View {
    
    @State private var activeLocation: String? = ""
    
    var body: some View {
        ZStack {
            if let location = activeLocation,
               let url = URL(string: location) {
                ViewPresenter(targetURL: url)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadLocation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            reloadLocation()
        }
    }
    
    private func loadLocation() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let cached = UserDefaults.standard.string(forKey: "cached_endpoint") ?? ""
        
        activeLocation = temp ?? cached
        
        if temp != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
    
    private func reloadLocation() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"),
           !temp.isEmpty {
            activeLocation = nil
            activeLocation = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}

struct ViewPresenter: UIViewRepresentable {
    
    let targetURL: URL
    
    @StateObject private var presenter = Presenter()
    
    func makeCoordinator() -> ViewCoordinator {
        ViewCoordinator(presenter: presenter)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        presenter.initializeMainView()
        presenter.mainView.uiDelegate = context.coordinator
        presenter.mainView.navigationDelegate = context.coordinator
        
        presenter.sessionStore.restore()
        presenter.mainView.load(URLRequest(url: targetURL))
        
        return presenter.mainView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

final class Presenter: ObservableObject {
    
    @Published private(set) var mainView: WKWebView!
    @Published var childViews: [WKWebView] = []
    
    let sessionStore = SessionStore()
    
    private var observers = Set<AnyCancellable>()
    
    func initializeMainView() {
        let config = createConfiguration()
        mainView = WKWebView(frame: .zero, configuration: config)
        applySettings(to: mainView)
    }
    
    private func createConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        return config
    }
    
    private func applySettings(to view: WKWebView) {
        view.scrollView.minimumZoomScale = 1.0
        view.scrollView.maximumZoomScale = 1.0
        view.scrollView.bounces = false
        view.scrollView.bouncesZoom = false
        view.allowsBackForwardNavigationGestures = true
    }
    
    func goBack(to url: URL? = nil) {
        if !childViews.isEmpty {
            if let last = childViews.last {
                last.removeFromSuperview()
                childViews.removeLast()
            }
            
            if let url = url {
                mainView.load(URLRequest(url: url))
            }
        } else if mainView.canGoBack {
            mainView.goBack()
        }
    }
    
    func refresh() {
        mainView.reload()
    }
}

final class ViewCoordinator: NSObject {
    
    private weak var presenter: Presenter?
    private var redirects = 0
    private var lastURL: URL?
    private let redirectLimit = 70
    
    init(presenter: Presenter) {
        self.presenter = presenter
        super.init()
    }
}

extension ViewCoordinator: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        lastURL = url
        
        if isNavigable(url) {
            decisionHandler(.allow)
        } else {
            openExternal(url)
            decisionHandler(.cancel)
        }
    }
    
    private func isNavigable(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let urlString = url.absoluteString.lowercased()
        
        let allowed: Set<String> = [
            "http", "https", "about", "blob", "data", "javascript", "file"
        ]
        
        let prefixes = ["srcdoc", "about:blank", "about:srcdoc"]
        
        return allowed.contains(scheme) ||
               prefixes.contains { urlString.hasPrefix($0) } ||
               urlString == "about:blank"
    }
    
    private func openExternal(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        redirects += 1
        
        if redirects > redirectLimit {
            webView.stopLoading()
            
            if let recovery = lastURL {
                webView.load(URLRequest(url: recovery))
            }
            
            redirects = 0
            return
        }
        
        lastURL = webView.url
        presenter?.sessionStore.save(from: webView)
    }
    
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        enhanceView(webView)
    }
    
    private func enhanceView(_ view: WKWebView) {
        let script = """
        (function() {
            const meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(meta);
            
            const style = document.createElement('style');
            style.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(style);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        
        view.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("View enhancement error: \(error)")
            }
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let code = (error as NSError).code
        
        if code == NSURLErrorHTTPTooManyRedirects,
           let recovery = lastURL {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension ViewCoordinator: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let presenter = presenter,
              let main = presenter.mainView else {
            return nil
        }
        
        let child = WKWebView(frame: .zero, configuration: configuration)
        
        setupChild(child, in: main)
        addGesture(to: child)
        
        presenter.childViews.append(child)
        
        if let url = navigationAction.request.url,
           url.absoluteString != "about:blank" {
            child.load(navigationAction.request)
        }
        
        return child
    }
    
    private func setupChild(_ child: WKWebView, in main: WKWebView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        child.scrollView.isScrollEnabled = true
        child.scrollView.minimumZoomScale = 1.0
        child.scrollView.maximumZoomScale = 1.0
        child.scrollView.bounces = false
        child.scrollView.bouncesZoom = false
        child.allowsBackForwardNavigationGestures = true
        child.navigationDelegate = self
        child.uiDelegate = self
        
        main.addSubview(child)
        
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: main.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: main.trailingAnchor),
            child.topAnchor.constraint(equalTo: main.topAnchor),
            child.bottomAnchor.constraint(equalTo: main.bottomAnchor)
        ])
    }
    
    private func addGesture(to view: WKWebView) {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleGesture(_:))
        )
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
    }
    
    @objc private func handleGesture(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended,
              let view = recognizer.view as? WKWebView else {
            return
        }
        
        if view.canGoBack {
            view.goBack()
        } else if presenter?.childViews.last === view {
            presenter?.goBack(to: nil)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

final class SessionStore {
    
    private let key = "stored_sessions"
    
    func restore() {
        guard let data = UserDefaults.standard.object(forKey: key) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else {
            return
        }
        
        let store = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = data.values
            .flatMap { $0.values }
            .compactMap { props in
                HTTPCookie(properties: props as [HTTPCookiePropertyKey: Any])
            }
        
        cookies.forEach { cookie in
            store.setCookie(cookie)
        }
    }
    
    func save(from view: WKWebView) {
        let store = view.configuration.websiteDataStore.httpCookieStore
        
        store.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            
            var data: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for cookie in cookies {
                var domain = data[cookie.domain] ?? [:]
                
                if let props = cookie.properties {
                    domain[cookie.name] = props
                }
                
                data[cookie.domain] = domain
            }
            
            UserDefaults.standard.set(data, forKey: self.key)
        }
    }
}

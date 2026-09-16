import Foundation
import WebKit

/// Real implementation, confirmed against an actual HAR capture of
/// yoyaku.cityheaven.net (Sept 2026). Key findings that shape this file:
///
///   - The calendar page ships with a completely EMPTY table — every <td>
///     is blank in the raw server response. The circle/tel/x/bell icons
///     are injected client-side by the site's own calendar.js, and there
///     is a `x-ws-request-id` header on related requests suggesting the
///     live update channel is a WebSocket, not a polling JSON endpoint.
///   - Reverse-engineering that WebSocket protocol would mean impersonating
///     the site's private wire protocol — exactly what the development
///     guide says not to do. Loading the real page in a WKWebView and
///     letting the site's own JS populate the DOM normally is the
///     legitimate equivalent of "a browser visited this page."
///   - Real URL pattern:
///       https://yoyaku.cityheaven.net/calendar/{pref}/{code1}/{code2}/{shopSlug}/{weekOffset}/{girlID}
///     confirmed for shop "natural-swim" (displayed as "Last Resort"),
///     girl_id 55983930 (「ゆめの」/ Yumeno).
///   - The page also exposes `window.get_start_date` ("YYYY-MM-DD") as a
///     plain global JS variable — the first of the 7 displayed dates.
///     Column N (1-indexed) = get_start_date + (N-1) days.
final class WebViewScheduleProvider: NSObject, ScheduleProviding, WKNavigationDelegate {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<[ScheduleEntry], Error>?
    private let baseURL: URL

    /// - Parameters:
    ///   - shopPathComponents: e.g. "saitama/A1101/A110101/natural-swim" —
    ///     confirmed real path for Last Resort. Update if the client's
    ///     actual shop/cast differs from what we captured in testing.
    ///   - weekOffset: "1" = current week, "2" = next week, etc. (as seen
    ///     in the real URL). Fetch multiple weeks by calling again with a
    ///     different offset.
    init(shopPathComponents: String = "saitama/A1101/A110101/natural-swim", weekOffset: Int = 1) {
        self.baseURL = URL(string: "https://yoyaku.cityheaven.net/calendar/\(shopPathComponents)/\(weekOffset)/")!
        super.init()
    }

    @MainActor
    func fetchSchedule(for cast: Cast) async throws -> [ScheduleEntry] {
        guard !cast.girlID.isEmpty, let url = URL(string: cast.girlID, relativeTo: baseURL) else {
            throw AppError.parsingFailed("Cast is missing a valid girl_id (site-internal numeric ID, e.g. 55983930).")
        }

        let webView = WKWebView(frame: .zero)
        self.webView = webView
        webView.navigationDelegate = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            webView.load(URLRequest(url: url))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // The table exists immediately, but icons are injected asynchronously
        // by the page's own JS after load. Poll briefly for at least one
        // populated cell before extracting, rather than racing it.
        Task { @MainActor in
            do {
                let json = try await pollUntilRendered(webView)
                let entries = try parse(json: json)
                continuation?.resume(returning: entries)
            } catch {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: AppError.network(error.localizedDescription))
        continuation = nil
    }

    @MainActor
    private func pollUntilRendered(_ webView: WKWebView, attempts: Int = 8) async throws -> String {
        let extractJS = """
        (function () {
            var result = { startDate: window.get_start_date || null, rows: [] };
            document.querySelectorAll('table.cth tbody tr').forEach(function (tr) {
                var th = tr.querySelector('th.daytime-child');
                if (!th) { return; }
                var time = th.getAttribute('data-sys_time');
                var cells = [];
                tr.querySelectorAll('td').forEach(function (td) {
                    var img = td.querySelector('img');
                    cells.push(img ? img.getAttribute('src') : null);
                });
                result.rows.push({ time: time, cells: cells });
            });
            return JSON.stringify(result);
        })();
        """

        for attempt in 0..<attempts {
            let result = try await webView.evaluateJavaScript(extractJS)
            if let json = result as? String, json.contains("circle_icon") || json.contains("bell_icon") || json.contains("x_icon") || json.contains("tel_icon") {
                return json
            }
            // Not rendered yet — the site's own JS is still populating icons.
            try await Task.sleep(nanoseconds: 400_000_000 * UInt64(attempt + 1))
        }

        // Nothing ever rendered — could genuinely mean "no data this week"
        // rather than a failure, so we still try to parse whatever we have
        // rather than erroring outright.
        let result = try await webView.evaluateJavaScript(extractJS)
        guard let json = result as? String else {
            throw AppError.parsingFailed("Calendar page did not return any table structure.")
        }
        return json
    }

    private func parse(json: String) throws -> [ScheduleEntry] {
        struct RawRow: Decodable {
            let time: String
            let cells: [String?]
        }
        struct RawResult: Decodable {
            let startDate: String?
            let rows: [RawRow]
        }

        guard let data = json.data(using: .utf8) else {
            throw AppError.parsingFailed("Calendar JS payload was not valid UTF-8.")
        }
        let raw = try JSONDecoder().decode(RawResult.self, from: data)

        guard let startDateString = raw.startDate else {
            throw AppError.siteStructureChanged("window.get_start_date was missing — the page structure may have changed.")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        guard let startDate = formatter.date(from: startDateString) else {
            throw AppError.parsingFailed("Could not parse start date '\(startDateString)'.")
        }

        let calendar = Calendar(identifier: .gregorian)
        var entries: [ScheduleEntry] = []

        for row in raw.rows {
            let time = row.time.replacingOccurrences(of: "-", with: "")
            let formattedTime = "\(time.prefix(2)):\(time.suffix(2))"

            for (columnIndex, cellSrc) in row.cells.enumerated() {
                guard let entryDate = calendar.date(byAdding: .day, value: columnIndex, to: startDate) else { continue }

                let status: SlotStatus
                if let src = cellSrc {
                    if src.contains("circle_icon") { status = .available }
                    else if src.contains("tel_icon") { status = .phoneOnly }
                    else if src.contains("bell_icon") { status = .waitlist }
                    else { status = .unavailable }
                } else {
                    status = .unavailable
                }

                // Skip unavailable/phone-only up front — nothing to act on,
                // and phone-only is explicitly not something this app
                // automates (a human has to call).
                guard status == .available || status == .waitlist else { continue }

                let dateKey = formatter.string(from: entryDate)
                entries.append(ScheduleEntry(
                    id: "\(dateKey)-\(formattedTime)",
                    date: entryDate,
                    startTime: formattedTime,
                    status: status
                ))
            }
        }

        return entries
    }
}

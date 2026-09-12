import Foundation

/// Real, site-specific implementation. **Not wired up to a live site yet.**
///
/// Per the development guide (sections 5 & 6), this needs, before it can
/// do anything real:
///   - the confirmed shop/cast page URL
///   - confirmation of whether schedule data is in raw HTML, JS-rendered,
///     or fetched via a separate XHR/fetch call
///   - the real diffing key for "new" entries
///   - confirmation that this kind of automated access does not violate
///     the target site's terms of service, robots.txt, or rate limits
///
/// Until that research is done and the TODO below is filled in, this
/// provider intentionally throws rather than guessing at a parsing
/// strategy against a page nobody has actually inspected yet.
final class HTMLScheduleProvider: ScheduleProviding {
    private let session: URLSession
    private let castPageURL: URL

    init(castPageURL: URL, session: URLSession = .shared) {
        self.castPageURL = castPageURL
        self.session = session
    }

    func fetchSchedule(for cast: Cast) async throws -> [ScheduleEntry] {
        guard let url = cast.castPageURL ?? Optional(castPageURL) else {
            throw AppError.parsingFailed("No cast page URL configured.")
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AppError.network("Unexpected response fetching schedule page.")
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw AppError.parsingFailed("Could not decode page as UTF-8.")
        }

        return try parseScheduleHTML(html)
    }

    // TODO (Phase 0 required): replace with real parsing once the page
    // structure is confirmed. Don't guess at selectors — a wrong guess can
    // silently return zero results, or worse, stale/incorrect entries that
    // the booking flow would then act on. See PHASE0_RESEARCH_TEMPLATE.md.
    private func parseScheduleHTML(_ html: String) throws -> [ScheduleEntry] {
        throw AppError.parsingFailed(
            "HTMLScheduleProvider.parseScheduleHTML is not implemented yet — " +
            "this requires real Phase 0 research against the actual target page. " +
            "See PHASE0_RESEARCH_TEMPLATE.md."
        )
    }
}

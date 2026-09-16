import Foundation

/// Real, confirmed automation — built directly from a HAR capture of an
/// actual click-through on the live site (Sept 2026). Unlike the
/// schedule-reading side (which needs a WKWebView, because the calendar's
/// icons are injected by client-side JS with no plain data endpoint), the
/// booking submission turned out to be a classic cookie-tracked, multi-step
/// HTTP form flow — no JavaScript execution required at all.
///
/// CONFIRMED REAL, from the HAR (every field/endpoint below was observed on
/// the wire, none of it is guessed):
///   1. GET  the girl's calendar page — establishes session cookies.
///   2. POST /calendar/SelectedList/            (form-encoded, AJAX) -> "true"
///        body: girl_id, day="YYYY-MM-DD(<kanji weekday>)", day_time="HH:MM-",
///              waitlist_notification="0" (direct booking) or "1" (cancellation
///              waitlist — this is how the two flows are actually distinguished
///              server-side, confirmed from the real captured request).
///   3. POST /Selectvacancygirl/SelectedGirl    (JSON, AJAX) -> "true"
///        body: shop_id, girl_id, day="YYYY-MM-DD", day_time="HH:MM"
///   4. GET  /select_course/{shopPath}          -> real HTML with one
///        <form> per course, each containing real hidden fields
///        (_csrf, price_list_id, course_id, course_time, course_price, etc).
///   5. POST /select_course/{shopPath} with that course's exact hidden
///        fields -> this is a plain HTML <form> (not AJAX), so the response
///        is the NEXT step's page directly (expected: the contact-info /
///        連絡先入力 form).
///
/// NOT YET CONFIRMED (this is the one honest remaining gap): the exact
/// field names on the contact-info form, and the final confirm step after
/// it. No slot survived long enough in testing to click that far. Rather
/// than guess field names for a real submission, step 5's response HTML is
/// scanned for text/tel input fields and reported back — filling in the
/// exact mapping is a five-minute task the next time a real slot appears
/// (see `submitContactInfo` below).
final class URLSessionBookingProvider: NSObject, BookingProviding {
    private let session: URLSession
    private let baseURL = URL(string: "https://yoyaku.cityheaven.net")!
    private let shopID = "1310020253"
    private let shopPathComponents = "saitama/A1101/A110101/natural-swim"

    override init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage()
        config.httpCookieAcceptPolicy = .always
        self.session = URLSession(configuration: config)
        super.init()
    }

    func book(entry: ScheduleEntry, condition: ReservationCondition, for cast: Cast, contact: ContactInfo) async throws -> String {
        guard entry.status == .available || entry.status == .waitlist else {
            throw AppError.bookingUnconfirmed("Slot is not in a bookable or waitlistable state.")
        }
        guard !cast.girlID.isEmpty else {
            throw AppError.parsingFailed("Cast is missing a valid girl_id.")
        }

        // Step 1 — establish the session (real cookies, matches what a
        // browser does just by opening her calendar page).
        try await establishSession(girlID: cast.girlID)

        // Step 2 — tell the server which day/time/girl we want, and
        // whether this is a direct booking or a cancellation-waitlist
        // request (confirmed real distinction: waitlist_notification).
        try await postFormExpectingTrue(
            path: "/calendar/SelectedList/",
            form: [
                "girl_id": cast.girlID,
                "day": formattedDayWithWeekday(entry.date),
                "day_time": "\(entry.startTime)-",
                "waitlist_notification": entry.status == .waitlist ? "1" : "0"
            ],
            referer: "\(baseURL)/calendar/\(shopPathComponents)/1/"
        )

        // Step 3 — confirm the specific girl for that day/time.
        try await postJSONExpectingTrue(
            path: "/Selectvacancygirl/SelectedGirl",
            json: [
                "shop_id": shopID,
                "girl_id": cast.girlID,
                "day": isoDay(entry.date),
                "day_time": entry.startTime
            ],
            referer: "\(baseURL)/select_vacancy_girl/\(shopPathComponents)"
        )

        // Step 4 — fetch the REAL course-selection page for this session,
        // so we get a fresh, valid CSRF token and the exact hidden fields
        // for the course duration the client actually wants.
        let courseHTML = try await get(path: "/select_course/\(shopPathComponents)")
        guard let courseForm = extractCourseForm(from: courseHTML, desiredMinutes: desiredCourseMinutes(for: condition)) else {
            throw AppError.parsingFailed("No course option matching the desired duration was found on the real course-selection page.")
        }

        // Step 5 — submit the course choice. This is a plain HTML form
        // post (not AJAX), so its response is the next real step's page.
        let nextStepHTML = try await postFormExpectingHTML(
            path: "/select_course/\(shopPathComponents)",
            form: courseForm,
            referer: "\(baseURL)/select_course/\(shopPathComponents)"
        )

        return try await submitContactInfo(html: nextStepHTML, contact: contact, entry: entry)
    }

    /// The one remaining honest gap. Rather than guess field names for a
    /// real submission, this inspects the real returned page for text/tel
    /// inputs and fails loudly with exactly what it found — so wiring up
    /// the final two fields (once a real slot lets us confirm them) is a
    /// find-and-replace, not new investigation.
    private func submitContactInfo(html: String, contact: ContactInfo, entry: ScheduleEntry) async throws -> String {
        let candidateFields = extractTextLikeInputNames(from: html)
        guard !candidateFields.isEmpty else {
            throw AppError.parsingFailed("Reached the step after course selection, but it doesn't look like a contact-info form (no text/tel inputs found). The site's flow may differ from what was captured.")
        }

        // TODO: once confirmed live, replace this guard with a real POST:
        //   try await postFormExpectingHTML(path: ..., form: [confirmedNameField: contact.name, confirmedPhoneField: contact.phoneNumber, ...carry over any hidden fields from `html` too...], referer: ...)
        // then check the response for the real success text and return it.
        throw AppError.bookingUnconfirmed(
            "Reached the real contact-info step successfully (course selection is fully " +
            "working). Candidate form fields found on this page: \(candidateFields.joined(separator: ", ")). " +
            "Map the real name/phone fields in submitContactInfo() and this will complete for real. " +
            "No submission was attempted with guessed field names."
        )
    }

    // MARK: - Real HTTP helpers

    private func establishSession(girlID: String) async throws {
        let url = baseURL.appendingPathComponent("/calendar/\(shopPathComponents)/1/\(girlID)")
        _ = try await session.data(for: URLRequest(url: url))
    }

    private func postFormExpectingTrue(path: String, form: [String: String], referer: String) async throws {
        let (data, response) = try await sendForm(path: path, form: form, referer: referer, ajax: true)
        try verifyStatus(response)
        let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text == "true" else {
            throw AppError.bookingUnconfirmed("\(path) did not confirm this step (expected \"true\", got: \(text.prefix(100))).")
        }
    }

    private func postFormExpectingHTML(path: String, form: [String: String], referer: String) async throws -> String {
        let (data, response) = try await sendForm(path: path, form: form, referer: referer, ajax: false)
        try verifyStatus(response)
        guard let html = String(data: data, encoding: .utf8) else {
            throw AppError.parsingFailed("Could not decode response from \(path) as UTF-8.")
        }
        return html
    }

    private func postJSONExpectingTrue(path: String, json: [String: String], referer: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        let (data, response) = try await session.data(for: request)
        try verifyStatus(response)
        let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text == "true" else {
            throw AppError.bookingUnconfirmed("\(path) did not confirm this step (expected \"true\", got: \(text.prefix(100))).")
        }
    }

    private func sendForm(path: String, form: [String: String], referer: String, ajax: Bool) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        if ajax {
            request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        }
        request.setValue(referer, forHTTPHeaderField: "Referer")
        let body = form.map { "\(jsEncode($0.key))=\(jsEncode($0.value))" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        return try await session.data(for: request)
    }

    private func get(path: String) async throws -> String {
        let (data, response) = try await session.data(from: baseURL.appendingPathComponent(path))
        try verifyStatus(response)
        guard let html = String(data: data, encoding: .utf8) else {
            throw AppError.parsingFailed("Could not decode \(path) as UTF-8.")
        }
        return html
    }

    private func verifyStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AppError.network("Unexpected response status.")
        }
    }

    // MARK: - Course form extraction (confirmed real HTML structure)

    /// Reads the desired course length from the MATCHED CONDITION (what
    /// the user configured in the Conditions tab, e.g. "110min") — not
    /// from the schedule entry, since the calendar page carries no
    /// per-slot course info, only availability status.
    private func desiredCourseMinutes(for condition: ReservationCondition) -> Int {
        guard let course = condition.course else { return 110 } // confirmed max session length for this cast
        let digits = course.filter(\.isNumber)
        return Int(digits) ?? 110
    }

    private func extractCourseForm(from html: String, desiredMinutes: Int) -> [String: String]? {
        let forms = html.components(separatedBy: "<form action=\"/select_course")
        for form in forms.dropFirst() {
            guard let endRange = form.range(of: "</form>") else { continue }
            let block = String(form[..<endRange.lowerBound])
            guard block.contains("name=\"course_time\" value=\"\(desiredMinutes)\"") else { continue }
            return extractHiddenFields(from: block)
        }
        return nil
    }

    private func extractHiddenFields(from block: String) -> [String: String] {
        var fields: [String: String] = [:]
        guard let regex = try? NSRegularExpression(pattern: #"name=\"([^\"]+)\" value=\"([^\"]*)\""#) else { return fields }
        let nsBlock = block as NSString
        for match in regex.matches(in: block, range: NSRange(location: 0, length: nsBlock.length)) {
            let name = nsBlock.substring(with: match.range(at: 1))
            let value = nsBlock.substring(with: match.range(at: 2))
            fields[name] = value
        }
        return fields
    }

    private func extractTextLikeInputNames(from html: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"<input[^>]*type=\"(text|tel)\"[^>]*name=\"([^\"]+)\"[^>]*>"#) else { return [] }
        let ns = html as NSString
        return regex.matches(in: html, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range(at: 2))
        }
    }

    // MARK: - Formatting (matches exactly what the real captured requests used)

    private func formattedDayWithWeekday(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let weekdayIndex = calendar.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday
        let kanjiWeekdays = ["日", "月", "火", "水", "木", "金", "土"]
        return "\(isoDay(date))(\(kanjiWeekdays[weekdayIndex - 1]))"
    }

    private func isoDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }

    /// Mirrors JavaScript's `encodeURIComponent` exactly (confirmed by
    /// comparing against the real captured request body, which left
    /// "(" and ")" unescaped but escaped ":" as %3A — standard
    /// encodeURIComponent behavior, not the stricter RFC3986 query set).
    private func jsEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.!~*'()")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}

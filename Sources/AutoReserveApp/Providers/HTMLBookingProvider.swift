import Foundation

/// Real, site-specific booking implementation. **Not implemented.**
///
/// Filling this in for real requires, at minimum:
///   - the manual booking flow reproduced step-by-step (guide, section 5)
///   - the auth/session/CSRF mechanism (guide, section 6)
///   - a way to positively confirm success from the response itself, not
///     just the HTTP status code (guide, section 8)
///   - explicit confirmation this is allowed under the target site's terms
///     of service (guide, sections 6 & 10) — this app must never bypass
///     CAPTCHA, rate limits, or other anti-automation measures.
final class HTMLBookingProvider: BookingProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func book(entry: ScheduleEntry, for cast: Cast) async throws -> String {
        throw AppError.bookingUnconfirmed(
            "HTMLBookingProvider is not implemented yet — real booking submission " +
            "requires completed Phase 0 research. See PHASE0_RESEARCH_TEMPLATE.md."
        )
    }
}

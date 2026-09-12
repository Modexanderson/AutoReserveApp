# Phase 0 Research Notes

This is a fill-in-the-blanks template matching development guide sections
5 and 6. **Nothing in `HTMLScheduleProvider.swift` or
`HTMLBookingProvider.swift` can be implemented for real until this is
filled in with the client** — filling it in by guessing would risk either
silently doing nothing, or (worse) submitting bookings based on a wrong
assumption about the page.

## 1. Target identity
- Shop name:
- Shop page URL:
- Cast name:
- Cast page URL:
- Typical posting pattern (frequency, day-before vs same-day, time of day):

## 2. "1st–3rd choice" — concrete definition
- [ ] Fixed date + time
- [ ] Time range on any date
- [ ] Day-of-week rule
- [ ] Relative pick among whatever dates get posted
- Course / other required selections at booking time:

## 3. Manual booking flow (screenshots ideal)
1. Starting screen:
2. ...
3. Confirmation screen:
4. Final "booked" screen:

## 4. Schedule data source
- [ ] Present directly in page HTML
- [ ] Rendered by JavaScript (would need WKWebView, not just URLSession)
- [ ] Fetched via a separate XHR/fetch call (note the endpoint URL if found)
- Proposed "new entry" diff key (date? shift ID? URL? DOM element?):

## 5. Auth / session
- Login method:
- Session storage (cookie? token?):
- CSRF or one-time tokens involved?
- Safe verification method (do NOT put the real password in this file):

## 6. iOS device
- iPhone model:
- iOS version:

## 7. Terms of service / technical restrictions check
- Terms of service reviewed? Any clause on automated access/booking?
- robots.txt reviewed?
- Rate limits / CAPTCHA observed during manual testing?
- Go / No-Go decision and reasoning:

## 8. Distribution method
- [ ] Direct install to a personal dev device (7-day free provisioning, or
      paid Apple Developer account for 1-year signing)
- [ ] TestFlight
- [ ] App Store (out of scope per development guide section 3)

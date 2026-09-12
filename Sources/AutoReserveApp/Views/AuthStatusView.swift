import SwiftUI

struct AuthStatusView: View {
    let status: AuthState

    var body: some View {
        Label(status.rawValue.capitalized, systemImage: icon)
            .foregroundStyle(color)
    }

    private var icon: String {
        switch status {
        case .loggedIn: return "checkmark.circle.fill"
        case .loggedOut, .expired: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    private var color: Color {
        switch status {
        case .loggedIn: return .green
        case .loggedOut, .expired: return .orange
        case .unknown: return .gray
        }
    }
}

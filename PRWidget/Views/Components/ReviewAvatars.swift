import SwiftUI
import CatalystSwift

struct ReviewAvatars: View {
    let reviews: [PRReview]
    let reviewRequests: [PRUser]

    var body: some View {
        HStack(spacing: -6) {
            ForEach(reviews.prefix(4)) { review in
                ReviewAvatarBadge(review: review)
            }
            ForEach(reviewRequests.prefix(2)) { user in
                PendingAvatarBadge(user: user)
            }
        }
        .accessibilityLabel("\(reviews.count) reviews, \(reviewRequests.count) pending")
    }
}

private struct ReviewAvatarBadge: View {
    let review: PRReview
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var stateLabel: String {
        switch review.state {
        case .approved: "approved"
        case .changesRequested: "changes requested"
        case .commented: "commented"
        case .dismissed: "dismissed"
        case .pending: "pending"
        }
    }

    private var stateIcon: String {
        switch review.state {
        case .approved: "checkmark"
        case .changesRequested: "xmark"
        case .commented: "text.bubble"
        case .dismissed: "minus"
        case .pending: "clock"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarImage(login: review.author.login, url: review.author.avatarURL)

            if differentiateWithoutColor {
                Image(systemName: stateIcon)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Catalyst.foreground)
                    .frame(width: 12, height: 12)
                    .background(reviewColor, in: Circle())
                    .overlay(Circle().stroke(Catalyst.card, lineWidth: 1))
                    .offset(x: 2, y: 2)
            } else {
                Circle()
                    .fill(reviewColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(Catalyst.card, lineWidth: 1)
                    )
                    .shadow(color: reviewColor.opacity(0.5), radius: 2)
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityLabel("\(review.author.login), \(stateLabel)")
        .catalystTooltip("\(review.author.login) — \(stateLabel)")
    }

    private var reviewColor: Color {
        switch review.state {
        case .approved: Catalyst.approved
        case .changesRequested: Catalyst.changesRequested
        case .commented: Catalyst.commented
        case .dismissed: Catalyst.dismissed
        case .pending: Catalyst.pendingReview
        }
    }
}

private struct PendingAvatarBadge: View {
    let user: PRUser
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarImage(login: user.login, url: user.avatarURL)

            if differentiateWithoutColor {
                Image(systemName: "clock")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Catalyst.foreground)
                    .frame(width: 12, height: 12)
                    .background(Catalyst.subtle, in: Circle())
                    .overlay(Circle().stroke(Catalyst.card, lineWidth: 1))
                    .offset(x: 2, y: 2)
            } else {
                Circle()
                    .fill(Catalyst.subtle)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(Catalyst.card, lineWidth: 1)
                    )
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityLabel("\(user.login), review pending")
        .catalystTooltip("\(user.login) — review pending")
    }
}

private struct AvatarImage: View {
    let login: String
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    InitialsAvatar(login: login)
                }
            } else {
                InitialsAvatar(login: login)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
        .overlay(Circle().stroke(Catalyst.card, lineWidth: 2))
    }
}

private struct InitialsAvatar: View {
    let login: String

    var body: some View {
        ZStack {
            Circle().fill(Catalyst.surface)
            Text(String(login.prefix(1)).uppercased())
                .font(.caption2)
                .fontWeight(.medium)
                .fontDesign(.monospaced)
                .foregroundStyle(Catalyst.cyan)
        }
    }
}

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

    private var stateLabel: String {
        switch review.state {
        case .approved: "approved"
        case .changesRequested: "changes requested"
        case .commented: "commented"
        case .dismissed: "dismissed"
        case .pending: "pending"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarImage(login: review.author.login, url: review.author.avatarURL)

            Circle()
                .fill(reviewColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(Catalyst.card, lineWidth: 1)
                )
                .shadow(color: reviewColor.opacity(0.5), radius: 2)
                .offset(x: 2, y: 2)
        }
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarImage(login: user.login, url: user.avatarURL)

            Circle()
                .fill(Catalyst.subtle)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(Catalyst.card, lineWidth: 1)
                )
                .offset(x: 2, y: 2)
        }
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

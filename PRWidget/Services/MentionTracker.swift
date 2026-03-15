import Foundation
import Observation
import CatalystSwift

@MainActor
@Observable
final class MentionTracker {
    private static let seenKey = Persisted<[String]>("PArr.seenMentionIDs", default: [])

    private(set) var unreadMentionCount: Int = 0
    private var seenMentionIDs: Set<String> {
        didSet {
            Self.seenKey.saveSet(seenMentionIDs)
        }
    }
    private(set) var mentionedPRIDs: Set<String> = []

    init() {
        self.seenMentionIDs = Self.seenKey.loadSet()
    }

    func checkForMentions(prs: [PullRequest], currentUser: String) {
        guard !currentUser.isEmpty else { return }
        var newMentionedPRIDs: Set<String> = []
        var unseenCount = 0

        for pr in prs {
            // If detail is loaded, check comments for @mentions
            if let detail = pr.detail {
                let mentionTag = "@\(currentUser)"
                let mentionComments = detail.comments.filter { $0.body.contains(mentionTag) }
                if !mentionComments.isEmpty {
                    newMentionedPRIDs.insert(pr.id)
                    unseenCount += mentionComments.filter { !seenMentionIDs.contains($0.id) }.count
                    continue
                }
            }

            // Without detail, use dashboard-level data as a proxy:
            // PRs where review is requested from us or we are assigned
            let isReviewRequested = pr.reviewRequests.contains { $0.login == currentUser }
            let isAssigned = pr.assignees.contains { $0.login == currentUser }
            let isNotAuthor = pr.author.login != currentUser

            if isNotAuthor && (isReviewRequested || isAssigned) {
                // Use pr.id as a synthetic mention ID for tracking
                if !seenMentionIDs.contains(pr.id) {
                    newMentionedPRIDs.insert(pr.id)
                    unseenCount += 1
                }
            }
        }

        mentionedPRIDs = newMentionedPRIDs
        unreadMentionCount = unseenCount
    }

    func markAsRead(prId: String, comments: [PRComment]) {
        // Count unseen before marking them seen
        let newlyMarked = comments.filter { !seenMentionIDs.contains($0.id) }.count
        let wasSyntheticUnseen = !seenMentionIDs.contains(prId)

        for comment in comments {
            seenMentionIDs.insert(comment.id)
        }
        seenMentionIDs.insert(prId)
        mentionedPRIDs.remove(prId)

        let reduction = newlyMarked + (wasSyntheticUnseen ? 1 : 0)
        unreadMentionCount = max(0, unreadMentionCount - reduction)
    }

    func markAllMentionsRead(for prId: String, detail: PRDetail) {
        // Count unseen comments before marking
        let unseenCommentCount = detail.comments.filter { !seenMentionIDs.contains($0.id) }.count
        let wasSyntheticUnseen = !seenMentionIDs.contains(prId)

        for comment in detail.comments {
            seenMentionIDs.insert(comment.id)
        }
        seenMentionIDs.insert(prId)
        mentionedPRIDs.remove(prId)

        let reduction = unseenCommentCount + (wasSyntheticUnseen ? 1 : 0)
        unreadMentionCount = max(0, unreadMentionCount - reduction)
    }

    func hasMention(prId: String) -> Bool {
        mentionedPRIDs.contains(prId)
    }
}

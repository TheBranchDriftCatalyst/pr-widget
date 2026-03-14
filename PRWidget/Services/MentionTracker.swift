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
        let mentionTag = "@\(currentUser)"
        var newMentionedPRIDs: Set<String> = []
        var unseenCount = 0

        for pr in prs {
            guard let detail = pr.detail else { continue }
            let hasMention = detail.comments.contains { comment in
                comment.body.contains(mentionTag)
            }
            if hasMention {
                newMentionedPRIDs.insert(pr.id)
                // Check if any comment mentioning us is unseen
                let unseenMentions = detail.comments.filter { comment in
                    comment.body.contains(mentionTag) && !seenMentionIDs.contains(comment.id)
                }
                unseenCount += unseenMentions.count
            }
        }

        mentionedPRIDs = newMentionedPRIDs
        unreadMentionCount = unseenCount
    }

    func markAsRead(prId: String, comments: [PRComment]) {
        let currentUser = "" // Will be passed from outside
        for comment in comments {
            seenMentionIDs.insert(comment.id)
        }
        mentionedPRIDs.remove(prId)
        // Recalculate count
        unreadMentionCount = max(0, unreadMentionCount - comments.count)
    }

    func markAllMentionsRead(for prId: String, detail: PRDetail) {
        for comment in detail.comments {
            seenMentionIDs.insert(comment.id)
        }
        mentionedPRIDs.remove(prId)
        // Simple recalc
        unreadMentionCount = max(0, unreadMentionCount)
    }

    func hasMention(prId: String) -> Bool {
        mentionedPRIDs.contains(prId)
    }
}

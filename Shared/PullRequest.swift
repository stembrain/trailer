
import CoreData
#if os(iOS)
	import UIKit
#endif

final class PullRequest: ListableItem {

	@NSManaged var lastStatusNotified: String?
	@NSManaged var mergeCommitSha: String?
	@NSManaged var hasNewCommits: Bool
	@NSManaged var assignedForReview: Bool
	@NSManaged var reviewers: String
	@NSManaged var teamReviewers: String
    @NSManaged var mergedByNodeId: String?
    @NSManaged var linesAdded: Int64
    @NSManaged var linesRemoved: Int64
    @NSManaged var isMergeable: Bool
    @NSManaged var headRefName: String?
    @NSManaged var headLabel: String?
    @NSManaged var baseLabel: String?

	@NSManaged var statuses: Set<PRStatus>
	@NSManaged var reviews: Set<Review>
    
    override var webUrl: String? {
        return super.webUrl?.appending(pathComponent: "pull").appending(pathComponent: String(number))
    }
    
    static func mostRecentItemUpdate(in repo: Repo) -> Date {
        return repo.pullRequests.reduce(.distantPast) { max($0, $1.updatedAt ?? .distantPast) }
    }
        
    static func sync(from nodes: ContiguousArray<GQLNode>, on server: ApiServer) {
        syncItems(of: PullRequest.self, from: nodes, on: server) { pr, node in
            
            guard node.created || node.updated,
                let parentId = node.parent?.id ?? (node.jsonPayload["repository"] as? [AnyHashable: Any])?["id"] as? String,
                let moc = server.managedObjectContext,
                let parent = DataItem.item(of: Repo.self, with: parentId, in: moc)
                else { return }

            let json = node.jsonPayload

            if let mergeField = json["mergeable"] as? String {
                pr.isMergeable = mergeField != "CONFLICTING"
            } else {
                pr.isMergeable = true
            }
            pr.linesAdded = json["additions"] as? Int64 ?? 0
            pr.linesRemoved = json["deletions"] as? Int64 ?? 0
            pr.mergeCommitSha = json["headRefOid"] as? String
            pr.mergedByNodeId = (json["mergedBy"] as? [AnyHashable: Any])?["id"] as? String
            pr.baseNodeSync(nodeJson: json, parent: parent)
            
            let headRefName = json["headRefName"] as? String
            if let headRefName = headRefName,
               let headRepoName = (json["headRepository"] as? [AnyHashable: Any])?["nameWithOwner"] as? String {
                pr.headLabel = headRepoName + ":" + headRefName
            } else {
                pr.headLabel = nil
            }
            pr.headRefName = headRefName

            let baseRefName = json["baseRefName"] as? String
            if let baseRefName = baseRefName,
               let baseRepoName = (json["baseRepository"] as? [AnyHashable: Any])?["nameWithOwner"] as? String {
                pr.baseLabel = baseRepoName + ":" + baseRefName
            } else {
                pr.baseLabel = nil
            }
        }
    }

    var reviewCommentLink: String? {
        return repo.apiUrl?.appending(pathComponent: "pulls").appending(pathComponent: String(number)).appending(pathComponent: "comments")
    }
    
    var statusesLink: String? {
        return repo.apiUrl?.appending(pathComponent: "statuses").appending(pathComponent: mergeCommitSha ?? "")
    }
    
	static func syncPullRequests(from data: [[AnyHashable : Any]]?, in repo: Repo) {
        let apiServer = repo.apiServer
        let apiServerUserId = apiServer.userNodeId
		items(with: data, type: PullRequest.self, server: apiServer) { item, info, isNewOrUpdated in
			if isNewOrUpdated {

				item.baseSync(from: info, in: repo)

                let baseInfo = info["base"] as? [AnyHashable: Any]
                item.baseLabel = baseInfo?["label"] as? String

                let headInfo = info["head"] as? [AnyHashable: Any]
                item.headRefName = headInfo?["ref"] as? String
                item.headLabel = headInfo?["label"] as? String

                if
                    let newHeadCommitSha = headInfo?["sha"] as? String,
                    let commitUserInfo = headInfo?["user"] as? [AnyHashable: Any],
                    let newHeadCommitUserId = commitUserInfo["node_id"] as? String {
                    
                    let currentSha = item.mergeCommitSha
                    if currentSha != nil && currentSha != newHeadCommitSha && apiServerUserId != newHeadCommitUserId {
                        item.hasNewCommits = Settings.markPrsAsUnreadOnNewCommits && item.postSyncAction != PostSyncAction.isNew.rawValue
                    }
                    item.mergeCommitSha = newHeadCommitSha
                }
			}
            if item.condition == ItemCondition.closed.rawValue {
                item.stateChanged = StateChange.reopened.rawValue
            }
			item.condition = ItemCondition.open.rawValue
            item.isMergeable = true // always, for v3 API
		}
	}

	override var searchKeywords: [String] {
		return ["PR", "Pull Request", "PRs", "Pull Requests"] + super.searchKeywords
	}

	override var hasUnreadCommentsOrAlert: Bool {
		return super.hasUnreadCommentsOrAlert || hasNewCommits
	}

	override var reviewedByMe: Bool {
		for r in reviews {
			if r.isMine {
				return true
			}
		}
		return false
	}
    
	func checkAndStoreReviewAssignments(_ reviewerNames: Set<String>, _ reviewerTeams: Set<String>) {
		reviewers = reviewerNames.joined(separator: ",")
		teamReviewers = reviewerTeams.joined(separator: ",")
		var assigned = reviewerNames.contains(S(apiServer.userName))
		if !assigned {
			for myTeamName in apiServer.teams.compactMap({ $0.slug }) {
				if reviewerTeams.contains(myTeamName) {
					assigned = true // TODO: have a separate notification for this
					break
				}
			}
		}
		let shouldNotify = assigned && !assignedForReview
		assignedForReview = assigned
        if shouldNotify && Settings.notifyOnReviewAssignments {
            NotificationQueue.add(type: .assignedForReview, for: self)
        }
	}

	static func allMerged(in moc: NSManagedObjectContext, criterion: GroupingCriterion? = nil, includeAllGroups: Bool = false) -> [PullRequest] {
		let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
		f.returnsObjectsAsFaults = false
		f.includesSubentities = false
		let p = ItemCondition.merged.matchingPredicate
		add(criterion: criterion, toFetchRequest: f, originalPredicate: p, in: moc, includeAllGroups: includeAllGroups)
		return try! moc.fetch(f)
	}

	static func allClosed(in moc: NSManagedObjectContext, criterion: GroupingCriterion? = nil, includeAllGroups: Bool = false) -> [PullRequest] {
		let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
		f.returnsObjectsAsFaults = false
		f.includesSubentities = false
		let p = ItemCondition.closed.matchingPredicate
		add(criterion: criterion, toFetchRequest: f, originalPredicate: p, in: moc, includeAllGroups: includeAllGroups)
		return try! moc.fetch(f)
	}

	override class func hasOpen(in moc: NSManagedObjectContext, criterion: GroupingCriterion?) -> Bool {
		let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
		f.includesSubentities = false
		f.fetchLimit = 1
		add(criterion: criterion, toFetchRequest: f, originalPredicate: ItemCondition.open.matchingPredicate, in: moc)
		return try! moc.count(for: f) > 0
	}

	static func markEverythingRead(in section: Section, in moc: NSManagedObjectContext) {
		let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
		f.returnsObjectsAsFaults = false
		f.includesSubentities = false
		if section != .none {
			f.predicate = section.matchingPredicate
		}
		for pr in try! moc.fetch(f) {
			pr.catchUpWithComments()
		}
	}

	override func catchUpWithComments() {
		hasNewCommits = false
		super.catchUpWithComments()
	}

	override class func badgeCount<T: ListableItem>(from fetch: NSFetchRequest<T>, in moc: NSManagedObjectContext) -> Int {
		var badgeCount = super.badgeCount(from: fetch, in: moc)
		if Settings.markPrsAsUnreadOnNewCommits {
			for i in try! moc.fetch(fetch) {
				if let i = i as? PullRequest, i.hasNewCommits {
					badgeCount += 1
				}
			}
		}
		return badgeCount
	}

	static func badgeCount(in section: Section, in moc: NSManagedObjectContext) -> Int {
		let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
		f.includesSubentities = false
		f.predicate = NSCompoundPredicate(type: .and, subpredicates: [section.matchingPredicate, includeInUnreadPredicate])
		return badgeCount(from: f, in: moc)
	}

	static func badgeCount(in moc: NSManagedObjectContext) -> Int {
		let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
		f.includesSubentities = false
		f.predicate = NSCompoundPredicate(type: .and, subpredicates: [Section.nonZeroPredicate, includeInUnreadPredicate])
		return badgeCount(from: f, in: moc)
	}

	static func badgeCount(in moc: NSManagedObjectContext, criterion: GroupingCriterion? = nil) -> Int {
		let f = requestForItems(of: PullRequest.self, withFilter: nil, sectionIndex: -1, criterion: criterion)
		return badgeCount(from: f, in: moc)
	}

	private static let _unreadOrNewCommitsPredicate = NSPredicate(format: "unreadComments > 0 or hasNewCommits == YES")
	override class var includeInUnreadPredicate: NSPredicate {
		return Settings.markPrsAsUnreadOnNewCommits ? _unreadOrNewCommitsPredicate : super.includeInUnreadPredicate
	}

	func shouldBeCheckedForRedStatuses(in section: Section) -> Bool {
		if Settings.hidePrsThatArentPassing {
			if Settings.hidePrsThatDontPassOnlyInAll {
				return section == .all
			} else {
				return section == .mine || section == .participated || section == .all
			}
		}
		return false
	}

    static func statusCheckBatch(in moc: NSManagedObjectContext) -> [PullRequest] {
        let f = NSFetchRequest<PullRequest>(entityName: "PullRequest")
        f.predicate = NSPredicate(format: "apiServer.lastSyncSucceeded == YES")
        f.sortDescriptors = [
            NSSortDescriptor(key: "lastStatusScan", ascending: true),
            NSSortDescriptor(key: "updatedAt", ascending: false),
        ]
        let prs = try! moc.fetch(f)
            .filter { $0.section.shouldCheckStatuses }
            .prefix(Settings.statusItemRefreshBatchSize)
        
        prs.forEach {
            $0.statuses.forEach {
                $0.postSyncAction = PostSyncAction.delete.rawValue
            }
        }
        return Array(prs)
    }
    
	var displayedStatuses: [PRStatus] {

		var contexts = [String : PRStatus]()
        let red = Settings.showStatusesRed
        let yellow = Settings.showStatusesYellow
        let green = Settings.showStatusesGreen
        let filteredStatuses: Set<PRStatus>
        if red && yellow && green {
            filteredStatuses = statuses
        } else {
            filteredStatuses = statuses.filter {
                let c = $0.colorForDisplay
                if c == .appRed { return red }
                if c == .appYellow { return yellow }
                if c == .appGreen { return green }
                return false
            }
        }
		let sortedStatuses = filteredStatuses.sorted { $1.createdBefore($0) }
		for s in sortedStatuses {
			let context = s.context ?? "//NO CONTEXT/-/"
			if let latestStatusInContext = contexts[context] {
				if latestStatusInContext.createdBefore(s) {
					contexts[context] = s
				}
			} else {
				contexts[context] = s
			}
		}

		var statusList = Array(contexts.values)

		let mode = Settings.statusFilteringMode
		if mode != StatusFilter.all.rawValue {
			let terms = Settings.statusFilteringTerms
			if !terms.isEmpty {
				let inclusive = mode == StatusFilter.include.rawValue
				// contains(a) or contains(b) or contains(c)  -vs-  not(contains(a) or contains(b) or contains(c))

				statusList = statusList.filter {
					for t in terms {
						if let d = $0.descriptionText, d.localizedCaseInsensitiveContains(t) {
							return inclusive
						}
					}
					return !inclusive
				}
			}
		}

		return statusList.sorted { $0.createdBefore($1) }
	}

	var labelsLink: String? {
		return issueUrl?.appending(pathComponent: "labels")
	}

	@objc var sectionName: String {
		return Section.prMenuTitles[Int(sectionIndex)]
	}
        
    var shouldAnnounceStatus: Bool {
        return canBadge && (Settings.notifyOnStatusUpdatesForAllPrs || createdByMe || assignedToParticipated || assignedToMySection)
    }

    func linesAttributedString(labelFont: FONT_CLASS) -> NSAttributedString? {
        let added = linesAdded
        let removed = linesRemoved
        
        if added == 0 && removed == 0 {
            return nil
        }

        let font = FONT_CLASS.boldSystemFont(ofSize: labelFont.pointSize - 3)

        let res = NSMutableAttributedString()
        if added > 0, let addedString = numberFormatter.string(for: added) {
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .baselineOffset: 4, .foregroundColor: COLOR_CLASS.appGreen]
            res.append(NSAttributedString(string: "+\(addedString)", attributes: attributes))
            if removed > 0 {
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .baselineOffset: 4, .foregroundColor: COLOR_CLASS.lightGray]
                res.append(NSAttributedString(string: "\u{a0}", attributes: attributes))
            }
        }
        if removed > 0, let removedString = numberFormatter.string(for: removed) {
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .baselineOffset: 4, .foregroundColor: COLOR_CLASS.appRed]
            res.append(NSAttributedString(string: "-\(removedString)", attributes: attributes))
        }
        return res
    }

    func reviewsAttributedString(labelFont: FONT_CLASS) -> NSAttributedString? {
        
        if !Settings.displayReviewsOnItems {
            return nil
        }
        
        let res = NSMutableAttributedString()
        
        if Settings.showRequestedTeamReviews {
            let teamReviewRequests = teamReviewers.components(separatedBy: ",")
            let names = teamReviewRequests.compactMap {
                if let moc = managedObjectContext {
                    return Team.team(with: $0, in: moc)?.calculatedReferral
                } else {
                    return nil
                }
            }.joined(separator: ", ")
            if !names.isEmpty {
                let a = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: COLOR_CLASS.appYellow]
                res.append(NSAttributedString(string: "Reviews asked from \(names)", attributes: a))
            }
        }
        
        var latestReviewByUser = [String: Review]()
        for r in reviews.filter({ $0.affectsBottomLine }).sorted(by: { $0.createdBefore($1) }) {
            latestReviewByUser[S(r.username)] = r
        }

        if !latestReviewByUser.isEmpty || !reviewers.isEmpty {

            let reviews = latestReviewByUser.values.sorted { $0.createdBefore($1) }

            let approvers = reviews.filter { $0.state == Review.State.APPROVED.rawValue }
            if !approvers.isEmpty {

                let a = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: COLOR_CLASS.appGreen]

                if res.length > 0 {
                    res.append(NSAttributedString(string: "\n", attributes: a))
                }

                var count = 0
                for r in approvers {
                    let name = r.username!.replacingOccurrences(of: " ", with: "\u{a0}")
                    res.append(NSAttributedString(string: "@\(name) ", attributes: a))
                    if count == approvers.count - 1 {
                        res.append(NSAttributedString(string: "approved changes", attributes: a))
                    }
                    count += 1
                }
            }

            let requesters = reviews.filter { $0.state == Review.State.CHANGES_REQUESTED.rawValue }
            if !requesters.isEmpty {

                let a = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: COLOR_CLASS.appRed]

                if res.length > 0 {
                    res.append(NSAttributedString(string: "\n", attributes: a))
                }
                
                var count = 0
                for r in requesters {
                    let name = r.username!.replacingOccurrences(of: " ", with: "\u{a0}")
                    res.append(NSAttributedString(string: "@\(name) ", attributes: a))
                    if count == requesters.count - 1 {
                        res.append(NSAttributedString(string: requesters.count > 1 ? "request changes" : "requests changes", attributes: a))
                    }
                    count += 1
                }
            }

            let approverNames = approvers.compactMap { $0.username }
            let requesterNames = requesters.compactMap { $0.username }
            let otherReviewers = reviewers.components(separatedBy: ",").filter { !($0.isEmpty || approverNames.contains($0) || requesterNames.contains($0)) }
            if !otherReviewers.isEmpty {

                let a = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: COLOR_CLASS.appYellow]

                if res.length > 0 {
                    res.append(NSAttributedString(string: "\n", attributes: a))
                }

                var count = 0
                for r in otherReviewers {
                    let name = r.replacingOccurrences(of: " ", with: "\u{a0}")
                    res.append(NSAttributedString(string: "@\(name) ", attributes: a))
                    if count == otherReviewers.count - 1 {
                        res.append(NSAttributedString(string: otherReviewers.count > 1 ? "haven't reviewed yet" : "hasn't reviewed yet", attributes: a))
                    }
                    count += 1
                }
            }
        }
        
        return res
    }
    
    final func handleMerging() {
        let byUserId = mergedByNodeId
        let myUserId = apiServer.userNodeId
        DLog("Detected merged PR: %@ by user %@, local user id is: %@, handling policy is %@, coming from section %@",
             title,
             byUserId,
             myUserId,
             Settings.mergeHandlingPolicy,
             sectionIndex)

        if !isVisibleOnMenu {
            DLog("Merged PR was hidden, won't announce")
            managedObjectContext?.delete(self)

        } else if byUserId == myUserId && Settings.dontKeepPrsMergedByMe {
            DLog("Will not keep PR merged by me")
            managedObjectContext?.delete(self)

        } else if shouldKeep(accordingTo: Settings.mergeHandlingPolicy) {
            DLog("Will keep merged PR")
            keep(as: .merged, notification: .prMerged)
            
        } else {
            DLog("Will not keep merged PR")
            managedObjectContext?.delete(self)
        }
    }
}

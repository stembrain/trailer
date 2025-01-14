import Foundation
import CoreData

final class GraphQL {
    
    private static let idField = GQLField(name: "id")
    
    private static let nameWithOwnerField = GQLField(name: "nameWithOwner")
        
    private static let userFragment = GQLFragment(on: "User", elements: [
        idField,
        GQLField(name: "login"),
        GQLField(name: "avatarUrl")
    ])

    private static let userIdFragment = GQLFragment(on: "User", elements: [
        idField,
    ])

    private static let mannequinFragment = GQLFragment(on: "Mannequin", elements: [
        idField,
        GQLField(name: "login"),
        GQLField(name: "avatarUrl")
    ])
    
    private static let teamFragment = GQLFragment(on: "Team", elements: [
        idField,
        GQLField(name: "slug")
    ])
    
    private static let commentFields: [GQLElement] = [
        idField,
        GQLField(name: "body"),
        GQLField(name: "url"),
        GQLField(name: "createdAt"),
        GQLField(name: "updatedAt"),
        GQLGroup(name: "author", fields: [userFragment])
    ]
    
    static func testApi(to apiServer: ApiServer, completion: @escaping (Bool, Error?) -> Void) {
        var gotUserNode = false
        let testQuery = GQLQuery(name: "Testing", rootElement: GQLGroup(name: "viewer", fields: [userFragment])) { node in
            DLog("Got a node, type: \(node.elementType), id: \(node.id)")
            if node.elementType == "User" {
                gotUserNode = true
            }
            return true
        }
        testQuery.run(for: apiServer.graphQLPath ?? "", authToken: apiServer.authToken ?? "", attempt: 0) { error, updatedStats in
            DispatchQueue.main.async {
                completion(gotUserNode, error)
            }
        }
    }

    static func update<T: ListableItem>(for items: [T], of type: T.Type, in moc: NSManagedObjectContext, steps: API.SyncSteps, callback: @escaping (Error?) -> Void) {
        let typeName = String(describing: T.self)
        
        var elements: [GQLElement] = [idField]
        var elementTypes = [String]()
        
        if let prs = items as? [PullRequest] {
            if steps.contains(.reviewRequests) {
                elementTypes.append("ReviewRequest")
                let requestFragment = GQLFragment(on: "ReviewRequest", elements: [
                    idField,
                    GQLGroup(name: "requestedReviewer", fields: [userFragment, teamFragment, mannequinFragment]),
                ])
                elements.append(GQLGroup(name: "reviewRequests", fields: [requestFragment], pageSize: 100))
            }
            
            if steps.contains(.reviews) {
                prs.forEach {
                    $0.reviews.forEach {
                        $0.postSyncAction = PostSyncAction.delete.rawValue
                    }
                }
                
                elementTypes.append("PullRequestReview")
                let reviewFragment = GQLFragment(on: "PullRequestReview", elements: [
                    idField,
                    GQLField(name: "body"),
                    GQLField(name: "state"),
                    GQLField(name: "createdAt"),
                    GQLField(name: "updatedAt"),
                    GQLGroup(name: "author", fields: [userFragment])
                ])
                elements.append(GQLGroup(name: "reviews", fields: [reviewFragment], pageSize: 100))
            }
            
            if steps.contains(.statuses) {
                let now = Date()
                prs.forEach {
                    $0.lastStatusScan = now
                    $0.statuses.forEach {
                        $0.postSyncAction = PostSyncAction.delete.rawValue
                    }
                }
                
                elementTypes.append("StatusContext")
                let statusFragment = GQLFragment(on: "StatusContext", elements: [
                    idField,
                    GQLField(name: "context"),
                    GQLField(name: "description"),
                    GQLField(name: "state"),
                    GQLField(name: "targetUrl"),
                    GQLField(name: "createdAt"),
                ])
                elements.append(GQLGroup(name: "commits", fields: [
                    GQLGroup(name: "commit", fields: [
                        GQLGroup(name: "status", fields: [
                            GQLGroup(name: "contexts", fields: [statusFragment])
                        ])
                    ])
                ], pageSize: 100, onlyLast: true))
            }
        }
        
        if steps.contains(.reactions) {
            let now = Date()
            items.forEach {
                $0.lastReactionScan = now
                $0.reactions.forEach {
                    $0.postSyncAction = PostSyncAction.delete.rawValue
                }
            }
            
            elementTypes.append("Reaction")
            let reactionFragment = GQLFragment(on: "Reaction", elements: [
                idField,
                GQLField(name: "content"),
                GQLField(name: "createdAt"),
                GQLGroup(name: "user", fields: [userFragment])
            ])
            elements.append(GQLGroup(name: "reactions", fields: [reactionFragment], pageSize: 100))
        }
                
        if steps.contains(.comments) {
            items.forEach {
                $0.comments.forEach {
                    $0.postSyncAction = PostSyncAction.delete.rawValue
                }
            }
            elementTypes.append("IssueComment")
            let commentFragment = GQLFragment(on: "IssueComment", elements: commentFields)
            elements.append(GQLGroup(name: "comments", fields: [commentFragment], pageSize: 100))
        }

        
        let fields = [GQLFragment(on: typeName, elements: elements)]

        process(name: steps.toString, elementTypes: elementTypes, items: items, parentType: T.self, fields: fields, callback: callback)
    }
    
    static func updateReactions(for comments: [PRComment], moc: NSManagedObjectContext, callback: @escaping (Error?) -> Void) {
        let reactionFragment = GQLFragment(on: "Reaction", elements: [
            idField,
            GQLField(name: "content"),
            GQLField(name: "createdAt"),
            GQLGroup(name: "user", fields: [userFragment])
        ])

        let itemFragment = GQLFragment(on: "IssueComment", elements: [
            idField,
            GQLGroup(name: "reactions", fields: [reactionFragment], pageSize: 100)
            ])
        
        process(name: "Comment Reactions", elementTypes: ["Reaction"], items: comments, fields: [itemFragment], callback: callback)
    }

    static func updateComments(for reviews: [Review], moc: NSManagedObjectContext, callback: @escaping (Error?) -> Void) {
        let commentFragment = GQLFragment(on: "PullRequestReviewComment", elements: commentFields)
        
        let itemFragment = GQLFragment(on: "PullRequestReview", elements: [
            idField,
            GQLGroup(name: "comments", fields: [commentFragment], pageSize: 100)
        ])

        process(name: "Review Comments", elementTypes: ["PullRequestReviewComment"], items: reviews, fields: [itemFragment], callback: callback)
    }

    private static func process<T: ListableItem>(name: String, elementTypes: [String], items: [DataItem], parentType: T.Type? = nil, fields: [GQLElement], callback: @escaping (Error?)->Void) {
        if items.isEmpty {
            callback(nil)
            return
        }
        
        let group = DispatchGroup()
        var finalError: Error?
        
        let itemsByServer = Dictionary(grouping: items) { $0.apiServer }
        var count = 0
        for (server, items) in itemsByServer {
            let ids = ContiguousArray(items.compactMap { $0.nodeId })
            var nodes = [String: ContiguousArray<GQLNode>]()
            let serverName = server.label ?? "<no label>"
            let queries = GQLQuery.batching("\(serverName): \(name)", fields: fields, idList: ids, batchSize: 100) { node in
                let type = node.elementType
                if var existingList = nodes[type] {
                    existingList.append(node)
                    nodes[type] = existingList
                } else {
                    var array = ContiguousArray<GQLNode>()
                    array.append(node)
                    nodes[type] = array
                }
                
                count += 1
                if count > 1999 {
                    count = 0
                    group.enter()
                    processItems(nodes, server.objectID, parentMoc: server.managedObjectContext, parentType: parentType, group: group)
                    nodes.removeAll()
                }
                return true
            }
            group.enter()
            server.run(queries: queries) { error in
                if count > 0 || error != nil {
                    DispatchQueue.main.async { // needed in order to be sure this is queued after the node callback
                        if let error = error {
                            finalError = error
                            server.lastSyncSucceeded = false
                            group.leave()
                        } else {
                            processItems(nodes, server.objectID, parentMoc: server.managedObjectContext, parentType: parentType, group: group)
                        }
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            DispatchQueue.main.async { // needed in order to be sure this is queued after the node callback
                callback(finalError)
            }
        }
    }

    private static var milestoneFragment: GQLFragment {
        return GQLFragment(on: "Milestone", elements: [
            GQLField(name: "title")
        ])
    }
    
    private static var labelFragment: GQLFragment {
        return GQLFragment(on: "Label", elements: [
            idField,
            GQLField(name: "name"),
            GQLField(name: "color"),
            GQLField(name: "createdAt"),
            GQLField(name: "updatedAt")
        ])
    }
    
    private static var repositoryFragment: GQLFragment {
        return GQLFragment(on: "Repository", elements: [
            idField,
            GQLField(name: "createdAt"),
            GQLField(name: "updatedAt"),
            GQLField(name: "isFork"),
            GQLField(name: "isArchived"),
            GQLField(name: "nameWithOwner"),
            GQLField(name: "url"),
            GQLField(name: "isPrivate"),
            GQLGroup(name: "owner", fields: [idField])
        ])
    }
    
    private static func prFragment(assigneesAndLabelPageSize: Int, includeRepo: Bool) -> GQLFragment {
        var elements: [GQLElement] = [
            idField,
            GQLField(name: "bodyText"),
            GQLField(name: "state"),
            GQLField(name: "createdAt"),
            GQLField(name: "updatedAt"),
            GQLField(name: "number"),
            GQLField(name: "title"),
            GQLField(name: "url"),
            GQLGroup(name: "milestone", fields: [milestoneFragment]),
            GQLGroup(name: "author", fields: [userFragment]),
            GQLGroup(name: "assignees", fields: [userFragment], pageSize: assigneesAndLabelPageSize),
            GQLGroup(name: "labels", fields: [labelFragment], pageSize: assigneesAndLabelPageSize),
            GQLField(name: "headRefOid"),
            GQLField(name: "mergeable"),
            GQLField(name: "additions"),
            GQLField(name: "deletions"),
            GQLField(name: "headRefName"),
            GQLField(name: "baseRefName"),
            GQLField(name: "isDraft"),
            GQLGroup(name: "mergedBy", fields: [userIdFragment]),
            GQLGroup(name: "baseRepository", fields: [nameWithOwnerField]),
            GQLGroup(name: "headRepository", fields: [nameWithOwnerField])
        ]
        if includeRepo {
            elements.append(GQLGroup(name: "repository", fields: [repositoryFragment]))
        }
        return GQLFragment(on: "PullRequest", elements: elements)
    }
    
    private static func issueFragment(assigneesAndLabelPageSize: Int, includeRepo: Bool) -> GQLFragment {
        var elements: [GQLElement] = [
            idField,
            GQLField(name: "bodyText"),
            GQLField(name: "state"),
            GQLField(name: "createdAt"),
            GQLField(name: "updatedAt"),
            GQLField(name: "number"),
            GQLField(name: "title"),
            GQLField(name: "url"),
            GQLGroup(name: "milestone", fields: [milestoneFragment]),
            GQLGroup(name: "author", fields: [userFragment]),
            GQLGroup(name: "assignees", fields: [userFragment], pageSize: assigneesAndLabelPageSize),
            GQLGroup(name: "labels", fields: [labelFragment], pageSize: assigneesAndLabelPageSize)
        ]
        if includeRepo {
            elements.append(GQLGroup(name: "repository", fields: [repositoryFragment]))
        }
        return GQLFragment(on: "Issue", elements: elements)
    }
    
    static func fetchAllAuthoredItems(from servers: [ApiServer], group: DispatchGroup) {

        for server in servers {
            var authorFields = [GQLGroup]()
            if Settings.queryAuthoredPRs {
                let group = GQLGroup(name: "pullRequests", fields: [prFragment(assigneesAndLabelPageSize: 20, includeRepo: true)], extraParams: ["states": "OPEN"], pageSize: 100)
                authorFields.append(group)
            } else {
                server.repos.filter { $0.displayPolicyForPrs == RepoDisplayPolicy.authoredOnly.rawValue}.forEach { $0.displayPolicyForPrs = RepoDisplayPolicy.hide.rawValue }
            }
            if Settings.queryAuthoredIssues {
                let group = GQLGroup(name: "issues", fields: [issueFragment(assigneesAndLabelPageSize: 20, includeRepo: true)], extraParams: ["states": "OPEN"], pageSize: 100)
                authorFields.append(group)
            } else {
                server.repos.filter { $0.displayPolicyForIssues == RepoDisplayPolicy.authoredOnly.rawValue}.forEach { $0.displayPolicyForIssues = RepoDisplayPolicy.hide.rawValue }
            }

            var count = 0
            var nodes = [String: ContiguousArray<GQLNode>]()
            let authoredItemsQuery = GQLQuery(name: "Authored Items", rootElement: GQLGroup(name: "viewer", fields: authorFields)) { (node: GQLNode) -> Bool in
                let type = node.elementType
                if var existingList = nodes[type] {
                    existingList.append(node)
                    nodes[type] = existingList
                } else {
                    var array = ContiguousArray<GQLNode>()
                    array.reserveCapacity(200)
                    array.append(node)
                    nodes[type] = array
                }
                
                count += 1
                if count > 1999 {
                    count = 0
                    group.enter()
                    self.processItems(nodes, server.objectID, parentMoc: server.managedObjectContext, group: group)
                    nodes.removeAll()
                }
                
                return true
            }
            group.enter()
            server.run(queries: [authoredItemsQuery]) { error in
                if error != nil {
                    server.lastSyncSucceeded = false
                    group.leave()
                } else {
                    self.processItems(nodes, server.objectID, parentMoc: server.managedObjectContext, group: group)
                }
            }
        }
    }
    
    static func fetchAllSubscribedItems(from repos: [Repo], group: DispatchGroup) {
        
        let latestPrsFragment = GQLFragment(on: "Repository", elements: [
            idField,
            GQLGroup(name: "pullRequests", fields: [prFragment(assigneesAndLabelPageSize: 20, includeRepo: false)], extraParams: ["orderBy": "{direction: DESC, field: UPDATED_AT}"], pageSize: 10),
            ])

        let latestIssuesFragment = GQLFragment(on: "Repository", elements: [
            idField,
            GQLGroup(name: "issues", fields: [issueFragment(assigneesAndLabelPageSize: 20, includeRepo: false)], extraParams: ["orderBy": "{direction: DESC, field: UPDATED_AT}"], pageSize: 20)
            ])
        
        let allOpenPrsFragment = GQLFragment(on: "Repository", elements: [
            idField,
            GQLGroup(name: "pullRequests", fields: [prFragment(assigneesAndLabelPageSize: 20, includeRepo: false)], extraParams: ["states": "OPEN"], pageSize: 50),
            ])

        let allOpenIssuesFragment = GQLFragment(on: "Repository", elements: [
            idField,
            GQLGroup(name: "issues", fields: [issueFragment(assigneesAndLabelPageSize: 20, includeRepo: false)], extraParams: ["states": "OPEN"], pageSize: 50)
            ])

        let reposByServer = Dictionary(grouping: repos) { $0.apiServer }
        var count = 0
        
        var prRepoIdToLatestExistingUpdate = [String: Date]()
        var issueRepoIdToLatestExistingUpdate = [String: Date]()

        let hideValue = RepoDisplayPolicy.hide.rawValue
        repos.forEach {
            if let n = $0.nodeId {
                if $0.displayPolicyForPrs != hideValue {
                    prRepoIdToLatestExistingUpdate[n] = PullRequest.mostRecentItemUpdate(in: $0)
                }
                if $0.displayPolicyForIssues != hideValue {
                    issueRepoIdToLatestExistingUpdate[n] = Issue.mostRecentItemUpdate(in: $0)
                }
            }
        }

        for (server, reposInThisServer) in reposByServer {

            var nodes = [String: ContiguousArray<GQLNode>]()

            let perNodeCallback = { (node: GQLNode) -> Bool in

                let type = node.elementType
                if var existingList = nodes[type] {
                    existingList.append(node)
                    nodes[type] = existingList
                } else {
                    var array = ContiguousArray<GQLNode>()
                    array.reserveCapacity(200)
                    array.append(node)
                    nodes[type] = array
                }
                
                if type == "PullRequest",
                    let repo = node.parent,
                    let updatedAt = node.jsonPayload["updatedAt"] as? String,
                    let d = DataItem.parseGH8601(updatedAt),
                    d < prRepoIdToLatestExistingUpdate[repo.id]! {
                    return false
                }

                if type == "Issue",
                    let repo = node.parent,
                    let updatedAt = node.jsonPayload["updatedAt"] as? String,
                    let d = DataItem.parseGH8601(updatedAt),
                    d < issueRepoIdToLatestExistingUpdate[repo.id]! {
                    return false
                }

                count += 1
                if count > 1999 {
                    count = 0
                    group.enter()
                    self.processItems(nodes, server.objectID, parentMoc: server.managedObjectContext, group: group)
                    nodes.removeAll()
                }
                
                return true
            }
            
            var queriesForServer = [GQLQuery]()
            let serverLabel = server.label ?? "<no label>"
            
            var idsForReposInThisServerWantingAllOpenPrs = ContiguousArray<String>()
            var idsForReposInThisServerWantingLatestPrs = ContiguousArray<String>()
            var idsForReposInThisServerWantingAllOpenIssues = ContiguousArray<String>()
            var idsForReposInThisServerWantingLatestIssues = ContiguousArray<String>()
            for repo in reposInThisServer {
                if let n = repo.nodeId {
                    if let last = prRepoIdToLatestExistingUpdate[n], last != .distantPast {
                        idsForReposInThisServerWantingLatestPrs.append(n)
                    } else if repo.displayPolicyForPrs != hideValue {
                        idsForReposInThisServerWantingAllOpenPrs.append(n)
                    }
                    if let last = issueRepoIdToLatestExistingUpdate[n], last != .distantPast {
                        idsForReposInThisServerWantingLatestIssues.append(n)
                    } else if repo.displayPolicyForIssues != hideValue {
                        idsForReposInThisServerWantingAllOpenIssues.append(n)
                    }
                }
            }
            
            if !idsForReposInThisServerWantingLatestIssues.isEmpty {
                let q = GQLQuery.batching("\(serverLabel): Updated Issues", fields: [latestIssuesFragment], idList: idsForReposInThisServerWantingLatestIssues, batchSize: 10, perNodeCallback: perNodeCallback)
                queriesForServer.append(contentsOf: q)
            }

            if !idsForReposInThisServerWantingAllOpenIssues.isEmpty {
                let q = GQLQuery.batching("\(serverLabel): Open Issues", fields: [allOpenIssuesFragment], idList: idsForReposInThisServerWantingAllOpenIssues, batchSize: 100, perNodeCallback: perNodeCallback)
                queriesForServer.append(contentsOf: q)
            }

            if !idsForReposInThisServerWantingLatestPrs.isEmpty {
                let q = GQLQuery.batching("\(serverLabel): Updated PRs", fields: [latestPrsFragment], idList: idsForReposInThisServerWantingLatestPrs, batchSize: 10, perNodeCallback: perNodeCallback)
                queriesForServer.append(contentsOf: q)
            }

            if !idsForReposInThisServerWantingAllOpenPrs.isEmpty {
                let q = GQLQuery.batching("\(serverLabel): Open PRs", fields: [allOpenPrsFragment], idList: idsForReposInThisServerWantingAllOpenPrs, batchSize: 100, perNodeCallback: perNodeCallback)
                queriesForServer.append(contentsOf: q)
            }
            
            group.enter()
            server.run(queries: queriesForServer) { error in
                if error != nil {
                    server.lastSyncSucceeded = false
                    group.leave()
                } else {
                    self.processItems(nodes, server.objectID, parentMoc: server.managedObjectContext, group: group)
                }
            }
        }
    }
        
    private static func processItems<T: ListableItem>(_ nodes: [String: ContiguousArray<GQLNode>], _ serverId: NSManagedObjectID, parentMoc: NSManagedObjectContext?, parentType: T.Type? = nil, group: DispatchGroup) {
        if nodes.isEmpty {
            group.leave()
            return
        }
    
        let processMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        processMoc.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        processMoc.parent = parentMoc ?? DataManager.main
        processMoc.undoManager = nil
        processMoc.perform {
            if let server = try? processMoc.existingObject(with: serverId) as? ApiServer {
                
                // Order must be fixed, since labels may refer to PRs or Issues, ensure they are created first

                if let nodeList = nodes["Repository"] {
                    Repo.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["Issue"] {
                    Issue.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["PullRequest"] {
                    PullRequest.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["Label"] {
                    PRLabel.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["CommentReaction"] {
                    Reaction.sync(from: nodeList, for: PRComment.self, on: server)
                }
                if let nodeList = nodes["IssueComment"] {
                    PRComment.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["PullRequestReviewComment"] {
                    PRComment.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["Reaction"], let parentType = parentType {
                    Reaction.sync(from: nodeList, for: parentType, on: server)
                }
                if let nodeList = nodes["ReviewRequest"] {
                    Review.syncRequests(from: nodeList, on: server)
                }
                if let nodeList = nodes["PullRequestReview"] {
                    Review.sync(from: nodeList, on: server)
                }
                if let nodeList = nodes["StatusContext"] {
                    PRStatus.sync(from: nodeList, on: server)
                }
                
                try? processMoc.save()
                group.leave()
            }
        }
    }
}

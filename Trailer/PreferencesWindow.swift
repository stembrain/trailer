
import Foundation

final class PreferencesWindow : NSWindow, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTabViewDelegate, NSControlTextEditingDelegate {

	private var deferredUpdateTimer: PopTimer!
	private var serversDirty = false

	func reset() {
		preferencesDirty = true
		Settings.lastSuccessfulRefresh = nil
		lastRepoCheck = .distantPast
		reloadRepositories()
		deferredUpdateTimer.push()
	}

	private var repoCache: [Repo]?

	private var repos: [Repo] {
		if let repoCache = repoCache {
			return repoCache
		}
		repoCache = ((Repo.reposFiltered(by: repoFilter.stringValue) as NSArray)
			.sortedArray(using: projectsTable.sortDescriptors) as! [Repo])
		return repoCache!
	}

	func reloadRepositories() {
		repoCache = nil
		projectsTable.reloadData()
	}

	// Preferences window
	@IBOutlet private var versionNumber: NSTextField!
	@IBOutlet private var launchAtStartup: NSButton!
	@IBOutlet private var refreshDurationLabel: NSTextField!
	@IBOutlet private var refreshDurationStepper: NSStepper!
	@IBOutlet private var hideUncommentedPrs: NSButton!
	@IBOutlet private var repoFilter: NSTextField!
	@IBOutlet private var showAllComments: NSButton!
	@IBOutlet private var sortingOrder: NSButton!
	@IBOutlet private var sortModeSelect: NSPopUpButton!
	@IBOutlet private var groupByRepo: NSButton!
	@IBOutlet private var checkForUpdatesAutomatically: NSButton!
	@IBOutlet private var checkForUpdatesLabel: NSTextField!
	@IBOutlet private var checkForUpdatesSelector: NSStepper!
	@IBOutlet private var openPrAtFirstUnreadComment: NSButton!
	@IBOutlet private var logActivityToConsole: NSButton!
	@IBOutlet private var commentAuthorBlacklist: NSTokenField!
    
    // Repositories
    @IBOutlet private var projectsTable: NSTableView!

	// History
	@IBOutlet private var prMergedPolicy: NSPopUpButton!
	@IBOutlet private var prClosedPolicy: NSPopUpButton!
	@IBOutlet private var dontKeepPrsMergedByMe: NSButton!
	@IBOutlet private var dontConfirmRemoveAllMerged: NSButton!
	@IBOutlet private var dontConfirmRemoveAllClosed: NSButton!
	@IBOutlet private var removeNotificationsWhenItemIsRemoved: NSButton!
    @IBOutlet private var scanClosedAndMergedItems: NSButton!
    
	// Statuses
	@IBOutlet private var showStatusItems: NSButton!
	@IBOutlet private var makeStatusItemsSelectable: NSButton!
	@IBOutlet private var statusItemRescanLabel: NSTextField!
	@IBOutlet private var statusItemRefreshCounter: NSStepper!
	@IBOutlet private var notifyOnStatusUpdates: NSButton!
	@IBOutlet private var notifyOnStatusUpdatesForAllPrs: NSButton!
	@IBOutlet private var statusTermMenu: NSPopUpButton!
	@IBOutlet private var statusTermsField: NSTokenField!
	@IBOutlet private var hidePrsThatDontPass: NSButton!
	@IBOutlet private var hidePrsThatDontPassOnlyInAll: NSButton!
	@IBOutlet private var showStatusesForAll: NSButton!
    @IBOutlet private var showStatusesRed: NSButton!
    @IBOutlet private var showStatusesYellow: NSButton!
    @IBOutlet private var showStatusesGreen: NSButton!

    // Filtering
    @IBOutlet private var includeRepositoriesInFiltering: NSButton!
    @IBOutlet private var includeLabelsInFiltering: NSButton!
    @IBOutlet private var includeTitlesInFiltering: NSButton!
    @IBOutlet private var includeMilestonesInFiltering: NSButton!
    @IBOutlet private var includeAssigneeNamesInFiltering: NSButton!
    @IBOutlet private var includeStatusesInFiltering: NSButton!
    @IBOutlet private var includeServersInFiltering: NSButton!
    @IBOutlet private var includeUsersInFiltering: NSButton!
    @IBOutlet private var includeNumbersInFiltering: NSButton!
    @IBOutlet private var itemFilteringBlacklist: NSTokenField!
    @IBOutlet private var labelFilteringBlacklist: NSTokenField!

	// Comments
	@IBOutlet private var disableAllCommentNotifications: NSButton!
	@IBOutlet private var assumeCommentsBeforeMineAreRead: NSButton!
	@IBOutlet private var newMentionMovePolicy: NSPopUpButton!
	@IBOutlet private var teamMentionMovePolicy: NSPopUpButton!
	@IBOutlet private var newItemInOwnedRepoMovePolicy: NSPopUpButton!
	@IBOutlet private var highlightItemsWithNewCommits: NSButton!

	// Display
	@IBOutlet private var grayOutWhenRefreshing: NSButton!
	@IBOutlet private var assignedPrHandlingPolicy: NSPopUpButton!
	@IBOutlet private var refreshItemsLabel: NSTextField!
	@IBOutlet private var showCreationDates: NSButton!
	@IBOutlet private var hideAvatars: NSButton!
	@IBOutlet private var showSeparateApiServersInMenu: NSButton!
	@IBOutlet private var displayRepositoryNames: NSButton!
	@IBOutlet private var hideCountsOnMenubar: NSButton!
	@IBOutlet private var showLabels: NSButton!
	@IBOutlet private var showRelativeDates: NSButton!
	@IBOutlet private var displayMilestones: NSButton!
	@IBOutlet private var displayNumbersForItems: NSButton!
    @IBOutlet private var draftHandlingPolicy: NSPopUpButton!
    @IBOutlet private var markUnmergeablePrs: NSButton!
    @IBOutlet private var showPrLines: NSButton!
    @IBOutlet private var showBaseAndHeadBranches: NSButton!
    
	// Servers
	@IBOutlet private var serverList: NSTableView!
	@IBOutlet private var apiServerName: NSTextField!
	@IBOutlet private var apiServerApiPath: NSTextField!
    @IBOutlet private var apiServerGraphQLPath: NSTextField!
    
	@IBOutlet private var apiServerWebPath: NSTextField!
	@IBOutlet private var apiServerAuthToken: NSTextField!
	@IBOutlet private var apiServerSelectedBox: NSBox!
	@IBOutlet private var apiServerTestButton: NSButton!
	@IBOutlet private var apiServerDeleteButton: NSButton!
	@IBOutlet private var apiServerReportError: NSButton!
    @IBOutlet private var v4ApiSwitch: NSButton!
    
	// Snoozing
	@IBOutlet private var snoozePresetsList: NSTableView!
	@IBOutlet private var snoozeTypeDuration: NSButton!
	@IBOutlet private var snoozeTypeDateTime: NSButton!
	@IBOutlet private var snoozeDurationDays: NSPopUpButton!
	@IBOutlet private var snoozeDurationHours: NSPopUpButton!
	@IBOutlet private var snoozeDurationMinutes: NSPopUpButton!
	@IBOutlet private var snoozeDateTimeDay: NSPopUpButton!
	@IBOutlet private var snoozeDateTimeHour: NSPopUpButton!
	@IBOutlet private var snoozeDateTimeMinute: NSPopUpButton!
	@IBOutlet private var snoozeDeletePreset: NSButton!
	@IBOutlet private var snoozeUp: NSButton!
	@IBOutlet private var snoozeDown: NSButton!
	@IBOutlet private var snoozeWakeOnComment: NSButton!
	@IBOutlet private var snoozeWakeOnMention: NSButton!
	@IBOutlet private var snoozeWakeOnStatusUpdate: NSButton!
	@IBOutlet private var hideSnoozedItems: NSButton!
	@IBOutlet private var snoozeWakeLabel: NSTextField!
	@IBOutlet private var countSnoozedItems: NSButton!

	@IBOutlet private var autoSnoozeSelector: NSStepper!
	@IBOutlet private var autoSnoozeLabel: NSTextField!

	// Misc
	@IBOutlet private var repeatLastExportAutomatically: NSButton!
	@IBOutlet private var lastExportReport: NSTextField!
	@IBOutlet private var dumpApiResponsesToConsole: NSButton!
	@IBOutlet private var defaultOpenApp: NSTextField!
	@IBOutlet private var defaultOpenLinks: NSTextField!
    @IBOutlet private var reloadAllData: NSButton!
    @IBOutlet private var reloadAllDataHelp: NSTextField!
    
	// Keyboard
	@IBOutlet private var hotkeyEnable: NSButton!
	@IBOutlet private var hotkeyCommandModifier: NSButton!
	@IBOutlet private var hotkeyOptionModifier: NSButton!
	@IBOutlet private var hotkeyShiftModifier: NSButton!
	@IBOutlet private var hotkeyLetter: NSPopUpButton!
	@IBOutlet private var hotKeyHelp: NSTextField!
	@IBOutlet private var hotKeyContainer: NSBox!
	@IBOutlet private var hotkeyControlModifier: NSButton!

	// Watchlist
	@IBOutlet private var allPrsSetting: NSPopUpButton!
	@IBOutlet private var allIssuesSetting: NSPopUpButton!
	@IBOutlet private var allHidingSetting: NSPopUpButton!
	@IBOutlet private var allNewPrsSetting: NSPopUpButton!
	@IBOutlet private var allNewIssuesSetting: NSPopUpButton!

	// Reviews
	@IBOutlet private var assignedReviewHandlingPolicy: NSPopUpButton!
	@IBOutlet private var notifyOnChangeRequests: NSButton!
	@IBOutlet private var notifyOnAcceptances: NSButton!
	@IBOutlet private var notifyOnReviewDismissals: NSButton!
	@IBOutlet private var notifyOnReviewAssignments: NSButton!
	@IBOutlet private var notifyOnAllChangeRequests: NSButton!
	@IBOutlet private var notifyOnAllAcceptances: NSButton!
	@IBOutlet private var notifyOnAllReviewDismissals: NSButton!
	@IBOutlet private var supportReviews: NSButton!
    @IBOutlet private var showRequestedTeamReviews: NSButton!
    
	// Reactions
	@IBOutlet private var notifyOnItemReactions: NSButton!
	@IBOutlet private var notifyOnCommentReactions: NSButton!
	@IBOutlet private var reactionIntervalLabel: NSTextField!
	@IBOutlet private var reactionIntervalStepper: NSStepper!

	// Tabs
	@IBOutlet var tabs: NSTabView!

	override func awakeFromNib() {
		super.awakeFromNib()
		delegate = self

		updateAllItemSettingButtons()
		fillSnoozingDropdowns()

		allNewPrsSetting.addItems(withTitles: RepoDisplayPolicy.labels)
		allNewIssuesSetting.addItems(withTitles: RepoDisplayPolicy.labels)

		addTooltips()
		reloadSettings()

		versionNumber.stringValue = versionString
        
		let selectedIndex = min(tabs.numberOfTabViewItems-1, Settings.lastPreferencesTabSelectedOSX)
		tabs.selectTabViewItem(tabs.tabViewItem(at: selectedIndex))

		if projectsTable.sortDescriptors.isEmpty, let firstSortDescriptor = projectsTable.tableColumns.first?.sortDescriptorPrototype {
			projectsTable.sortDescriptors = [firstSortDescriptor]
		}

		let n = NotificationCenter.default
        n.addObserver(self, selector: #selector(updateApiTable), name: .ApiUsageUpdate, object: nil)
        n.addObserver(self, selector: #selector(updateImportExportSettings), name: .SettingsExported, object: nil)

		deferredUpdateTimer = PopTimer(timeInterval: 1) { [weak self] in
            DataManager.postProcessAllItems()
			if let s = self, s.serversDirty {
				s.serversDirty = false
				DataManager.saveDB()
				Settings.possibleExport(nil)
				app.setupWindows()
			} else {
				DataManager.saveDB()
				app.updateAllMenus()
			}
		}
	}

	private func updateReviewOptions() {
		if !Settings.notifyOnReviewChangeRequests {
			Settings.notifyOnAllReviewChangeRequests = false
		}
		if !Settings.notifyOnReviewDismissals {
			Settings.notifyOnAllReviewDismissals = false
		}
		if !Settings.notifyOnReviewAcceptances {
			Settings.notifyOnAllReviewAcceptances = false
		}

		notifyOnAllChangeRequests.isEnabled = Settings.notifyOnReviewChangeRequests
		notifyOnAllReviewDismissals.isEnabled = Settings.notifyOnReviewDismissals
		notifyOnAllAcceptances.isEnabled = Settings.notifyOnReviewAcceptances

		notifyOnChangeRequests.integerValue = Settings.notifyOnReviewChangeRequests ? 1 : 0
		notifyOnReviewDismissals.integerValue = Settings.notifyOnReviewDismissals ? 1 : 0
		notifyOnAcceptances.integerValue = Settings.notifyOnReviewAcceptances ? 1 : 0
		notifyOnAllChangeRequests.integerValue = Settings.notifyOnAllReviewChangeRequests ? 1 : 0
		notifyOnAllReviewDismissals.integerValue = Settings.notifyOnAllReviewDismissals ? 1 : 0
		notifyOnAllAcceptances.integerValue = Settings.notifyOnAllReviewAcceptances ? 1 : 0
	}

	private func showOptionalReviewWarning(previousSync: Bool) {

		updateReviewOptions()

		if !previousSync && (API.shouldSyncReviews || API.shouldSyncReviewAssignments) {
			for p in DataItem.allItems(of: PullRequest.self, in: DataManager.main) {
				p.resetSyncState()
			}
			preferencesDirty = true

			showLongSyncWarning()
		} else {
			deferredUpdateTimer.push()
		}
	}

    @IBAction private func showBaseAndHeadBranchesSelected(_ sender: NSButton) {
        Settings.showBaseAndHeadBranches = sender.integerValue == 1
        deferredUpdateTimer.push()
    }
    
    @IBAction private func showPrLinesSelected(_ sender: NSButton) {
        Settings.showPrLines = sender.integerValue == 1
        deferredUpdateTimer.push()
    }

    @IBAction private func listStatusesGreenSelected(_ sender: NSButton) {
        Settings.showStatusesGreen = sender.integerValue ==  1
        deferredUpdateTimer.push()
    }

    @IBAction private func listStatusesYellowSelected(_ sender: NSButton) {
        Settings.showStatusesYellow = sender.integerValue ==  1
        deferredUpdateTimer.push()
    }

    @IBAction private func listStatusesRedSelected(_ sender: NSButton) {
        Settings.showStatusesRed = sender.integerValue ==  1
        deferredUpdateTimer.push()
    }

    @IBAction private func markUnmergeablePrsSelected(_ sender: NSButton) {
        Settings.markUnmergeablePrs = sender.integerValue == 1
        deferredUpdateTimer.push()
    }

	@IBAction private func supportReviewsSelected(_ sender: NSButton) {
		let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
		Settings.displayReviewsOnItems = sender.integerValue == 1
		showOptionalReviewWarning(previousSync: previousShouldSync)
	}
    
    @IBAction private func showRequestedTeamReviewsSelected(_ sender: NSButton) {
        let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
        Settings.showRequestedTeamReviews = sender.integerValue == 1
        showOptionalReviewWarning(previousSync: previousShouldSync)
        deferredUpdateTimer.push()
    }

	@IBAction private func notifyOnChangeRequestsSelected(_ sender: NSButton) {
		let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
		Settings.notifyOnReviewChangeRequests = sender.integerValue == 1
		showOptionalReviewWarning(previousSync: previousShouldSync)
	}
	@IBAction private func notifyOnAllChangeRequestsSelected(_ sender: NSButton) {
		Settings.notifyOnAllReviewChangeRequests = sender.integerValue == 1
	}

	@IBAction private func notifyOnAcceptancesSelected(_ sender: NSButton) {
		let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
		Settings.notifyOnReviewAcceptances = sender.integerValue == 1
		showOptionalReviewWarning(previousSync: previousShouldSync)
	}
	@IBAction private func notifyOnAllAcceptancesSelected(_ sender: NSButton) {
		Settings.notifyOnAllReviewAcceptances = sender.integerValue == 1
	}

	@IBAction private func notifyOnReviewDismissalsSelected(_ sender: NSButton) {
		let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
		Settings.notifyOnReviewDismissals = sender.integerValue == 1
		showOptionalReviewWarning(previousSync: previousShouldSync)
	}
	@IBAction private func notifyOnAllReviewDismissalsSelected(_ sender: NSButton) {
		Settings.notifyOnAllReviewDismissals = sender.integerValue == 1
	}

	private func showOptionalReviewAssignmentWarning(previousSync: Bool) {

		if !previousSync && (API.shouldSyncReviews || API.shouldSyncReviewAssignments) {
			for p in DataItem.allItems(of: PullRequest.self, in: DataManager.main) {
				p.resetSyncState()
			}
			preferencesDirty = true

			showLongSyncWarning()
		} else {
			deferredUpdateTimer.push()
		}
	}

	@IBAction private func notifyOnReviewAssignmentsSelected(_ sender: NSButton) {
		let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
		Settings.notifyOnReviewAssignments = sender.integerValue == 1
		showOptionalReviewAssignmentWarning(previousSync: previousShouldSync)
	}

	@IBAction private func assignedReviewHandlingPolicySelected(_ sender: NSPopUpButton) {
		let previousShouldSync = (API.shouldSyncReviews || API.shouldSyncReviewAssignments)
		Settings.assignedReviewHandlingPolicy = sender.index(of: sender.selectedItem!)
		deferredUpdateTimer.push()
		showOptionalReviewAssignmentWarning(previousSync: previousShouldSync)
	}
    
    @IBAction private func draftHandlingPolicy(_ sender: NSPopUpButton) {
        Settings.draftHandlingPolicy = sender.index(of: sender.selectedItem!)
        deferredUpdateTimer.push()
    }

	private func showLongSyncWarning() {
		let a = NSAlert()
		a.messageText = "The next sync may take a while, because everything will need to be fully re-synced. This will be needed only once: Subsequent syncs will be fast again."
		a.beginSheetModal(for: self, completionHandler: nil)
	}
    
    @IBAction private func v4APISwitchChanged(_ sender: NSButton) {
        if sender.integerValue == 1, let error = API.canUseV4API(for: DataManager.main) {
            sender.integerValue = 0
            let a = NSAlert()
            a.messageText = Settings.v4title
            a.informativeText = error
            a.beginSheetModal(for: self, completionHandler: nil)
        } else {
            confirmApiSwitch(sender: sender)
        }
    }
    
    private func confirmApiSwitch(sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Reload All Data?"
        alert.informativeText = "Changing API versions will require a full delete and reload of all items, which can take a while and/or use quite a bit of bandwidth depending on your settings. Are you sure you'd like to proceed right now?"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Delete & Reload All Items")
        
        if alert.runModal() == .alertSecondButtonReturn {
            Settings.useV4API = sender.integerValue == 1
            sender.isEnabled = false
            performFullReload()
        } else {
            sender.integerValue = 1 - sender.integerValue
        }
    }

	@objc private func updateApiTable() {
		serverList.reloadData()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	private func addTooltips() {
		snoozePresetsList.toolTip = "The list of presets that will be displayed in the snooze context menu"
		serverList.toolTip = "The list of GitHub API servers that Trailer will attempt to sync data from. You can edit each server's details from the pane on the right. Bear in mind that some servers, like the public GitHub server for instance, have strict API volume limits, and syncing too many repos or items too often can result in API usage going over the limit. You can monitor your usage from the bar next to the server's name. If it is red, you're close to maximum. Your API usage is reset every hour."
		apiServerName.toolTip = "An internal name you want to use to refer to this server."
		apiServerApiPath.toolTip = "The full URL of the root of the v3 REST API endpoints for this server. The placeholder text shows examples for GitHub and GitHub Enterprise servers, but your own custom configuration may vary."
        apiServerGraphQLPath.toolTip = "The full URL of the root of the v4 GraphQL API endpoints for this server. The placeholder text shows examples for GitHub and GitHub Enterprise servers, but your own custom configuration may vary."
        apiServerWebPath.toolTip = "This is the root of the web front-end of your server. It is used for constructing the paths to open your watchlist and API key management links. Other than that it is not used to sync data."
		apiServerReportError.toolTip = "If this is checked, Trailer will display a red 'X' symbol on your menubar if sync fails with this server. It is usually a good idea to keep this on, but you may want to turn it off if a specific server isn't always reacahble, for instance."
		projectsTable.toolTip = "These are all your watched repositories.\n\nTrailer scans the watchlists of all the servers you have configured and adds the repositories to this combined watchlist.\n\nYou can visit and edit the watchlist of each server from the link provided on that server's entry on the 'Servers' tab.\n\nYou can keep clutter low by editing the visibility of items from each repository with the dropdown menus on the right."
		repoFilter.toolTip = "Quickly find a repository you are looking for by typing some text in there. Productivity tip: If you use the buttons on the right to set visibility of 'all' items, those settings will apply to only the visible filtered items."
		allNewPrsSetting.toolTip = "The visibility settings you would like to apply by default for Pull Requests if a new repository is added in your watchlist."
		allNewIssuesSetting.toolTip = "The visibility settings you would like to apply by default for Pull Requests if a new repository is added in your watchlist."
		launchAtStartup.toolTip = "Automatically launch Trailer when you log in."
		allPrsSetting.toolTip = "Set the PR visibility of all (or the currently selected/filtered) repositories"
		allIssuesSetting.toolTip = "Set the issue visibility of all (or the currently selected/filtered) repositories"
		allHidingSetting.toolTip = "Set the any special hiding settings of all (or the currently selected/filtered) repositories"
		showCreationDates.toolTip = Settings.showCreatedInsteadOfUpdatedHelp
		highlightItemsWithNewCommits.toolTip = Settings.markPrsAsUnreadOnNewCommitsHelp
		displayRepositoryNames.toolTip = Settings.showReposInNameHelp
		hideAvatars.toolTip = Settings.hideAvatarsHelp
		showSeparateApiServersInMenu.toolTip = Settings.showSeparateApiServersInMenuHelp
		hideCountsOnMenubar.toolTip = Settings.hideMenubarCountsHelp
		sortModeSelect.toolTip = Settings.sortMethodHelp
		sortingOrder.toolTip = Settings.sortDescendingHelp
		groupByRepo.toolTip = Settings.groupByRepoHelp
		assignedPrHandlingPolicy.toolTip = Settings.assignedPrHandlingPolicyHelp
        draftHandlingPolicy.toolTip = Settings.draftHandlingPolicyHelp
		includeTitlesInFiltering.toolTip = Settings.includeTitlesInFilterHelp
		includeMilestonesInFiltering.toolTip = Settings.includeMilestonesInFilterHelp
		includeAssigneeNamesInFiltering.toolTip = Settings.includeAssigneeInFilterHelp
		includeLabelsInFiltering.toolTip = Settings.includeLabelsInFilterHelp
		includeRepositoriesInFiltering.toolTip = Settings.includeReposInFilterHelp
		includeServersInFiltering.toolTip = Settings.includeServersInFilterHelp
		includeStatusesInFiltering.toolTip = Settings.includeStatusesInFilterHelp
		includeUsersInFiltering.toolTip = Settings.includeUsersInFilterHelp
		includeNumbersInFiltering.toolTip = Settings.includeNumbersInFilterHelp
		grayOutWhenRefreshing.toolTip = Settings.grayOutWhenRefreshingHelp
		refreshItemsLabel.toolTip = Settings.refreshPeriodHelp
		refreshDurationStepper.toolTip = Settings.refreshPeriodHelp
		prMergedPolicy.toolTip = Settings.mergeHandlingPolicyHelp
		prClosedPolicy.toolTip = Settings.closeHandlingPolicyHelp
		dontKeepPrsMergedByMe.toolTip = Settings.dontKeepPrsMergedByMeHelp
		removeNotificationsWhenItemIsRemoved.toolTip = Settings.removeNotificationsWhenItemIsRemovedHelp
        scanClosedAndMergedItems.toolTip = Settings.scanClosedAndMergedItemsHelp
        dontConfirmRemoveAllClosed.toolTip = Settings.dontAskBeforeWipingClosedHelp
		dontConfirmRemoveAllMerged.toolTip = Settings.dontAskBeforeWipingMergedHelp
		showAllComments.toolTip = Settings.showCommentsEverywhereHelp
		hideUncommentedPrs.toolTip = Settings.hideUncommentedItemsHelp
		openPrAtFirstUnreadComment.toolTip = Settings.openPrAtFirstUnreadCommentHelp
		assumeCommentsBeforeMineAreRead.toolTip = Settings.assumeReadItemIfUserHasNewerCommentsHelp
		disableAllCommentNotifications.toolTip = Settings.disableAllCommentNotificationsHelp
		showStatusItems.toolTip = Settings.showStatusItemsHelp
		statusItemRefreshCounter.toolTip = Settings.statusItemRefreshBatchSizeHelp
		statusItemRescanLabel.toolTip = Settings.statusItemRefreshBatchSizeHelp
		makeStatusItemsSelectable.toolTip = Settings.makeStatusItemsSelectableHelp
		notifyOnStatusUpdates.toolTip = Settings.notifyOnStatusUpdatesHelp
		notifyOnStatusUpdatesForAllPrs.toolTip = Settings.notifyOnStatusUpdatesForAllPrsHelp
		hidePrsThatDontPass.toolTip = Settings.hidePrsThatArentPassingHelp
		hidePrsThatDontPassOnlyInAll.toolTip = Settings.hidePrsThatDontPassOnlyInAllHelp
		showStatusesForAll.toolTip = Settings.showStatusesOnAllItemsHelp
		statusTermMenu.toolTip = Settings.statusFilteringTermsHelp
		logActivityToConsole.toolTip = Settings.logActivityToConsoleHelp
		dumpApiResponsesToConsole.toolTip = Settings.dumpAPIResponsesInConsoleHelp
		checkForUpdatesAutomatically.toolTip = Settings.checkForUpdatesAutomaticallyHelp
		snoozeWakeOnStatusUpdate.toolTip = Settings.snoozeWakeOnStatusUpdateHelp
		snoozeWakeOnMention.toolTip = Settings.snoozeWakeOnMentionHelp
		snoozeWakeOnComment.toolTip = Settings.snoozeWakeOnCommentHelp
		hideSnoozedItems.toolTip = Settings.hideSnoozedItemsHelp
		countSnoozedItems.toolTip = Settings.countVisibleSnoozedItemsHelp
		autoSnoozeSelector.toolTip = Settings.autoSnoozeDurationHelp
		autoSnoozeLabel.toolTip = Settings.autoSnoozeDurationHelp
		newMentionMovePolicy.toolTip = Settings.newMentionMovePolicyHelp
		teamMentionMovePolicy.toolTip = Settings.teamMentionMovePolicyHelp
		newItemInOwnedRepoMovePolicy.toolTip = Settings.newItemInOwnedRepoMovePolicyHelp
		notifyOnAllChangeRequests.toolTip = Settings.notifyOnAllReviewChangeRequestsHelp
		notifyOnChangeRequests.toolTip = Settings.notifyOnReviewChangeRequestsHelp
		notifyOnAllAcceptances.toolTip = Settings.notifyOnAllReviewChangeRequestsHelp
		notifyOnAcceptances.toolTip = Settings.notifyOnReviewAcceptancesHelp
		notifyOnAllAcceptances.toolTip = Settings.notifyOnAllReviewAcceptancesHelp
		notifyOnReviewDismissals.toolTip = Settings.notifyOnReviewDismissalsHelp
		notifyOnAllReviewDismissals.toolTip = Settings.notifyOnAllReviewDismissalsHelp
		notifyOnReviewAssignments.toolTip = Settings.notifyOnReviewAssignmentsHelp
		assignedReviewHandlingPolicy.toolTip = Settings.assignedReviewHandlingPolicyHelp
		supportReviews.toolTip = Settings.displayReviewsOnItemsHelp
        showRequestedTeamReviews.toolTip = Settings.showRequestedTeamReviewsHelp
        notifyOnItemReactions.toolTip = Settings.notifyOnItemReactionsHelp
		notifyOnCommentReactions.toolTip = Settings.notifyOnCommentReactionsHelp
		showLabels.toolTip = Settings.showLabelsHelp
		reactionIntervalLabel.toolTip = Settings.reactionScanningBatchSizeHelp
		reactionIntervalStepper.toolTip = Settings.reactionScanningBatchSizeHelp
		showRelativeDates.toolTip = Settings.showRelativeDatesHelp
		displayMilestones.toolTip = Settings.showMilestonesHelp
		displayNumbersForItems.toolTip = Settings.displayNumbersForItemsHelp
        v4ApiSwitch.toolTip = Settings.useV4APIHelp
        markUnmergeablePrs.toolTip = Settings.markUnmergeablePrsHelp
        showPrLines.toolTip = Settings.showPrLinesHelp
        reloadAllDataHelp.stringValue = Settings.reloadAllDataHelp
        showBaseAndHeadBranches.toolTip = Settings.showBaseAndHeadBranchesHelp
        showStatusesGreen.toolTip = Settings.showStatusesGreenHelp
        showStatusesYellow.toolTip = Settings.showStatusesYellowHelp
        showStatusesRed.toolTip = Settings.showStatusesRedHelp
	}

	private func updateAllItemSettingButtons() {

		allPrsSetting.removeAllItems()
		allIssuesSetting.removeAllItems()
		allHidingSetting.removeAllItems()

		if projectsTable.selectedRowIndexes.count > 1 {
			allPrsSetting.addItem(withTitle: "Set selected PRs…")
			allIssuesSetting.addItem(withTitle: "Set selected issues…")
			allHidingSetting.addItem(withTitle: "Set selected hiding…")
		} else if !repoFilter.stringValue.isEmpty {
			allPrsSetting.addItem(withTitle: "Set filtered PRs…")
			allIssuesSetting.addItem(withTitle: "Set filtered issues…")
			allHidingSetting.addItem(withTitle: "Set filtered hiding…")
		} else {
			allPrsSetting.addItem(withTitle: "Set all PRs…")
			allIssuesSetting.addItem(withTitle: "Set all issues…")
			allHidingSetting.addItem(withTitle: "Set all hiding…")
		}

		allPrsSetting.addItems(withTitles: RepoDisplayPolicy.labels)
		allIssuesSetting.addItems(withTitles: RepoDisplayPolicy.labels)
		allHidingSetting.addItems(withTitles: RepoHidingPolicy.labels)
	}

	func reloadSettings() {
		let firstRow = IndexSet(integer: 0)
		serverList.selectRowIndexes(firstRow, byExtendingSelection: false)
		fillServerApiFormFromSelectedServer()
		fillSnoozeFormFromSelectedPreset()

		API.updateLimitsFromServer()
		updateStatusTermPreferenceControls()
		commentAuthorBlacklist.objectValue = Settings.commentAuthorBlacklist
        labelFilteringBlacklist.objectValue = Settings.labelBlacklist
        itemFilteringBlacklist.objectValue = Settings.itemAuthorBlacklist

		setupSortMethodMenu()
		sortModeSelect.selectItem(at: Settings.sortMethod)

		prMergedPolicy.selectItem(at: Settings.mergeHandlingPolicy)
		prClosedPolicy.selectItem(at: Settings.closeHandlingPolicy)

		launchAtStartup.integerValue = Settings.isAppLoginItem ? 1 : 0
		dontConfirmRemoveAllClosed.integerValue = Settings.dontAskBeforeWipingClosed ? 1 : 0
		displayRepositoryNames.integerValue = Settings.showReposInName ? 1 : 0
		includeRepositoriesInFiltering.integerValue = Settings.includeReposInFilter ? 1 : 0
		includeLabelsInFiltering.integerValue = Settings.includeLabelsInFilter ? 1 : 0
		includeTitlesInFiltering.integerValue = Settings.includeTitlesInFilter ? 1 : 0
		includeMilestonesInFiltering.integerValue = Settings.includeMilestonesInFilter ? 1 : 0
		includeAssigneeNamesInFiltering.integerValue = Settings.includeAssigneeNamesInFilter ? 1 : 0
		includeUsersInFiltering.integerValue = Settings.includeUsersInFilter ? 1 : 0
		includeNumbersInFiltering.integerValue = Settings.includeNumbersInFilter ? 1 : 0
		includeServersInFiltering.integerValue = Settings.includeServersInFilter ? 1 : 0
		includeStatusesInFiltering.integerValue = Settings.includeStatusesInFilter ? 1 : 0
		dontConfirmRemoveAllMerged.integerValue = Settings.dontAskBeforeWipingMerged ? 1 : 0
		hideUncommentedPrs.integerValue = Settings.hideUncommentedItems ? 1 : 0
		assumeCommentsBeforeMineAreRead.integerValue = Settings.assumeReadItemIfUserHasNewerComments ? 1 : 0
		hideAvatars.integerValue = Settings.hideAvatars ? 1 : 0
		hideCountsOnMenubar.integerValue = Settings.hideMenubarCounts ? 1 : 0
		showSeparateApiServersInMenu.integerValue = Settings.showSeparateApiServersInMenu ? 1 : 0
		dontKeepPrsMergedByMe.integerValue = Settings.dontKeepPrsMergedByMe ? 1 : 0
		removeNotificationsWhenItemIsRemoved.integerValue = Settings.removeNotificationsWhenItemIsRemoved ? 1 : 0
        scanClosedAndMergedItems.integerValue = Settings.scanClosedAndMergedItems ? 1 : 0
        grayOutWhenRefreshing.integerValue = Settings.grayOutWhenRefreshing ? 1 : 0
		notifyOnStatusUpdates.integerValue = Settings.notifyOnStatusUpdates ? 1 : 0
		notifyOnStatusUpdatesForAllPrs.integerValue = Settings.notifyOnStatusUpdatesForAllPrs ? 1 : 0
		disableAllCommentNotifications.integerValue = Settings.disableAllCommentNotifications ? 1 : 0
		showAllComments.integerValue = Settings.showCommentsEverywhere ? 1 : 0
		sortingOrder.integerValue = Settings.sortDescending ? 1 : 0
		showCreationDates.integerValue = Settings.showCreatedInsteadOfUpdated ? 1 : 0
		groupByRepo.integerValue = Settings.groupByRepo ? 1 : 0
		assignedPrHandlingPolicy.selectItem(at: Settings.assignedPrHandlingPolicy)
        draftHandlingPolicy.selectItem(at: Settings.draftHandlingPolicy)
		showStatusItems.integerValue = Settings.showStatusItems ? 1 : 0
		makeStatusItemsSelectable.integerValue = Settings.makeStatusItemsSelectable ? 1 : 0
		openPrAtFirstUnreadComment.integerValue = Settings.openPrAtFirstUnreadComment ? 1 : 0
		logActivityToConsole.integerValue = Settings.logActivityToConsole ? 1 : 0
		dumpApiResponsesToConsole.integerValue = Settings.dumpAPIResponsesInConsole ? 1 : 0
		hidePrsThatDontPass.integerValue = Settings.hidePrsThatArentPassing ? 1 : 0
		hidePrsThatDontPassOnlyInAll.integerValue = Settings.hidePrsThatDontPassOnlyInAll ? 1 : 0
		showStatusesForAll.integerValue = Settings.showStatusesOnAllItems ? 1 : 0
		highlightItemsWithNewCommits.integerValue = Settings.markPrsAsUnreadOnNewCommits ? 1 : 0
		hideSnoozedItems.integerValue = Settings.hideSnoozedItems ? 1 : 0
		countSnoozedItems.integerValue = Settings.countVisibleSnoozedItems ? 1 : 0
		showLabels.integerValue = Settings.showLabels ? 1 : 0
		showRelativeDates.integerValue = Settings.showRelativeDates ? 1 : 0
		displayMilestones.integerValue = Settings.showMilestones ? 1 : 0
		displayNumbersForItems.integerValue = Settings.displayNumbersForItems ? 1 : 0
        v4ApiSwitch.integerValue = Settings.useV4API ? 1 : 0
        markUnmergeablePrs.integerValue = Settings.markUnmergeablePrs ? 1 : 0
        showPrLines.integerValue = Settings.showPrLines ? 1 : 0
        showRequestedTeamReviews.integerValue = Settings.showRequestedTeamReviews ? 1 : 0
        showBaseAndHeadBranches.integerValue = Settings.showBaseAndHeadBranches ? 1: 0
        
		defaultOpenApp.stringValue = Settings.defaultAppForOpeningItems
		defaultOpenLinks.stringValue = Settings.defaultAppForOpeningWeb

		notifyOnItemReactions.integerValue = Settings.notifyOnItemReactions ? 1 : 0
		notifyOnCommentReactions.integerValue = Settings.notifyOnCommentReactions ? 1 : 0

		supportReviews.integerValue = Settings.displayReviewsOnItems ? 1 : 0
		notifyOnReviewAssignments.integerValue = Settings.notifyOnReviewAssignments ? 1 : 0

		allNewPrsSetting.selectItem(at: Settings.displayPolicyForNewPrs)
		allNewIssuesSetting.selectItem(at: Settings.displayPolicyForNewIssues)

		newMentionMovePolicy.selectItem(at: Settings.newMentionMovePolicy)
		teamMentionMovePolicy.selectItem(at: Settings.teamMentionMovePolicy)
		newItemInOwnedRepoMovePolicy.selectItem(at: Settings.newItemInOwnedRepoMovePolicy)

		hotkeyEnable.integerValue = Settings.hotkeyEnable ? 1 : 0
		hotkeyControlModifier.integerValue = Settings.hotkeyControlModifier ? 1 : 0
		hotkeyCommandModifier.integerValue = Settings.hotkeyCommandModifier ? 1 : 0
		hotkeyOptionModifier.integerValue = Settings.hotkeyOptionModifier ? 1 : 0
		hotkeyShiftModifier.integerValue = Settings.hotkeyShiftModifier ? 1 : 0

		assignedReviewHandlingPolicy.select(assignedReviewHandlingPolicy.item(at: Settings.assignedReviewHandlingPolicy))

		enableHotkeySegments()

		hotkeyLetter.addItems(withTitles: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "[", "]", "\\", ";", "'", ",", ".", "/", "`", "-", "="])

		hotkeyLetter.selectItem(withTitle: Settings.hotkeyLetter)

		refreshUpdatePreferences()
		updateStatusItemsOptions()
		updateReactionItemOptions()
		updateHistoryOptions()

		hotkeyEnable.isEnabled = true

		refreshDurationStepper.doubleValue = min(Settings.refreshPeriod, 3600)
		refreshDurationChanged(nil)

		updateImportExportSettings()

		updateReviewOptions()

		updateActivity()
	}

	func updateActivity() {
        
        let isIdle = !API.isRefreshing
        projectsTable.isEnabled = isIdle
        allPrsSetting.isEnabled = isIdle
        allIssuesSetting.isEnabled = isIdle
        allHidingSetting.isEnabled = isIdle
        v4ApiSwitch.isEnabled = isIdle
        reloadAllData.isEnabled = isIdle

		if isIdle {
            projectsTable.alphaValue = 1
            reloadRepositories()
		} else {
            projectsTable.alphaValue = 0.3
		}
		advancedReposWindow?.updateActivity()
	}
    
    @IBAction private func reloadAllDataSelected(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Reload All Data?"
        alert.informativeText = Settings.reloadAllDataHelp
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Reload All Data")

        if alert.runModal() == .alertSecondButtonReturn {
            performFullReload()
        }
    }
    
    private func performFullReload() {
        for a in ApiServer.allApiServers(in: DataManager.main) {
            a.deleteEverything()
            a.resetSyncState()
        }
        DataManager.saveDB()
        RestAccess.clearAllBadLinks()
        app.updateAllMenus()
        app.startRefresh()
    }
    
	@IBAction private func displayNumbersForItemsSelected(_ sender: NSButton) {
		Settings.displayNumbersForItems = sender.integerValue == 1
		deferredUpdateTimer.push()
	}

	@IBAction private func displayMilestonesSelected(_ sender: NSButton) {
		Settings.showMilestones = sender.integerValue == 1
		deferredUpdateTimer.push()
	}

	@IBAction private func showRelativeDatesSelected(_ sender: NSButton) {
		Settings.showRelativeDates = sender.integerValue == 1
		deferredUpdateTimer.push()
	}

	@IBAction private func notifyOnItemReactionsSelected(_ sender: NSButton) {
		Settings.notifyOnItemReactions = sender.integerValue == 1
		updateReactionItemOptions()
		deferredUpdateTimer.push()
	}

	@IBAction private func notifyOnCommentReactionsSelected(_ sender: NSButton) {
		Settings.notifyOnCommentReactions = sender.integerValue == 1
		updateReactionItemOptions()
		deferredUpdateTimer.push()
	}

	@IBAction private func newMentionMovePolicySelected(_ sender: NSPopUpButton) {
		Settings.newMentionMovePolicy = sender.indexOfSelectedItem
		deferredUpdateTimer.push()
	}
	@IBAction private func teamMentionMovePolicySelected(_ sender: NSPopUpButton) {
		Settings.teamMentionMovePolicy = sender.indexOfSelectedItem
		deferredUpdateTimer.push()
	}
	@IBAction private func newItemInOwnedRepoMovePolicySelected(_ sender: NSPopUpButton) {
		Settings.newItemInOwnedRepoMovePolicy = sender.indexOfSelectedItem
		deferredUpdateTimer.push()
	}

	@IBAction private func dontConfirmRemoveAllMergedSelected(_ sender: NSButton) {
		Settings.dontAskBeforeWipingMerged = (sender.integerValue==1)
	}

	@IBAction private func displayRepositoryNameSelected(_ sender: NSButton) {
		Settings.showReposInName = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func showLabelsSelected(_ sender: NSButton) {
		let wasOff = Settings.showLabels
		Settings.showLabels = sender.integerValue == 1
		if wasOff && Settings.showLabels {
			ApiServer.resetSyncOfEverything()
			preferencesDirty = true
			showLongSyncWarning()
		}
		deferredUpdateTimer.push()
	}

	@IBAction private func logActivityToConsoleSelected(_ sender: NSButton) {
		Settings.logActivityToConsole = (sender.integerValue==1)
		logActivityToConsole.integerValue = Settings.logActivityToConsole ? 1 : 0
		if Settings.logActivityToConsole {
			let alert = NSAlert()
			alert.messageText = "Warning"
			#if DEBUG
				alert.informativeText = "Sorry, logging is always active in development versions"
			#else
				alert.informativeText = "Logging is a feature meant for error reporting, having it constantly enabled will cause this app to be less responsive, use more power, and constitute a security risk"
			#endif
			alert.addButton(withTitle: "OK")
			alert.beginSheetModal(for: self, completionHandler: nil)
		}
	}

	@IBAction private func selectDefaultAppSelected(_ sender: NSButton) {
		let o = NSOpenPanel()
		o.title = "Select Application…"
		o.prompt = "Select"
		o.nameFieldLabel = "Application"
		o.message = "Select Application For Opening Items…"
		o.isExtensionHidden = true
		o.allowedFileTypes = ["app"]
		o.beginSheetModal(for: self) { [weak self] response in
			if response.rawValue == NSFileHandlingPanelOKButton, let url = o.url {
				Settings.defaultAppForOpeningItems = url.path
				self?.defaultOpenApp.stringValue = url.path
			}
		}
	}

	@IBAction private func selectDefaultLinkSelected(_ sender: NSButton) {
		let o = NSOpenPanel()
		o.title = "Select Application…"
		o.prompt = "Select"
		o.nameFieldLabel = "Application"
		o.message = "Select Application For Opening Web Links…"
		o.isExtensionHidden = true
		o.allowedFileTypes = ["app"]
		o.beginSheetModal(for: self) { [weak self] response in
			if response.rawValue == NSFileHandlingPanelOKButton, let url = o.url {
				Settings.defaultAppForOpeningWeb = url.path
				self?.defaultOpenLinks.stringValue = url.path
			}
		}
	}


	@IBAction private func dumpApiResponsesToConsoleSelected(_ sender: NSButton) {
		Settings.dumpAPIResponsesInConsole = (sender.integerValue==1)
		if Settings.dumpAPIResponsesInConsole {
			let alert = NSAlert()
			alert.messageText = "Warning"
			alert.informativeText = "This is a feature meant for error reporting, having it constantly enabled will cause this app to be less responsive, use more power, and constitute a security risk"
			alert.addButton(withTitle: "OK")
			alert.beginSheetModal(for: self, completionHandler: nil)
		}
	}

	@IBAction private func includeServersInFilteringSelected(_ sender: NSButton) {
		Settings.includeServersInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeNumbersInFilteringSelected(_ sender: NSButton) {
		Settings.includeNumbersInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeUsersInFilteringSelected(_ sender: NSButton) {
		Settings.includeUsersInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeLabelsInFilteringSelected(_ sender: NSButton) {
		Settings.includeLabelsInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeStatusesInFilteringSelected(_ sender: NSButton) {
		Settings.includeStatusesInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeTitlesInFilteringSelected(_ sender: NSButton) {
		Settings.includeTitlesInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeMilestonesInFilteringSelected(_ sender: NSButton) {
		Settings.includeMilestonesInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeAssigneeNamesInFilteringSelected(_ sender: NSButton) {
		Settings.includeAssigneeNamesInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func includeRepositoriesInfilterSelected(_ sender: NSButton) {
		Settings.includeReposInFilter = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func dontConfirmRemoveAllClosedSelected(_ sender: NSButton) {
		Settings.dontAskBeforeWipingClosed = (sender.integerValue==1)
	}

	@IBAction private func assumeAllCommentsBeforeMineAreReadSelected(_ sender: NSButton) {
		Settings.assumeReadItemIfUserHasNewerComments = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func removeNotificationsWhenItemIsRemovedSelected(_ sender: NSButton) {
		Settings.removeNotificationsWhenItemIsRemoved = (sender.integerValue==1)
	}

    @IBAction private func scanClosedAndMergedItemsSelected(_ sender: NSButton) {
        Settings.scanClosedAndMergedItems = sender.integerValue == 1
    }
    
	@IBAction private func dontKeepMyPrsSelected(_ sender: NSButton) {
		Settings.dontKeepPrsMergedByMe = (sender.integerValue==1)
		updateHistoryOptions()
	}

	private func updateHistoryOptions() {
		dontKeepPrsMergedByMe.isEnabled = Settings.mergeHandlingPolicy != HandlingPolicy.keepNone.rawValue
	}

	@IBAction private func highlightItemsWithNewCommitsSelected(_ sender: NSButton) {
		Settings.markPrsAsUnreadOnNewCommits = (sender.integerValue==1)
	}

	@IBAction private func grayOutWhenRefreshingSelected(_ sender: NSButton) {
		Settings.grayOutWhenRefreshing = (sender.integerValue==1)
	}

	@IBAction private func disableAllCommentNotificationsSelected(_ sender: NSButton) {
		Settings.disableAllCommentNotifications = (sender.integerValue==1)
	}

	@IBAction private func notifyOnStatusUpdatesSelected(_ sender: NSButton) {
		Settings.notifyOnStatusUpdates = (sender.integerValue==1)
		updateStatusItemsOptions()
	}

	@IBAction private func notifyOnStatusUpdatesOnAllPrsSelected(_ sender: NSButton) {
		Settings.notifyOnStatusUpdatesForAllPrs = (sender.integerValue==1)
	}

	@IBAction private func hidePrsThatDontPassOnlyInAllSelected(_ sender: NSButton) {
		Settings.hidePrsThatDontPassOnlyInAll = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func showStatusesForAllSelected(_ sender: NSButton) {
		Settings.showStatusesOnAllItems = (sender.integerValue==1)
		deferredUpdateTimer.push()
		if Settings.showStatusItems {
			preferencesDirty = true
		}
	}

	@IBAction private func hidePrsThatDontPassSelected(_ sender: NSButton) {
		Settings.hidePrsThatArentPassing = (sender.integerValue==1)
		updateStatusItemsOptions()
		deferredUpdateTimer.push()
	}

	@IBAction private func hideAvatarsSelected(_ sender: NSButton) {
		Settings.hideAvatars = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func showSeparateApiServersInMenuSelected(_ sender: NSButton) {
		Settings.showSeparateApiServersInMenu = (sender.integerValue==1)
		serversDirty = true
		deferredUpdateTimer.push()
	}

	private var affectedReposFromSelection: [Repo] {
		let selectedRows = projectsTable.selectedRowIndexes
		var affectedRepos = [Repo]()
		if selectedRows.count > 1 {
			for row in selectedRows {
				affectedRepos.append(repos[row])
			}
		} else {
			affectedRepos = repos
		}
		return affectedRepos
	}

	@IBAction private func allPrsPolicySelected(_ sender: NSPopUpButton) {
		let index = Int64(sender.indexOfSelectedItem - 1)
		if index < 0 { return }

		for r in affectedReposFromSelection {
			r.displayPolicyForPrs = index
			if index != RepoDisplayPolicy.hide.rawValue { r.resetSyncState() }
		}
		reloadRepositories()
		sender.selectItem(at: 0)
		updateDisplayIssuesSetting()
	}

	@IBAction private func allIssuesPolicySelected(_ sender: NSPopUpButton) {
		let index = Int64(sender.indexOfSelectedItem - 1)
		if index < 0 { return }

		for r in affectedReposFromSelection {
			r.displayPolicyForIssues = index
			if index != RepoDisplayPolicy.hide.rawValue { r.resetSyncState() }
		}
		reloadRepositories()
		sender.selectItem(at: 0)
		updateDisplayIssuesSetting()
	}

	@IBAction private func allHidingPolicySelected(_ sender: NSPopUpButton) {
		let index = Int64(sender.indexOfSelectedItem - 1)
		if index < 0 { return }

		for r in affectedReposFromSelection {
			r.itemHidingPolicy = index
		}
		reloadRepositories()
		sender.selectItem(at: 0)
		updateDisplayIssuesSetting()
	}

	private func updateDisplayIssuesSetting() {
		preferencesDirty = true
		serversDirty = true
		deferredUpdateTimer.push()
	}

	@IBAction private func allNewPrsPolicySelected(_ sender: NSPopUpButton) {
		Settings.displayPolicyForNewPrs = sender.indexOfSelectedItem
	}

	@IBAction private func allNewIssuesPolicySelected(_ sender: NSPopUpButton) {
		Settings.displayPolicyForNewIssues = sender.indexOfSelectedItem
	}

	@IBAction private func hideUncommentedRequestsSelected(_ sender: NSButton) {
		Settings.hideUncommentedItems = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func showAllCommentsSelected(_ sender: NSButton) {
		Settings.showCommentsEverywhere = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func sortOrderSelected(_ sender: NSButton) {
		Settings.sortDescending = (sender.integerValue==1)
		setupSortMethodMenu()
		deferredUpdateTimer.push()
	}

	@IBAction private func openPrAtFirstUnreadCommentSelected(_ sender: NSButton) {
		Settings.openPrAtFirstUnreadComment = (sender.integerValue==1)
	}

	@IBAction private func sortMethodChanged(_ sender: NSMenuItem) {
		Settings.sortMethod = sortModeSelect.indexOfSelectedItem
		deferredUpdateTimer.push()
	}

	@IBAction private func showStatusItemsSelected(_ sender: NSButton) {
		Settings.showStatusItems = (sender.integerValue==1)
		deferredUpdateTimer.push()
		updateStatusItemsOptions()

		if Settings.showStatusItems {
			preferencesDirty = true
		}
	}

	private func setupSortMethodMenu() {
		let m = NSMenu(title: "Sorting")
		for t in Settings.sortDescending ? SortingMethod.reverseTitles : SortingMethod.normalTitles {
			m.addItem(withTitle: t, action: #selector(sortMethodChanged), keyEquivalent: "")
		}
		sortModeSelect.menu = m
		sortModeSelect.selectItem(at: Settings.sortMethod)
	}

	private func updateStatusItemsOptions() {
		let enable = Settings.showStatusItems
		makeStatusItemsSelectable.isEnabled = enable
		notifyOnStatusUpdates.isEnabled = enable
		notifyOnStatusUpdatesForAllPrs.isEnabled = enable
		statusTermMenu.isEnabled = enable
		statusItemRefreshCounter.isEnabled = enable
		statusItemRescanLabel.alphaValue = enable ? 1.0 : 0.5
		hidePrsThatDontPass.alphaValue = enable ? 1.0 : 0.5
		hidePrsThatDontPass.isEnabled = enable
		showStatusesForAll.isEnabled = enable
        showStatusesGreen.isEnabled = enable
        showStatusesYellow.isEnabled = enable
        showStatusesRed.isEnabled = enable
		hidePrsThatDontPassOnlyInAll.isEnabled = enable && Settings.hidePrsThatArentPassing
		notifyOnStatusUpdatesForAllPrs.isEnabled = enable && Settings.notifyOnStatusUpdates

		let count = Settings.statusItemRefreshBatchSize
		statusItemRefreshCounter.integerValue = count
		statusItemRescanLabel.stringValue = "…re-scan up to \(count) items on every refresh"

		updateStatusTermPreferenceControls()
	}

	private func updateReactionItemOptions() {
		let count = Settings.reactionScanningBatchSize
		reactionIntervalStepper.integerValue = count
		reactionIntervalLabel.stringValue = "Re-scan up to \(count) items on every refresh"
		let enabled = API.shouldSyncReactions
		reactionIntervalStepper.isEnabled = enabled
		reactionIntervalLabel.isEnabled = enabled
		reactionIntervalLabel.textColor = enabled ? NSColor.labelColor : NSColor.disabledControlTextColor
	}

	@IBAction private func reactionIntervalCountChanged(_ sender: NSStepper) {
		Settings.reactionScanningBatchSize = sender.integerValue
		updateReactionItemOptions()
	}

	@IBAction private func statusItemRefreshCountChanged(_ sender: NSStepper) {
		Settings.statusItemRefreshBatchSize = sender.integerValue
		updateStatusItemsOptions()
	}

	@IBAction private func makeStatusItemsSelectableSelected(_ sender: NSButton) {
		Settings.makeStatusItemsSelectable = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func hideCountsOnMenubarSelected(_ sender: NSButton) {
		Settings.hideMenubarCounts = (sender.integerValue==1)
		serversDirty = true
		deferredUpdateTimer.push()
	}

	@IBAction private func showCreationSelected(_ sender: NSButton) {
		Settings.showCreatedInsteadOfUpdated = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func groupbyRepoSelected(_ sender: NSButton) {
		Settings.groupByRepo = (sender.integerValue==1)
		deferredUpdateTimer.push()
	}

	@IBAction private func assignedPrHandlingPolicySelected(_ sender: NSPopUpButton) {
		Settings.assignedPrHandlingPolicy = sender.indexOfSelectedItem
		deferredUpdateTimer.push()
	}

	@IBAction private func checkForUpdatesAutomaticallySelected(_ sender: NSButton) {
		Settings.checkForUpdatesAutomatically = (sender.integerValue==1)
		refreshUpdatePreferences()
	}

	private func refreshUpdatePreferences() {
		let setting = Settings.checkForUpdatesAutomatically
		let interval = Settings.checkForUpdatesInterval

		checkForUpdatesLabel.isHidden = !setting
		checkForUpdatesSelector.isHidden = !setting

		checkForUpdatesSelector.integerValue = interval
		checkForUpdatesAutomatically.integerValue = setting ? 1 : 0
		checkForUpdatesLabel.stringValue = interval<2 ? "Check every hour" : "Check every \(interval) hours"
	}

	@IBAction private func checkForUpdatesIntervalChanged(_ sender: NSStepper) {
		Settings.checkForUpdatesInterval = sender.integerValue
		refreshUpdatePreferences()
	}

	@IBAction private func launchAtStartSelected(_ sender: NSButton) {
        Settings.isAppLoginItem = sender.integerValue == 1
	}

	func refreshRepos() {
        API.isRefreshing = true
		let tempContext = DataManager.buildChildContext()
		API.fetchRepositories(to: tempContext) {

			if ApiServer.shouldReportRefreshFailure(in: tempContext) {
				var errorServers = [String]()
				for apiServer in ApiServer.allApiServers(in: tempContext) {
					if apiServer.goodToGo && !apiServer.lastSyncSucceeded {
						errorServers.append(S(apiServer.label))
					}
				}

				let serverNames = errorServers.joined(separator: ", ")

				let alert = NSAlert()
				alert.messageText = "Error"
				alert.informativeText = "Could not refresh repository list from \(serverNames), please ensure that the tokens you are using are valid"
				alert.addButton(withTitle: "OK")
				alert.runModal()
            } else if tempContext.hasChanges {
                try? tempContext.save()
			}
			DataItem.nukeDeletedItems(in: DataManager.main)
            API.isRefreshing = false
		}
	}

	private var selectedServer: ApiServer? {
		let selected = serverList.selectedRow
		if selected >= 0 {
			return ApiServer.allApiServers(in: DataManager.main)[selected]
		}
		return nil
	}

	@IBAction private func deleteSelectedServerSelected(_ sender: NSButton) {
		if let selectedServer = selectedServer, let index = ApiServer.allApiServers(in: DataManager.main).firstIndex(of: selectedServer) {
			DataManager.main.delete(selectedServer)
			serverList.reloadData()
			serverList.selectRowIndexes(IndexSet(integer: min(index, serverList.numberOfRows-1)), byExtendingSelection: false)
			fillServerApiFormFromSelectedServer()
			serversDirty = true
			deferredUpdateTimer.push()
		}
	}

	@IBAction private func apiServerReportErrorSelected(_ sender: NSButton) {
		if let apiServer = selectedServer {
			apiServer.reportRefreshFailures = (sender.integerValue != 0)
			storeApiFormToSelectedServer()
		}
	}

	@objc private func updateImportExportSettings() {
		repeatLastExportAutomatically.integerValue = Settings.autoRepeatSettingsExport ? 1 : 0
		if let lastExportDate = Settings.lastExportDate, let fileName = Settings.lastExportUrl?.absoluteString, let unescapedName = fileName.removingPercentEncoding {
			let time = itemDateFormatter.string(from: lastExportDate)
			lastExportReport.stringValue = "Last exported \(time) to \(unescapedName)"
		} else {
			lastExportReport.stringValue = ""
		}
	}

	@IBAction private func repeatLastExportSelected(_ sender: NSButton) {
		Settings.autoRepeatSettingsExport = (repeatLastExportAutomatically.integerValue==1)
	}

	@IBAction private func exportCurrentSettingsSelected(_ sender: NSButton) {
		let s = NSSavePanel()
		s.title = "Export Current Settings…"
		s.prompt = "Export"
		s.nameFieldLabel = "Settings File"
		s.message = "Export Current Settings…"
		s.isExtensionHidden = false
		s.nameFieldStringValue = "Trailer Settings"
		s.allowedFileTypes = ["trailerSettings"]
		s.beginSheetModal(for: self) { response in
			if response.rawValue == NSFileHandlingPanelOKButton, let url = s.url {
				Settings.writeToURL(url)
				DLog("Exported settings to %@", url.absoluteString)
			}
		}
	}

	@IBAction private func importSettingsSelected(_ sender: NSButton) {
		let o = NSOpenPanel()
		o.title = "Import Settings From File…"
		o.prompt = "Import"
		o.nameFieldLabel = "Settings File"
		o.message = "Import Settings From File…"
		o.isExtensionHidden = false
		o.allowedFileTypes = ["trailerSettings"]
		o.beginSheetModal(for: self) { response in
			if response.rawValue == NSFileHandlingPanelOKButton, let url = o.url {
                DispatchQueue.main.async {
					app.tryLoadSettings(from: url, skipConfirm: Settings.dontConfirmSettingsImport)
				}
			}
		}
	}

	private func color(button: NSButton, withColor: NSColor) {
		let title = button.attributedTitle.mutableCopy() as! NSMutableAttributedString
		title.addAttribute(NSAttributedString.Key.foregroundColor, value: withColor, range: NSRange(location: 0, length: title.length))
		button.attributedTitle = title
	}

	private func enableHotkeySegments() {
		if Settings.hotkeyEnable {
			color(button: hotkeyCommandModifier, withColor: Settings.hotkeyCommandModifier ? .controlTextColor : .disabledControlTextColor)
			color(button: hotkeyControlModifier, withColor: Settings.hotkeyControlModifier ? .controlTextColor : .disabledControlTextColor)
			color(button: hotkeyOptionModifier, withColor: Settings.hotkeyOptionModifier ? .controlTextColor : .disabledControlTextColor)
			color(button: hotkeyShiftModifier, withColor: Settings.hotkeyShiftModifier ? .controlTextColor : .disabledControlTextColor)
		}
		hotKeyContainer.isHidden = !Settings.hotkeyEnable
		hotKeyHelp.isHidden = Settings.hotkeyEnable
	}

	@IBAction private func enableHotkeySelected(_ sender: NSButton) {
		Settings.hotkeyEnable = hotkeyEnable.integerValue != 0
		Settings.hotkeyLetter = hotkeyLetter.titleOfSelectedItem ?? "T"
		Settings.hotkeyControlModifier = hotkeyControlModifier.integerValue != 0
		Settings.hotkeyCommandModifier = hotkeyCommandModifier.integerValue != 0
		Settings.hotkeyOptionModifier = hotkeyOptionModifier.integerValue != 0
		Settings.hotkeyShiftModifier = hotkeyShiftModifier.integerValue != 0
		enableHotkeySegments()
		app.addHotKeySupport()
	}

	private func reportNeedFrontEnd() {
		let alert = NSAlert()
		alert.messageText = "Please provide a full URL for the web front end of this server first"
		alert.addButton(withTitle: "OK")
		alert.runModal()
	}

	@IBAction private func createTokenSelected(_ sender: NSButton) {
		if apiServerWebPath.stringValue.isEmpty {
			reportNeedFrontEnd()
		} else {
			let address = "\(apiServerWebPath.stringValue)/settings/tokens/new"
			openLink(URL(string: address)!)
		}
	}

	@IBAction private func viewExistingTokensSelected(_ sender: NSButton) {
		if apiServerWebPath.stringValue.isEmpty {
			reportNeedFrontEnd()
		} else {
			let address = "\(apiServerWebPath.stringValue)/settings/tokens"
			openLink(URL(string: address)!)
		}
	}

	@IBAction private func viewWatchlistSelected(_ sender: NSButton) {
		if apiServerWebPath.stringValue.isEmpty {
			reportNeedFrontEnd()
		} else {
			let address = "\(apiServerWebPath.stringValue)/watching"
			openLink(URL(string: address)!)
		}
	}

	@IBAction private func prMergePolicySelected(_ sender: NSPopUpButton) {
		Settings.mergeHandlingPolicy = sender.indexOfSelectedItem
		updateHistoryOptions()
	}

	@IBAction private func prClosePolicySelected(_ sender: NSPopUpButton) {
		Settings.closeHandlingPolicy = sender.indexOfSelectedItem
	}

	private func updateStatusTermPreferenceControls() {
		let mode = Settings.statusFilteringMode
		statusTermMenu.selectItem(at: mode)
		if mode != 0 {
			statusTermsField.isEnabled = true
			statusTermsField.alphaValue = 1.0
		}
		else
		{
			statusTermsField.isEnabled = false
			statusTermsField.alphaValue = 0.5
		}
		statusTermsField.objectValue = Settings.statusFilteringTerms
	}

	@IBAction private func statusFilterMenuChanged(_ sender: NSPopUpButton) {
		Settings.statusFilteringMode = sender.indexOfSelectedItem
		Settings.statusFilteringTerms = statusTermsField.objectValue as! [String]
		updateStatusTermPreferenceControls()
		deferredUpdateTimer.push()
	}

	@IBAction private func testApiServerSelected(_ sender: NSButton) {
		sender.isEnabled = false
		let apiServer = selectedServer!
        let group = DispatchGroup()

        var finalSuccess = true
        var finalError: Error?
        var failedPath: String?
        
        if apiServer.graphQLPath != nil {
            DLog("Checking GraphQL interface on \(S(apiServer.graphQLPath))")
            group.enter()
            GraphQL.testApi(to: apiServer) { success, error in
                if let e = error {
                    finalError = e
                    finalSuccess = false
                    failedPath = apiServer.graphQLPath
                } else if !success {
                    finalSuccess = false
                    failedPath = apiServer.graphQLPath
                }
                group.leave()
            }
        }
        
        group.enter()
		API.testApi(to: apiServer) { error in
            if let e = error {
                finalError = e
                finalSuccess = false
                failedPath = apiServer.apiPath
            }
            group.leave()
		}
        
        group.notify(queue: .main) {
            let alert = NSAlert()
            if let e = finalError {
                alert.messageText = "The test failed for \(S(failedPath))"
                alert.informativeText = e.localizedDescription
            } else if !finalSuccess {
                alert.messageText = "The test failed for \(S(failedPath))"
                alert.informativeText = "There was no network error"
            } else {
                alert.messageText = "This API server seems OK!"
            }
            alert.addButton(withTitle: "OK")
            alert.runModal()
            sender.isEnabled = true
        }
	}

	@IBAction private func apiRestoreDefaultsSelected(_ sender: NSButton)
	{
		if let apiServer = selectedServer {
			apiServer.resetToGithub()
			fillServerApiFormFromSelectedServer()
			storeApiFormToSelectedServer()
		}
	}

	private func fillServerApiFormFromSelectedServer() {
		if let apiServer = selectedServer {
			apiServerName.stringValue = S(apiServer.label)
			apiServerWebPath.stringValue = S(apiServer.webPath)
			apiServerApiPath.stringValue = S(apiServer.apiPath)
            apiServerGraphQLPath.stringValue = S(apiServer.graphQLPath)
            apiServerAuthToken.stringValue = S(apiServer.authToken)
			apiServerSelectedBox.title = apiServer.label ?? "New Server"
			apiServerTestButton.isEnabled = !S(apiServer.authToken).isEmpty
			apiServerDeleteButton.isEnabled = (ApiServer.countApiServers(in: DataManager.main) > 1)
			apiServerReportError.integerValue = apiServer.reportRefreshFailures ? 1 : 0
		}
	}

	private func storeApiFormToSelectedServer() {
		if let apiServer = selectedServer {
            apiServer.label = apiServerName.stringValue.trim
            apiServer.apiPath = apiServerApiPath.stringValue.trim
            apiServer.graphQLPath = apiServerGraphQLPath.stringValue.trim
			apiServer.webPath = apiServerWebPath.stringValue.trim
			apiServer.authToken = apiServerAuthToken.stringValue.trim
			apiServerTestButton.isEnabled = !S(apiServer.authToken).isEmpty
			serverList.reloadData()
			serversDirty = true
			deferredUpdateTimer.push()
		}
	}

	@IBAction private func addNewApiServerSelected(_ sender: NSButton) {
		let a = ApiServer.insertNewServer(in: DataManager.main)
		a.label = "New API Server"
		serverList.reloadData()
		if let index = ApiServer.allApiServers(in: DataManager.main).firstIndex(of: a) {
			serverList.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
			fillServerApiFormFromSelectedServer()
		}
		serversDirty = true
		deferredUpdateTimer.push()
	}

	@IBAction private func refreshDurationChanged(_ sender: NSStepper?) {
		Settings.refreshPeriod = refreshDurationStepper.doubleValue
		refreshDurationLabel.stringValue = "Refresh items every \(refreshDurationStepper.integerValue) seconds"
	}

	func windowWillClose(_ notification: Notification) {
		advancedReposWindow?.close()
		if ApiServer.someServersHaveAuthTokens(in: DataManager.main) && preferencesDirty {
			app.startRefresh()
		} else {
			if app.refreshTimer == nil && Settings.refreshPeriod > 0.0 {
				app.startRefreshIfItIsDue()
			}
		}
		app.setUpdateCheckParameters()
		app.closedPreferencesWindow()
	}

	func controlTextDidChange(_ n: Notification) {
		guard let obj = n.object as? NSTextField else {
            return
        }

        if obj===defaultOpenLinks {
            Settings.defaultAppForOpeningWeb = defaultOpenLinks.stringValue.trim

        } else if obj===defaultOpenApp {
            Settings.defaultAppForOpeningItems = defaultOpenApp.stringValue.trim

        } else if obj===apiServerName {
            if let apiServer = selectedServer {
                apiServer.label = apiServerName.stringValue
                storeApiFormToSelectedServer()
            }
            
        } else if obj===apiServerApiPath {
            if let apiServer = selectedServer {
                apiServer.apiPath = apiServerApiPath.stringValue
                storeApiFormToSelectedServer()
                reset()
            }
            
        } else if obj===apiServerGraphQLPath {
            if let apiServer = selectedServer {
                apiServer.graphQLPath = apiServerGraphQLPath.stringValue
                storeApiFormToSelectedServer()
                reset()
            }
            
        } else if obj===apiServerWebPath {
            if let apiServer = selectedServer {
                apiServer.webPath = apiServerWebPath.stringValue
                storeApiFormToSelectedServer()
            }
            
        } else if obj===apiServerAuthToken {
            if let apiServer = selectedServer {
                apiServer.authToken = apiServerAuthToken.stringValue
                storeApiFormToSelectedServer()
                reset()
            }
        } else if obj===repoFilter {
            reloadRepositories()
            updateAllItemSettingButtons()

        } else if obj===statusTermsField {
            let newTokens = statusTermsField.objectValue as! [String]
            if Settings.statusFilteringTerms != newTokens {
                Settings.statusFilteringTerms = newTokens
                deferredUpdateTimer.push()
            }
            
        } else if obj===commentAuthorBlacklist {
            let newTokens = commentAuthorBlacklist.objectValue as! [String]
            if Settings.commentAuthorBlacklist != newTokens {
                Settings.commentAuthorBlacklist = newTokens
                deferredUpdateTimer.push()
            }
            
        } else if obj===itemFilteringBlacklist {
            let newTokens = itemFilteringBlacklist.objectValue as! [String]
            if Settings.itemAuthorBlacklist != newTokens {
                Settings.itemAuthorBlacklist = newTokens
                deferredUpdateTimer.push()
            }
            
        } else if obj===labelFilteringBlacklist {
            let newTokens = labelFilteringBlacklist.objectValue as! [String]
            if Settings.labelBlacklist != newTokens {
                Settings.labelBlacklist = newTokens
                deferredUpdateTimer.push()
            }
        }
    }

	///////////// Tabs

	func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		if let item = tabViewItem {
			let newIndex = tabView.indexOfTabViewItem(item)
			if newIndex == 1 {
				if lastRepoCheck == .distantPast && DataManager.appIsConfigured {
					refreshRepos()
				}
			}
			Settings.lastPreferencesTabSelectedOSX = newIndex
		}
	}

	///////////// Repo table

	func tableViewSelectionDidChange(_ notification: Notification) {
		if let o = notification.object as? NSTableView {
			if serverList === o {
				fillServerApiFormFromSelectedServer()
			} else if projectsTable === o {
				updateAllItemSettingButtons()
			} else if snoozePresetsList === o {
				fillSnoozeFormFromSelectedPreset()
			}
		}
	}

	func tableView(_ tv: NSTableView, willDisplayCell c: Any, for tableColumn: NSTableColumn?, row: Int) {
		guard let tid = tableColumn?.identifier.rawValue else { return }
		let cell = c as! NSCell
		if tv === projectsTable {
			if tid == "repos" {
				cell.isEnabled = true
				let r = repos[row]
				let repoName = S(r.fullName)
				let title = r.inaccessible ? "\(repoName) (inaccessible)" : repoName
				let textColor = (row == tv.selectedRow) ? .selectedControlTextColor : (r.shouldSync ? .textColor : NSColor.textColor.withAlphaComponent(0.4))
				cell.attributedStringValue = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: textColor])
			} else if let menuCell = cell as? NSTextFieldCell {
				if tableColumn?.identifier.rawValue == "group" {
					let r = repos[row]
					menuCell.isEnabled = true
					menuCell.placeholderString = "None"
					menuCell.stringValue = S(r.groupLabel)
				}
			} else if let menuCell = cell as? NSPopUpButtonCell {
				menuCell.removeAllItems()
				let r = repos[row]
				menuCell.isEnabled = true
				menuCell.arrowPosition = .arrowAtBottom

				let fontSize = NSFont.systemFontSize(for: .small)
				if tid == "hide" {
					for policy in RepoHidingPolicy.policies {
						let m = NSMenuItem()
						m.attributedTitle = NSAttributedString(string: policy.name, attributes: [
                            .font: policy.bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize),
							.foregroundColor: policy.color,
							])
						menuCell.menu?.addItem(m)
					}
					menuCell.selectItem(at: Int(r.itemHidingPolicy))
				} else {
                    let prs = tableColumn?.identifier.rawValue == "prs"
                    let currentPolicy = prs ? r.displayPolicyForPrs : r.displayPolicyForIssues
                    let hiddenName = (currentPolicy == RepoDisplayPolicy.authoredOnly.rawValue) ? RepoDisplayPolicy.authoredOnly.name : RepoDisplayPolicy.hide.name
                    let selectedIndex = (currentPolicy == RepoDisplayPolicy.authoredOnly.rawValue) ? RepoDisplayPolicy.hide.rawValue : currentPolicy

                    for policy in RepoDisplayPolicy.allCases.filter({ $0.selectable }) {
						let m = NSMenuItem()
                        let name = policy == .hide ? hiddenName : policy.name
						m.attributedTitle = NSAttributedString(string: name, attributes: [
							.font: policy.bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize),
							.foregroundColor: policy.color,
							])
						menuCell.menu?.addItem(m)
					}
					menuCell.selectItem(at: Int(selectedIndex))
				}
			} else if let forkButton = cell as? NSButtonCell {
				if tid == "fork" {
					let r = repos[row]
					forkButton.integerValue = r.fork ? 1 : 0
				}
			}
		} else if tv == serverList {
			let allServers = ApiServer.allApiServers(in: DataManager.main)
			let apiServer = allServers[row]
			if tid == "server" {
				cell.title = S(apiServer.label)
				let tc = c as! NSTextFieldCell
				if apiServer.lastSyncSucceeded {
					tc.textColor = .textColor
				} else {
					tc.textColor = .appRed
				}
			} else { // api usage
				let c = cell as! NSLevelIndicatorCell
				c.minValue = 0
				let rl = Double(apiServer.requestsLimit)
				c.maxValue = rl
				c.warningValue = rl*0.5
				c.criticalValue = rl*0.8
				c.doubleValue = rl - Double(apiServer.requestsRemaining)
			}
		} else if tv == snoozePresetsList {
			let allPresets = SnoozePreset.allSnoozePresets(in: DataManager.main)
			let preset = allPresets[row]
			cell.title = preset.listDescription
			let tc = c as! NSTextFieldCell
			tc.textColor = .textColor
		}
	}

	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		reloadRepositories()
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		if tableView === projectsTable {
			return repos.count
		} else if tableView === serverList {
			return ApiServer.countApiServers(in: DataManager.main)
		} else if tableView === snoozePresetsList {
			return SnoozePreset.allSnoozePresets(in: DataManager.main).count
		}
		return 0
	}

	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return nil
	}

	func tableView(_ tv: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
		if tv === projectsTable {
			let r = repos[row]
			if tableColumn?.identifier.rawValue == "group" {
                let g = S(object as? String)
                let newValue = g.isEmpty ? nil : g
                if newValue != r.groupLabel {
                    r.groupLabel = newValue
                    self.serversDirty = true
                    self.deferredUpdateTimer.push()
                }
                DispatchQueue.main.async {
                    self.windowController?.window?.makeFirstResponder(tv)
                }

			} else if let index = object as? Int64 {
				if tableColumn?.identifier.rawValue == "prs" {
					r.displayPolicyForPrs = index
				} else if tableColumn?.identifier.rawValue == "issues" {
					r.displayPolicyForIssues = index
				} else if tableColumn?.identifier.rawValue == "hide" {
					r.itemHidingPolicy = index
				}
				if index != RepoDisplayPolicy.hide.rawValue {
					r.resetSyncState()
				}
				updateDisplayIssuesSetting()
			}
		}
	}

	/////////////////////////////// snoozing

	@IBAction private func snoozeWakeChanged(_ sender: NSButton) {
		if let preset = selectedSnoozePreset {
			preset.wakeOnComment = snoozeWakeOnComment.integerValue == 1
			preset.wakeOnMention = snoozeWakeOnMention.integerValue == 1
			preset.wakeOnStatusChange = snoozeWakeOnStatusUpdate.integerValue == 1
			snoozePresetsList.reloadData()
			deferredUpdateTimer.push()
		}
	}

	@IBAction private func hideSnoozedItemsChanged(_ sender: NSButton) {
		Settings.hideSnoozedItems = hideSnoozedItems.integerValue == 1
		deferredUpdateTimer.push()
	}

	@IBAction private func countSnoozedItemsChanged(_ sender: NSButton) {
		Settings.countVisibleSnoozedItems = countSnoozedItems.integerValue == 1
		deferredUpdateTimer.push()
	}

	private func fillSnoozingDropdowns() {
		snoozeDurationDays.addItem(withTitle: "No Days")
		snoozeDurationHours.addItem(withTitle: "No Hours")
		snoozeDurationMinutes.addItem(withTitle: "No Minutes")

		snoozeDurationDays.addItem(withTitle: "1 Day")
		snoozeDurationHours.addItem(withTitle: "1 Hour")
		snoozeDurationMinutes.addItem(withTitle: "1 Minute")

		var titles = [String]()

		for f in 2..<400 {
			titles.append("\(f) Days")
		}
		snoozeDurationDays.addItems(withTitles: titles)
		titles.removeAll()
		for f in 2..<24 {
			titles.append("\(f) Hours")
		}
		snoozeDurationHours.addItems(withTitles: titles)
		titles.removeAll()
		for f in 2..<60 {
			titles.append("\(f) Minutes")
		}
		snoozeDurationMinutes.addItems(withTitles: titles)
		titles.removeAll()

		snoozeDateTimeDay.addItems(withTitles: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
		for f in 0..<24 {
			titles.append(String(format: "%02d", f))
		}
		snoozeDateTimeHour.addItems(withTitles: titles)
		titles.removeAll()
		for f in 0..<60 {
			titles.append(String(format: "%02d", f))
		}
		snoozeDateTimeMinute.addItems(withTitles: titles)

		if Settings.autoSnoozeDuration == 0 {
			autoSnoozeLabel.stringValue = "Do not auto-snooze items"
			autoSnoozeLabel.textColor = .disabledControlTextColor
		} else if Settings.autoSnoozeDuration == 1 {
			autoSnoozeLabel.stringValue = "Automatically snooze any item that has been idle for longer than a day"
			autoSnoozeLabel.textColor = .controlTextColor
		} else {
			autoSnoozeLabel.stringValue = "Automatically snooze any item that has been idle for longer than \(Settings.autoSnoozeDuration) days"
			autoSnoozeLabel.textColor = .controlTextColor
		}
		autoSnoozeSelector.integerValue = Settings.autoSnoozeDuration
	}

	@IBAction private func autoSnoozeDurationChanged(_ sender: NSStepper) {
		Settings.autoSnoozeDuration = sender.integerValue
		fillSnoozingDropdowns()
		for p in DataItem.allItems(of: PullRequest.self, in: DataManager.main) {
			p.wakeIfAutoSnoozed()
		}
		for i in DataItem.allItems(of: Issue.self, in: DataManager.main) {
			i.wakeIfAutoSnoozed()
		}
		deferredUpdateTimer.push()
	}

	var selectedSnoozePreset: SnoozePreset? {
		let selected = snoozePresetsList.selectedRow
		if selected >= 0 {
			return SnoozePreset.allSnoozePresets(in: DataManager.main)[selected]
		}
		return nil
	}

	private func fillSnoozeFormFromSelectedPreset() {
		if let s = selectedSnoozePreset {
			if s.duration {
				snoozeTypeDuration.integerValue = 1
				snoozeTypeDateTime.integerValue = 0
				snoozeDurationMinutes.isEnabled = true
				snoozeDurationHours.isEnabled = true
				snoozeDurationDays.isEnabled = true
				snoozeDurationMinutes.selectItem(at: Int(s.minute))
				snoozeDurationHours.selectItem(at: Int(s.hour))
				snoozeDurationDays.selectItem(at: Int(s.day))
				snoozeDateTimeMinute.isEnabled = false
				snoozeDateTimeMinute.selectItem(at: 0)
				snoozeDateTimeHour.isEnabled = false
				snoozeDateTimeHour.selectItem(at: 0)
				snoozeDateTimeDay.isEnabled = false
				snoozeDateTimeDay.selectItem(at: 0)
			} else {
				snoozeTypeDuration.integerValue = 0
				snoozeTypeDateTime.integerValue = 1
				snoozeDurationMinutes.isEnabled = false
				snoozeDurationMinutes.selectItem(at: 0)
				snoozeDurationHours.isEnabled = false
				snoozeDurationHours.selectItem(at: 0)
				snoozeDurationDays.isEnabled = false
				snoozeDurationDays.selectItem(at: 0)
				snoozeDateTimeMinute.isEnabled = true
				snoozeDateTimeHour.isEnabled = true
				snoozeDateTimeDay.isEnabled = true
				snoozeDateTimeMinute.selectItem(at: Int(s.minute))
				snoozeDateTimeHour.selectItem(at: Int(s.hour))
				snoozeDateTimeDay.selectItem(at: Int(s.day))
			}
			snoozeWakeOnComment.isEnabled = true
			snoozeWakeOnComment.integerValue = s.wakeOnComment ? 1 : 0
			snoozeWakeOnMention.isEnabled = true
			snoozeWakeOnMention.integerValue = s.wakeOnMention ? 1 : 0
			snoozeWakeOnStatusUpdate.isEnabled = true
			snoozeWakeOnStatusUpdate.integerValue = s.wakeOnStatusChange ? 1 : 0
			snoozeWakeLabel.textColor = .controlTextColor
			snoozeTypeDuration.isEnabled = true
			snoozeTypeDateTime.isEnabled = true
			snoozeDeletePreset.isEnabled = true
			snoozeUp.isEnabled = true
			snoozeDown.isEnabled = true
		} else {
			snoozeTypeDuration.isEnabled = false
			snoozeTypeDateTime.isEnabled = false
			snoozeDateTimeMinute.isEnabled = false
			snoozeDateTimeHour.isEnabled = false
			snoozeDateTimeDay.isEnabled = false
			snoozeDurationMinutes.isEnabled = false
			snoozeDurationHours.isEnabled = false
			snoozeDurationDays.isEnabled = false
			snoozeDeletePreset.isEnabled = false
			snoozeUp.isEnabled = false
			snoozeDown.isEnabled = false
			snoozeWakeOnComment.isEnabled = false
			snoozeWakeOnComment.integerValue = 0
			snoozeWakeOnMention.isEnabled = false
			snoozeWakeOnMention.integerValue = 0
			snoozeWakeOnStatusUpdate.isEnabled = false
			snoozeWakeOnStatusUpdate.integerValue = 0
			snoozeWakeLabel.textColor = .disabledControlTextColor
		}
	}

	private func commitSnoozeSettings() {
		snoozePresetsList.reloadData()
		deferredUpdateTimer.push()
		Settings.possibleExport(nil)
	}

	@IBAction private func createNewSnoozePresetSelected(_ sender: NSButton) {
		let s = SnoozePreset.newSnoozePreset(in: DataManager.main)
		commitSnoozeSettings()
		if let index = SnoozePreset.allSnoozePresets(in: DataManager.main).firstIndex(of: s) {
			snoozePresetsList.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
			fillSnoozeFormFromSelectedPreset()
		}
	}

	@IBAction private func deleteSnoozePresetSelected(_ sender: NSButton) {
		if let selectedPreset = selectedSnoozePreset, let index = SnoozePreset.allSnoozePresets(in: DataManager.main).firstIndex(of: selectedPreset) {

			let appliedCount = selectedPreset.appliedToIssues.count + selectedPreset.appliedToPullRequests.count
			if appliedCount > 0 {
				let alert = NSAlert()
				alert.messageText = "Warning"
				alert.informativeText = "You have \(appliedCount) items that have been snoozed using this preset. What would you like to do with them?"
				alert.addButton(withTitle: "Cancel")
				alert.addButton(withTitle: "Wake Them Up")
				alert.addButton(withTitle: "Keep Them Snoozed")
				alert.beginSheetModal(for: self) { response in
					switch response {
					case .alertFirstButtonReturn:
						break
					case .alertSecondButtonReturn:
						selectedPreset.wakeUpAllAssociatedItems()
						fallthrough
					case .alertThirdButtonReturn:
						self.completeSnoozeDelete(for: selectedPreset, index)
					default: break
					}
				}
			} else {
				completeSnoozeDelete(for: selectedPreset, index)
			}
		}
	}

	private func completeSnoozeDelete(for selectedPreset: SnoozePreset, _ index: Int) {
		DataManager.main.delete(selectedPreset)
		commitSnoozeSettings()
		snoozePresetsList.selectRowIndexes(IndexSet(integer: min(index, snoozePresetsList.numberOfRows-1)), byExtendingSelection: false)
		fillSnoozeFormFromSelectedPreset()
	}

	@IBAction private func snoozeTypeChanged(_ sender: NSButton) {
		if let s = selectedSnoozePreset {
			s.duration = sender == snoozeTypeDuration
			fillSnoozeFormFromSelectedPreset()
			commitSnoozeSettings()
		}
	}

	@IBAction private func snoozeOptionsChanged(_ sender: NSPopUpButton) {
		if let s = selectedSnoozePreset {
			if s.duration {
				s.day = Int64(snoozeDurationDays.indexOfSelectedItem)
				s.hour = Int64(snoozeDurationHours.indexOfSelectedItem)
				s.minute = Int64(snoozeDurationMinutes.indexOfSelectedItem)
			} else {
				s.day = Int64(snoozeDateTimeDay.indexOfSelectedItem)
				s.hour = Int64(snoozeDateTimeHour.indexOfSelectedItem)
				s.minute = Int64(snoozeDateTimeMinute.indexOfSelectedItem)
			}
			commitSnoozeSettings()
		}
	}

	@IBAction private func snoozeUpSelected(_ sender: NSButton) {
		if let this = selectedSnoozePreset {
			let all = SnoozePreset.allSnoozePresets(in: DataManager.main)
			if let index = all.firstIndex(of: this), index > 0 {
				let other = all[index-1]
				other.sortOrder = Int64(index)
				this.sortOrder = Int64(index-1)
				snoozePresetsList.selectRowIndexes(IndexSet(integer: index-1), byExtendingSelection: false)
				commitSnoozeSettings()
			}
		}
	}

	@IBAction private func snoozeDownSelected(_ sender: NSButton) {
		if let this = selectedSnoozePreset {
			let all = SnoozePreset.allSnoozePresets(in: DataManager.main)
			if let index = all.firstIndex(of: this), index < all.count-1 {
				let other = all[index+1]
				other.sortOrder = Int64(index)
				this.sortOrder = Int64(index+1)
				snoozePresetsList.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
				commitSnoozeSettings()
			}
		}
	}

	private var advancedReposWindowController: NSWindowController?
	private var advancedReposWindow: AdvancedReposWindow?
	@IBAction private func advancedSelected(_ sender: NSButton) {
		if advancedReposWindowController == nil {
			advancedReposWindowController = NSWindowController(windowNibName:NSNib.Name("AdvancedReposWindow"))
		}
		if let w = advancedReposWindowController?.window as? AdvancedReposWindow {
			w.prefs = self
			w.level = .floating
			w.center()
			w.makeKeyAndOrderFront(self)
			advancedReposWindow = w
		}
	}
	func closedAdvancedWindow() {
		advancedReposWindow = nil
		advancedReposWindowController = nil
	}

}

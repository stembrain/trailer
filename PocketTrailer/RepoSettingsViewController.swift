import UIKit

final class RepoSettingsViewController: UITableViewController, UITextFieldDelegate {

	var repo: Repo?

	private var allPrsIndex = -1
	private var allIssuesIndex = -1
	private var allHidingIndex = -1

	@IBOutlet weak var groupField: UITextField!
	@IBOutlet weak var repoNameTitle: UILabel!

	private var settingsChangedTimer: PopTimer!

	override func viewDidLoad() {
		super.viewDidLoad()
		if repo == nil {
			repoNameTitle.text = "All Repositories (You don't need to pick values for each setting below, you can set only a specific setting if you prefer)"
			groupField.isHidden = true
		} else {
			repoNameTitle.text = repo?.fullName
			groupField.text = repo?.groupLabel
		}
		settingsChangedTimer = PopTimer(timeInterval: 1.0) {
			DataManager.postProcessAllItems()
			DataManager.saveDB()
		}
	}

	override func viewDidLayoutSubviews() {
		if let s = tableView.tableHeaderView?.systemLayoutSizeFitting(CGSize(width: tableView.bounds.size.width, height: 500)) {
			tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: s.height)
		}
		super.viewDidLayoutSubviews()
	}


	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 2 {
			return RepoHidingPolicy.labels.count
		}
		return RepoDisplayPolicy.labels.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
		if repo == nil {
			switch indexPath.section {
			case 0:
				cell.accessoryType = (allPrsIndex==indexPath.row) ? .checkmark : .none
				cell.textLabel?.text = RepoDisplayPolicy.labels[indexPath.row]
				cell.textLabel?.textColor = RepoDisplayPolicy.colors[indexPath.row]
			case 1:
				cell.accessoryType = (allIssuesIndex==indexPath.row) ? .checkmark : .none
				cell.textLabel?.text = RepoDisplayPolicy.labels[indexPath.row]
				cell.textLabel?.textColor = RepoDisplayPolicy.colors[indexPath.row]
			case 2:
				cell.accessoryType = (allHidingIndex==indexPath.row) ? .checkmark : .none
				cell.textLabel?.text = RepoHidingPolicy.labels[indexPath.row]
				cell.textLabel?.textColor = RepoHidingPolicy.colors[indexPath.row]
			default: break
			}
		} else {
			switch indexPath.section {
			case 0:
				cell.accessoryType = (Int(repo?.displayPolicyForPrs ?? 0)==indexPath.row) ? .checkmark : .none
				cell.textLabel?.text = RepoDisplayPolicy.labels[indexPath.row]
				cell.textLabel?.textColor = RepoDisplayPolicy.colors[indexPath.row]
			case 1:
				cell.accessoryType = (Int(repo?.displayPolicyForIssues ?? 0)==indexPath.row) ? .checkmark : .none
				cell.textLabel?.text = RepoDisplayPolicy.labels[indexPath.row]
				cell.textLabel?.textColor = RepoDisplayPolicy.colors[indexPath.row]
			case 2:
				cell.accessoryType = (Int(repo?.itemHidingPolicy ?? 0)==indexPath.row) ? .checkmark : .none
				cell.textLabel?.text = RepoHidingPolicy.labels[indexPath.row]
				cell.textLabel?.textColor = RepoHidingPolicy.colors[indexPath.row]
			default: break
			}
		}
		cell.selectionStyle = cell.accessoryType == .checkmark ? .none : .default
		return cell
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0: return "Pull Request Sections"
		case 1: return "Issue Sections"
		case 2: return "Author Based Hiding"
		default: return nil
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if repo == nil {
			let repos = Repo.allItems(ofType: "Repo", in: mainObjectContext) as! [Repo]
			if indexPath.section == 0 {
				allPrsIndex = indexPath.row
				for r in repos {
					r.displayPolicyForPrs = Int64(allPrsIndex)
					if allPrsIndex != RepoDisplayPolicy.hide.intValue {
						r.resetSyncState()
					}
				}
			} else if indexPath.section == 1 {
				allIssuesIndex = indexPath.row
				for r in repos {
					r.displayPolicyForIssues = Int64(allIssuesIndex)
					if allIssuesIndex != RepoDisplayPolicy.hide.intValue {
						r.resetSyncState()
					}
				}
			} else {
				allHidingIndex = indexPath.row
				for r in repos {
					r.itemHidingPolicy = Int64(allHidingIndex)
				}
			}
		} else if indexPath.section == 0 {
			repo?.displayPolicyForPrs = Int64(indexPath.row)
			if indexPath.row != RepoDisplayPolicy.hide.intValue {
				repo?.resetSyncState()
			}
		} else if indexPath.section == 1 {
			repo?.displayPolicyForIssues = Int64(indexPath.row)
			if indexPath.row != RepoDisplayPolicy.hide.intValue {
				repo?.resetSyncState()
			}
		} else {
			repo?.itemHidingPolicy = Int64(indexPath.row)
		}
		tableView.reloadData()
		preferencesDirty = true
		DataManager.saveDB()
		settingsChangedTimer.push()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		let newText = (groupField.text?.isEmpty ?? true) ? nil : groupField.text
		if let r = repo, r.groupLabel != newText {
			r.groupLabel = newText
			preferencesDirty = true
			DataManager.saveDB()
			settingsChangedTimer.push()
		}
	}

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if string == "\n" {
			textField.resignFirstResponder()
			return false
		}
		return true
	}
}

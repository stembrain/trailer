
import UIKit

class SectionHeaderView: UITableViewHeaderFooterView {

	@IBOutlet var title: UILabel!
	@IBOutlet var action: UIButton!

	var callback: Completion?

	@IBAction private func buttonSelected(_ sender: UIButton) {
		callback?()
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		action.setTitleColor(UIColor(named: "apptint"), for: .normal)
	}

}

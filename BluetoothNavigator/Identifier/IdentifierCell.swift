
import UIKit

// TODO: Consider whether or not an ordinary UITablewViewCell will suffice.
class IdentifierCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var uuid: UILabel! {
        didSet {
            uuid.font = uuid.font.monospacedDigitFont
        }
    }
}

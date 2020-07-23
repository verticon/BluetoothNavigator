
import UIKit
import VerticonsToolbox

class BluetoothCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        let gradientView = GradientView()
        backgroundView = gradientView

        tintColor = .bluetoothBlue

        func setup(view: UIView) {
            for subview in view.subviews {
                if let label = subview as? UILabel {
                    label.textColor = .bluetoothBlue
                    label.adjustsFontSizeToFitWidth = true
                    label.minimumScaleFactor = 0.1
                }
                else {
                    setup(view: subview)
                }
            }
        }

        setup(view: self)
    }

    func prepareDisclosureIndicator() {
        // Cause the disclosure indicator to inherit the cell's tint color
        for case let button as UIButton in subviews {
            let image = button.backgroundImage(for: .normal)?.withRenderingMode(.alwaysTemplate)
            button.setBackgroundImage(image, for: .normal)
        }
    }
}

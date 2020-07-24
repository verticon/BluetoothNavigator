
import UIKit

@IBDesignable class BluetoothNavigatorView: UIView {

    override func awakeFromNib() {
        setup()
    }

   override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func prepareForInterfaceBuilder() {
        setup()
    }

    private func setup() {
    }
}

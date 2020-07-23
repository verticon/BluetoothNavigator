
import UIKit

class DescriptorCell: BluetoothCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!

    func update(with descriptor: Descriptor) {
        nameLabel.text = descriptor.id.name
        valueLabel.text = "\(descriptor.cbDescriptor?.value ?? "<unknown value>")"
    }
}

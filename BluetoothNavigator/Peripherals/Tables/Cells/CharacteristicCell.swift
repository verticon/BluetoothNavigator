
import UIKit

class CharacteristicCell: BluetoothCell {

    @IBOutlet private weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.textColor = .bluetoothBlue
    }

    func update(with characteristic: Characteristic) {
        nameLabel.text = characteristic.name
    }
}

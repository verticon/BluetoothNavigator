
import UIKit

class CharacteristicCell: BluetoothCell {

    @IBOutlet private weak var nameLabel: UILabel!

    func update(with characteristic: Characteristic) {
        nameLabel.text = characteristic.name
    }
}

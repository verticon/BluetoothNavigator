
import UIKit
import MoBetterBluetooth

class SubscriptionCell: BluetoothCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.textColor = .bluetoothBlue
        infoLabel.textColor = .bluetoothBlue
    }

    func update(with manager: CentralManager) {
        nameLabel.text = manager.name
        infoLabel.text = "\(manager.isScanning ? "Scanning" : "Not scanning") - \(manager.peripherals.count) peripherals"
        accessoryView?.tintColor = .bluetoothBlue //
    }
}

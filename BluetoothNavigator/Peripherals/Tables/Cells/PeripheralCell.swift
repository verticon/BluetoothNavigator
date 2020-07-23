
import UIKit
import MoBetterBluetooth

class PeripheralCell: BluetoothCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var data: UILabel!
    @IBOutlet weak var rssiValue: UILabel!
    @IBOutlet weak var rssiGraph: RssiGraph!
    @IBOutlet weak var connectedImage: UIImageView!

    func update(with peripheral: Peripheral) {
        name.text = peripheral.name
        updateLocationData(using: peripheral)
        updateRssiData(using: peripheral)
        updateReceptionData(using: peripheral)
    }

    func updateLocationData(using peripheral: CentralManager.Peripheral) {
        data?.text = "\(peripheral.discoveryTime) @\(peripheral.discoveryLocation ?? "")"
    }
    
    func updateRssiData(using peripheral: CentralManager.Peripheral) {
        rssiGraph.rssi =  peripheral.rssi.intValue
        rssiValue?.text = getRssiText(for: peripheral)
    }
    
    func updateReceptionData(using peripheral: CentralManager.Peripheral) {
        rssiGraph.receptionState =  peripheral.receptionState
        rssiValue?.text = getRssiText(for: peripheral)
        connectedImage.isHidden = peripheral.receptionState != .connected
    }

    func getRssiText(for peripheral: CentralManager.Peripheral) -> String {
        switch peripheral.receptionState {
        case .receiving:
            return peripheral.rssi.int32Value.description
        default:
            return ""
        }
    }
}

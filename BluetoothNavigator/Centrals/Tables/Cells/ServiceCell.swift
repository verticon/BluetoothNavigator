
import UIKit
import MoBetterBluetooth
import VerticonsToolbox

class ServiceCell: BluetoothCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var uuidLabel: UILabel!
    @IBOutlet private weak var dropDownButton: UIButton!

    private var uuidLabelZeroHeightConstraint: NSLayoutConstraint!

    weak private var tableView: UITableView?
    weak private var service: Service?

    override func awakeFromNib() {
        super.awakeFromNib()

        uuidLabelZeroHeightConstraint = NSLayoutConstraint(item: uuidLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)

        nameLabel.textColor = .bluetoothBlue
        uuidLabel.textColor = .bluetoothBlue
        dropDownButton.tintColor = .bluetoothBlue
    }

    func update(using service: Service, and table: UITableView) {
        self.tableView = table
        self.service = service

        nameLabel.text? = service.name
        
        if service.name != service.id.uuid.uuidString {
            uuidLabel.text? = service.id.uuid.uuidString

            dropDownButton.isHidden = false
            if service.collapsed { collapse() }
            else { expand() }
        }
        else {
            dropDownButton.isHidden = true
            collapse()
        }
    }
    
    var collapsed: Bool {
        return dropDownButton.transform == CGAffineTransform.identity
    }
    
    private func collapse() {
        dropDownButton.transform = CGAffineTransform.identity
        uuidLabel.addConstraint(uuidLabelZeroHeightConstraint)
        service?.collapsed = true
    }

    private func expand() {
        dropDownButton.transform = CGAffineTransform(rotationAngle: .pi)
        uuidLabel.removeConstraint(uuidLabelZeroHeightConstraint)
        service?.collapsed = false
    }

    @IBAction private func dropDownHandler(_ sender: UIButton) {
        if collapsed { expand() }
        else { collapse() }

        tableView?.reloadData()
    }
}

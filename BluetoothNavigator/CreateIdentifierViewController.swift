
import UIKit
import AudioToolbox
import CoreBluetooth
import VerticonsToolbox
import MoBetterBluetooth

class CreateIdentifierViewController: UITableViewController {
    
    private(set) var name: String?
    private(set) var uuid: CBUUID?

    @IBOutlet weak fileprivate var nameTextField: UITextField!
    
    @IBOutlet weak fileprivate var uuidTextField: UITextField! {
        didSet {
            HexadecimalKeypad.setup(forTextField: uuidTextField, withDelegate: self)
        }
    }
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.tintColor = UIColor.navigationBarTint
        nameTextField.becomeFirstResponder()
    }

    // Within the TableCell there is a small margin arround the TextField.
    // Ensure that the TextField becomes the keyboard target even if the user taps in that margin.
    // Also, tapping in that margin will select the cell causing it to become highlighted. So, deselect it.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            nameTextField.becomeFirstResponder()
        }
        else {
            uuidTextField.becomeFirstResponder()
        }

        if let selectedIndex = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndex, animated: false)
        }
    }
    

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard identifier == "Save" else { return true }

        name = nameTextField.text
        let nameValid = name != nil && name!.count > 0
        if !nameValid {
            nameTextField.borderColor = .red
            nameTextField.borderWidth = 1.0
        }
        
        let uuidValid = uuidTextField.text != nil && [4,8,36].contains(uuidTextField.text!.count) // 16, 32, or 128 bit uuid
        if uuidValid { // 16, 32, or 128 bit uuid
            self.uuid = CBUUID(string: uuidTextField.text!)
        }
        else {
            uuidTextField.borderColor = .red
            uuidTextField.borderWidth = 1.0
        }

        return nameValid && uuidValid
    }
}

extension CreateIdentifierViewController : HexadecimalKeypadDelegate {

    func newKey(_ key: HexadecimalKey) {
         // 00000000-0000-0000-0000-000000000000
        let uuidDashIndices = [8, 13, 18, 23]
        let maxCount = 36

        if (uuidTextField.text == nil) { uuidTextField.text = "" }

        let count = uuidTextField.text!.count
        
        switch key {
        case .del:
            if count > 0 {
                uuidTextField.text = String(uuidTextField.text!.dropLast())
                if uuidTextField.text!.hasSuffix("-") {
                    uuidTextField.text = String(uuidTextField.text!.dropLast())
                }
            }
        case .done:
            uuidTextField.endEditing(true)
        default:
            if count < maxCount {
                if uuidDashIndices.contains(count) {
                    uuidTextField.text!.append("-")
                }
                uuidTextField.text!.append(key.toString())
            }
        }
    }
}

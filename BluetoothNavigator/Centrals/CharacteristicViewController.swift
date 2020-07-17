
import UIKit
import MoBetterBluetooth
import VerticonsToolbox

// TODO: Display a count of the number of bytes in the data.
// TODO: Revisit the "Extended Properties" property.
class CharacteristicViewController: UIViewController {

    var characteristic: Characteristic! // The presenting VC will set it
    @IBOutlet weak private var characteristicName: UILabel!

    @IBOutlet weak var propertiesDropDown: DropDownListBarButton!

    @IBOutlet weak private var controls: UIStackView!
    @IBOutlet weak private var formatControls: UIStackView!

    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var writeButton: UIButton!
    @IBOutlet weak var notifySwitch: TitledSwitch!

    @IBOutlet weak private var value: UITextView!

    @IBOutlet weak private var stringButton: RadioButton!
    @IBOutlet weak var numberButton: RadioButton!
    private var valueTypeButtonGroup: RadioButtonGroup!

    @IBOutlet weak private var stringEncodingButton: DropDownMenuButton!
    @IBOutlet weak var numberTypeButton: DropDownMenuButton!

    @IBOutlet weak var hexButton: RadioButton!
    @IBOutlet weak var decimalButton: RadioButton!
    private var radixButtonGroup: RadioButtonGroup!

    @IBOutlet weak private var discoverDescriptors: UIButton!
    @IBOutlet weak fileprivate var descriptorTable: UITableView!

    private var managerEventListener: ListenerManagement?
    private var peripheralEventListener: ListenerManagement?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        characteristicName.text = characteristic.name

        readButton.isEnabled = characteristic.isReadable
        writeButton.isEnabled = characteristic.isWriteable
        value.isEditable = characteristic.isWriteable
        notifySwitch.isEnabled = characteristic.isNotifiable

        setupDiscoverDescriptorsButton()

        setupFormatButtons()

        let _ = propertiesDropDown.setList(items: characteristic.properties.all)

        controls.addHorizontalSeparators(color: .black)

        //self.automaticallyAdjustsScrollViewInsets = false // Else there will be space at the top and bottom and scrolling will be needed to see the text that appears in the middle.
        //self.contentInsetAdjustmentBehavior = .never

        let accessoryToolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        accessoryToolbar.items = [doneButton]
        accessoryToolbar.sizeToFit()
        value.inputAccessoryView = accessoryToolbar
        _ = displayValue()
        value.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isMovingToParent { // Pushed to the navigation stack
            managerEventListener = characteristic.parent.parent.manager.addListener(self, handlerClassMethod: CharacteristicViewController.managerEventHandler)
            peripheralEventListener = characteristic.parent.parent.addListener(self, handlerClassMethod: CharacteristicViewController.peripheralEventHandler)
            if characteristic.descriptorsDiscovered {
                characteristic.descriptors.forEach { readDescriptor($0) }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {  // Popped from the navigation stack
            managerEventListener?.removeListener()
            peripheralEventListener?.removeListener()
        }
    }

    @IBAction func readButtonHandler(_ sender: UIButton) {
        dismissKeyboard()
        
        value.text = ""

        let marchingAntsBorder = MarchingAntsRect(bounds: value.bounds, color: value.borderColor!)

        let processResult: (Characteristic.ReadResult) -> () = { result in
            switch result {
            case .success: _ = self.displayValue()
            case .failure(let error): alertUser(title: "Read Error", body: String(describing: error))
            }

            try? marchingAntsBorder.uninstall()
            self.readButton.isEnabled = self.characteristic.isReadable
            self.writeButton.isEnabled = self.characteristic.isWriteable
            self.value.isEditable = self.characteristic.isWriteable
        }
    
        if case .failure(let error) = characteristic.read(processResult) {
            alertUser(title: "Cannot Read", body: String(describing: error))
        }
        else {
            try? marchingAntsBorder.install(in: value)
            try? marchingAntsBorder.startMarching()
            readButton.isEnabled = false
            writeButton.isEnabled = false
            value.isEditable = false
        }
    }

    @IBAction func notifySwitchHandler(_ sender: TitledSwitch) {
        dismissKeyboard()

        let notificationHandler = { (result: CentralManager.Characteristic.ReadResult) in
            switch result {
            case .success:
                let originalColor = self.value.textColor!

                func blink(millisecondsDelay: Int, repetitions: Int) {
                    guard repetitions > 0 else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millisecondsDelay)) {
                        self.value.textColor = self.value.textColor == originalColor ? UIColor.darkText : originalColor
                        let remaining = self.value.textColor == originalColor ? repetitions - 1 : repetitions
                        blink(millisecondsDelay: millisecondsDelay, repetitions: remaining)
                   }
                }
    
                if self.displayValue(wasNotification: true) { blink(millisecondsDelay: 300, repetitions: 4) }
                
            case .failure(let error):
                alertUser(title: "Notification Error", body: String(describing: error))
            }
        }

        if case .failure(let error) = characteristic.notify(enabled: sender.isOn, handler: notificationHandler) {
            alertUser(title: "Cannot Turn \(sender.isOn ? "On" : "Off") Notifications", body: String(describing: error))
        }
    }

    @IBAction func writeButtonHandler(_ sender: UIButton) {
        dismissKeyboard()

        guard (value.text?.count)! > 0 else {
            alertUser(title: "No Value", body: "Please provide the value to be written")
            return
        }
        
        var data: Data?

        if numberButton.isPressed {
            let numericType = numberTypeButton.selectedItem as! NumericType
            data = numericType.valueToData(value: value.text)
            if data == nil {
                alertUser(title: "Invalid \(numericType.name)", body: value.text)
            }
        }
        else if stringButton.isPressed {
            let encoding = (stringEncodingButton.selectedItem as! StringEncoding).rawValue
            data = Data(with: value.text!, using: encoding)
        }
        
        if let data = data {
            let marchingAntsBorder = MarchingAntsRect(bounds: value.bounds, color: value.borderColor!)

            let handler = { (status: PeripheralStatus) -> Void in
                try? marchingAntsBorder.uninstall()

                if case .failure(let error) = status {
                    alertUser(title: "Write Error", body: String(describing: error))
                }
            }

            if case .failure(let error) = characteristic.write(data, completionHandler: handler) {
                alertUser(title: "Cannot Write", body: String(describing: error))
            }
            else {
                try? marchingAntsBorder.install(in: value)
                try? marchingAntsBorder.startMarching()
            }
        }
    }
    
    @IBAction func discoverDescriptorsButtonHandler(_ sender: UIButton) {
        dismissKeyboard()

        if case let .failure(error) = characteristic.discoverDescriptors() {
            alertUser(title: "Cannot Discover Descriptors", body: String(describing: error))
        }

        setupDiscoverDescriptorsButton()
    }

    fileprivate func readDescriptor(_ descriptor: CentralManager.Descriptor) {
        if case let .failure(error) = descriptor.read( { result in
            switch result {
            case .success:
                if (descriptor.id.uuid.uuidString == CharacteristicUserDescriptionUUID.uuidString) { self.characteristicName.text = self.characteristic.name }
                self.descriptorTable.reloadData()
            case let .failure(.descriptorReadError(_, error)):
                alertUser(title: "Descriptor Read Error", body: "\(descriptor.name): \(error)")
            case let .failure(error):
                alertUser(title: "Descriptor Read Error", body: "\(descriptor.name): \(error)")
            }
        }) {
            alertUser(title: "Descriptor Read Error", body: "\(descriptor.name): \(error)")
        }
    }
    
    private func managerEventHandler(_ event: CentralManagerEvent) {
        switch event {
            
        case let .error(.peripheralDisconnected(_, cbError)):
            alertUser(title: "Peripheral \(characteristic.parent.parent.name) Disconnected", body: String(describing: cbError)) { action in
                self.performSegue(withIdentifier: "ExitOnDisconnect", sender: self)
            }
            
        default:
            break
        }
    }
    
    private func peripheralEventHandler(_ event: PeripheralEvent) {
        switch event {
            
        case .descriptorsDiscovered:
            setupDiscoverDescriptorsButton()
            descriptorTable.reloadData()
            characteristic.descriptors.forEach { readDescriptor($0) }

        default:
            break
        }
    }

    private func displayValue(wasNotification: Bool = false) -> Bool {
        guard let data = characteristic.cbCharacteristic?.value else {
            value.text = "<no value>"
            return true
        }

        guard data.count > 0 else {
            value.text = "<zero bytes>"
            return true
        }

        value.text = ""
        var status = true

        if numberButton.isPressed {
            let numericType = numberTypeButton.selectedItem as! NumericType
            if let value = numericType.valueFromData(data: data, hex: hexButton.isPressed) {
                self.value.text = value
            }
            else {
                alertUser(title: "Not a Valid \(numericType.name)", body: data.toHexString(seperator: " "))
                status = false
            }
        }
        else if stringButton.isPressed {
            let encoding = stringEncodingButton.selectedItem as! StringEncoding
            let data = data.withoutTrailingZeros()
            if let decoded = String(data: data, encoding: encoding.rawValue) {
                value.text = decoded.count > 0 ? decoded : "<empty string>"

                // NOTE: The size of notification data is limited by the size of the
                // MTU on the sending side. Apparantly the default value is 20 bytes.
                // TODO: What is the "right" way to deal with this?
                if wasNotification && data.count == 20 {
                    alertUser(title: "Data Truncation Warning", body: "20 bytes of notification data was received. It might have been truncated.")
                }
            }
            else {
                alertUser(title: "Not a Valid \(encoding.name) String", body: data.toHexString(seperator: " "))
                status = false
            }
        }

        return status
    }

    private func setupDiscoverDescriptorsButton() {
        
        discoverDescriptors.isEnabled = false
        discoverDescriptors.borderWidth = 0
        discoverDescriptors.titleLabel?.textAlignment = .center
        if characteristic.descriptorsDiscovered {
            discoverDescriptors.titleLabel?.numberOfLines = 0
            discoverDescriptors.setTitle("Descriptors\n<tap an entry to refresh it>", for: .disabled)
        }
        else if characteristic.descriptorDiscoveryInProgress {
            discoverDescriptors.setTitle("<Discovering Descriptors>", for: .disabled)
        }
        else {
            discoverDescriptors.isEnabled = true
            discoverDescriptors.borderWidth = 1
            discoverDescriptors.setTitle("Discover Descriptors", for: .normal)
        }
    }
    
    // TODO: Remember which formatting choices were made the last time that this characteristic was displayed.
    // TODO: Setup numeric keyboards when the numeric button is selected.
    private func setupFormatButtons() {

        func changeHandler() {
            dismissKeyboard()
            
            value.text = ""
            displayValue()
            
            reconfigure()
        }
        
        func reconfigure() {
            self.stringEncodingButton.isHidden = !self.stringButton.isPressed
            self.numberTypeButton.isHidden = !self.numberButton.isPressed
            self.radixButtonGroup.set(hidden: !self.numberButton.isPressed)

            /*
            for control in formatControls.arrangedSubviews { formatControls.removeArrangedSubview(control) }
            if numberButton.isPressed {
                formatControls.addArrangedSubview(numberTypeButton)
                formatControls.addArrangedSubview(hexButton)
                formatControls.addArrangedSubview(decimalButton)
            }
            else if stringButton.isPressed {
                formatControls.addArrangedSubview(stringEncodingButton)
            }
 */
        }
        

        let _ = numberTypeButton.setMenu(items: NumericType.all, initialSelection: NumericType.uint8.index) { type in

            changeHandler()

            let numericType = type as! NumericType
            if numericType == .float || numericType == .double {
                self.radixButtonGroup.set(enabled: false)
                self.radixButtonGroup.set(selected: self.decimalButton)
            }
        }

        let _ = stringEncodingButton.setMenu(items: StringEncoding.all, initialSelection: StringEncoding(rawValue: .utf8)!.index!) { _ in changeHandler() }

        valueTypeButtonGroup = RadioButtonGroup(buttons: stringButton, numberButton, initialSelection: numberButton) { _ in changeHandler() }

        radixButtonGroup = RadioButtonGroup(buttons: decimalButton, hexButton, initialSelection: decimalButton) { _ in changeHandler() }

        reconfigure()
    }
        
    @objc private func dismissKeyboard() {
        value.resignFirstResponder()
    }
}

extension CharacteristicViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characteristic.descriptors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let descriptor = characteristic[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptorCell")! as! DescriptorCell
        cell.update(with: descriptor)
        return cell
    }
}

extension CharacteristicViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        readDescriptor(characteristic[indexPath.item])
    }
}

extension CharacteristicViewController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if value.text.starts(with: "<") { value.text = "" } // Hmmmm ... kludgy
    }
}

extension Data {
    func withoutTrailingZeros() -> Data {
        var length = 0
        for byte in self {
            if byte == 0 { break }
            length += 1
        }
        var data = self
        if length < data.count { data = data.dropLast(data.count - length) }
        return data
    }
}

extension UIStackView {

    func addHorizontalSeparators(color : UIColor) {
        var i = self.arrangedSubviews.count - 1
        while i > 0 {
            let separator = createSeparator(color: color)
            insertArrangedSubview(separator, at: i)
            separator.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8).isActive = true
            i -= 1
        }
    }

    private func createSeparator(color : UIColor) -> UIView {
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.backgroundColor = color
        return separator
    }
}

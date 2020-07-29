
import UIKit
import VerticonsToolbox
import MoBetterBluetooth

// TODO: With the Characteristcs screen up, force a disconnect.
// Insure that the Peripheral view updates correctly.
class PeripheralViewController : BluetoothNavigatorViewController {

    var peripheral: Peripheral! // The presenting controller will set it.
    private var peripheralEventListener: ListenerManagement?

    @IBOutlet weak var advertismentDropDown: DropDownListBarButton!

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet weak private var connect: UIButton!

    @IBOutlet weak fileprivate var servicesTable: BluetoothNavigatorTableView!
    @IBOutlet weak private var discoverServices: UIButton!
    fileprivate var selectedService: Service?
    fileprivate let serviceCellReuseId = "ServiceCell"

    // What is displayed in the characteristics table is determined by which service is selected in the services table
    @IBOutlet weak fileprivate var characteristicsTable: BluetoothNavigatorTableView!
    @IBOutlet weak fileprivate var discoverCharacteristics: UIButton!
    fileprivate let characteristicCellReuseId = "CharacteristicCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text = peripheral.name // Event though we have replaced the title view, we still need this for the back button

        let nib = UINib(nibName: String(describing: ServiceCell.self), bundle: Bundle(for: ServiceCell.self))
        servicesTable.register(nib, forCellReuseIdentifier: serviceCellReuseId)

        BluetoothNavigatorTheme.setDropDownColors(of: advertismentDropDown)
        advertismentDropDown.setList(title: "Advertising Data", items: peripheral.advertisement.list ?? ["<no advertisements>"])
        advertismentDropDown.size *= 2

        servicesTable.name = "Services"
        characteristicsTable.name = "Charateristics"

        setupButtons()

        discoverCharacteristics.titleLabel?.adjustsFontSizeToFitWidth = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isMovingToParent { // Pushed to the navigation stack
            peripheralEventListener = peripheral.addListener(self, handlerClassMethod: PeripheralViewController.peripheralEventHandler)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {  // Popped from the navigation stack
            peripheralEventListener?.removeListener()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
            
        case let (characteristicVC as CharacteristicViewController, cell as UITableViewCell):
            characteristicVC.characteristic = selectedService![characteristicsTable.indexPath(for: cell)!.row]

        default:
            print("Unrecognized segue to \(segue.destination) from \(String(describing: sender))")
        }
    }
    
    // TODO: Consider using the completion handler
    @IBAction func toggeleConnect(_ sender: UIButton) {
        let status: PeripheralStatus
        let operation: String
        
        if peripheral.cbPeripheral.state == .connected {
            operation = "Disconnect"
            status = peripheral.disconnect(completionhandler: nil)
        }
        else {
            operation = "Connect"
            status = peripheral.connect( completionhandler: nil)
        }

        if case .failure = status {
            alertUser(title: "Cannot \(operation)", body: String(describing: status))
        }
    }

    @IBAction func discoverServices(_ sender: UIButton) {
        if case let .failure(error) = peripheral.discoverServices() {
            alertUser(title: "Cannot Discover Services", body: String(describing: error))
        }
        setupButtons()
    }

    @IBAction func discoverCharacteristics(_ sender: UIButton) {
        if case let .failure(error) = selectedService!.discoverCharacteristics() {
            alertUser(title: "Cannot Discover Services", body: String(describing: error))
        }
        setupButtons()
    }

    private func peripheralEventHandler(_ event: PeripheralEvent) {
        switch event {

        case .advertisementReceptionStateChange:
            setupButtons()

        case .stateChanged:
            setupButtons()
            if peripheral.cbPeripheral.state == .disconnected {
                selectedService = nil
                servicesTable.reloadData()
                characteristicsTable.reloadData()
            }
            
        case .servicesDiscovered:
            setupButtons()
            servicesTable.reloadData()
            
        case .characteristicsDiscovered:
            setupButtons()
            characteristicsTable.reloadData()

        case .descriptorsDiscovered(let characteristic):
            // If a User Description descriptor comes in then the characteristic's name might change.
            for descriptor in characteristic.descriptors {
                if descriptor.id.uuid.uuidString == CharacteristicUserDescriptionUUID.uuidString {
                    if case let .failure(error) = descriptor.read( { result in if case .success = result { self.characteristicsTable.reloadData() } }) {
                        alertUser(title: "Descriptor Read Error", body: String(describing: error))
                    }
                }
            }

        default:
            break
        }
    }

    // TODO: Consider whether or not an AutoConnect subscription should produce an immediate reconnect attempt whenever the connection is lost.
    // TODO: Add the ability to cancel an in progress connection attempt. Note conection attempts do not timeout?
    fileprivate func setupButtons() {
        
        discoverServices.setTitle("Services", for: .normal)
        discoverServices.isEnabled = false
        discoverServices.borderWidth = 0
        
        discoverCharacteristics.setTitle("Characteristics", for: .normal)
        discoverCharacteristics.isEnabled = false
        discoverCharacteristics.borderWidth = 0
        
        connect.isHidden = true
        
        if !peripheral.connectable { return }
        
        connect.isHidden = false
        connect.isEnabled = false
        connect.borderWidth = 0
        
        switch peripheral.cbPeripheral.state {
            
        case .connecting:
            connect.setTitle("<Connecting>", for: .normal)
            
        case .connected:
            connect.setTitle("Disconnect", for: .normal)
            connect.isEnabled = true
            connect.borderWidth = 1
            
            if !peripheral.servicesDiscovered {
                if peripheral.servicesDiscoveryInProgress {
                    discoverServices.setTitle("<Discovering Services>", for: .normal)
                }
                else {
                    discoverServices.setTitle("Discover Services", for: .normal)
                    discoverServices.isEnabled = true
                    discoverServices.borderWidth = 1
                }
            }
            
            if let service = selectedService {
                if service.characteristicsDiscovered {
                    discoverCharacteristics.setTitle(service.name, for: .normal)
                }
                else {
                    discoverCharacteristics.isEnabled = !service.characteristicDiscoveryInProgress
                    discoverCharacteristics.borderWidth = service.characteristicDiscoveryInProgress ? 0 : 1
                    discoverCharacteristics.setTitle(service.characteristicDiscoveryInProgress ? "<Discovering Characteristics>" : "Discover Characteristics", for: .normal)
                }
            }
            
        case .disconnecting:
            connect.setTitle("<Disconnecting>", for: .normal)
            
        case .disconnected:
            if peripheral.receptionState == .receiving {
                connect.setTitle("Connect", for: .normal)
                connect.isEnabled = true
                connect.borderWidth = 1
            }
            else {
                connect.setTitle("<No Advertisments>", for: .normal)
            }

        default:
            connect.setTitle("<?????>", for: .normal)
        }
    }

    @IBAction func characteristicDisconnect(_ unwindSegue: UIStoryboardSegue) {
    }
}

extension PeripheralViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView === servicesTable ? peripheral.services.count : selectedService?.characteristics.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell

        if tableView === servicesTable {
            let service = peripheral.services[indexPath.row] as! Service
            cell = tableView.dequeueReusableCell(withIdentifier: serviceCellReuseId)!
            (cell as! ServiceCell).update(using: service, and: tableView)
        }
        else {
            let characteristic = selectedService!.characteristics[indexPath.row] as! Characteristic
            cell = tableView.dequeueReusableCell(withIdentifier: characteristicCellReuseId)!
            (cell as! CharacteristicCell).update(with: characteristic)
        }

        return cell
    }
}

// TODO: Remember and restore the selected service
extension PeripheralViewController { // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === servicesTable {
            let service = peripheral[indexPath.row]
            if service !== selectedService {
                selectedService = service
                setupButtons()
            }
            characteristicsTable.reloadData()
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }
}

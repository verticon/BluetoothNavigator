
import UIKit
import VerticonsToolbox
import MoBetterBluetooth

// TODO: Test editting a subscription while the connection is live.
// Note: I modified a subscription; I set autodiscover to true. I ended up with a
// fatal error on the following line of CBCentralManager delegate, in didDisconnectPeripheral:
//      guard let delegate = peripheraDelegates[key] else { fatalError("Unrecognized peripheral - \(cbPeripheral)") }

class SubscriptionEditorViewController : UIViewController {

    // TODO: Rethink all of the force unwrapped optionals.

    var subscription: CentralManager.PeripheralSubscription? // The presenting controller might (or not) set it.

    @IBOutlet weak fileprivate var subscriptionName: UITextField!
    @IBOutlet weak private var autoConnect: TitledSwitch!
    @IBOutlet weak private var autoDiscover: TitledSwitch!
    @IBOutlet weak var monitorAdvertisements: TitledSwitch!

    // TODO: Consider eliminating the services and characteristics arrays, instead directly using the subscription..

    fileprivate var services: [Identifier] = []
    fileprivate var selectedService: Identifier?
    @IBOutlet weak fileprivate var servicesTable: UITableView!
    
    // What is displayed in the characteristics table is determined by which service is selected in the services table
    fileprivate var characteristics: [String : [Identifier]] = [:] // Keys are service names
    @IBOutlet weak fileprivate var characteristicsTable: UITableView!
    @IBOutlet weak fileprivate var addCharacteristic: UIButton!
    @IBOutlet weak fileprivate var characteristicsTableName: UILabel! // The characteristics table name reflect the selected service


    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: String(describing: IdentifierCell.self), bundle: Bundle(for: IdentifierCell.self))
        servicesTable.register(nib, forCellReuseIdentifier: "Identifier")
        characteristicsTable.register(nib, forCellReuseIdentifier: "Identifier")
        
        servicesTable.delegate = self
        servicesTable.dataSource = self
        characteristicsTable.delegate = self
        characteristicsTable.dataSource = self

        if let subscription = subscription {
            subscriptionName.text = subscription.name
            subscription.services.forEach { service in
                services.append(service.id)
                characteristics[service.id.name!] = service.characteristics.map { return $0.id }
            }
            autoConnect.isOn = subscription.autoConnect
            autoDiscover.isOn   = subscription.autoDiscover
            monitorAdvertisements.isOn   = subscription.monitorAdvertisements
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = UIColor.navigationBarTint
    }
    // MARK: Handle segues
    
    private let saveSegueId = "SaveSubscription"
    
    // When the create identifier VC performs an exit segue back to us we will need to
    // remember which table's add button initiated the segue to the create identifier VC.
    fileprivate enum WhichTable {
        case services
        case characteristics
    }
    fileprivate var whichTable = WhichTable.services

    override func shouldPerformSegue(withIdentifier segueId: String?, sender: Any?) -> Bool {
        switch segueId {
        case saveSegueId?:
            guard let name = subscriptionName.text, name.count > 0
            else {
                subscriptionName.borderColor = .red
                subscriptionName.borderWidth = 1.0
                return false
            }

        case "GetServiceId"?:
            whichTable = .services
        case "GetCharacteristicId"?:
            whichTable = .characteristics

        default:
            break
        }
    
        return true
    }

    @IBAction func saveIdentifier(_ unwindSegue: UIStoryboardSegue) {

        let creator = unwindSegue.source as! CreateIdentifierViewController

        switch whichTable {
        case .services:
            servicesTable.beginUpdates()
            services.append(Identifier(uuid: creator.uuid!, name: creator.name))
            characteristics[creator.name!] = []
            servicesTable.insertRows(at: [IndexPath(item: services.count - 1, section: 0)], with: .right)
            servicesTable.endUpdates()
        case .characteristics:
            characteristicsTable.beginUpdates()
            let key = selectedService!.name!
            characteristics[key]!.append(Identifier(uuid: creator.uuid!, name: creator.name))
            characteristicsTable.insertRows(at: [IndexPath(item: characteristics[key]!.count - 1, section: 0)], with: .right)
            characteristicsTable.endUpdates()
        }
    }
    
    @IBAction func cancelIdentifierCreation(_ unwindSegue: UIStoryboardSegue) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id == saveSegueId else { return }

        let services = self.services.map { serviceId in
            CentralManager.ServiceSubscription(id: serviceId, characteristics: characteristics[serviceId.name!]!.map { characteristicId in
                CentralManager.CharacteristicSubscription(id: characteristicId)
            })
        }
        subscription = CentralManager.PeripheralSubscription(name: subscriptionName.text!, services: services, autoConnect: autoConnect.isOn, autoDiscover: autoDiscover.isOn, monitorAdvertisements: monitorAdvertisements.isOn)
    }
}

extension SubscriptionEditorViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        func charateristicsCount() -> Int {
            guard let service = selectedService else { return 0 }
            return characteristics[service.name!]!.count
        }
        return tableView === servicesTable ? services.count : charateristicsCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Identifier") as! IdentifierCell

        if tableView === servicesTable {
            cell.name.text = services[indexPath.row].name
            cell.uuid.text = services[indexPath.row].uuid.uuidString
        }
        else {
            let characteristic = characteristics[selectedService!.name!]![indexPath.row]
            cell.name.text = characteristic.name
            cell.uuid.text = characteristic.uuid.uuidString
        }

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()

            if tableView === servicesTable {
                services.remove(at: indexPath.row)
            }
            else {
                characteristics[selectedService!.name!]!.remove(at: indexPath.row)
            }

            tableView.deleteRows(at: [indexPath], with: .automatic)

            tableView.endUpdates()
        }
    }
}

extension SubscriptionEditorViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === characteristicsTable {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let service = services[indexPath.row]
        if service != selectedService {
            selectedService = service
            characteristicsTableName.text = "\(selectedService!.name!)'s Characteristics"
            characteristicsTable.reloadData()
        }
        
        addCharacteristic.isEnabled = true
    }
}

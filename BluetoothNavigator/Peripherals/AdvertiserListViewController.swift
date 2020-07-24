
import UIKit
import MoBetterBluetooth
import VerticonsToolbox

// TODO: I turned off the Bose AE2 SoundLink and it did not dissappear from the list
class AdvertiserListViewController : UITableViewController {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var scanSwitch: UISwitch!

    var manager: CentralManager! // The presenting controller will set it
    private var managerEventListener: ListenerManagement?

    private var peripherals = [Peripheral]()
    private var peripheralEventListeners = [String : ListenerManagement]()
    private let peripheralCellID = "PeripheralCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationItem.title = manager.name
        //navigationItem.backBarButtonItem?.title = manager.name
        nameLabel.text = manager.name

        let nib = UINib(nibName: String(describing: PeripheralCell.self), bundle: Bundle(for: PeripheralCell.self))
        tableView.register(nib, forCellReuseIdentifier: peripheralCellID)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isMovingToParent { // Pushed to the navigation stack
            managerEventListener = manager.addListener(self, handlerClassMethod: AdvertiserListViewController.managerEventHandler)
            scanSwitch.isEnabled = manager.isReady
            scanSwitch.isOn = manager.isScanning
            
            manager.peripherals.forEach { peripheral in
                peripherals.append(peripheral as! Peripheral)
                let key = listenerKeyFor(peripheral: peripheral)
                peripheralEventListeners[key] = peripheral.addListener(self, handlerClassMethod: AdvertiserListViewController.peripheralEventHandler)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {  // Popped from the navigation stack
            managerEventListener?.removeListener()
            managerEventListener = nil
            peripheralEventListeners.values.forEach { $0.removeListener() }
            peripheralEventListeners.removeAll()
        }
    }

    @IBAction func scanSwitchToggled(_ sender: UISwitch) {
        if sender.isOn {
            if case .failure(let error) = manager.startScanning() {
                alertUser(title: "Cannot Start Scanning", body: String(describing: error))
            }
        }
        else {
            if !manager.stopScanning() {
                alertUser(title: "Cannot Stop Scanning", body: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
            
        case let (peripheralVC as PeripheralViewController, cell as UITableViewCell):
            peripheralVC.peripheral = peripherals[tableView.indexPath(for: cell)!.row]
            
        case let (navigator as UINavigationController, _) where navigator.viewControllers[0] is SubscriptionEditorViewController:
            (navigator.viewControllers[0] as! SubscriptionEditorViewController).subscription = manager.subscription

        default:
            print("Unrecognized segue \(segue) from \(String(describing: sender))")
        }
    }

    @IBAction func saveSubscription(_ unwindSegue: UIStoryboardSegue) {
        if  let subscriptionEditor = unwindSegue.source as? SubscriptionEditorViewController {
            guard let subscription = subscriptionEditor.subscription else {
                fatalError("The Subscription Editor's subscription is nil???")
            }
            
            manager.subscription = subscription
        }
        else {
            print("Received a Save Subscription unwind segue from an unrecognized controller: \(unwindSegue.source)")
        }
    }
    
    @IBAction func cancelSubscription(_ unwindSegue: UIStoryboardSegue) {
    }

    private func managerEventHandler(_ event: CentralManagerEvent) {
        switch event {
            
        case .ready:
            scanSwitch.isEnabled = true
        
        case .startedScanning:
            scanSwitch.isOn = true
            
        case .stoppedScanning:
            scanSwitch.isOn = false
            
        case let .peripheralDiscovered(peripheral):

            peripherals.append(peripheral as! Peripheral)
            /*
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: peripherals.count - 1, section: 0)], with: .right)
            tableView.endUpdates()
            */
            tableView.reloadData()

            peripheralEventListeners[peripheral.cbPeripheral.identifier.uuidString] = peripheral.addListener(self, handlerClassMethod: AdvertiserListViewController.peripheralEventHandler)

        case .subscriptionUpdated:
            navigationItem.title = manager.name
            tableView.reloadData()
            
        case let .peripheralRemoved(peripheral):
            let peripheral = peripheral as! Peripheral
            let index = peripherals.firstIndex(of: peripheral)!

            peripherals.remove(at: index)
            /*
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
            tableView.endUpdates()
            */
            tableView.reloadData()

            peripheralEventListeners.removeValue(forKey: listenerKeyFor(peripheral: peripheral))?.removeListener()

        default:
            break
        }
    }

    private func peripheralEventHandler(_ event: PeripheralEvent) {

        func getCell(for peripheral: CentralManager.Peripheral) -> PeripheralCell? {
            let index = peripherals.firstIndex(where: { $0 === peripheral})!
            return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PeripheralCell
        }

        switch event {
        case let .locationDetermined(peripheral,_):
            if let cell = getCell(for: peripheral) { cell.updateLocationData(using: peripheral) }
        case let .rssiUpdated(peripheral,_):
            if let cell = getCell(for: peripheral) { cell.updateRssiData(using: peripheral) }
        case let .advertisementReceptionStateChange(peripheral, _):
            if let cell = getCell(for: peripheral) { cell.updateReceptionData(using: peripheral) }
        default:
            break
        }
    }

    private func listenerKeyFor(peripheral: CentralManager.Peripheral) -> String {
        return peripheral.cbPeripheral.identifier.uuidString
    }
}

extension AdvertiserListViewController { // UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let peripheral = peripherals[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: peripheralCellID, for: indexPath) as! PeripheralCell
        cell.update(with: peripheral)

        if peripheral.connectable {
            if !(cell.accessoryView is DisclosureIndicator) {
                cell.accessoryView = DisclosureIndicator.create(color: cell.name.textColor, highlightedColor: UIColor.bluetoothBlue)
            }
        }
        else {
            var button: DropDownListButton! = cell.accessoryView as? DropDownListButton
            if button == nil {
                button = DropDownListButton()
                button.color = UIColor.bluetoothBlue
                cell.accessoryView = button
            }
            _ = button.setList(items: peripheral.advertisement.list ?? ["<no advertisements>"])!
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let _ = manager.removePeripheral(peripherals[indexPath.item]) // The peripheralRemoved event handler will take care of the rest
        }
    }
}

extension AdvertiserListViewController { // UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let cell = tableView.cellForRow(at: indexPath)!
        if peripherals[indexPath.item].connectable {
            performSegue(withIdentifier: "Peripheral", sender: cell)
        }
        else {
            (cell.accessoryView as! DropDownListButton).trigger()
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("The accessory view was tapped")
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // TODO: Dragging up will sometimes result in the tableCellGradientFirst being chosen???
        let draggingUp = scrollView.panGestureRecognizer.translation(in: scrollView.superview).y < 0
        //scrollView.backgroundColor = draggingUp ? .tableCellGradientSecond : .tableCellGradientFirst
    }
}


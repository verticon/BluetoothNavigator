
import UIKit
import VerticonsToolbox
import MoBetterBluetooth
import CoreBluetooth

class SubscriptionListViewController: UITableViewController {

    fileprivate var centralManagers = [CentralManager]()

    fileprivate let subscriptionsKey = "CentralSubscriptions"

    private var footerView: LogoView { return tableView.tableFooterView as! LogoView }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = ""
    }

    private var firstTime = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if firstTime {
            footerView.updateLogo(relativeSize: 0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if firstTime {
            firstTime = false
//DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.footerView.updateLogo(relativeSize: 1.0, animate: true, rotate: true, rotationDuration: 1.5, rotationRepeatCount: 2) {
                print("SubscriptionsViewController: Animate Logo Completed")

                self.footerView.upperText = "Bluetooth"
                self.footerView.lowerText = "Navigator"

                self.navigationItem.title = "Subscriptions"
                self.navigationController?.navigationBar.tintColor = UIColor.navigationBarTint

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let subscriptions = loadFromUserDefaults(type: CentralManager.PeripheralSubscription.self, withKey: self.subscriptionsKey) {
                        for (index, subscription) in subscriptions.enumerated() {
                            let centralManager = CentralManager(subscription: subscription, factory: Factory.instance)
                            _ = centralManager.addListener(self, handlerClassMethod: SubscriptionListViewController.managerEventHandler)
                            self.centralManagers.append(centralManager)
                            //CATransaction.setAnimationDuration(5)
                            self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                        }
                    }
                }
            }
//}
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {

        case let (centralVC as AdvertiserListViewController, cell as UITableViewCell): // Present an existing Central
            centralVC.manager = centralManagers[tableView.indexPath(for: cell)!.row]

        case let (navigator as UINavigationController, _) where navigator.viewControllers[0] is SubscriptionEditorViewController: // Create a new Central's subscription
            break

        default:
            print("Unrecognized segue \(segue) from \(String(describing: sender))")
        }
    }
    
    @IBAction func saveSubscription(_ unwindSegue: UIStoryboardSegue) {
        if  let controller = unwindSegue.source as? SubscriptionEditorViewController {
            guard let subscription = controller.subscription else {
                fatalError("The Subscription Editor's subscription is nil???")
            }

            let centralManager = CentralManager(subscription: subscription, factory: Factory.instance)
            _ = centralManager.addListener(self, handlerClassMethod: SubscriptionListViewController.managerEventHandler)

            centralManagers.append(centralManager)
            // ToDo: If insertRows is used then the colors of the cell's backgound, gradient view are
            // not set via UIAppearence (see BluetoothNavigatorThemes). RelaodData does not have this issue.
            //tableView.insertRows(at: [IndexPath(item: centralManagers.count - 1, section: 0)], with: .none)
            tableView.reloadData()

            saveToUserDefaults(centralManagers.map{ $0.subscription }, withKey: subscriptionsKey)
        }
        else {
            print("Received a Save Subscription unwind segue from an unrecognized controller: \(unwindSegue.source)")
        }
    }
    
    @IBAction func cancelSubscription(_ unwindSegue: UIStoryboardSegue) {}

    private func managerEventHandler(_ event: CentralManagerEvent) {
        var managerToReload: CentralManager? = nil

        switch event {

        case let .startedScanning((manager, _)):
            managerToReload = manager

        case let .stoppedScanning(manager):
            managerToReload = manager

        case let .subscriptionUpdated(manager):
            managerToReload = manager
            saveToUserDefaults(centralManagers.map{ $0.subscription }, withKey: subscriptionsKey)

        case let .peripheralDiscovered(peripheral):
            let _ = peripheral.addListener(self, handlerClassMethod: SubscriptionListViewController.peripheralEventHandler)
            managerToReload = peripheral.manager
            
        case let .peripheralRemoved(peripheral):
            managerToReload = peripheral.manager
            
        default:
            break
        }

        if let manager = managerToReload,
           let index = centralManagers.firstIndex(where: { $0 === manager }) {
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            tableView.endUpdates()
        }

        #if LogEvents
            print("\(event)")
        #endif
    }

    private func peripheralEventHandler(_ event: PeripheralEvent) {
        switch event {
            
        case .rssiUpdated:
            return // Don't print it; it happens too often.
            
        default:
            break
        }
        
        #if LogEvents
            print("\(event)")
        #endif
    }
}

extension SubscriptionListViewController { // UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return centralManagers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionCell") as! SubscriptionCell
        let manager = centralManagers[indexPath.item]
        cell.update(with: manager)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //tableView.beginUpdates()
            centralManagers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            //tableView.endUpdates()

            saveToUserDefaults(centralManagers.map{ $0.subscription }, withKey: subscriptionsKey)
        }
    }
}

extension SubscriptionListViewController { // UITableViewDelegate
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! BluetoothCell).prepareDisclosureIndicator()
    }
}

extension SubscriptionListViewController { // UIScrollViewDelegate
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // TODO: Dragging up will sometimes result in the tableCellGradientFirst being chosen???
        let draggingUp = scrollView.panGestureRecognizer.translation(in: scrollView.superview).y < 0
        //scrollView.backgroundColor = draggingUp ? .tableCellGradientSecond : .tableCellGradientFirst
    }
}

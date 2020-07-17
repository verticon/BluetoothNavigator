
import UIKit
import VerticonsToolbox
import MoBetterBluetooth

class BeaconRegionsTableViewController: UITableViewController {

    fileprivate let headerFooterReuseID = "Beacon Region"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "BeaconRegionHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: headerFooterReuseID)

        _ = BeaconRegion.addListener(regionListener)

        print("The BeaconRegionsTableViewController's view was loaded")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func saveIdentifier(_ unwindSegue: UIStoryboardSegue) {
        if let controller = unwindSegue.source as? CreateIdentifierViewController {
            var errorMsg = ""
            self.tableView.beginUpdates()
            if let region = BeaconRegion.addRegion(controller.name!, uuid: UUID(uuidString: controller.uuid!.uuidString)!,  errorDescription: &errorMsg) {
                self.tableView.insertSections(IndexSet(integer: region.index), with: .left)
                self.tableView.endUpdates()
            }
            else{
                alertUser(title: "Add Beacon Region Error", body: errorMsg)
            }
            self.tableView.endUpdates()
        }
        else {
            print("Received a Save Identifier segue from an unsupported controller type: \(type(of: unwindSegue.source))")
        }
    }

    @IBAction func cancelIdentifierCreation(_ unwindSegue: UIStoryboardSegue) {
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return BeaconRegion.numberOfRegions
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let region = BeaconRegion.regionAtIndex(section) {
            return region.numberOfBeacons
        }
        else {
            print("tableView:numberOfRowsInSection: there is no region at index \(section); number of regions = \(BeaconRegion.numberOfRegions)")
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Beacon", for: indexPath)

        if let region = BeaconRegion.regionAtIndex(indexPath.section) {
            if let beacon = region.beaconAtIndex(indexPath.row) {
                cell.textLabel?.text = "\(beacon.identifier)  \(nameForProximity(beacon.currentProximity))"
                switch (beacon.currentProximity) {
                case .far:
                    cell.textLabel?.backgroundColor = UIColor.red
                case.immediate:
                    cell.textLabel?.backgroundColor = UIColor.green
                case .near:
                    cell.textLabel?.backgroundColor = UIColor.yellow
                case .unknown:
                    cell.textLabel?.backgroundColor = UIColor.gray                }
            }
            else {
                print("tableView:cellForRowAtIndexPath: the \(region.name) region does not have a beacon at index \(indexPath.row); number of beacons = \(region.numberOfBeacons)")
            }
        }
        else {
            print("tableView:cellForRowAtIndexPath: there is no region at index \(indexPath.section); number of regions = \(BeaconRegion.numberOfRegions)")
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerFooterReuseID) as? BeaconRegionHeader, let region = BeaconRegion.regionAtIndex(section) {
            header.region = region
            return header
        }
        else {
            print("Could not dequeue reusable Beacon Region header")
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(65)
    }

    fileprivate func regionListener(_ region: BeaconRegion, event: BeaconRegion.Event, beacon: BeaconRegion.Beacon?) {
        switch event {
        case .addedBeacon:
            self.tableView?.insertRows(at: [IndexPath(row: beacon!.index, section: region.index)], with: .automatic)
        case .changedBeaconProximity:
            self.tableView?.reloadRows(at: [IndexPath(row: beacon!.index, section: region.index)], with: .automatic)
        case .exitedRegion:
            self.tableView?.reloadSections(IndexSet(integer: region.index), with: .automatic)
        default:
            break
        }
    }
}


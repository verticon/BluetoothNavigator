
import UIKit
import VerticonsToolbox
import MoBetterBluetooth

class BeaconRegionHeader: UITableViewHeaderFooterView {

    fileprivate static var locatedInsideColor = UIColor(red: 222/255.0, green: 221/255.0, blue: 222/255.0, alpha: 1.0)
    fileprivate static var locatedOutsideColor = UIColor.lightText
    fileprivate var listenerKey = BeaconRegion.invalidListenerKey

    // The Table View Controller will set the region when it dequeues the header
    var region: BeaconRegion! {
        willSet(newValue) {
            if listenerKey != BeaconRegion.invalidListenerKey && region !== newValue {
                _ = region.removeListener(listenerKey)
                listenerKey = BeaconRegion.invalidListenerKey
            }
        }
        didSet {
            nameLabel.text = region.name
            monitoringSwitch.setOn(region.isMonitoring, animated: false)
            rangingSwitch.setOn(region.isRanging, animated: false)
            rangingSwitch.isEnabled = region.locatedInside
            uuidLabel.text = "<\(region.uuid.uuidString)>"

            contentView.backgroundColor = region.locatedInside ? BeaconRegionHeader.locatedInsideColor : BeaconRegionHeader.locatedOutsideColor

            if listenerKey == BeaconRegion.invalidListenerKey {
                listenerKey = region.addListener(regionListener)
                print("BeaconRegionHeader - listening to region \(region.name)")
            }
        }
    }

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var monitoringSwitch: UISwitch!
    @IBOutlet weak var rangingSwitch: UISwitch!
    @IBOutlet weak var uuidLabel: UILabel!

    @IBAction func didToggleMonitoring(_ sender: UISwitch) {
        if sender.isOn {
            region.startMonitoring()
        }
        else {
            region.stopMonitoring()
        }
    }
    
    @IBAction func didToggleRanging(_ sender: UISwitch) {
        if sender.isOn {
            region.startRanging()
        }
        else {
            region.stopRanging()
        }
    }
    
    // Here is the "trick" that allows us to display a custom view in a table section header.
    override var contentView: UIView {
        get {
            return self.subviews[0]
        }
    }

    // Note that toggling the monitoring/ranging switches results in stop/start commands being sent
    // to the BeaconRegion which in turn causes an event to fire which then invokes this listener,
    // albeit needlessly. This is okay, no harm will be doen. The listener needs to respond to those
    // stop/start events in order to properly maintain the UI if and when the stop/start commands
    // are issued by a source other than the switches.
    fileprivate func regionListener(_ region: BeaconRegion, event: BeaconRegion.Event, beacon: BeaconRegion.Beacon?) {
        switch event {
        case .enteredRegion:
            rangingSwitch.isEnabled = true
            contentView.backgroundColor = BeaconRegionHeader.locatedInsideColor
        case .exitedRegion:
            rangingSwitch.isOn = false;
            rangingSwitch.isEnabled = false
            contentView.backgroundColor = BeaconRegionHeader.locatedOutsideColor
        case .startedMonitoring:
            monitoringSwitch.isOn = true;
        case .stoppedMonitoring:
            monitoringSwitch.isOn = false;
        case .startedRanging:
            rangingSwitch.isOn = true;
        case .stoppedRanging:
            rangingSwitch.isOn = false;
        default:
            break
        }
    }
}

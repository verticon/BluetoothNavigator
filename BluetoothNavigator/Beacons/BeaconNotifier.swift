
import UIKit
import VerticonsToolbox
import MoBetterBluetooth
import UserNotifications

class BeaconNotifier {

//    private var appDefaults = Dictionary<String, AnyObject>()
    fileprivate let RegionEnteredExited = "RegionEnteredExitedNotificationSetting"
    fileprivate let BeaconDetected = "BeaconDetectedNotificationSetting"
    fileprivate let ProximityChanged = "BeaconProximityChangedNotificationSetting"

    init() {
        _ = BeaconRegion.addListener(handleBeaconEvent)
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
            if granted { print("Notification authorization was granted") }
            else { print("Notification authorization was denied: \(String(describing: error))") }
        }
/*
        appDefaults[RegionEnteredExited] = false
        appDefaults[BeaconDetected] = false
        appDefaults[ProximityChanged] = false
        NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
        NSUserDefaults.standardUserDefaults().synchronize()
*/
    }
    
    fileprivate func handleBeaconEvent(_ region: BeaconRegion, event: BeaconRegion.Event, beacon: BeaconRegion.Beacon?) {
        if UIApplication.shared.applicationState == .background {
            var shouldNotify = false

            switch event {

            case .enteredRegion:
                fallthrough
            case .exitedRegion:
                shouldNotify = UserDefaults.standard.bool(forKey: RegionEnteredExited)

            case .addedBeacon:
                shouldNotify = UserDefaults.standard.bool(forKey: BeaconDetected)

            case .changedBeaconProximity:
                shouldNotify = UserDefaults.standard.bool(forKey: ProximityChanged)

            default:
                break
            }
            
            if shouldNotify {
                notifyUser(event.describeEvent(region, beacon: beacon))
            }
        }
    }
}

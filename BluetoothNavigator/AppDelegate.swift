
import UIKit
//import UserNotifications
import VerticonsToolbox
import MoBetterBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    fileprivate let notifier = BeaconNotifier()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        func printStartupMessage() {
            var message = "\(applicationName) was launched \(LocalTime.text) "
            if let options = launchOptions {
                message += "with options:"
                for (key, value) in options { message += "\n\t\(key) = \(value)" }
            }
            else {
                message += "without options."
            }
            print(message)
        }


        func setupWindow() {
            window = UIWindow(frame: UIScreen.main.bounds)
            window!.makeKeyAndVisible()
            window!.backgroundColor = .black

            window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            //window!.rootViewController = StartupController()
        }
        
        // *******************************************************************
        
        printStartupMessage()

        BluetoothNavigatorTheme.configure()

        if let _ = launchOptions?[UIApplication.LaunchOptionsKey.location] { _ = BeaconRegion.restore() }

        setupWindow()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("\(applicationName) will become inactive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("\(applicationName) moved to the background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("\(applicationName) will move to the foreground")
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("\(applicationName) became active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("\(applicationName) will terminate")
    }
}

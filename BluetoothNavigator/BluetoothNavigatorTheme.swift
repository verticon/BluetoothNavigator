
import UIKit
import VerticonsToolbox

class BluetoothNavigatorTheme {
    static func configure() {

        func navigationBar() {
            UINavigationBar.appearance().barStyle = UIBarStyle.black
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().barTintColor = UIColor.black
            UINavigationBar.appearance().tintColor = UIColor.black
        }
        
        func tabBar() {
            UITabBar.appearance().barTintColor = UIColor.black
            UITabBar.appearance().tintColor = UIColor.white
        }
        
        func bluetoothNavigatorView() {
            BluetoothNavigatorView.appearance().backgroundColor = .bluetoothNavigatorGradientFirst
        }
        
        func bluetoothNavigatorTableView() {
            BluetoothNavigatorTableView.appearance().backgroundColor = .black
        }
        
        func bluetoothNavigatorTableHeader() {
            BluetoothNavigatorTableHeader.appearance().backgroundColor = .darkGray
        }
        
        func gradientView() {
            GradientView.appearance().firstColor = .bluetoothNavigatorGradientFirst
            GradientView.appearance().secondColor = .bluetoothNavigatorGradientSecond
        }
        
        func textView() {
            UITextView.appearance().borderWidth = 1
            UITextView.appearance().borderColor = .darkGray
            UITextView.appearance().cornerRadius = 5
            UITextView.appearance().textColor = .white
            UITextView.appearance().backgroundColor = .clear
        }
        
        func switches() {
            UISwitch.appearance().onTintColor = .bluetoothBlue
            TitledSwitch.appearance().tintColor = .darkGray
            TitledSwitch.appearance().thumbTintColor = .darkGray
            TitledSwitch.appearance().titleColorEnabled = .white
            TitledSwitch.appearance(whenContainedInInstancesOf: [BluetoothNavigatorTableHeader.self]).tintColor = .white
            TitledSwitch.appearance(whenContainedInInstancesOf: [BluetoothNavigatorTableHeader.self]).thumbTintColor = .white
            TitledSwitch.appearance(whenContainedInInstancesOf: [BluetoothNavigatorTableHeader.self]).titleColorEnabled = .black
        }
    
        func buttons() {
            BluetoothNavigatorButton.appearance().borderWidth = 1
            BluetoothNavigatorButton.appearance().borderColor = .darkGray
            BluetoothNavigatorButton.appearance(whenContainedInInstancesOf: [BluetoothNavigatorTableHeader.self]).borderColor = .white
            BluetoothNavigatorButton.appearance().cornerRadius = 5
            BluetoothNavigatorButton.appearance().tintColor = .white

            RadioButton.appearance().bezelColor = .darkGray
            RadioButton.appearance().bezelWidth = 1
            RadioButton.appearance().buttonColor = .darkGray

            DropDownMenuButton.appearance().color = .bluetoothBlue
        }

        navigationBar()
        tabBar()
        bluetoothNavigatorView()
        bluetoothNavigatorTableView()
        bluetoothNavigatorTableHeader()
        gradientView()
        textView()
        switches()
        buttons()
    }
}

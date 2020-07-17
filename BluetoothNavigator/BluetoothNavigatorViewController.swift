

import UIKit

class BluetoothNavigatorViewController: UIViewController, UITableViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // TODO: Dragging up will sometimes result in the tableCellGradientFirst being chosen???
        let draggingUp = scrollView.panGestureRecognizer.translation(in: scrollView.superview).y < 0
        scrollView.backgroundColor = draggingUp ? .bluetoothNavigatorGradientSecond : .bluetoothNavigatorGradientFirst
    }

}

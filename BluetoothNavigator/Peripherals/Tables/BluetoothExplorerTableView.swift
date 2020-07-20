
import UIKit
import VerticonsToolbox

@IBDesignable class BluetoothNavigatorTableView: UITableView {

    @IBInspectable var name: String = "Bluetooth"

    let footer = LogoView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override func prepareForInterfaceBuilder() {
        setup()
    }

    private func setup() {
        tableFooterView = footer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print("BluetoothTable.layoutSubviews: cells = \(self.visibleCells.count)")
        layoutFooter()
    }

    // ************************************************************************************

    // Execute the methods that change the number of table rows within a CATransaction
    // so that their completion can be detected. Upon completion resize the footer.
    
    override func reloadData() {
        print("BluetoothTable.reloadData: cells = \(self.visibleCells.count)")
        perform { super.reloadData() }
    }
    
    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        print("BluetoothTable.reloadRows: cells = \(self.visibleCells.count)")
        perform { super.reloadRows(at: indexPaths, with: animation) }
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        print("BluetoothTable.insertRows: cells = \(self.visibleCells.count)")
        perform { super.insertRows(at: indexPaths, with: animation) }
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        print("BluetoothTable.deleteRows: cells = \(self.visibleCells.count)")
        perform { super.deleteRows(at: indexPaths, with: animation) }
    }

    private func perform(operation: @escaping () -> Void) {
//        CATransaction.begin()
//        CATransaction.setCompletionBlock() {
//            print("BluetoothTable: transaction completed; cells = \(self.visibleCells.count)")
//            //self.layoutFooter()
//        }
       operation()
//        CATransaction.commit()
    }

    // ************************************************************************************
    
    var logoIsHidden: Bool {
        get { return footer.logoIsHidden }
        set { footer.logoIsHidden = newValue }
    }

    // ************************************************************************************

    private func layoutFooter() {
        guard let footerView = tableFooterView else { return }
        
        func calcFooterHeight() -> CGFloat {
            var heightUsed = tableHeaderView?.bounds.height ?? 0
            for cell in visibleCells { heightUsed += cell.bounds.height }
            let heightRemaining = bounds.height - heightUsed

            let minHeight: CGFloat = 44
            return heightRemaining > minHeight ? heightRemaining : minHeight
        }

        let newHeight = calcFooterHeight()
        guard newHeight != footerView.bounds.height else {
            print("BluetoothTable: Footer layout did not change; cells = \(self.visibleCells.count)")
            return }
        
        // Keep the origin where it is, i.e. tweaking just the height expands the frame about its center
        let currentFrame = footerView.frame
        footerView.frame = CGRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: currentFrame.width, height: newHeight)
        print("BluetoothTable: Laid out footer; visible cells = \(visibleCells.count), frame = \(footerView.frame)")
    }
}

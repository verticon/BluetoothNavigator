
import UIKit
import MoBetterBluetooth

class RssiGraph: UIView {

    private let maxBars = 5
    private var currentBars = 0

    var rssi = 0 {
        didSet {
            let bars: Int
            if rssi > -40 { bars = 5 }
            else if rssi > -50 { bars = 4 }
            else if rssi > -60 { bars = 3 }
            else if rssi > -70 { bars = 2 }
            else if rssi > -80 { bars = 1 }
            else { bars = 0 }

            if bars != currentBars {
                currentBars = bars
                setNeedsDisplay()
            }
        }
    }

    var receptionState : AdvertisementReceptionState = .receiving {
        didSet {
            if receptionState != oldValue { setNeedsDisplay() }
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard receptionState == .receiving || receptionState == .notReceiving else { return }

        let numberOfBars = receptionState == .receiving ? currentBars : 0

        let xAxisIncrement: CGFloat = bounds.width / CGFloat(maxBars)
        var xAxisLocation = xAxisIncrement / 2

        let barHeightIncrement = bounds.height / CGFloat(maxBars)
        var barHeight = barHeightIncrement

        let context = UIGraphicsGetCurrentContext()!;

        let lineWidth = xAxisIncrement / 2
        context.setLineCap(.square)
        context.setLineWidth(lineWidth)

        (1 ... maxBars).forEach { bar in

            context.move(to: CGPoint(x: xAxisLocation, y: bounds.height)) // Max y is at the bottom
            context.addLine(to: CGPoint(x: xAxisLocation, y: bounds.height - barHeight)) // so we have to increase the height "backwards"

            context.setStrokeColor(bar <= numberOfBars ? UIColor.bluetoothBlue.cgColor : UIColor.lightGray.cgColor)
            context.strokePath()

            xAxisLocation += xAxisIncrement
            barHeight += barHeightIncrement
        }

        if receptionState == .notReceiving {
            drawFailureIndication(lineWidth: lineWidth)
        }
    }
}

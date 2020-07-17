
import Foundation
import CoreBluetooth
import MoBetterBluetooth

class Factory : CentralManagerTypesFactory {
    
    private static let _instance = Factory()
    public static var instance: Factory {
        return _instance
    }
    
    private init() {}

    public func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisement: Advertisement, rssi: NSNumber) -> CentralManager.Peripheral {
        return Peripheral(cbPeripheral: cbPeripheral, manager: manager, advertisement: advertisement, rssi: rssi)
    }

    public func makeService(for cbService: CBService, id: Identifier, parent: CentralManager.Peripheral) -> CentralManager.Service {
        return Service(cbService: cbService, id: id, parent: parent)
    }
    
    public func makeCharacteristic(for cbCharacteristic: CBCharacteristic, id: Identifier, parent: CentralManager.Service) -> CentralManager.Characteristic {
        return Characteristic(cbCharacteristic: cbCharacteristic, id: id, parent: parent)
    }
    
    public func makeDescriptor(for cbDescriptor: CBDescriptor, id: Identifier, parent: CentralManager.Characteristic) -> CentralManager.Descriptor {
        return Descriptor(cbDescriptor: cbDescriptor, id: id, parent: parent)
    }
}

class Peripheral : CentralManager.Peripheral {
    subscript(index: Int) -> Service {
        return super.services[index] as! Service
    }
}

class Service : CentralManager.Service {
    var collapsed = true

    subscript(index: Int) -> Characteristic {
        return super.characteristics[index] as! Characteristic
    }
}

class Characteristic : CentralManager.Characteristic {
    subscript(index: Int) -> Descriptor {
        return super.descriptors[index] as! Descriptor
    }
}

class Descriptor : CentralManager.Descriptor {
}

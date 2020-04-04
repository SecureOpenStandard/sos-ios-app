//
//  BLE_iOS_Connection.swift
//
//
//  Created by Marvin Mouroum on 03.04.20.
//  Copyright © 2020 Marvin Mouroum. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum BLE_State {
    case advertising
    case noStream
    case noBLE
}

///can be used to stream and observe Bluetooth BLE signals
@objc(BLE_iOS_Connection)
public class BLE_iOS_Connection:NSObject {
    
    var uuid:String {
        
        if #available(iOS 13.0, *){
            return "C0D58B00-73B1-441C-9896-A5D454D8E50D"
        }
        else{
            return "1e6db851-b619-4114-9b04-276e02be6c7f"
        }
    }
    
    public  var manager:CBPeripheralManager!
    private var connection_name:String?
    private var data:Data?
    private var delegate:BLE_Delegate?
    
    public var central:CBCentralManager?
    
    private var foundUUIDS:[String] = []
    
    var uuids:[String]{
        
        get {
            return foundUUIDS
        }
    }
    
    var isScanning:Bool {
        return central!.isScanning
    }
    
    init(_ name:String? = nil, _ data:Data? = nil){
        super.init()
        self.delegate = BLE_Delegate(ble: self)
        self.connection_name = name
        self.data = data
        self.manager = CBPeripheralManager(delegate: delegate, queue: nil)
    }
    
    
    private func run_bluetooth(){
        
        let custom_uuid = CBUUID(string: uuid)
        
        let characteristic = CBMutableCharacteristic(type: custom_uuid, properties: .read, value: data, permissions: .readable)
        
        //A primary service describes the primary functionality of a device and can be included (referenced) by another service. A secondary service describes a service that is relevant only in the context of another service that has referenced it. For example, the primary service of a heart rate monitor may be to expose heart rate data from the monitor’s heart rate sensor, whereas a secondary service may be to expose the sensor’s battery data.
        let service = CBMutableService(type: custom_uuid, primary: true)
        service.characteristics = [characteristic]
        
        manager.add(service)
        
        manager.startAdvertising([CBAdvertisementDataLocalNameKey:connection_name ?? "ENGEL",
                                  CBAdvertisementDataServiceUUIDsKey: [custom_uuid]])
    }
    
    public func start_observing(_ callback: @escaping ([String]) -> Void  ){
        
        central = CBCentralManager(delegate: self.delegate, queue: nil)
        
        if !central!.isScanning {
            central?.scanForPeripherals(withServices: nil, options: nil)
            callback(["no error","will scan"])
        }
        else{
            callback(["no error","already scanning"])
        }
    }
    
    ///more detailed information about state of the manager
    @objc public func check_state(_ callback: @escaping ([String])->Void){
        
        switch manager.state {
        case .poweredOff:
            print("powered off")
            callback( ["no error","powered off"])
        case .poweredOn:
            print("powered on")
            callback( ["no error","powered on"])
        case .resetting:
            print("resetting")
            callback( ["no error","resetting"])
        case .unauthorized:
            print("unauthorized")
            callback( ["no error","unauthorized"])
        case .unknown:
            print("unknown")
            callback( ["no error","unknown"])
        case .unsupported:
            print("unsupported")
           callback( ["no error","unsupported"])
        }
    }
    
    ///inside wheather BLE is running
    public var state:BLE_State {
        
        get {
            if manager.state != .poweredOn {
                return .noBLE
            }
            else if manager.isAdvertising {
                return .advertising
            }
            else {
                return .noStream
            }
        }
    }
    
    ///advertising starts automatically after init. however when something went wrong it can be called again
    @objc public func start_advertising(_ callback: @escaping ([String]) -> Void  ){
        if !manager.isAdvertising {
            run_bluetooth()
            callback(["no error","will advertise"])
        }
        else{
            callback(["no error","already advertising"])
        }
    }
    
    private class BLE_Delegate:NSObject, CBPeripheralManagerDelegate, CBCentralManagerDelegate {
        
        
        var BLE:BLE_iOS_Connection
        
        init(ble:BLE_iOS_Connection){
            self.BLE = ble
            super.init()
        }
        
        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
            print("peripheral manager updated state - bravo")
            if peripheral.state == .poweredOn {
                BLE.start_advertising { (Return) in
                    print(Return as? [String] ?? "no data")
                }
            }
        }
        
        func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
            if let err = error {
                print("An ERROR occured whenn adding the service \n\(err)")
            }
        }
        
        func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
            if let err = error {
                print("An ERROR occured when advertising \n\(err)")
            }
        }
        
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            print("central manager updated state")
            
            print("central powered on -> \(central.state == CBManagerState.poweredOn)")
            
            if central.state == CBManagerState.poweredOn {
                central.scanForPeripherals(withServices: nil, options: nil)
            }
            
        }
        
        
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            
            let uuid = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            
            guard let uniqueID = uuid?.first?.uuidString else { return }
            
            
            let rs = Int(truncating: RSSI)
            
            if rs < -70 || rs > 0 {
                return
            }
            
            if !BLE.foundUUIDS.contains(uniqueID){
                BLE.foundUUIDS.append(uniqueID)
                print("discovered peripheral with name \(peripheral.name ?? "n/a"), uuid \(uniqueID) and rssi \(RSSI)")
                
            }
            else{
                BLE.foundUUIDS.removeAll { (id) -> Bool in
                    return id == uniqueID
                }
                BLE.foundUUIDS.append(uniqueID)
            }
            
            
        }
        
    }
    
}

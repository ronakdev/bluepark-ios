//
//  ViewController.swift
//  UCSD Parking
//
//  Created by Anthony2018317 on 1/20/19.
//  Copyright © 2019 Anthony2018317. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

enum UUIDS: String {
    case PrimaryService = "8556f0aa-38ec-4f2c-a499-021c5c8c4a49"
    case ParkCharacteristic = "4dfda589-ab7e-4304-bb88-9ea25910c888"
    case EmptyParkingSpotCharacteristic = "651edd60-cd7a-460f-8991-489739b155e3"
}
class ViewController: UIViewController {
    //MARK: Properties
    
    @IBOutlet weak var parkStatusLabel: UILabel!
    
    // Bluetooth Instance Variables
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!

    @IBAction func onParkCancel(_ sender: UIButton) {
        if (self.peripheral == nil) {
            self.scan("peripherals")
            return
        }
        
        if (self.peripheral.services == nil) {
            self.scan("services")
            return
        }
        
        for service in (self.peripheral.services)! {
            if let serviceChars = service.characteristics {
                if serviceChars.count > 0 {
                    for char in serviceChars {
                        if char.uuid.uuidString == UUIDS.EmptyParkingSpotCharacteristic.rawValue {
                            let bytes: [UInt8] = [0x4]
                            let data = Data(bytes: bytes)
                            peripheral.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
                            self.parkStatusLabel.text = "You have now left the spot!"
                        }
                    }
                }
            } else {
                self.scan("characteristics")
            }
        }
    }
    
    @IBAction func onParkCLick(_ sender: UIButton) {
        if (self.peripheral == nil) {
            self.scan("peripherals")
            return
        }
        
        if (self.peripheral.services == nil) {
            self.scan("services")
            return
        }
        
        for service in (self.peripheral.services)! {
            if let serviceChars = service.characteristics {
                if serviceChars.count > 0 {
                    for char in serviceChars {
                        if char.uuid.uuidString == UUIDS.ParkCharacteristic.rawValue {
                            let bytes: [UInt8] = [0x4]
                            let data = Data(bytes: bytes)
                            peripheral.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
                            self.parkStatusLabel.text = "You have now parked!!!"
                        }
                    }
                    
                }
            } else {
                self.scan("characteristics")
            }
        }
    }
    
    override func viewDidLoad() { // basically a constructor
        super.viewDidLoad()
//        self.textFieldView.text = "Starting Log...\n\n"
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan(_ target: String) {
        switch target {
        case "peripherals":
            self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            break
        case "services":
            self.peripheral.discoverServices([CBUUID(string: "8556f0aa-38ec-4f2c-a499-021c5c8c4a49")])
            break
        case "characteristics":
            if let peripheralServices = self.peripheral.services{
                self.peripheral.discoverCharacteristics([CBUUID(string:UUIDS.ParkCharacteristic.rawValue), CBUUID(string: UUIDS.EmptyParkingSpotCharacteristic.rawValue)], for: peripheralServices[0])
            }
        default:
            break
        }
    }
}

/**
 * Keep Bluetooth Stuff Here
 */
extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.parkStatusLabel.text = "Looking for Parking"
//            self.textFieldView.text += ("central.state is .poweredOn\n")
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]) //?
            break
        default:
            self.parkStatusLabel.text = "Check your Bluetooth Settings!"
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let device = (advertisementData as NSDictionary)
            .object(forKey: CBAdvertisementDataLocalNameKey)
            as? NSString
        
        if device?.contains("Spot 1-1 (A)") == true {
            self.centralManager.stopScan()
            self.parkStatusLabel.text = "Found Spot, Requesting Services"
            
            self.peripheral = peripheral
            self.peripheral.delegate = self
            
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.scan("services")
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let peripheralServices = self.peripheral.services {
            self.parkStatusLabel.text = "Services Acquired, Requesting Permission to Send Permit Info"
            self.peripheral.discoverCharacteristics([CBUUID(string:UUIDS.ParkCharacteristic.rawValue), CBUUID(string: UUIDS.EmptyParkingSpotCharacteristic.rawValue)], for: peripheralServices[0])
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let serviceCharacteristics = service.characteristics {
            self.parkStatusLabel.text = "Sending Permit Data to Parking Spot"
        } else {
            self.parkStatusLabel.text = "An Error Occurred"
        }
    }
    
}

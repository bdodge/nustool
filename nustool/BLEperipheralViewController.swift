//
//  BLEperipheralViewController.swift
//  magtool
//
//  Created by Brian Dodge on 1/14/19.
//

import UIKit
import CoreBluetooth
import Foundation
import CoreMotion

class BLEperipheralViewController:  UIViewController,
                                    CBPeripheralDelegate
{
    //MARK: Properties
    @IBOutlet weak var devName: UILabel!
    @IBOutlet weak var findActivity: UIActivityIndicatorView!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var opStatus: UILabel!
    @IBOutlet weak var findStatus: UILabel!

    var parentView : ViewController? = nil
    
    //MARK: Core Bluetooth members
    var centralMan : CBCentralManager?
    var thePeripheral : CBPeripheral?
    
    //MARK: services and characteristics database
    var services : [CBService] = [CBService]()
    var characters : [[CBCharacteristic]] = [[CBCharacteristic]()]
    
    var cmdCharServiceIndex : Int = -1
    var cmdCharCharIndex : Int = 0
    var conCharServiceIndex : Int = -1
    var conCharCharIndex : Int = 0
    var stsCharServiceIndex : Int = -1
    var stsCharCharIndex : Int = 0
    var nrxCharServiceIndex : Int = -1
    var nrxCharCharIndex : Int = 0
    var ntxCharServiceIndex : Int = -1
    var ntxCharCharIndex : Int = 0

    // MARK: TCP/IP members
    var termPort : UInt16 = 8889
    var terminalServiceStarted = false
    var terminalServer : SocketServer = SocketServer()
    
    //MARK: member vars
    var utils : BLEutils = BLEutils()
    var readValue : String = ""
    
    var pollTimer : Timer = Timer()
    var tickCount : UInt = 0

    let statusCharUUID = CBUUID.init(string:String(format:"%04X", LevelHomecharacteristicUUIDs.StatusCharacteristicShortID.rawValue))
    let changeCharUUID = CBUUID.init(string:String(format:"%04X", LevelHomecharacteristicUUIDs.LevelServiceChangedCharacteristicShortID.rawValue))
    let consoleCharUUID = CBUUID.init(string:String(format:"%04X", LevelHomecharacteristicUUIDs.ConsoleCharacteristicShortID.rawValue))
    let commandCharUUID = CBUUID.init(string:String(format:"%04X", LevelHomecharacteristicUUIDs.CommandCharacteristicShortID.rawValue))

    override func viewDidLoad() {
        super.viewDidLoad()
       
        // set this controller as peripheral's delegate
        thePeripheral?.delegate = self
    
        // set labels up
        if thePeripheral != nil && thePeripheral?.name != nil {
            devName.text = "Device: " + thePeripheral!.name!
        }
        else {
            devName.text = "<No Device Connected>"
        }
        // discover services/characteristics for device
        //
        services.removeAll()
        opStatus.text = "<none>"
        findStatus.text = "Finding Services"
        self.findActivity.startAnimating()
 
        // enumerate services
        thePeripheral?.discoverServices(nil)
        
        // start polling status
        //
        pollTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(pollStatus), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        pollTimer.invalidate()
        terminalServer.Close()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if (parent == nil) {
            thePeripheral?.delegate = parentView as? CBPeripheralDelegate
        }
    }
    
    @objc func pollStatus() {
        if terminalServiceStarted {
            DispatchQueue.main.async { () -> Void in
                self.updateTerminalServer()
            }
        }
        
        tickCount += 1
        
        if (tickCount % 20) == 0 {
            if !terminalServiceStarted {
               startTerminalServer()
            }
            readLockStatus()
        }
    }
    
    func startTerminalServer() {
        // if found NUS services, open port
        if nrxCharServiceIndex < 0 || ntxCharServiceIndex < 0 {
            findStatus.text = "No NUS Service Available"
            return
        }
        findStatus.text = "found NUS Service"
        
        if !terminalServer.Init(port: termPort) {
            findStatus.text = "Failed: terminal (init)"
            return
        }
        
        // subscribe to nus Tx char
        if ntxCharServiceIndex > 0 {
            thePeripheral!.setNotifyValue(true, for: characters[ntxCharServiceIndex][ntxCharCharIndex])
        }
        
        terminalServiceStarted = true
    }
    
    func updateTerminalServer() {
        if !terminalServiceStarted {
            return
        }
        
        if !terminalServer.IsConnected() {
            if !terminalServer.IsAccepting() {
                // defer accepting to work queue
                if !terminalServer.Accept() {
                    findStatus.text = "Failed: terminal (accept)"
                }
            }
        } else {
            if let rxdata = terminalServer.Recv(maxLength: 64) {
                //print("Got data" + rxdata)
                // send data to Rx Characteristic
                if nrxCharServiceIndex > 0 {
                    writeValue(characters[nrxCharServiceIndex][nrxCharCharIndex], dataToWrite: rxdata)
                }
            }
        }
    }

    func onTerminalData(_ data: String) {
        if terminalServiceStarted && terminalServer.IsConnected() {
            if !terminalServer.Send(data: data) {
                findStatus.text = "Failed: terminal (send)"
            }
        }
    }
    
    func readLockStatus() {
        if true {
            //let shortid = LevelHomecharacteristicUUIDs.StatusCharacteristicShortID.rawValue
            
            if stsCharServiceIndex >= 0 {
                // read status char
                readValue(characters[stsCharServiceIndex][stsCharCharIndex])
            }
            
            /* do this to reset auto-disconnect timer if configured
            if conCharServiceIndex >= 0 {
                // ping console char to keep connection open
                writeValue(characters[conCharServiceIndex][conCharCharIndex], dataToWrite: "\n")
            }
            */
        }
    }
    
    //MARK: CBPeripheralDelegate functions
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            print("  Discoserv \(utils.nameForService(uuid: service.uuid))")
            services += [service]
            DispatchQueue.main.async { () -> Void in
                self.findActivity.startAnimating()
                self.findStatus.text = "Finding Characteristics for\(self.utils.nameForService(uuid: service.uuid))"
            }
            // enumerate chars
            characters += [[CBCharacteristic]()]
            thePeripheral?.discoverCharacteristics(nil, for: service)
        }
        DispatchQueue.main.async { () -> Void in

            self.findStatus.text = "Press Disconnect to disconnect"
            self.opStatus.text = ""
            self.findActivity.stopAnimating()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
         for ourservice in 0..<services.count {
            if service == services[ourservice] {
                var charindex = 0;
                
                for achar in service.characteristics! {
                    print("  serv\(ourservice) Discochar \(utils.nameForCharacteristic(uuid: achar.uuid))")
                    characters[ourservice] += [achar]
                    if achar.uuid == commandCharUUID {
                        cmdCharServiceIndex = ourservice;
                        cmdCharCharIndex = charindex;
                    }
                    if achar.uuid == consoleCharUUID {
                        conCharServiceIndex = ourservice;
                        conCharCharIndex = charindex;
                    }
                    if achar.uuid == statusCharUUID {
                        stsCharServiceIndex = ourservice;
                        stsCharCharIndex = charindex;
                    }
                    if achar.uuid == NordicNUSRxUUID {
                        nrxCharServiceIndex = ourservice;
                        nrxCharCharIndex = charindex;
                    }
                    if achar.uuid == NordicNUSTxUUID {
                        ntxCharServiceIndex = ourservice;
                        ntxCharCharIndex = charindex;
                    }

                    DispatchQueue.main.async {
                        peripheral.discoverDescriptors(for: achar)
                    }
                    
                    charindex += 1
                }
                break;
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let descriptors = characteristic.descriptors {
            for desc in descriptors {
                if desc.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString {
                    peripheral.readValue(for: desc)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        DispatchQueue.main.async {
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async { () -> Void in
            //
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async { () -> Void in
            //
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic == characters[ntxCharServiceIndex][ntxCharCharIndex] {
            let rv = utils.formatValue(for: characteristic)
            //print("read uuid=\(characteristic.uuid) value=\(rv)")
            
            if terminalServiceStarted {
                DispatchQueue.main.async { () -> Void in
                    self.onTerminalData(rv)
                }
            }
        }
    }


    //MARK: IO functions
    func readValue(_ characteristic: CBCharacteristic) {
        thePeripheral?.readValue(for: characteristic)
    }
    
    func writeValue(_ characteristic: CBCharacteristic, dataToWrite : String?) {
        // get value and convert to raw bytes
        if dataToWrite != nil {
            let bval = [UInt8](dataToWrite!.utf8)
            let dval = Data(bytes: bval, count: bval.count)
            thePeripheral?.writeValue(dval, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    @IBAction func onDisconnect(_ sender: Any) {
        pollTimer.invalidate()
        if thePeripheral != nil && centralMan != nil {
            centralMan!.cancelPeripheralConnection(thePeripheral!)
            navigationController?.popViewController(animated: true)
        }
    }
}

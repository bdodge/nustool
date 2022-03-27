//
//  ViewController.swift
//  magtool
//
//  Created by Brian Dodge on 2/8/19.
//  Copyright © 2019 Brian Dodge. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion

//MARK: BLE Standard Service UUIDs
let BLE_Heart_Rate_Service_CBUUID = CBUUID(string: "0x180D")
let BLE_Battery_Service_CBUUID    = CBUUID(string: "0x180F")
let BLE_CalThings_Service_CBUUID  = CBUUID(string: "0xFDBF")
let BLE_Default_Service_CBUUID = BLE_CalThings_Service_CBUUID;
//let BLE_Default_Service_CBUUID = BLE_Battery_Service_CBUUID;

//MARK: Scene Seques
let sequeDeviceScene = "showDeviceScene"

enum bleState {
    case Off
    case On
    case Searching
    case Selected
    case Connecting
    case Connected
    case Cancelling
    case Disconnecting
}

enum connectForMode : Int {
    case forOperation = 0
    case forConsole = 1
}

class ViewController:
    UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    UIPickerViewDelegate,
    UIPickerViewDataSource,
    CBCentralManagerDelegate
{
    //MARK: Properties
    @IBOutlet weak var searchByButton: UISegmentedControl!
    @IBOutlet weak var serviceUUID: UITextField!
    @IBOutlet weak var searchActivity: UIActivityIndicatorView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchStatus: UILabel!
    @IBOutlet weak var deviceTable: UITableView!
    @IBOutlet weak var termPort: UITextField!
    
    // MARK: Core Bluetooth members
    var centralMan : CBCentralManager?
    var foundPeripheral : CBPeripheral?

    var state : bleState = bleState.Cancelling

    // MARK: search mode
    var searchByName = false
    var searchName = "B0"

    // MARK: device table database
    var devices = [CBPeripheral]()

    // MARK: peripheral services database
    var services = [CBService]()

    // MARK: connection mode list
    var connmodeList = [String]()
    var connectionMode : connectForMode = .forOperation

    override func viewDidLoad() {
        super.viewDidLoad()

        connmodeList = ["Operation", "Debug"]
        connectionMode = .forOperation

        searchActivity.hidesWhenStopped = true
        searchByButton.selectedSegmentIndex = 0

        // setup delegate and datasource for table
        deviceTable.delegate = self
        deviceTable.dataSource = self

        // start off in powered down state
        setState(bleState.Off)

        setTextFields()

        // Creates a dispatch queue for concurrent central operations
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.cci.blecentralq", attributes: .concurrent)

        // Create a core bluetooth central manager
        centralMan = CBCentralManager(delegate: self, queue: centralQueue)

    }

    func setTextFields() {
        let toolbar = UIToolbar()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                    target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done,
                                    target: self, action: #selector(doneButtonTapped))
           
        toolbar.setItems([flexSpace, doneButton], animated: true)
        toolbar.sizeToFit()

        termPort.keyboardType = UIKeyboardType.numberPad;
        termPort.inputAccessoryView = toolbar

        if searchByName {
            serviceUUID.text = searchName
        }
        else {
            serviceUUID.text = BLE_Default_Service_CBUUID.uuidString
        }
        
        termPort.text = "8889"
        
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == sequeDeviceScene {
            let blevc = segue.destination as! BLEperipheralViewController
            blevc.parentView = self
            blevc.centralMan = centralMan
            blevc.thePeripheral = foundPeripheral
            blevc.termPort = UInt16(termPort.text ?? "8889", radix: 10) ?? 8889
        }
    }

    //MARK: State functions
    func setState(_ newState: bleState) {
        var servUUID = BLE_Default_Service_CBUUID

        if newState == state {
            return
        }
        if state == bleState.Searching {
            centralMan?.stopScan()
        }
        state = newState
        print("New state: \(state)")

        switch state {
        case .Off:
            self.searchActivity.startAnimating()
            searchStatus.text = "Starting BLE Radio"
            searchButton.setTitle("Search", for: .normal)
            searchButton.isEnabled = false
            serviceUUID.text = ""
        case .On:
            self.searchActivity.stopAnimating()
            searchStatus.text = "Press Search to find Devices"
            searchButton.setTitle("Search", for: .normal)
            searchButton.isEnabled = true
        case .Searching:
            deviceTable_clear()
            if let servUUIDstr = serviceUUID.text {
                if searchByName {
                    searchName = servUUIDstr
                    print("Searching for Name pattern \(searchName)")
                    centralMan?.scanForPeripherals(withServices: nil)
                }
                else {
                    servUUID = CBUUID(string: servUUIDstr)
                    print("Searching for UUID \(servUUID)")
                    centralMan?.scanForPeripherals(withServices: [servUUID])
                }
            }
            searchActivity.startAnimating()
            searchStatus.text = "Searching"
            searchButton.setTitle("Stop Searching", for: .normal)
            searchButton.isEnabled = true
        case .Selected:
            services.removeAll()
            searchActivity.stopAnimating()
            searchStatus.text = "Press Connect to Connect"
            searchButton.setTitle("Connect", for: .normal)
            searchButton.isEnabled = true
        case .Connecting:
            if foundPeripheral != nil {
                centralMan?.connect(foundPeripheral!)
                searchActivity.startAnimating()
                searchStatus.text = "Connecting"
                searchButton.setTitle("Cancel", for: .normal)
            }
            searchButton.isEnabled = true
        case .Connected:
            searchActivity.stopAnimating()
            searchStatus.text = "Connected"
            searchButton.setTitle("Disconnect", for: .normal)
            searchButton.isEnabled = true
            self.performSegue(withIdentifier: sequeDeviceScene, sender: self)
        case .Cancelling:
            searchActivity.startAnimating()
            searchStatus.text = "Cancelling"
            searchButton.setTitle("Cancel", for: .normal)
            searchButton.isEnabled = false
        case .Disconnecting:
            if foundPeripheral != nil {
                centralMan?.cancelPeripheralConnection(foundPeripheral!)
                searchActivity.startAnimating()
                searchStatus.text = "Disconnecting"
            }
            searchButton.isEnabled = true
        }
    }

    //MARK: Device Table functions
    func deviceTable_clear() {
        devices.removeAll()
        deviceTable.reloadData()
    }

    //MARK: Device TableView functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)

        cell.textLabel?.text = devices[indexPath.row].name
        cell.detailTextLabel?.text = devices[indexPath.row].identifier.uuidString
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        foundPeripheral = devices[indexPath.row]
        setState(bleState.Selected)
        //self.performSegue(withIdentifier: sequeDeviceScene, sender: self)
    }

    //MARK: Connection Mode PickerViewDataSource functions
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return connmodeList.count
    }

    //MARK: Connection Mode PickerViewDelegate functions
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return connmodeList[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let conmode = connectForMode(rawValue: row) {
            connectionMode = conmode
        }
    }

    //MARK: CBCentralManagerDelegate functions
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {
        case .unknown:
            print("Bluetooth status is UNKNOWN")
        case .resetting:
            print("Bluetooth status is RESETTING")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
        @unknown default:
            print("Bluetooth status is Unknown")
        }

        if central.state == .poweredOn {
            DispatchQueue.main.async { () -> Void in
                self.setState(bleState.On)
            }
        }
        else {
            DispatchQueue.main.async { () -> Void in
                self.setState(bleState.Off)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if let pername = peripheral.name {
            print("Found \(pername)")

            if searchByName {
                if !searchName.isEmpty {
                    if pername.lowercased().range(of: searchName.lowercased()) == nil {
                        return
                    }
                }
            }
            // add peripheral to array
            //
            print("Added \(pername)")
            if !devices.contains(peripheral) {
                devices += [peripheral]
                DispatchQueue.main.async {
                    self.deviceTable.reloadData()
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name!)")
        DispatchQueue.main.async { () -> Void in
            self.setState(bleState.Connected)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let pn = peripheral.name {
            print("Disconnected from \(pn)")
        }
        else {
            print("Disconnected from anonymous periperhal")
        }
        DispatchQueue.main.async { () -> Void in
            // pop back to root view
            let navigation = self.navigationController
            navigation?.popToRootViewController(animated: true)

            // reset state
            self.setState(bleState.Selected)
        }
    }

    //MARK: Action functions
    @IBAction func onSearchByName(_ sender: Any) {
        searchByName = searchByButton.selectedSegmentIndex == 0
        if searchByName {
            serviceUUID.text = searchName
        }
        else {
            serviceUUID.text = BLE_Default_Service_CBUUID.uuidString
        }
        deviceTable_clear()
        self.setState(bleState.On)
    }

    @IBAction func searchButton_Press(_ sender: Any) {
        //        self.performSegue(withIdentifier: sequePerfScene, sender: self)
        //        return
        switch state {
        case .Off:
            searchButton.isEnabled = false // can't get here
        case .On:
            setState(bleState.Searching)
        case .Searching:
            setState(bleState.On)
        case .Selected:
            setState(bleState.Connecting)
        case .Connecting:
            setState(bleState.On)
        case .Connected:
            setState(bleState.Disconnecting)
        case .Cancelling:
            searchButton.isEnabled = false // can't get here
        case .Disconnecting:
            searchButton.isEnabled = false // can't get here
        }
    }
}

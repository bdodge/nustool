//
//  BLEutils.swift
//  magtool
//
//  Created by Brian Dodge on 1/23/19.
//

import Foundation
import CoreBluetooth

let LevelHomeUUID           = CBUUID(string:"FDBF")

let HAPaccessoryInfoUUID    = CBUUID(string:"0000003E-0000-1000-8000-0026BB765291")
let HAPprotocolInoUUID      = CBUUID(string:"000000A2-0000-1000-8000-0026BB765291")
let HAPparingServiceUUID    = CBUUID(string:"00000055-0000-1000-8000-0026BB765291")
let HAPlockMechanismUUID    = CBUUID(string:"00000045-0000-1000-8000-0026BB765291")
let HAPlockManagmentUUID    = CBUUID(string:"00000044-0000-1000-8000-0026BB765291")

let HAPlockMechCurrentState = CBUUID(string:"0000001D-0000-1000-8000-0026BB765291")
let HAPlockMechTargetState  = CBUUID(string:"0000001E-0000-1000-8000-0026BB765291")
let HAPlockMechName         = CBUUID(string:"00000023-0000-1000-8000-0026BB765291")

let NordicNUSUUID           = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
let NordicNUSRxUUID         = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
let NordicNUSTxUUID         = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

public enum LevelHomecharacteristicUUIDs : UInt16 {
    case CommandCharacteristicShortID             = 0x0010
    case StatusCharacteristicShortID              = 0x0011
    case ResponseCharacteristicShortID            = 0x0012
    case DFUControlPointCharacteristicShortID     = 0x0013
    case DFUPacketCharacteristicShortID           = 0x0014
    case LevelServiceChangedCharacteristicShortID = 0x0015
    case ConsoleCharacteristicShortID             = 0x0002
    case SidewalkCharacteristicShortID            = 0x96C9  // This value is from SidewalkConfig.c
}

class BLEutils {
    
    let sig_base_uuid = "0000-1000-8000-00805F9B34FB"

    enum GATTserviceUUIDs : UInt16 {
        case None = 0
        case AlertNotification = 0x1811
        case AndroidHearingAssistant = 0xFDF0
        case Battery = 0x180F
        case BloodPressure = 0x1810
        case CurrentTimeService = 0x1805
        case CyclingSpeedandCadence = 0x1816
        case DeviceInformation = 0x180A
        case GenericAccess = 0x1800
        case GenericAttribute = 0x1801
        case Glucose = 0x1808
        case HealthThermometer = 0x1809
        case HeartRate = 0x180D
        case HumanInterfaceDevice = 0x1812
        case ImmediateAlert = 0x1802
        case LinkLoss = 0x1803
        case NextDSTChange = 0x1807
        case PhoneAlertStatus = 0x180E
        case ReferenceTimeUpdateService = 0x1806
        case RunningSpeedandCadence = 0x1814
        case ScanParameters = 0x1813
        case TxPower = 0x1804
        case SimpleKeyService = 0xFFE0
        case LevelHome = 0xFDBF
    }

    enum GATTcharacteristicUUIDs : UInt16 {
        case None = 0
        case AlertCategoryID = 0x2A43
        case AlertCategoryIDBitMask = 0x2A42
        case AlertLevel = 0x2A06
        case AlertNotificationControlPoint = 0x2A44
        case AlertStatus = 0x2A3F
        case Appearance = 0x2A01
        case BatteryLevel = 0x2A19
        case BloodPressureFeature = 0x2A49
        case BloodPressureMeasurement = 0x2A35
        case BodySensorLocation = 0x2A38
        case BootKeyboardInputReport = 0x2A22
        case BootKeyboardOutputReport = 0x2A32
        case BootMouseInputReport = 0x2A33
        case CSCFeature = 0x2A5C
        case CSCMeasurement = 0x2A5B
        case CurrentTime = 0x2A2B
        case DateTime = 0x2A08
        case DayDateTime = 0x2A0A
        case DayofWeek = 0x2A09
        case DeviceName = 0x2A00
        case DSTOffset = 0x2A0D
        case ExactTime256 = 0x2A0C
        case FirmwareRevisionString = 0x2A26
        case GlucoseFeature = 0x2A51
        case GlucoseMeasurement = 0x2A18
        case GlucoseMeasurementContext = 0x2A34
        case HardwareRevisionString = 0x2A27
        case HeartRateControlPoint = 0x2A39
        case HeartRateMeasurement = 0x2A37
        case HIDControlPoint = 0x2A4C
        case HIDInformation = 0x2A4A
        case IEEE11073_20601RegulatoryCertificationDataList = 0x2A2A
        case IntermediateCuffPressure = 0x2A36
        case IntermediateTemperature = 0x2A1E
        case LocalTimeInformation = 0x2A0F
        case ManufacturerNameString = 0x2A29
        case MeasurementInterval = 0x2A21
        case ModelNumberString = 0x2A24
        case NewAlert = 0x2A46
        case PeripheralPreferredConnectionParameters = 0x2A04
        case PeripheralPrivacyFlag = 0x2A02
        case PnPID = 0x2A50
        case ProtocolMode = 0x2A4E
        case ReconnectionAddress = 0x2A03
        case RecordAccessControlPoint = 0x2A52
        case ReferenceTimeInformation = 0x2A14
        case Report = 0x2A4D
        case ReportMap = 0x2A4B
        case RingerControlPoint = 0x2A40
        case RingerSetting = 0x2A41
        case RSCFeature = 0x2A54
        case RSCMeasurement = 0x2A53
        case SCControlPoint = 0x2A55
        case ScanIntervalWindow = 0x2A4F
        case ScanRefresh = 0x2A31
        case SensorLocation = 0x2A5D
        case SerialNumberString = 0x2A25
        case ServiceChanged = 0x2A05
        case SoftwareRevisionString = 0x2A28
        case SupportedNewAlertCategory = 0x2A47
        case SupportedUnreadAlertCategory = 0x2A48
        case SystemID = 0x2A23
        case TemperatureMeasurement = 0x2A1C
        case TemperatureType = 0x2A1D
        case TimeAccuracy = 0x2A12
        case TimeSource = 0x2A13
        case TimeUpdateControlPoint = 0x2A16
        case TimeUpdateState = 0x2A17
        case TimewithDST = 0x2A11
        case TimeZone = 0x2A0E
        case TxPowerLevel = 0x2A07
        case UnreadAlertStatus = 0x2A45
        case AggregateInput = 0x2A5A
        case AnalogInput = 0x2A58
        case AnalogOutput = 0x2A59
        case CyclingPowerControlPoint = 0x2A66
        case CyclingPowerFeature = 0x2A65
        case CyclingPowerMeasurement = 0x2A63
        case CyclingPowerVector = 0x2A64
        case DigitalInput = 0x2A56
        case DigitalOutput = 0x2A57
        case ExactTime100 = 0x2A0B
        case LNControlPoint = 0x2A6B
        case LNFeature = 0x2A6A
        case LocationandSpeed = 0x2A67
        case Navigation = 0x2A68
        case NetworkAvailability = 0x2A3E
        case PositionQuality = 0x2A69
        case ScientificTemperatureinCelsius = 0x2A3C
        case SecondaryTimeZone = 0x2A10
        case String = 0x2A3D
        case TemperatureinCelsius = 0x2A1F
        case TemperatureinFahrenheit = 0x2A20
        case TimeBroadcast = 0x2A15
        case BatteryLevelState = 0x2A1B
        case BatteryPowerState = 0x2A1A
        case PulseOximetryContinuousMeasurement = 0x2A5F
        case PulseOximetryControlPoint = 0x2A62
        case PulseOximetryFeatures = 0x2A61
        case PulseOximetryPulsatileEvent = 0x2A60
        case SimpleKeyState = 0xFFE1
    }

    enum GATTdescriptorUUIDs : UInt16 {
        case CharacteristicExtendedProperties = 0x2900
        case CharacteristicUserDescription = 0x2901
        case ClientCharacteristicConfiguration = 0x2902
        case ServerCharacteristicConfiguration = 0x2903
        case CharacteristicPresentationFormat = 0x2904
        case CharacteristicAggregateFormat = 0x2905
        case ValidRange = 0x2906
        case ExternalReportReference = 0x2907
        case ReportReference = 0x2908
    }

    var NUSserviceUUIDS : [CBUUID] = [
        NordicNUSUUID,
    ]
    
    var NUSserviceNames : [String] = [
        "Nordic NUS (Uart)",
    ]
    
    var NUScharUUIDS : [CBUUID] = [
        NordicNUSRxUUID,
        NordicNUSTxUUID,
    ]
    
    var NUScharNames : [String] = [
        "Nordic NUS Rx",
        "Nordic NUS Tx",
    ]
    
    var HAPserviceUUIDS : [CBUUID] = [
        HAPaccessoryInfoUUID,
        HAPprotocolInoUUID,
        HAPparingServiceUUID,
        HAPlockMechanismUUID,
        HAPlockManagmentUUID
    ]
    
    var HAPserviceNames : [String] = [
        "HAP Accessory Info",
        "HAP Protocol Info",
        "HAP Pairing Service",
        "HAP Lock Mechanism",
        "HAP Lock Managment"
    ]
    
    var HAPcharUUIDS : [CBUUID] = [
        HAPlockMechCurrentState,
        HAPlockMechTargetState,
        HAPlockMechName,
    ]
    
    var HAPcharNames : [String] = [
        "HAP Lock Mech Current State",
        "HAP Lock Mech Target State",
        "HAP Lock Mech Name"
    ]
    
    func isSigUUID(_ uuid: CBUUID) -> Bool {
        if uuid.uuidString.count == 4 {
            return true
        }
        // if everything but the first 8 chars matches sig base, it is a sig uuid
        let us = uuid.uuidString
        let baseuuid = us[us.index(us.startIndex, offsetBy: 9)..<us.index(us.startIndex, offsetBy: us.count)]

        if String(baseuuid) == sig_base_uuid {
            return true
        }
        return false
    }
    
    func uuid16String(_ uuid: CBUUID) -> String {
        let us = uuid.uuidString
        if (us.count == 4) {
            return us
        }
        let baseuuid = us[us.index(us.startIndex, offsetBy: 4)..<us.index(us.startIndex, offsetBy: 8)]
        return String(baseuuid)
    }
    
    func nameForService(uuid : CBUUID) -> String {
        let us : String

        if isSigUUID(uuid) {
            us = uuid16String(uuid)
        }
        else {
            us = uuid.uuidString
        }

        if us.count == 4 {
            // a 16 bit uuid, must be sig
            //
            if let uuid16 = UInt16(us, radix: 16) {
                if let eservice = GATTserviceUUIDs(rawValue: uuid16) {
                    return String(describing: eservice)
                }
            }
        }
        for i in 0..<NUSserviceUUIDS.count {
            if (uuid.isEqual(NUSserviceUUIDS[i])) {
                return NUSserviceNames[i]
            }
        }
        for i in 0..<HAPserviceUUIDS.count {
            if (uuid.isEqual(HAPserviceUUIDS[i])) {
                return HAPserviceNames[i]
            }
        }
        return uuid.uuidString
    }

    func nameFor(service: CBService) -> String {
        return nameForService(uuid: service.uuid)
    }
    
    func nameForCharacteristic(uuid : CBUUID) -> String {
        let us : String
        
        if isSigUUID(uuid) {
            us = uuid16String(uuid)
        }
        else {
            us = uuid.uuidString
        }
        
        if us.count == 4 {
            if let uuid16 = UInt16(us, radix: 16) {
                if let echar = GATTcharacteristicUUIDs(rawValue: uuid16) {
                    return String(describing: echar)
                }
            }
            if let uuid16 = UInt16(us, radix: 16) {
                if let echar = LevelHomecharacteristicUUIDs(rawValue: uuid16) {
                    return String(describing: echar)
                }
            }
        }
        for i in 0..<NUScharUUIDS.count {
            if (uuid.isEqual(NUScharUUIDS[i])) {
                return NUScharNames[i]
            }
        }
        for i in 0..<HAPcharUUIDS.count {
            if (uuid.isEqual(HAPcharUUIDS[i])) {
                return HAPcharNames[i]
            }
        }
        return uuid.uuidString
    }
    
    func nameFor(characteristic: CBCharacteristic?) -> String {
        if characteristic == nil {
            return ""
        }
        // if the characteristic has descriptors and a user description,
        // use that if the value is filled
        //
        if characteristic!.descriptors != nil {
            for desc in characteristic!.descriptors! {
                if desc.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString {
                    if desc.value != nil {
                        return descriptorValueAsString(for: desc, includingTitle: false)
                    }
                }
            }
        }
        return nameForCharacteristic(uuid: characteristic!.uuid)
    }
    
    func descriptorValueAsString(for descriptor: CBDescriptor, includingTitle: Bool) -> String {
        
        var description: String?
        var value: String?
        
        switch descriptor.uuid.uuidString {
        case CBUUIDCharacteristicFormatString:
            if let data = descriptor.value as? Data {
                description = "Characteristic format: "
                value = data.description
            }
        case CBUUIDCharacteristicUserDescriptionString:
            if let val = descriptor.value as? String {
                description = "User description: "
                value = val
            }
        case CBUUIDCharacteristicExtendedPropertiesString:
            if let val = descriptor.value as? NSNumber {
                description = "Extended Properties: "
                value = val.description
            }
        case CBUUIDClientCharacteristicConfigurationString:
            if let val = descriptor.value as? NSNumber {
                description = "Client characteristic configuration: "
                value = val.description
            }
        case CBUUIDServerCharacteristicConfigurationString:
            if let val = descriptor.value as? NSNumber {
                description = "Server characteristic configuration: "
                value = val.description
            }
        case CBUUIDCharacteristicAggregateFormatString:
            if let val = descriptor.value as? String {
                description = "Characteristic aggregate format: "
                value = val
            }
        default:
            break
        }
        
        if let desc=description, let val = value  {
            if includingTitle {
                return "\(desc)\(val)"
            }
            else {
                return "\(val)"
            }
        } else {
            if includingTitle {
                return "Unknown descriptor ???"
            }
            else {
                return "???"
            }
        }
    }
    
    func formatValue(for characteristic: CBCharacteristic) -> String {
        if let v : Data = characteristic.value {
            let size = v.count
            var isascii = true
            var somezeros = false
            var vs : String = String("")

            // sniff out type of data
            for i in 0..<size {
                let av = UInt8(v[i])
                if ((av < 0x20 && av != 0xA && av != 0xD && av != 0x8 && av != 0x9 && av != 0x1B) || av > 0x7f) {
                    if av != 0 {
                        isascii = false
                        break
                    }
                    else {
                        somezeros = true
                    }
                }
                else if somezeros {
                    isascii = false
                    break
                }
                else {
                    vs += String(UnicodeScalar(av))
                }
            }
            if isascii {
                return vs
            }
            else {
                vs = ""
                for i in 0..<size {
                    vs += String(format: "%02X ", v[i])
                }
            }
            return vs
        }
        return "<no value>"
    }
}

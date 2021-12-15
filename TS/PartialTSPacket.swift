//
//  PartialTSPacket.swift
//  SwiftH264
//
//  Created by admin on 2021/11/02.
//  Copyright © 2021 zhongzhendong. All rights reserved.
//

import Foundation

struct PartialTSPacket {
    
    static let length: Int = 188
    static let headerSize: Int = 4
    static let syncByte: UInt8 = 0x47
    
    var syncByte                  : UInt8  = PartialTSPacket.syncByte
    var transportErrorIndicator   : Bool   = false
    var payloadUnitStartIndicator : Bool   = false
    var transportPriority         : Bool   = false
    var pid                       : UInt16 = 0
    var transportScamblingControl : UInt8  = 0
    var adaptationFieldFlag       : Bool   = false
    var payloadFlag               : Bool   = false
    var continuityCounter         : UInt8  = 0
    var adaptationField           : TSAdaptationField?
    var payloadOffset             : Int   = 0
    var payloadLength             : Int   = 0
    
    var payload = Data()
    init() {
        
    }
    
    private var remain: Int {
        var adaptationFieldSize: Int = 0
        if let adaptationField: TSAdaptationField = adaptationField, adaptationFieldFlag {
            adaptationField.compute()
            adaptationFieldSize = Int(adaptationField.length) + 1
        }
        return PartialTSPacket.length - PartialTSPacket.headerSize - adaptationFieldSize - payload.count
    }
    
    init?(data: Data) {
        guard PartialTSPacket.length == data.count else {
            return nil
        }
        self.data = data
        if syncByte != PartialTSPacket.syncByte {
            return nil
        }
    }
    
    mutating func fill(_ data: Data?, useAdaptationField: Bool) -> Int {
        guard let data: Data = data else {
            payload.append(Data(repeating: 0xff, count: remain))
            return 0
        }
        payloadFlag = true
        let length: Int = min(data.count, remain, 182)
        payload.append(data[0..<length])
        if remain == 0 {
            return length
        }
        if useAdaptationField {
            adaptationFieldFlag = true
            if adaptationField == nil {
                adaptationField = TSAdaptationField()
            }
            adaptationField?.stuffing(remain)
            adaptationField?.compute()
            return length
        }
        payload.append(Data(repeating: 0xff, count: remain))
        return length
    }
    
    func dump() {
        
        print(String(format: """
            syncByte : %02X \
            transportErrorIndicator : %02X \
            payloadUnitStartIndicator : %02X \
            transportPriority : %02X \
            pid : %02X \
            transportScamblingControl : %02X \
            adaptationFieldFlag : %02X \
            payloadFlag : %02X \
            continuityCounter : %02X
            """, syncByte,
                     transportErrorIndicator,
                     payloadUnitStartIndicator,
                     transportPriority,
                     pid,
                     transportScamblingControl,
                     adaptationFieldFlag,
                     payloadFlag,
                     continuityCounter
                    )
        )
        
        if let data = adaptationField {
            data.dump()
        } else {
            print("No adaptationField")
        }
        
    }
}

extension PartialTSPacket: DataConvertible {
    var data: Data {
        get {
            var bytes = Data([syncByte, 0x00, 0x00, 0x00])
            bytes[1] |= transportErrorIndicator ? 0x80 : 0
            bytes[1] |= payloadUnitStartIndicator ? 0x40 : 0
            bytes[1] |= transportPriority ? 0x20 : 0
            bytes[1] |= UInt8(pid >> 8)
            bytes[2] |= UInt8(pid & 0x00FF)
            bytes[3] |= transportScamblingControl << 6
            bytes[3] |= adaptationFieldFlag ? 0x20 : 0
            bytes[3] |= payloadFlag ? 0x10 : 0
            bytes[3] |= continuityCounter
            return ByteArray()
                .writeBytes(bytes)
                .writeBytes(adaptationFieldFlag ? adaptationField!.data : Data())
                .data
        }
        
        set {
            
            let buffer = ByteArray(data: newValue)
            do {
                let data: Data = try buffer.readBytes(4)
                syncByte = data[0]
                transportErrorIndicator = (data[1] & 0x80) == 0x80
                payloadUnitStartIndicator = (data[1] & 0x40) == 0x40
                transportPriority = (data[1] & 0x20) == 0x20
                pid = UInt16(data[1] & 0x1f) << 8 | UInt16(data[2])
                transportScamblingControl = UInt8(data[3] & 0xc0)
                adaptationFieldFlag = (data[3] & 0x20) == 0x20
                payloadFlag = (data[3] & 0x10) == 0x10
                continuityCounter = UInt8(data[3] & 0xf)
                if adaptationFieldFlag {
                    let length = Int(try buffer.readUInt8())
                        if (length != 0) {
                            buffer.position -= 1
                            adaptationField = TSAdaptationField(data: try buffer.readBytes(length + 1))
                    }
                }
                if payloadFlag {
                    payload = try buffer.readBytes(buffer.bytesAvailable)
                }
            } catch {
                print("Error PartialTSPacket")
            }
        }
    }
}
// MARK: -
struct TSTimestamp {
    static let resolution: Double = 90 * 1000 // 90kHz
    static let PTSMask: UInt8 = 0x10
    static let PTSDTSMask: UInt8 = 0x30

    static func decode(_ data: Data) -> UInt64 {
        var result: UInt64 = 0
        result |= UInt64(data[0] & 0x0e) << 29
        result |= UInt64(data[1]) << 22 | UInt64(data[2] & 0xfe) << 14
        result |= UInt64(data[3]) << 7 | UInt64(data[3] & 0xfe) << 1
        return result
    }

    static func encode(_ b: UInt64, _ m: UInt8) -> Data {
        var data = Data(count: 5)
        data[0] = UInt8(truncatingIfNeeded: b >> 29) | 0x01 | m
        data[1] = UInt8(truncatingIfNeeded: b >> 22)
        data[2] = UInt8(truncatingIfNeeded: b >> 14) | 0x01
        data[3] = UInt8(truncatingIfNeeded: b >> 7)
        data[4] = UInt8(truncatingIfNeeded: b << 1) | 0x01
        return data
    }
}

// MARK: -
struct TSProgramClockReference {
    static let resolutionForBase: Int32 = 90 * 1000 // 90kHz
    static let resolutionForExtension: Int32 = 27 * 1000 * 1000 // 27MHz

    static func decode(_ data: Data) -> (UInt64, UInt16) {
        var b: UInt64 = 0
        var e: UInt16 = 0
        b |= UInt64(data[0]) << 25
        b |= UInt64(data[1]) << 17
        b |= UInt64(data[2]) << 9
        b |= UInt64(data[3]) << 1
        b |= ((data[4] & 0x80) == 0x80) ? 1 : 0
        e |= UInt16(data[4] & 0x01) << 8
        e |= UInt16(data[5])
        return (b, e)
    }

    static func encode(_ b: UInt64, _ e: UInt16) -> Data {
        var data = Data(count: 6)
        data[0] = UInt8(truncatingIfNeeded: b >> 25)
        data[1] = UInt8(truncatingIfNeeded: b >> 17)
        data[2] = UInt8(truncatingIfNeeded: b >> 9)
        data[3] = UInt8(truncatingIfNeeded: b >> 1)
        data[4] = 0xff
        if (b & 1) == 1 {
            data[4] |= 0x80
        } else {
            data[4] &= 0x7f
        }
        if UInt16(data[4] & 0x01) >> 8 == 1 {
            data[4] |= 1
        } else {
            data[4] &= 0xfe
        }
        data[5] = UInt8(truncatingIfNeeded: e)
        return data
    }
}

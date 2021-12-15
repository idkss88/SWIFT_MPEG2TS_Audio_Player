//
//  AVVonfigurationRecord.swift
//  SwiftH264
//
//  Created by admin on 2021/11/03.
//  Copyright © 2021 zhongzhendong. All rights reserved.
//

import AVFoundation
import VideoToolbox
import BinaryKit

struct AVCConfigurationRecord {
    static func getData(_ formatDescription: CMFormatDescription?) -> Data? {
        guard let formatDescription = formatDescription else {
            return nil
        }
        if let atoms: NSDictionary = CMFormatDescriptionGetExtension(formatDescription, extensionKey: "SampleDescriptionExtensionAtoms" as CFString) as? NSDictionary {
            return atoms["avcC"] as? Data
        }
        return nil
    }

    static let reserveLengthSizeMinusOne: UInt8 = 0x3F
    static let reserveNumOfSequenceParameterSets: UInt8 = 0xE0
    static let reserveChromaFormat: UInt8 = 0xFC
    static let reserveBitDepthLumaMinus8: UInt8 = 0xF8
    static let reserveBitDepthChromaMinus8 = 0xF8

    var configurationVersion: UInt8 = 1
    var AVCProfileIndication: UInt8 = 0
    var profileCompatibility: UInt8 = 0
    var AVCLevelIndication: UInt8 = 0
    var lengthSizeMinusOneWithReserved: UInt8 = 0
    var numOfSequenceParameterSetsWithReserved: UInt8 = 0
    var sequenceParameterSets: [[UInt8]] = []
    var pictureParameterSets: [[UInt8]] = []

    var chromaFormatWithReserve: UInt8 = 0
    var bitDepthLumaMinus8WithReserve: UInt8 = 0
    var bitDepthChromaMinus8WithReserve: UInt8 = 0
    var sequenceParameterSetExt: [[UInt8]] = []

    var naluLength: Int32 {
        Int32((lengthSizeMinusOneWithReserved >> 6) + 1)
    }

    init() {
    }

    init(data: Data) {
        self.data = data
    }

    func makeFormatDescription(_ formatDescriptionOut: UnsafeMutablePointer<CMFormatDescription?>) -> OSStatus {
        var parameterSetPointers: [UnsafePointer<UInt8>] = [
            UnsafePointer<UInt8>(sequenceParameterSets[0]),
            UnsafePointer<UInt8>(pictureParameterSets[0])
        ]
        var parameterSetSizes: [Int] = [
            sequenceParameterSets[0].count,
            pictureParameterSets[0].count
        ]
        return CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: &parameterSetPointers,
            parameterSetSizes: &parameterSetSizes,
            nalUnitHeaderLength: naluLength,
            formatDescriptionOut: formatDescriptionOut
        )
    }
}

extension AVCConfigurationRecord: DataConvertible {
    // MARK: DataConvertible
    var data: Data {
        get {
            
            var buffer = Binary()
            buffer.writeInt(configurationVersion)
            buffer.writeInt(AVCProfileIndication)
            buffer.writeInt(profileCompatibility)
            buffer.writeInt(AVCLevelIndication)
            buffer.writeInt(lengthSizeMinusOneWithReserved)
            buffer.writeInt(numOfSequenceParameterSetsWithReserved)
            
            for i in 0..<sequenceParameterSets.count {
                buffer.writeInt(UInt16(sequenceParameterSets[i].count))
                buffer.writeBytes(sequenceParameterSets[i])
            }
                
            buffer.writeInt(UInt8(pictureParameterSets.count))
            for i in 0..<pictureParameterSets.count {
                buffer.writeInt(UInt16(pictureParameterSets[i].count))
                buffer.writeBytes(pictureParameterSets[i])
            }
            
            if let data = try? Data(buffer.readBytes(buffer.count) ) {
                return data
            }
            
            return Data()
        }
        set {
            var buffer = Binary(bytes: newValue.bytes)
            do {
                configurationVersion = try buffer.readUInt8()
                AVCProfileIndication = try buffer.readUInt8()
                profileCompatibility = try buffer.readUInt8()
                AVCLevelIndication = try buffer.readUInt8()
                lengthSizeMinusOneWithReserved = try buffer.readUInt8()
                numOfSequenceParameterSetsWithReserved = try buffer.readUInt8()
                let numOfSequenceParameterSets: UInt8 = numOfSequenceParameterSetsWithReserved & ~AVCConfigurationRecord.reserveNumOfSequenceParameterSets
                for _ in 0..<numOfSequenceParameterSets {
                    let length = Int(try buffer.readUInt16())
                    sequenceParameterSets.append(try buffer.readBytes(length))
                }
                let numPictureParameterSets: UInt8 = try buffer.readUInt8()
                for _ in 0..<numPictureParameterSets {
                    let length = Int(try buffer.readUInt16())
                    pictureParameterSets.append(try buffer.readBytes(length))
                }
            } catch {
                print("Error AVCConfigurationRecord")
            }
        }
    }
}

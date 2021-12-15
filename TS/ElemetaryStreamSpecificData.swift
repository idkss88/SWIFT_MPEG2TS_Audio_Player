//
//  ElemetaryStreamSpecificData.swift
//  SwiftH264
//
//  Created by admin on 2021/11/02.
//  Copyright © 2021 zhongzhendong. All rights reserved.
//

import Foundation

struct ElementaryStreamSpecificData {
    static let fixedHeaderSize: Int = 5

    var streamType: UInt8 = 0
    var elementaryPID: UInt16 = 0
    var ESInfoLength: UInt16 = 0
    var ESDescriptors = Data()

    init() {
    }

    init?(_ data: Data) {
        self.data = data
    }
}

extension ElementaryStreamSpecificData: DataConvertible {
    // MARK: DataConvertible
    var data: Data {
        get {
            ByteArray()
                .writeUInt8(streamType)
                .writeUInt16(elementaryPID | 0xe000)
                .writeUInt16(ESInfoLength | 0xf000)
                .writeBytes(ESDescriptors)
                .data
        }
        set {
            let buffer = ByteArray(data: newValue)
            do {
                streamType = try buffer.readUInt8()
                elementaryPID = try buffer.readUInt16() & 0x0fff
                ESInfoLength = try buffer.readUInt16() & 0x01ff
                ESDescriptors = try buffer.readBytes(Int(ESInfoLength))
            } catch {
                print("Error ElementaryStreamSpecificData")
            }
        }
    }
}

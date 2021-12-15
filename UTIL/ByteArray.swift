//
//  ByteArray.swift
//  SwiftH264
//
//  Created by admin on 2021/11/03.
//  Copyright © 2021 zhongzhendong. All rights reserved.
//
import Foundation


extension Data {
    var uint16: UInt16 {
            withUnsafeBytes { $0.bindMemory(to: UInt16.self) }[0]
        }
    
    var uint32: UInt32 {
            withUnsafeBytes { $0.bindMemory(to: UInt32.self) }[0]
        }
}

extension Data {
    var bytes: [UInt8] {
        withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return []
            }
            return [UInt8](UnsafeBufferPointer(start: pointer, count: count))
        }
    }
}


extension Numeric {
    var data: Data {
        var source = self
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}
extension Data {
    var array: [UInt8] { return Array(self) }
}



protocol ByteArrayConvertible {
    var data: Data { get }
    var length: Int { get set }
    var position: Int { get set }
    var bytesAvailable: Int { get }

    subscript(i: Int) -> UInt8 { get set }

    @discardableResult
    func writeUInt8(_ value: UInt8) -> Self
    func readUInt8() throws -> UInt8

    @discardableResult
    func writeInt8(_ value: Int8) -> Self
    func readInt8() throws -> Int8

    @discardableResult
    func writeBytes(_ value: Data) -> Self
    func readBytes(_ length: Int) throws -> Data

    @discardableResult
    func clear() -> Self
}

// MARK: -
open class ByteArray: ByteArrayConvertible {
    static let fillZero: [UInt8] = [0x00]

    static let sizeOfInt8: Int = 1
    static let sizeOfInt16: Int = 2
    static let sizeOfInt24: Int = 3
    static let sizeOfInt32: Int = 4
    static let sizeOfFloat: Int = 4
    static let sizeOfInt64: Int = 8
    static let sizeOfDouble: Int = 8

    public enum Error: Swift.Error {
        case eof
        case parse
    }

    init() {
    }

    init(data: Data) {
        self.data = data
    }

    private(set) var data = Data()

    open var length: Int {
        get {
            data.count
        }
        set {
            switch true {
            case (data.count < newValue):
                data.append(Data(count: newValue - data.count))
            case (newValue < data.count):
                data = data.subdata(in: 0..<newValue)
            default:
                break
            }
        }
    }

    open var position: Int = 0

    open var bytesAvailable: Int {
        data.count - position
    }

    open subscript(i: Int) -> UInt8 {
        get {
            data[i]
        }
        set {
            data[i] = newValue
        }
    }

    open func readUInt8() throws -> UInt8 {
        guard ByteArray.sizeOfInt8 <= bytesAvailable else {
            throw ByteArray.Error.eof
        }
        defer {
            position += 1
        }
        return data[position]
    }

    @discardableResult
    open func writeUInt8(_ value: UInt8) -> Self {
        writeBytes(Data([value]))
    }

    open func readInt8() throws -> Int8 {
        guard ByteArray.sizeOfInt8 <= bytesAvailable else {
            throw ByteArray.Error.eof
        }
        defer {
            position += 1
        }
        return Int8(bitPattern: UInt8(data[position]))
    }
    
    @discardableResult
    open func writeInt8(_ value: Int8) -> Self {
        writeBytes(Data([UInt8(bitPattern: value)]))
    }

    open func readUInt16() throws -> UInt16 {
        guard ByteArray.sizeOfInt16 <= bytesAvailable else {
            throw ByteArray.Error.eof
        }
        position += ByteArray.sizeOfInt16

        return UInt16(data.subdata(in: position - ByteArray.sizeOfInt16..<position).uint16).bigEndian//UInt16(data[position - ByteArray.sizeOfInt16..<position]).bigEndian
    }
    
    @discardableResult
    open func writeUInt16(_ value: UInt16) -> Self {
        writeBytes(value.bigEndian.data)
    }
    /*
    @discardableResult
    open func writeUInt16(_ value: UInt16) -> Self {
        let bytePtr = value.bigEndian.data.array
        return writeBytes(Data(bytePtr))
    }*/
    
    
    open func readUInt24() throws -> UInt32 {
        guard ByteArray.sizeOfInt24 <= bytesAvailable else {
            throw ByteArray.Error.eof
        }
        position += ByteArray.sizeOfInt24

        return UInt32(data.subdata(in: position - ByteArray.sizeOfInt24..<position).uint32).bigEndian
    }

    @discardableResult
    open func writeUInt24(_ value: UInt32) -> Self {
        writeBytes(value.bigEndian.data.subdata(in: 1..<ByteArray.sizeOfInt24 + 1))
    }
    
    open func readUInt32() throws -> UInt32 {
        guard ByteArray.sizeOfInt32 <= bytesAvailable else {
            throw ByteArray.Error.eof
        }
        position += ByteArray.sizeOfInt32
        return UInt32(data[position - ByteArray.sizeOfInt32..<position].uint32).bigEndian
    }

    @discardableResult
    open func writeUInt32(_ value: UInt32) -> Self {
        writeBytes(value.bigEndian.data)
    }
    
    
    /*
    let lenghtByte = UInt16(8)
    let bytePtr = lenghtByte.bigEndian.data.array   // [0, 8]
    
    let source: [UInt8] = [0, 0, 0, 0x0e]
    let bigEndianUInt32 = source.withUnsafeBytes { $0.load(as: UInt32.self) }
    let value = CFByteOrderGetCurrent() == CFByteOrder(CFByteOrderLittleEndian.rawValue)
        ? UInt32(bigEndian: bigEndianUInt32)
        : bigEndianUInt32
    */
    
    
    open func readBytes(_ length: Int) throws -> Data {
        guard length <= bytesAvailable else {
            throw ByteArray.Error.eof
        }
        position += length
        return data.subdata(in: position - length..<position)
    }
    @discardableResult
    open func writeBytes(_ value: Data) -> Self {
        if position == data.count {
            data.append(value)
            position = data.count
            return self
        }
        let length: Int = min(data.count, value.count)
        data[position..<position + length] = value[0..<length]
        if length == data.count {
            data.append(value[length..<value.count])
        }
        position += value.count
        return self
    }

    @discardableResult
    open func clear() -> Self {
        position = 0
        data.removeAll()
        return self
    }

    func sequence(_ length: Int, lambda: ((ByteArray) -> Void)) {
        let r: Int = (data.count - position) % length
        for index in stride(from: data.startIndex.advanced(by: position), to: data.endIndex.advanced(by: -r), by: length) {
            lambda(ByteArray(data: data.subdata(in: index..<index.advanced(by: length))))
        }
        if 0 < r {
            lambda(ByteArray(data: data.advanced(by: data.endIndex - r)))
        }
    }

    /*
    func toUInt32() -> [UInt32] {
        let size: Int = MemoryLayout<UInt32>.size
        if (data.endIndex - position) % size != 0 {
            return []
        }
        var result: [UInt32] = []
        for index in stride(from: data.startIndex.advanced(by: position), to: data.endIndex, by: size) {
            result.append(UInt32(data: data[index..<index.advanced(by: size)]))
        }
        return result
    }
     */
}


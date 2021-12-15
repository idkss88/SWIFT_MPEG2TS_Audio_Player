//
//  Parser+Packets.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

var dataOffset:Int = 0
func ParserPacketCallback(_ context: UnsafeMutableRawPointer,
                          _ byteCount: UInt32,
                          _ packetCount: UInt32,
                          _ data: UnsafeRawPointer,
                          _ packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>?) {
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    let packetDescriptionsOrNil: UnsafeMutablePointer<AudioStreamPacketDescription>? = packetDescriptions
    let isCompressed = packetDescriptionsOrNil != nil
    os_log("%@ - %d [bytes: %i, packets: %i, compressed: %@]", log: Parser.loggerPacketCallback, type: .debug, #function, #line, byteCount, packetCount, "\(isCompressed)")
    //2021-11-29 20:34:40.864992+0900 SwiftH264[10108:477004] [Parser.Packets] ParserPacketCallback(_:_:_:_:_:) - 21 [bytes: 1792, packets: 1, compressed: true]
    //parser.dataFormat Optional(<AVAudioFormat 0x600001179220:  2 ch,  48000 Hz, 'ac-3' (0x00000000) 0 bits/channel, 0 bytes/packet, 1536 frames/packet, 0 bytes/frame>)
    // 31 = 480000/1546
    // 1packet = 32ms = (1/31)
    /// At this point we should definitely have a data format
    ///
    /// 
    guard let dataFormat = parser.dataFormat else {
        return
    }
    
    let time = parser.recvTimetable[parser.callbackCnt]
    print("pacekt CMTime \(time.seconds)")
    /// Iterate through the packets and store the data appropriately
    ///
 
    
    if isCompressed {
        for i in 0 ..< Int(packetCount) {
            let packetDescription = packetDescriptions![i]
            let packetStart = Int(packetDescription.mStartOffset)
            let packetSize = Int(packetDescription.mDataByteSize)
            //let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            let packetData = Data(bytes: data.advanced(by: 0), count: Int(byteCount))
            parser.ac3Data!.append(packetData)
            if (dataFormat.streamDescription.pointee.mFormatID == kAudioFormatMPEG4AAC) {
                print("AAC!!!!")
                if let adtsHeader = ADTSFormatHelper.parseHeader(adtsData: packetData, dataOffset: dataOffset) {
                    dataOffset += adtsHeader.frameLength
                   // parser.packets.append((packetData, packetDescription, time, adtsHeader))
                }
                parser.packets.append((packetData, packetDescription, time, nil))
            } else {
                
                if let ac3Header = AC3FormatHelper.parseHeader(parser: parser, dataOffset: dataOffset) {
                    dataOffset += ac3Header.frameLength
                    print("parser dataOffsets \(dataOffset)")
                    parser.audioFrames.append(ac3Header)
                   
                print("AC-3!!!!")
                    
                parser.packets.append((packetData, packetDescription, time, ac3Header))
                }
            }
        }
    } else {
        let format = dataFormat.streamDescription.pointee
        let bytesPerPacket = Int(format.mBytesPerPacket)
        for i in 0 ..< Int(packetCount) {
            let packetStart = i * bytesPerPacket
            let packetSize = bytesPerPacket
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, nil, CMTime.zero,nil))
        }
    }
    
    parser.callbackCnt += 1
    print("callbackCnt \(parser.callbackCnt)")
}

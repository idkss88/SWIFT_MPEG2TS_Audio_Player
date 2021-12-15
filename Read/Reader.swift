//
//  Reader.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import os.log

/// The `Reader` is a concrete implementation of the `Reading` protocol and is intended to provide the audio data provider for an `AVAudioEngine`. The `parser` property provides a `Parseable` that handles converting binary audio data into audio packets in whatever the original file's format was (MP3, AAC, WAV, etc). The reader handles converting the audio data coming from the parser to a LPCM format that can be used in the context of `AVAudioEngine` since the `AVAudioPlayerNode` requires we provide `AVAudioPCMBuffer` in the `scheduleBuffer` methods.
public class Reader: Reading {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Reader")
    static let loggerConverter = OSLog(subsystem: "com.fastlearner.streamer", category: "Reader.Converter")
    
    
    // MARK: - Reading props
    
    public internal(set) var currentPacket: AVAudioPacketCount = 0
    public let parser: Parser
    public let readFormat: AVAudioFormat
    
    // MARK: - Properties
    
    /// An `AudioConverterRef` used to do the conversion from the source format of the `parser` (i.e. the `sourceFormat`) to the read destination (i.e. the `destinationFormat`). This is provided by the Audio Conversion Services (I prefer it to the `AVAudioConverter`)
    var converter: AudioConverterRef? = nil
    
    /// A `DispatchQueue` used to ensure any operations we do changing the current packet index is thread-safe
    private let queue = DispatchQueue(label: "com.fastlearner.streamer")
    
    // MARK: - Lifecycle
    
    deinit {
        guard AudioConverterDispose(converter!) == noErr else {
            os_log("Failed to dispose of audio converter", log: Reader.logger, type: .error)
            return
        }
    }
    
    public required init(parser: Parser, readFormat: AVAudioFormat) throws {
        self.parser = parser
        
        guard let dataFormat = parser.dataFormat else {
            throw ReaderError.parserMissingDataFormat
        }

        let sourceFormat = dataFormat.streamDescription
        let commonFormat = readFormat.streamDescription
        let result = AudioConverterNew(sourceFormat, commonFormat, &converter)
        guard result == noErr else {
            throw ReaderError.unableToCreateConverter(result)
        }
        /*
        var error = AudioConverterSetProperty(converter!, kAudioConverterDecompressionMagicCookie, parser.magicSize!, parser.cookie!)
        
        if error != noErr {
            print("Could not Set kAudioConverterDecompressionMagicCookie on the Audio Converter!")
        }
         */
        /*
         error = AudioConverterSetProperty(converter!, kAudioConverterOutputChannelLayout, parser.audioChannelLayoutSize!, parser.audioChannelLayout!)
        
        if error != noErr {
            print("Could not Set kAudioConverterOutputChannelLayout on the Audio Converter!")
        }
        */
        self.readFormat = readFormat
        
        os_log("%@ - %d [sourceFormat: %@, destinationFormat: %@]", log: Reader.logger, type: .debug, #function, #line, String(describing: dataFormat), String(describing: readFormat))
    }

    public func readCompressed(_ frames: UInt32) throws -> CMSampleBuffer? {
        
        var status: OSStatus
        var outBlockListBuffer: CMBlockBuffer? = nil
        var sampleBuffer: CMSampleBuffer? = nil
        var sampleBufferWithTiming: CMSampleBuffer? = nil
     
        
        if Int(parser.callbackCnt) < currentPacket + (frames * 1) {
            return sampleBuffer
        }
        
        status = CMBlockBufferCreateEmpty(allocator: kCFAllocatorDefault, capacity: 0, flags: 0, blockBufferOut: &outBlockListBuffer)
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        guard let blockListBuffer = outBlockListBuffer else { throw NSError(domain: NSOSStatusErrorDomain, code: -1) }
        
        var aspdArray:[AudioStreamPacketDescription] = [AudioStreamPacketDescription]()
        var timingArray:[CMSampleTimingInfo] = [CMSampleTimingInfo]()
        aspdArray.reserveCapacity(Int(frames))
        timingArray.reserveCapacity(Int(frames))
        let firstSamplePTS = parser.packets[Int(currentPacket)].2

        let adtsHeaderLength = 7
        var offset = adtsHeaderLength
        
        var storedData : Data = Data()
        for i in 0 ..< frames {
            print("currentPacket : \(currentPacket)")
            let readIndex: UInt32 = UInt32(currentPacket) + i
            let data = parser.packets[Int(readIndex)].0
            let dataSize = data.count
            storedData.append(data: data,offset: 0,size: dataSize)
            let frameLength = dataSize
            print("frameLength \(frameLength)")
            
            aspdArray.append(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(dataSize-adtsHeaderLength)))
            offset += frameLength
            print("idkss88 \(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(frameLength-adtsHeaderLength)))")
            parser.dataFormat?.streamDescription.pointee.mFramesPerPacket
            var timing = CMSampleTimingInfo(duration: CMTime(value: CMTimeValue(Int32((parser.dataFormat?.streamDescription.pointee.mFramesPerPacket)!)), timescale: Int32((parser.dataFormat?.streamDescription.pointee.mSampleRate)!)), presentationTimeStamp: parser.packets[Int(readIndex)].2, decodeTimeStamp: CMTime.invalid)
            timingArray.append(timing)
            /*
            let readIndex: UInt32 = UInt32(currentPacket) + i
            print("index \(i) readIndex \(readIndex)")
            aspdArray.append(parser.packets[Int(readIndex)].1!)
            var timing = CMSampleTimingInfo(duration: CMTime(value: 1536, timescale: Int32(44100)), presentationTimeStamp: parser.packets[Int(readIndex)].2, decodeTimeStamp: CMTime.invalid)
            timingArray.append(timing)
            let data = parser.packets[Int(readIndex)].0
            let dataSize = data.count
            var outBlockBuffer: CMBlockBuffer? = nil
            
            status = CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: nil,
                blockLength: dataSize,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: dataSize,
                flags: kCMBlockBufferAssureMemoryNowFlag,
                blockBufferOut: &outBlockBuffer)
            
            
            guard status == noErr else {
                print("Error CMBlockBufferCreateWithMemoryBlock")
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
            guard let blockBuffer = outBlockBuffer else {
                print("Error blockBuffer is null")
                throw NSError(domain: NSOSStatusErrorDomain, code: -1)
            }
            
            status = data.withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
                return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer, offsetIntoDestination: 0, dataLength: dataSize)
            })
            
            guard status == noErr else {
                print("Error CMBlockBufferReplaceDataBytes")
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
                
            }
            status = CMBlockBufferAppendBufferReference(
                blockListBuffer,
                targetBBuf: blockBuffer,
                offsetToData: 0,
                dataLength: CMBlockBufferGetDataLength(blockBuffer),
                flags: 0)
            
            guard status == noErr else {
                print("Error CMBlockBufferAppendBufferReference")
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
                
            }
             */
        }
        
        var blockBuffer:CMBlockBuffer?
        var osstatus = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                          memoryBlock: nil, blockLength: storedData.count,
                                                          blockAllocator: nil, customBlockSource: nil, offsetToData: 0,
                                                          dataLength: storedData.count, flags: 0, blockBufferOut: &blockBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print("kCMBlockBufferNoErr")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
        osstatus = storedData.withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
            return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: storedData.count)
        })
  

        
        status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer!/*blockListBuffer*/, formatDescription: parser.dataFormat!.formatDescription, sampleCount: CMItemCount(frames), presentationTimeStamp: firstSamplePTS, packetDescriptions: aspdArray, sampleBufferOut: &sampleBuffer)
        guard status == kCMBlockBufferNoErr else {
            print("Error CMAudioSampleBufferCreateReadyWithPacketDescriptions")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
            return nil
        }
        

        status =  CMSampleBufferCreateCopyWithNewTiming(allocator:kCFAllocatorDefault, sampleBuffer: sampleBuffer!, sampleTimingEntryCount:CMItemCount(frames), sampleTimingArray:&timingArray, sampleBufferOut:&sampleBufferWithTiming)
        guard status == kCMBlockBufferNoErr else {
            print("Error CMSampleBufferCreateCopyWithNewTiming")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
            return nil
        }
        
        self.currentPacket = self.currentPacket + frames
        print("test2 \(sampleBufferWithTiming) ")
        

        return sampleBuffer
        /*
        
        let framesPerPacket = readFormat.streamDescription.pointee.mFramesPerPacket
       
        var packets = 1//frames / framesPerPacket
       // print("idkss88 readFormat.streamDescription.pointee.mFramesPerPacket \(readFormat.streamDescription.pointee.mFramesPerPacket) read framesPerPacket \(framesPerPacket) frames \(frames) packets \(packets)")
        /// Allocate a buffer to hold the target audio data in the Read format
        print("index [\(currentPacket)] idkss88 readFormat.streamDescription.pointee.mFramesPerPacket \(readFormat.streamDescription.pointee.mFramesPerPacket) read framesPerPacket \(framesPerPacket) frames \(frames) packets \(packets)")
        var aspdArray:[AudioStreamPacketDescription] = [AudioStreamPacketDescription]()
        aspdArray.reserveCapacity(Int(packets))
        
        aspdArray.append(parser.packets[Int(currentPacket)].1!)
        print("aspd \(aspdArray[0])")
        let data = parser.packets[Int(currentPacket)].0
        let dataSize = data.count
        let presentationTimeStamp = parser.packets[Int(currentPacket)].2
        
        var blockBuffer:CMBlockBuffer?
        var osstatus = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: dataSize, blockAllocator: nil, customBlockSource: nil, offsetToData: 0, dataLength: dataSize, flags: 0, blockBufferOut: &blockBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print("kCMBlockBufferNoErr")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
    
        var sampleBuffer:CMSampleBuffer?
        osstatus = data.withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
            return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: dataSize)
        })
        guard osstatus == kCMBlockBufferNoErr else {
            print("kCMBlockBufferNoErr")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }

        print("formatDescription: parser.dataFormat!.formatDescription \(parser.dataFormat!.formatDescription)")
        print("formatDescription: parser.dataFormat!.formatDescription \(aspdArray)")
        osstatus = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer!, formatDescription: parser.dataFormat!.formatDescription, sampleCount: Int(packets), presentationTimeStamp: presentationTimeStamp, packetDescriptions: aspdArray, sampleBufferOut: &sampleBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print("kCMBlockBufferNoErr")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        self.currentPacket = self.currentPacket + 1
        return sampleBuffer
         */
  
        
    }
    
    
    public func read(_ frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        let framesPerPacket = readFormat.streamDescription.pointee.mFramesPerPacket
       
        var packets = frames / framesPerPacket
        print("idkss88 readFormat.streamDescription.pointee.mFramesPerPacket \(readFormat.streamDescription.pointee.mFramesPerPacket) read framesPerPacket \(framesPerPacket) frames \(frames) packets \(packets)")
        /// Allocate a buffer to hold the target audio data in the Read format
        guard let buffer = AVAudioPCMBuffer(pcmFormat: readFormat, frameCapacity: frames) else {
            throw ReaderError.failedToCreatePCMBuffer
        }
        buffer.frameLength = frames
        // Try to read the frames from the parser
        try queue.sync {
            let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
            let status = AudioConverterFillComplexBuffer(converter!, ReaderConverterCallback, context, &packets, buffer.mutableAudioBufferList, nil)
            
            print("AudioConverterFillComplexBuffer buffer.mutableAudioBufferList.pointee.mNumberBuffers \(buffer.mutableAudioBufferList.pointee.mNumberBuffers)")
            print("AudioConverterFillComplexBuffer buffer.mutableAudioBufferList.pointee.mBuffers \(buffer.mutableAudioBufferList.pointee.mBuffers)")
            guard status == noErr else {
                switch status {
                case ReaderMissingSourceFormatError:
                    print("ReaderMissingSourceFormatError")
                    throw ReaderError.parserMissingDataFormat
                case ReaderReachedEndOfDataError:
                    print("ReaderReachedEndOfDataError")
                    throw ReaderError.reachedEndOfFile
                case ReaderNotEnoughDataError:
                    print("ReaderNotEnoughDataError")
                    throw ReaderError.notEnoughData
                default:
                    print("defaultError")
                    throw ReaderError.converterFailed(status)
                }
            }
        }
        
        return buffer
    }
    
    public func seek(_ packet: AVAudioPacketCount) throws {
        os_log("%@ - %d [packet: %i]", log: Parser.logger, type: .debug, #function, #line, packet)
        
        queue.sync {
            currentPacket = packet
        }
    }
}

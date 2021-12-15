//
//  AC3SampleBufferSource.swift
//  SampleBufferPlayer
//
//  Created by admin on 2021/12/13.
//  Copyright © 2021 Apple. All rights reserved.
//

import AVFoundation
//import Foundation
//import CoreMedia

class AC3SampleBufferSource : TSDemuxDelegate {
    
    func demuxer(_ demuxer: TSDemux, didReadPacketizedElementaryStream data: ElementaryStreamSpecificData, PES: PacketizedElementaryStream) {
        
        print("data is called")
        
        print("idkss88 demxuer is called ")
        if (data.streamType == 27) {
            print("idkss88 demxuer is called ")
        } else {
            print("demuxer callback is called.")
            do {
                guard let parser = parser else {
                    print("Error parser.")
                    return
                }
                
                try parser.parse(data: PES.data,time: CMTimeMake(value: Int64(PES.optionalPESHeader!.PTS), timescale: 1000000000))
                
                print("Reader is \(reader)")
                
                if reader == nil, let _ = parser.dataFormat {
                    do {
                        print("create reader")
                        reader = try Reader(parser: parser, readFormat: readFormat)
                    } catch {
                        print("reader error.")
                    }
                    print("play.")
                }
            } catch {
                print("Error demuxing")
            }
        }
         
    }
    
    
    public internal(set) var parser: Parser?
    public internal(set) var reader: Reader?
    
    
    public lazy var demuxer: TSDemux? = {
        let demuxer = TSDemux()
        print("new demux is initialized \(parser) \(reader)")
        print("self is \(self)")
        demuxer.delegate = self
        return demuxer
    }()
    
    public var readBufferSize: AVAudioFrameCount {
        return 1024//1536
    }
    
    public var readFormat: AVAudioFormat {
        
        var streamDescription = AudioStreamBasicDescription()
        streamDescription.mSampleRate = 48000.0
        streamDescription.mFormatID = kAudioFormatLinearPCM
        streamDescription.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian // no endian flag means little endian
        streamDescription.mBytesPerPacket = 8
        streamDescription.mFramesPerPacket = 1
        streamDescription.mBytesPerFrame = 8
        streamDescription.mChannelsPerFrame = 2
        streamDescription.mBitsPerChannel = 32
        streamDescription.mReserved = 0
        
        
       // var avformat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: true)!
    
       // let outputFormat = AVAudioFormat(streamDescription: &streamDescription)!

        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0 , channels: 2, interleaved: true)!
    }
    


    var ac3Data:Data? = Data()
    var firstSampleOffset: CMTime = CMTime.zero
    var infoHeader = AC3Info()
    var audioFrames = [AC3Info]()
    var audioFormatDesc:CMAudioFormatDescription? = nil
    var framePosition:Int = 0
    private(set) var nextSampleOffset: CMTime = CMTime.zero
    
    deinit {
        print("deinit ADTSSampleBufferSource")
        demuxer = nil
    }
    
    init(fromOffset offset: CMTime) {
        
        firstSampleOffset = offset
        
        self.nextSampleOffset = CMTimeMake(value: 0, timescale: Int32(self.infoHeader.sampleRate))
        
        // Create a new parser
        do {
            parser = try Parser.shared
        } catch {
            print("Error parser.")
        }
        
        self.nextSampleOffset = offset.convertScale(Int32(self.infoHeader.sampleRate), method: .default)
        framePosition = Int(nextSampleOffset.value / Int64(infoHeader.samplesPerFrame))
        
        if framePosition >= audioFrames.count {
            framePosition = 0
        }
        print("self in init \(self)")
        demuxer!.downloader!.ip = "233.15.200.55"
        print("idkss88 init called end")
    }
    
    init?(fileURL: URL, fromOffset offset: CMTime) {
        firstSampleOffset = offset
        self.nextSampleOffset = CMTimeMake(value: 0, timescale: Int32(self.infoHeader.sampleRate))
        guard loadData(url:fileURL) else {
            return nil
        }
        
        guard parseFrames() else {
            return nil
        }
        self.nextSampleOffset = offset.convertScale(Int32(self.infoHeader.sampleRate), method: .default)
        framePosition = Int(nextSampleOffset.value / Int64(infoHeader.samplesPerFrame))
        
        if framePosition >= audioFrames.count {
            framePosition = 0
        }
    }
    
    func loadData(url:URL) -> Bool {
        if let data = try? Data.init(contentsOf: url) {
            self.ac3Data = data
            return true
        }
        
        return false
    }
    
    func loadData() -> Bool {
   
        return true
    }
    
    
    

    /// - Tag: AACParseADTSFrames
    func parseFrames() -> Bool {
        if let data = self.ac3Data {
            var dataOffset:Int = 0
            while dataOffset < data.count {
                
                if let ac3Header = AC3FormatHelper.parseHeader(parser: parser!, dataOffset: dataOffset) {
                    dataOffset += ac3Header.frameLength
                    if dataOffset > data.count {
                        break
                    }
                    
                    if ac3Header.dataOffset == 0 {
                        
                        self.audioFormatDesc = AC3FormatHelper.createAudioFormatDescription(ac3info: ac3Header)
                        
                        if self.audioFormatDesc == nil {
                            return false
                        }
                        
                        self.infoHeader = ac3Header
                    }
                    
                    audioFrames.append(ac3Header)
                } else {
                    return false
                }
            }
            return true
        }
        return false
    }
    
    var index = 0
    
    func nextSampleBuffer_local() throws -> CMSampleBuffer {
        

        if self.audioFrames.count == 0 {
            throw NSError(domain: "AC3 Source", code: -1, userInfo: nil)
        }
        if framePosition >= self.audioFrames.count {
            throw NSError(domain: "AC3 Source", code: -2, userInfo: nil)
        }
         
        print("framePosition \(framePosition) parser!.audioFrames.count \(self.audioFrames.count) index \(index) ")

        print("infoHeader.samplesPerFrame  \(self.audioFrames[index].samplesPerFrame)  audioFrames.count  \(self.audioFrames.count)  framePosition \(framePosition)")
        //let frameCount = min(self.audioFrames[index].samplesPerFrame/parser!.audioFrames[index].samplesPerFrame/*16384*/, self.audioFrames.count - framePosition)
        let frameCount = 1
        print("idkss88 frameCount \(frameCount)")
        let sampleBuffer = buildSampleBuffer_local(framePos: framePosition, frameCount: frameCount, presentationTimeStamp: self.nextSampleOffset)!
        print("result sampleBuffer \(sampleBuffer)")
        framePosition += frameCount
        let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
        nextSampleOffset = pts + duration
        print("NEXT SAMPLE OFFSET:", stime(nextSampleOffset), stime(pts), stime(duration))
        index += 1
        return sampleBuffer
    }
    
    public func buildSampleBuffer_local(framePos:Int, frameCount:Int, presentationTimeStamp:CMTime) -> CMSampleBuffer? {
        var aspdArray:[AudioStreamPacketDescription] = [AudioStreamPacketDescription]()
        aspdArray.reserveCapacity(frameCount)
        /*
         header length
         */

        var offset = 0

        for headerIndex in framePos..<framePos+frameCount {
            let frameLength = self.audioFrames[headerIndex].frameLength

            print("frameLength[\(headerIndex)] \(frameLength)")
            aspdArray.append(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(frameLength)))
            print("idkss88 \(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(frameLength)))")
            offset += frameLength
            print("headerIndex \(headerIndex)")
            self.audioFormatDesc = AC3FormatHelper.createAudioFormatDescription(ac3info: self.audioFrames[headerIndex])
            
        }
  

        let dataOffset = self.audioFrames[framePos].dataOffset
        let dataSize = self.audioFrames[framePos+frameCount-1].dataOffset + self.audioFrames[framePos+frameCount-1].frameLength - dataOffset
 
        print("dataOffset \(dataOffset) framePos \(framePos) frameCount \(frameCount) dataSize \(dataSize)")
        var blockBuffer:CMBlockBuffer?
        var osstatus = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: dataSize, blockAllocator: nil, customBlockSource: nil, offsetToData: 0, dataLength: dataSize, flags: 0, blockBufferOut: &blockBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }

        var sampleBuffer:CMSampleBuffer?
        print(self.ac3Data!.subdata(in: dataOffset..<dataOffset+dataSize).bytes)
        osstatus = self.ac3Data!.subdata(in: dataOffset..<dataOffset+dataSize).withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
            return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: dataSize)
        })
        

        
        
        var data = Data(capacity: dataSize)
        
        var ret = data.withUnsafeMutableBytes({ (blockSamples: UnsafeMutablePointer<Int16>) in
            CMBlockBufferCopyDataBytes(blockBuffer!, atOffset: 0, dataLength: dataSize, destination: blockSamples)
        })
     
        guard ret == kCMBlockBufferNoErr else {
            print("idkss88  CMBlockBufferCopyDataBytes error ")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
        print( "out(\(dataSize)) data \(data.bytes)")
        
        /*
        do {
            print("data[0] \(try blockBuffer?.dataBytes()[0])")
        } catch {
            print("idkss88 error")
        }
        */
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }

        osstatus = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer!, formatDescription: self.audioFormatDesc!, sampleCount: frameCount, presentationTimeStamp: presentationTimeStamp, packetDescriptions: aspdArray, sampleBufferOut: &sampleBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
        
        /*
        var testData = Data(capacity: dataSize)
        
        var testBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer!)
        
        CMBlockBufferCopyDataBytes(testBlockBuffer!, atOffset: 0, dataLength: dataSize, destination: &testData)
        
        print("idkss88 test \(testData.bytes)")
        */
        //reader!.currentPacket = reader!.currentPacket + UInt32(frameCount)
        return sampleBuffer
    }
    
    
    
    func nextSampleBuffer() throws -> CMSampleBuffer {
        

        if parser!.audioFrames.count == 0 {
            throw NSError(domain: "AC3 Source", code: -1, userInfo: nil)
        }
        
        if framePosition >= parser!.audioFrames.count {
            throw NSError(domain: "AC3 Source", code: -2, userInfo: nil)
        }
        
     if parser!.audioFrames.count < 20 {
            print("audioFrames.count \(parser!.audioFrames.count)")
            throw NSError(domain: "AC3 Source", code: -3, userInfo: nil)
        }
         
        print("framePosition \(framePosition) parser!.audioFrames.count \(parser!.audioFrames.count) index \(index) ")

        print("infoHeader.samplesPerFrame  \(parser!.audioFrames[index].samplesPerFrame)  audioFrames.count  \(parser!.audioFrames.count)  framePosition \(framePosition)")
        let frameCount = min(parser!.audioFrames[index].samplesPerFrame/parser!.audioFrames[index].samplesPerFrame/*16384*/, parser!.audioFrames.count - framePosition)
        var audioClock: CMClock?
        CMAudioClockCreate(allocator: nil, clockOut: &audioClock)
        var scaleTime = audioClock!.convertTime(parser!.packets[Int(index)].2, to: audioClock!)
        print("idkss88 self.nextSampleOffset \(self.nextSampleOffset.seconds) parser!.packets[Int(index)].2 \(scaleTime.seconds)")
        let sampleBuffer = buildSampleBuffer(framePos: framePosition, frameCount: frameCount, presentationTimeStamp: /*CMTimeConvertScale(parser!.packets[Int(index)].2,timescale: 44100, method: .quickTime)*/self.nextSampleOffset)!
        print("result sampleBuffer \(sampleBuffer)")

        
        framePosition += frameCount
        let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
        nextSampleOffset = pts + duration
        print("NEXT SAMPLE OFFSET:", stime(nextSampleOffset), stime(pts), stime(duration))
        index += 1
        return sampleBuffer
    }
    /*
    func nextSampleBuffer() throws -> CMSampleBuffer {
        if parser!.callbackCnt < 5  {
            print("idkss88 \(parser!.callbackCnt)")
            throw NSError(domain: "ADTS Source", code: -1, userInfo: nil)
        }
        
        if reader == nil {
            throw NSError(domain: "ADTS Source", code: -2, userInfo: nil)
        }
        
        if reader!.currentPacket >= parser!.callbackCnt {
            print("reader!.currentPacket \(reader!.currentPacket) parser!.callbackCnt \(parser!.callbackCnt)")
            throw NSError(domain: "ADTS Source", code: -3, userInfo: nil)
        }
        
        /*
        if reader == nil, let _ = parser!.dataFormat {
            do {
                print("create reader")
                reader = try Reader(parser: parser!, readFormat: readFormat)
            } catch {
                print("reader error.")
            }
            print("play with nextSampleBuffer.")
        }*/
        /*
        if framePosition >= audioFrames.count {
            throw NSError(domain: "ADTS Source", code: -2, userInfo: nil)
        }*/
        
        print("infoHeader.samplesPerFrame  \(infoHeader.samplesPerFrame)  audioFrames.count  \(audioFrames.count)  framePosition \(framePosition)")
        
       // let frameCount = min(infoHeader.samplesPerFrame/infoHeader.samplesPerFrame/*16384*/, audioFrames.count - framePosition)
        let frameCount = 1
        print("idkss88 frameCount \(frameCount)")
        let sampleBuffer = buildSampleBuffer(framePos: framePosition, frameCount: frameCount, presentationTimeStamp: self.nextSampleOffset)!
        print("result sampleBuffer \(sampleBuffer)")
        framePosition += frameCount
        let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
        nextSampleOffset = pts + duration
        print("NEXT SAMPLE OFFSET:", stime(nextSampleOffset), stime(pts), stime(duration))
        return sampleBuffer
    }
    */
    /*
    /// - Tag: AACBuildSampleBuffer
    public func buildSampleBuffer(framePos:Int, frameCount:Int, presentationTimeStamp:CMTime) -> CMSampleBuffer? {
        
        var aspdArray:[AudioStreamPacketDescription] = [AudioStreamPacketDescription]()
        aspdArray.reserveCapacity(frameCount)
        /*
         header length
         */
        var adtsHeaderLength = self.infoHeader.protectionAbsent ? 7 : 9
        adtsHeaderLength = 7
        var offset = adtsHeaderLength
        
        var storedData : Data = Data()
        for i in 0 ..< frameCount {
         
            let readIndex: UInt32 = UInt32(reader!.currentPacket) + UInt32(i)
            print("readIndex \(readIndex)")
            let data = parser!.packets[Int(readIndex)].0
            let dataSize = data.count
            let frameLength = dataSize
            storedData.append(data: data,offset: 0,size: dataSize)
            aspdArray.append(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(dataSize-adtsHeaderLength)))
            offset += frameLength
            print("idkss88 \(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(frameLength-adtsHeaderLength)))")
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
        
        var sampleBuffer:CMSampleBuffer?
        osstatus = storedData.withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
            return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: storedData.count)
        })
        
        /*
        do {
            print("data[0] \(try blockBuffer?.dataBytes()[0])")
        } catch {
            print("idkss88 error")
        }
        */
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }

        print ("idkss88 formatDescription \(parser!.dataFormat!.formatDescription)")
        osstatus = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer!, formatDescription: parser!.dataFormat!.formatDescription, sampleCount: frameCount, presentationTimeStamp: parser.packets[reader!.currentPacket].2, packetDescriptions: aspdArray, sampleBufferOut: &sampleBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
        
        /*
        var testData = Data(capacity: dataSize)
        
        var testBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer!)
        
        CMBlockBufferCopyDataBytes(testBlockBuffer!, atOffset: 0, dataLength: dataSize, destination: &testData)
        
        print("idkss88 test \(testData.bytes)")
        */
        reader!.currentPacket = reader!.currentPacket + UInt32(frameCount)
        return sampleBuffer
    }
    */
    
    /// - Tag: AACBuildSampleBuffer
    public func buildSampleBuffer(framePos:Int, frameCount:Int, presentationTimeStamp:CMTime) -> CMSampleBuffer? {
        var aspdArray:[AudioStreamPacketDescription] = [AudioStreamPacketDescription]()
        aspdArray.reserveCapacity(frameCount)
        /*
         header length
         */

        var offset = 0

        for headerIndex in framePos..<framePos+frameCount {
           // let frameLength = self.audioFrames[headerIndex].frameLength
            let frameLength = parser!.audioFrames[headerIndex].frameLength
            print("frameLength[\(headerIndex)] \(frameLength)")
            aspdArray.append(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(frameLength)))
            print("idkss88 \(AudioStreamPacketDescription(mStartOffset: Int64(offset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(frameLength)))")
            offset += frameLength
            print("headerIndex \(headerIndex)")
            self.audioFormatDesc = AC3FormatHelper.createAudioFormatDescription(ac3info: parser!.audioFrames[headerIndex])
            
        }
  

     //   let dataOffset = self.audioFrames[framePos].dataOffset
     //   let dataSize = self.audioFrames[framePos+frameCount-1].dataOffset + self.audioFrames[framePos+frameCount-1].frameLength - dataOffset
        let dataOffset = parser!.audioFrames[framePos].dataOffset
        let dataSize = parser!.audioFrames[framePos+frameCount-1].dataOffset + parser!.audioFrames[framePos+frameCount-1].frameLength - dataOffset
        
        print("dataOffset \(dataOffset) framePos \(framePos) frameCount \(frameCount) dataSize \(dataSize)")
        var blockBuffer:CMBlockBuffer?
        var osstatus = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: dataSize, blockAllocator: nil, customBlockSource: nil, offsetToData: 0, dataLength: dataSize, flags: 0, blockBufferOut: &blockBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }

        var sampleBuffer:CMSampleBuffer?
        //print(self.ac3Data!.subdata(in: dataOffset..<dataOffset+dataSize).bytes)
        //osstatus = self.ac3Data!.subdata(in: dataOffset..<dataOffset+dataSize).withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
        //    return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: dataSize)
        //})
        
        print(parser!.ac3Data!.subdata(in: dataOffset..<dataOffset+dataSize).bytes)
        osstatus = parser!.ac3Data!.subdata(in: dataOffset..<dataOffset+dataSize).withUnsafeBytes( { (vp:UnsafeRawBufferPointer) -> OSStatus in
            return CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: dataSize)
        })
        
        
        var data = Data(capacity: dataSize)
        
        var ret = data.withUnsafeMutableBytes({ (blockSamples: UnsafeMutablePointer<Int16>) in
            CMBlockBufferCopyDataBytes(blockBuffer!, atOffset: 0, dataLength: dataSize, destination: blockSamples)
        })
     
        guard ret == kCMBlockBufferNoErr else {
            print("idkss88  CMBlockBufferCopyDataBytes error ")
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
        print( "out(\(dataSize)) data \(data.bytes)")
        
        /*
        do {
            print("data[0] \(try blockBuffer?.dataBytes()[0])")
        } catch {
            print("idkss88 error")
        }
        */
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }

        osstatus = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer!, formatDescription: self.audioFormatDesc!, sampleCount: frameCount, presentationTimeStamp: presentationTimeStamp, packetDescriptions: aspdArray, sampleBufferOut: &sampleBuffer)
        
        guard osstatus == kCMBlockBufferNoErr else {
            print(NSError(domain: NSOSStatusErrorDomain, code: Int(osstatus)))
            return nil
        }
        
        
    /*
        var testData = Data(capacity: dataSize)
        
        var testBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer!)
        
        CMBlockBufferCopyDataBytes(testBlockBuffer!, atOffset: 0, dataLength: dataSize, destination: &testData)
        
        print("idkss88 test \(testData.bytes)")
        */
        
        print("sampleBuffer \(sampleBuffer)")
        return sampleBuffer
    }

    public func stime(_ time:CMTime?) -> String {
        if time == nil {
            return "(null)"
        } else {
            return String(format: "%.4f", time!.seconds)
        }
    }
}



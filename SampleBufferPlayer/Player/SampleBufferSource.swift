/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Class `SampleBufferSource` reads from audio files, and produces audio sample buffers.
*/

import CoreMedia
import AVFoundation


extension Data {
    func splitByLength(length: Int) -> [Data] {
        var lines: [Data] = []
        var start = self.startIndex
        let endIndex = self.endIndex
       
        while start != endIndex {
            let end = start.advanced(by: length)
            
            lines.append(self.subdata(in:start..<end))
        
            start = end
        }
       
        return lines
    }
    
    mutating func append(data: Data, offset: Int, size: Int) {
        let start = data.startIndex + offset
        let end = start + size
        self.append(data[start..<end])
    }
}


class SampleBufferSource {
    
    // The file providing audio samples.
    private let file: AVAudioFile
    // The number of frames to read from the file in a single operation.
    private let frameCount: AVAudioFrameCount = 1024//65_536 / 4
    
    // The time offset from the start of the file of the first sample to use.
    private let firstSampleOffset: CMTime
    
    // The time offset from the start of the file of the next sample to use.
    private(set) var nextSampleOffset: CMTime
    
    // Initializes a new sample buffer source.
    init(fileURL: URL, fromOffset offset: CMTime) throws {
        
        file = try AVAudioFile(forReading: fileURL, commonFormat: .pcmFormatFloat32, interleaved: true)
        firstSampleOffset = offset
        // Compute the actual time offset of the first sample to read, and the file position that
        // corresponds to this time offset.
        nextSampleOffset = offset.convertScale(Int32(file.processingFormat.sampleRate), method: .default)
        
        file.framePosition = nextSampleOffset.value
    }
    
    // Gets the next sample buffer, if there is one.
    func nextSampleBuffer() throws -> CMSampleBuffer {
        // Read data into a new audio buffer, and convert it to a sample buffer.
     
        
        var streamDescription = AudioStreamBasicDescription()
        streamDescription.mSampleRate = 44100.0
        streamDescription.mFormatID = kAudioFormatLinearPCM
        streamDescription.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked // no endian flag means little endian
        streamDescription.mBytesPerPacket = 8
        streamDescription.mFramesPerPacket = 1
        streamDescription.mBytesPerFrame = 8
        streamDescription.mChannelsPerFrame = 2
        streamDescription.mBitsPerChannel = 32
        streamDescription.mReserved = 0
        
        let outputFormat = AVAudioFormat(streamDescription: &streamDescription)!

       // var avformat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: true)!
        //let audioBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat/*file.processingFormat*/, frameCapacity: frameCount)!
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount)!

        print("file.processingFormat FORMAT DESC:", file.processingFormat)

        try file.read(into: audioBuffer, frameCount: frameCount)
        
        
        print("audioBuffer \(audioBuffer.frameCapacity)")
        print("audioBuffer \(audioBuffer.frameLength)")
        print("audioBuffer \(audioBuffer.audioBufferList.pointee.mNumberBuffers)")
        print("audioBuffer \(audioBuffer.audioBufferList.pointee.mBuffers)")
        let sampleBuffer = try makeSampleBuffer(from: audioBuffer, presentationTimeStamp: nextSampleOffset)
        
        // Compute the time of the next sample.
        let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
        nextSampleOffset = pts + duration
        print("sampleBuffer \(sampleBuffer)" )
        
        return sampleBuffer
    }
    
    // A helper method that makes a sample buffer from an audio buffer list.
    private func makeSampleBuffer(from audioListBuffer: AVAudioPCMBuffer, presentationTimeStamp sampleTime: CMTime) throws -> CMSampleBuffer {
        
        let blockBuffer = try makeBlockBuffer(from: audioListBuffer)
        
        var sampleBuffer: CMSampleBuffer? = nil
        
        let err = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            formatDescription: audioListBuffer.format.formatDescription,
            sampleCount: CMItemCount(audioListBuffer.frameLength),
            presentationTimeStamp: sampleTime,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer)
        
        guard err == noErr else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err))
        }
        
        return sampleBuffer! // assume non-null sample buffer if noErr was returned
    }
    
    // A helper method that makes a core media buffer list from an audio buffer list.
    private func makeBlockBuffer(from audioListBuffer: AVAudioPCMBuffer) throws -> CMBlockBuffer {
        
        var status: OSStatus
        var outBlockListBuffer: CMBlockBuffer? = nil
        
        status = CMBlockBufferCreateEmpty(allocator: kCFAllocatorDefault, capacity: 0, flags: 0, blockBufferOut: &outBlockListBuffer)
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        guard let blockListBuffer = outBlockListBuffer else { throw NSError(domain: NSOSStatusErrorDomain, code: -1) }
        
        for audioBuffer in UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: audioListBuffer.audioBufferList)) {
            
            var outBlockBuffer: CMBlockBuffer? = nil
            let dataByteSize = Int(audioBuffer.mDataByteSize)
            print("dataByteSize \(dataByteSize)")
            status = CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: nil,
                blockLength: dataByteSize,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: dataByteSize,
                flags: kCMBlockBufferAssureMemoryNowFlag,
                blockBufferOut: &outBlockBuffer)
            
            guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
            guard let blockBuffer = outBlockBuffer else { throw NSError(domain: NSOSStatusErrorDomain, code: -1) }
            
            status = CMBlockBufferReplaceDataBytes(
                with: audioBuffer.mData!,
                blockBuffer: blockBuffer,
                offsetIntoDestination: 0,
                dataLength: dataByteSize)
            
            guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
            
            
            status = CMBlockBufferAppendBufferReference(
                blockListBuffer,
                targetBBuf: blockBuffer,
                offsetToData: 0,
                dataLength: CMBlockBufferGetDataLength(blockBuffer),
                flags: 0)
            
            guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        }
        
        return blockListBuffer
    }
}

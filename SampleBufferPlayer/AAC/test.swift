//
//  test.swift
//  SampleBufferPlayer
//
//  Created by admin on 2021/12/02.
//  Copyright © 2021 Apple. All rights reserved.
//

import AVFoundation

class ADTSSampleBufferSource2 : TSDemuxDelegate {
    
    func demuxer(_ demuxer: TSDemux, didReadPacketizedElementaryStream data: ElementaryStreamSpecificData, PES: PacketizedElementaryStream) {
        
        print("data is called")

    }
   var nextSampleOffset = 0
    
    public internal(set) var parser: Parser?
    public internal(set) var reader: Reader?
    
    
    public lazy var demuxer: TSDemux = {
        let demuxer = TSDemux()
        print("demux is initialized")
        demuxer.delegate = self
        print("self is \(self)")
        return demuxer
    }()
    
    init() {
        demuxer.downloader!.ip = "233.15.200.55"
    }
    
   // func nextSampleBuffer() throws -> CMSampleBuffer {
    //    print("test")
      //  var test :CMSampleBuffer = nil
       // return test
    //}
}

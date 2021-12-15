//
//  AC3Info.swift
//  SampleBufferPlayer
//
//  Created by admin on 2021/12/13.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

import CoreMedia

public struct AC3Info {
    
    public var sampleRate:Double = 44100.0
    public var channels:Int = 2
    public var frameLength:Int = 0
    public var dataOffset:Int = 0
    public var samplesPerFrame:Int = 1024
    public var formatID:AudioFormatID = kAudioFormatAC3
    

}


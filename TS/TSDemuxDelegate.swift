//
//  TSDemuxDelegate.swift
//  SampleBufferPlayer
//
//  Created by admin on 2021/12/02.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

protocol TSDemuxDelegate: AnyObject {
    func demuxer(_ demuxer: TSDemux, didReadPacketizedElementaryStream data: ElementaryStreamSpecificData, PES: PacketizedElementaryStream)
}

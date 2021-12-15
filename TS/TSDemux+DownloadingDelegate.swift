//
//  TSDemux+DownloadingDelegate.swift
//  SampleBufferPlayer
//
//  Created by admin on 2021/12/02.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import os.log

extension TSDemux: DownloadingDelegate {
    
    public func download(_ download: Downloading, completedWithError error: Error?) {
        os_log("%@ - %d [error: %@]", log: TSDemux.logger, type: .debug, #function, #line, String(describing: error?.localizedDescription))
        
        if let error = error, let ip = download.ip {
            DispatchQueue.main.async { [unowned self] in
                //self.delegate?.demuxer(self, failedDownloadWithError: error, forURL: url)
                print("not suppported. To do.")
            }
        }
    }
    
    public func download(_ download: Downloading, changedState downloadState: DownloadingState) {
        os_log("%@ - %d [state: %@]", log: TSDemux.logger, type: .debug, #function, #line, String(describing: downloadState))
    }
    
    public func download(_ download: Downloading, didReceiveData data: Data, progress: Float) {
        //os_log("%@ - %d", log: TSDemux.logger, type: .debug, #function, #line)

        self.readPacket(data: data)
    }
        
}

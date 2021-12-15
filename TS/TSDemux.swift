import Foundation
import VideoToolbox
import AVFoundation
import os.log


// MARK: -
class TSDemux {
    
    static let logger = OSLog(subsystem: "com.fastlearner.tsdemux", category: "TSDemux")
    var audioTrack: [UInt16] = []
    public lazy var downloader: Downloader? = {
        let downloader = Downloader()
        downloader.delegate = self
        return downloader
    }()
    
    public var delegate: TSDemuxDelegate?

    private(set) var PAT: ProgramAssociationSpecific? {
        didSet {
            guard let PAT: ProgramAssociationSpecific = PAT else {
                return
            }
            for (channel, PID) in PAT.programs {
                dictionaryForPrograms[PID] = channel
            }
        }
    }
    private(set) var PMT: [UInt16: ProgramMapSpecific] = [:] {
        didSet {
            for (_, pmt) in PMT {
                print ("didSet PMT")

                for data in pmt.elementaryStreamSpecificData {
                    print ("didSet \(data.elementaryPID) \(data) ")
                    if (data.streamType == 129) {
                        audioTrack.append(data.elementaryPID)
                    }
                    dictionaryForESSpecData[data.elementaryPID] = data
                }
            }
        }
    }
    private(set) var numberOfPackets: Int = 0

    private var eof: UInt64 = 0
    private var cursor: Int = 0
    private var fileHandle: FileHandle?
    private var dictionaryForPrograms: [UInt16: UInt16] = [:]
    private var dictionaryForESSpecData: [UInt16: ElementaryStreamSpecificData] = [:]
    private var packetizedElementaryStreams: [UInt16: PacketizedElementaryStream] = [:]

    init(url: URL) throws {
        fileHandle = try FileHandle(forReadingFrom: url)
        eof = fileHandle!.seekToEndOfFile()
    }
    
    init() {
        
    }
    
    deinit {
        print("TSDemux deinit")
        downloader = nil
    }

    func read() {
        while let packet: PartialTSPacket = next() {
            numberOfPackets += 1
            if packet.pid == 0x0000 {
                PAT = ProgramAssociationSpecific(packet.payload)
                continue
            }
            if let channel: UInt16 = dictionaryForPrograms[packet.pid] {
                PMT[channel] = ProgramMapSpecific(packet.payload)
                continue
            }
            if let data: ElementaryStreamSpecificData = dictionaryForESSpecData[packet.pid] {
                readPacketizedElementaryStream(data, packet: packet)
            }
        }
    }
    
    
    func readPacket(data:Data) {
        if let packet = PartialTSPacket(data: data) {
            
            if packet.adaptationFieldFlag == true {
                
                /*
                if packet.adaptationField?.PCRFlag == true {
                    print("pcr exsit")
                    let (b, e) = TSProgramClockReference.decode(packet.adaptationField!.PCR)
                    print ("b : \(Double(b) / Double(TSProgramClockReference.resolutionForBase)) e : \(Double(e) / Double(TSProgramClockReference.resolutionForExtension))")
                    print ("result : \((Double(b) / Double(TSProg   ramClockReference.resolutionForBase) + (Double(e) / Double(TSProgramClockReference.resolutionForExtension))) * 1000000000)")
                    var result = ((Double(b) / Double(TSProgramClockReference.resolutionForBase) + (Double(e) / Double(TSProgramClockReference.resolutionForExtension))) * 1000000000)
                    if let controlTimebase = ViewController.videoLayer!.controlTimebase{
                        CMTimebaseSetTime(controlTimebase,
                                          time:CMTimeMake(value: (Int64)(result), timescale: 1000000000))
                        CMTimebaseSetRate(controlTimebase, rate: 1.0)
                    }
                }*/
            }
           // packet.dump()
            
            numberOfPackets += 1
            if packet.pid == 0x0000 {
                PAT = ProgramAssociationSpecific(packet.payload)
                return
            }
            if let channel: UInt16 = dictionaryForPrograms[packet.pid] {
                PMT[channel] = ProgramMapSpecific(packet.payload)
                return
            }
            if let data: ElementaryStreamSpecificData = dictionaryForESSpecData[packet.pid] {
                readPacketizedElementaryStream(data, packet: packet)
 
            } else {
                print("NO es \(packet.pid)")
            }
        } else {
            print("Error readPacket")
        }
    }

    func readPacketizedElementaryStream(_ data: ElementaryStreamSpecificData, packet: PartialTSPacket) {
        if packet.payloadUnitStartIndicator {
           
            if let PES: PacketizedElementaryStream = packetizedElementaryStreams[packet.pid] {
                print ("PES(startIndicator)[\(packet.pid)] : \(PES.optionalPESHeader?.PTS) ")
                if (data.streamType == 27 || data.elementaryPID == audioTrack[0]) {
                    delegate?.demuxer(self, didReadPacketizedElementaryStream: data, PES: PES)
                }
            } else {
                //print("idkss88 error packet \(packetizedElementaryStreams[packet.pid]?.payload.count) packetLength : \(packetizedElementaryStreams[packet.pid]?.packetLength)")
            }
            packetizedElementaryStreams[packet.pid] = PacketizedElementaryStream(packet.payload)
            return
        }
        //print("packet payload \(packet.payload.count)")
            packetizedElementaryStreams[packet.pid]?.append(packet.payload)
        if let PES = packetizedElementaryStreams[packet.pid] {
          //  print ("PES [\(packet.pid)] : \((PES.optionalPESHeader?.PTS)!) ")
        }
    }

    func close() {
        fileHandle?.closeFile()
    }
}

extension TSDemux: IteratorProtocol {
    // MARK: IteratorProtocol
    func next() -> PartialTSPacket? {
        guard let fileHandle = fileHandle, UInt64(cursor * PartialTSPacket.length) < eof else {
            return nil
        }
        defer {
            cursor += 1
        }
        fileHandle.seek(toFileOffset: UInt64(cursor * PartialTSPacket.length))
        return PartialTSPacket(data: fileHandle.readData(ofLength: PartialTSPacket.length))
    }
}


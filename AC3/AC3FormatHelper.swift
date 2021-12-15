//
//  AC3FormatHelper.swift
//  SampleBufferPlayer
//
//  Created by admin on 2021/12/13.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import CoreMedia


struct Color {
    var tint: String
    var tintDisabled: String
    var accent: String
    var background: String
    var items: [String]
}

struct Theme {
    var ID: Int
    var name: String
    var color: Color
}

var acmod_chans:[UInt8] = [ 2, 1, 2, 3, 3, 4, 4, 5 ]

struct _frmsizecod {
    var bit_rate: Int;         /* nominal bit rate */
    var frame_size: [Int] = [Int](repeating: 0, count: 3);    /* frame size for 32kHz, 44kHz, and 48kHz */
}

var frmsizecod:[_frmsizecod] = [
    _frmsizecod(bit_rate:32,frame_size:[64,69,96]),
    _frmsizecod(bit_rate:32,frame_size:[64,70,96]),
    _frmsizecod(bit_rate:40,frame_size:[80,87,120]),
    _frmsizecod(bit_rate:40,frame_size:[80,88,120]),
    _frmsizecod(bit_rate:48,frame_size:[96,104,144]),
    _frmsizecod(bit_rate:48,frame_size:[96,105,144]),
    _frmsizecod(bit_rate:56,frame_size:[112,121,168]),
    _frmsizecod(bit_rate:56,frame_size:[112,122,168]),
    _frmsizecod(bit_rate:64,frame_size:[128,139,192]),
    _frmsizecod(bit_rate:64,frame_size:[128,140,192]),
    _frmsizecod(bit_rate:80,frame_size:[160,174,240]),
    _frmsizecod(bit_rate:80,frame_size:[160,175,240]),
    _frmsizecod(bit_rate:96,frame_size:[192,208,288]),
    _frmsizecod(bit_rate:96,frame_size:[192,209,288]),
    
    _frmsizecod(bit_rate:112,frame_size:[224,243,336]),
    _frmsizecod(bit_rate:112,frame_size:[224,244,336]),
    
    _frmsizecod(bit_rate:128,frame_size:[256,278,384]),
    _frmsizecod(bit_rate:128,frame_size:[256,279,384]),
    
    _frmsizecod(bit_rate:160,frame_size:[320,348,480]),
    _frmsizecod(bit_rate:160,frame_size:[320,349,480]),
    
    _frmsizecod(bit_rate:192,frame_size:[384,417,576]),
    _frmsizecod(bit_rate:192,frame_size:[384,418,576]),
    
    _frmsizecod(bit_rate:224,frame_size:[448, 487, 672]),
    _frmsizecod(bit_rate:224,frame_size:[448, 488, 672]),
    
    _frmsizecod(bit_rate:256,frame_size:[512, 557, 768]),
    _frmsizecod(bit_rate:256,frame_size:[512, 558, 768]),
    
    _frmsizecod(bit_rate:320,frame_size:[640, 696, 960]),
    _frmsizecod(bit_rate:320,frame_size:[640, 697, 960]),
    
    _frmsizecod(bit_rate:384,frame_size:[768, 835, 1152]),
    _frmsizecod(bit_rate:384,frame_size:[768, 836, 1152]),
    
    _frmsizecod(bit_rate:448,frame_size:[896, 975, 1344]),
    _frmsizecod(bit_rate:448,frame_size:[896, 976, 1344]),
    
    _frmsizecod(bit_rate:512,frame_size:[1024, 1114, 1536]),
    _frmsizecod(bit_rate:512,frame_size:[1024, 1115, 1536]),
    
    _frmsizecod(bit_rate:576,frame_size:[1152, 1253, 1728]),
    _frmsizecod(bit_rate:576,frame_size:[1152, 1254, 1728]),
    
    _frmsizecod(bit_rate:640,frame_size:[1280, 1393, 1920]),
    _frmsizecod(bit_rate:640,frame_size:[1280, 1394, 1920]),

]

/*
static struct _frmsizecod
{
  var bit_rate;         /* nominal bit rate */
  var frame_size[3];    /* frame size for 32kHz, 44kHz, and 48kHz */
} frmsizcod_table[38] = {
  {
    32, {
  64, 69, 96}}, {
    32, {
  64, 70, 96}}, {
    40, {
  80, 87, 120}}, {
    40, {
  80, 88, 120}}, {
    48, {
  96, 104, 144}}, {
    48, {
  96, 105, 144}}, {
    56, {
  112, 121, 168}}, {
    56, {
  112, 122, 168}}, {
    64, {
  128, 139, 192}}, {
    64, {
  128, 140, 192}}, {
    80, {
  160, 174, 240}}, {
    80, {
  160, 175, 240}}, {
    96, {
  192, 208, 288}}, {
    96, {
  192, 209, 288}}, {
    112, {
  224, 243, 336}}, {
    112, {
  224, 244, 336}}, {
    128, {
  256, 278, 384}}, {
    128, {
  256, 279, 384}}, {
    160, {
  320, 348, 480}}, {
    160, {
  320, 349, 480}}, {
    192, {
  384, 417, 576}}, {
    192, {
  384, 418, 576}}, {
    224, {
  448, 487, 672}}, {
    224, {
  448, 488, 672}}, {
    256, {
  512, 557, 768}}, {
    256, {
  512, 558, 768}}, {
    320, {
  640, 696, 960}}, {
    320, {
  640, 697, 960}}, {
    384, {
  768, 835, 1152}}, {
    384, {
  768, 836, 1152}}, {
    448, {
  896, 975, 1344}}, {
    448, {
  896, 976, 1344}}, {
    512, {
  1024, 1114, 1536}}, {
    512, {
  1024, 1115, 1536}}, {
    576, {
  1152, 1253, 1728}}, {
    576, {
  1152, 1254, 1728}}, {
    640, {
  1280, 1393, 1920}}, {
    640, {
  1280, 1394, 1920}}
};
*/


public class AC3FormatHelper {
    public class func parseHeader(parser:Parser /*ac3Data:Data*/, dataOffset:Int) -> AC3Info? {
        print("dataOffset \(dataOffset) data count \(parser.ac3Data!.count)")
        let data = parser.ac3Data!.subdata(in: dataOffset..<dataOffset+100)
        var bit_skip_unchecked = 0
        if (!(data[0] == 0x0B && data[1] == 0x77)) {
            print("data[0] \(data[0])")
            print("data[1] \(data[1])")
            print("No syncword")
            return nil
        } else {
            print("data[0] \(data[0])")
            print("data[1] \(data[1])")
            print("syncword")
        }
    
        var crc1      = data[2] << 8 |  data[3] // 16bit
        bit_skip_unchecked += 16
        print("data[4] is \(data[4])")
        var fscod     = (data[4] & 0xC0) >> 6   // 2bit
        bit_skip_unchecked += 2
        var frmsizcodIdx = data[4] & 0x3F          // 6bit
        bit_skip_unchecked += 6
        
        var bsid      = (data[5] & 0xf8) >> 3   //5bit
        bit_skip_unchecked += 5
        var bsmod     = data[5] & 0x07        //3bit
        bit_skip_unchecked += 3
        var acmod     = (data[6] & 0xE0) >> 5   //3bit
        bit_skip_unchecked += 3

        if (((acmod & 0x1) != 0) && (acmod != 0x1)) { /* 3 front channels */
            bit_skip_unchecked += 2
        }
        if (((acmod & 0x4)) != 0) {           /* if a surround channel exists */
            bit_skip_unchecked += 2
        }
        if (acmod == 0x2) {             /* if in 2/0 mode */
            bit_skip_unchecked += 2
        }
        
        var nextByte = bit_skip_unchecked / 8
        var nextbit = bit_skip_unchecked % 8
        if(nextbit == 0) {
            nextbit += 1
        }
        print("usedByte \(nextByte) usedbit \(nextbit)")
        var lfe_on =  data[nextByte] & (0x80 >> nextbit) // 1bit
        
        var channels = acmod_chans[Int(acmod)] + lfe_on
        
        var formatID:AudioFormatID = kAudioFormatAC3
        var samplesPerFrame:Int = dataOffset
        
        var sampleRate = 0.0
        print("fscod \(fscod)")
        switch (fscod) {
        case 0b00 :
            sampleRate = 48000.0
        case 0b01 :
            sampleRate = 44100.0
        case 0b10 :
            sampleRate = 32000.0
        case 0b11 :
            sampleRate = 44100.0
        default:
            sampleRate = 44100.0
        }
        
        
        switch (frmsizcodIdx) {
        case 0b000000:
            print("32Kbps    96    69    64")
        case 0b000001:
            print("32Kbps    96    70    64")
        case 0b000010:
            print("40Kbps    120    87    80")
        case 0b000011:
            print("40Kbps    120    88    80")
        case 0b000100:
            print("48Kbps    144    104    96")
        case 0b000101:
            print("48Kbps    144    105    96")
        case 0b000110:
            print("56Kbps    168    121    112")
        case 0b000111:
            print("56Kbps    168    122    112")
        case 0b001000:
            print("64Kbps    192    139    128")
        case 0b001001:
            print("64Kbps    192    140    128")
        case 0b001010:
            print("80Kbps    240    174    160")
        case 0b001011:
            print("80Kbps    240    175    160")
        case 0b001100:
            print("96Kbps    288    208    192")
        case 0b001101:
            print("96Kbps    288    209    192")
        case 0b001110:
            print("112Kbps    336    243    224")
        case 0b001111:
            print("112Kbps    336    244    224")
        case 0b010000:
            print("128Kbps    384    278    256")
        case 0b010001:
            print("128Kbps    384    279    256")
        case 0b010010:
            print("160Kbps    480    348    320")
        case 0b010011:
            print("160Kbps    480    349    320")
        case 0b010100:
            print("192Kbps    576    417    384")
        case 0b010101:
            print("192Kbps    576    418    384")
        case 0b010110:
            print("224Kbps    672    487    448")
        case 0b010111:
            print("224Kbps    672    488    448")
        case 0b011000:
            print("256Kbps    768    557    512")
        case 0b011001:
            print("256Kbps    768    558    512")
        case 0b011010:
            print("320Kbps    960    696    640")
        case 0b011011:
            print("320Kbps    960    697    640")
        case 0b011100:
            print("384Kbps    1152    835    768")
        case 0b011101:
            print("384Kbps    1152    836    768")
        case 0b011110:
            print("448Kbps    1344    975    896")
        case 0b011111:
            print("448Kbps    1344    976    896")
        case 0b100000:
            print("512Kbps    1536    1114    1024")
        case 0b100001:
            print("512Kbps    1536    1115    1024")
        case 0b100010:
            print("576Kbps    1728    1253    1152")
        case 0b100011:
            print("576Kbps    1728    1254    1152")
        case 0b100100:
            print("640Kbps    1920    1393    1280")
        case 0b100101:
            print("640Kbps    1920    1394    1280")
        default:
            print("reserved")
        }
         
        var frame_size = frmsizecod[Int(frmsizcodIdx)].frame_size[Int(fscod)] * 2
        print("frame_size \(frame_size)")
        return AC3Info(sampleRate: sampleRate , channels: 2, frameLength: frame_size, dataOffset: dataOffset, samplesPerFrame: frame_size, formatID: formatID)
    }
    
    /// - Tag: AACAudioFormatDescriptionCreating
    public class func createAudioFormatDescription(ac3info:AC3Info) -> CMAudioFormatDescription? {
        var audioFormatDescription:CMAudioFormatDescription?

        var audioStreamBasicDescription = createAudioStreamBaseDescription(ac3info: ac3info)
        let status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: &audioStreamBasicDescription, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &audioFormatDescription)
        
        guard status == noErr else {
            return nil
        }
        return audioFormatDescription
    }
    
    public class func createAudioStreamBaseDescription(ac3info:AC3Info) -> AudioStreamBasicDescription {
        /*
         For compressed streams like AAC, set mBytesPerPacket, mBytesPerFrame, mBitsPerChannel to 0.
         The packet layout will set when create samplebuffer with packets.
         */
        return AudioStreamBasicDescription(mSampleRate: Float64(ac3info.sampleRate), mFormatID: ac3info.formatID, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: UInt32(1536/*ac3info.samplesPerFrame*/), mBytesPerFrame: 0, mChannelsPerFrame: UInt32(ac3info.channels), mBitsPerChannel: 0, mReserved: 0)
    }
    
    public class func createAudioStreamPacketDescription(ac3info:AC3Info) -> AudioStreamPacketDescription {
        return AudioStreamPacketDescription(mStartOffset: Int64(ac3info.dataOffset), mVariableFramesInPacket: 0, mDataByteSize: UInt32(ac3info.frameLength))
    }
 
}


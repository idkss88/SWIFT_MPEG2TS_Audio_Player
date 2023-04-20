# "MPEG TS Audio Player" plays naked audio stream packets with AVSampleBufferAudioRenderer.

이 프로젝트는 Apple의 AirPlay2 데모 프로젝트 SampleBufferPlayer 에서 기능을 추가 & 수정 하였습니다.

MPEG TS Audio Player 는 MPEG-TS 로 스트리밍 되는 Audio data를 AVSampleBufferAudioRenderer 를 통해 플레이 합니다.

추가된 내용은 다음 과 같습니다.
 - multicast receiver
 - mpeg ts demuxer
 - AC3 foramt parsing & play

## 1. 제작 기간 & 참여 인원
- 한 달
- 개인 프로젝트

## 2. 사용 언어
- swift

## 구현 내용
- multicast receiver
- mpeg ts demuxer
- AC3 foramt parsing & play

## 4. 핵심 기능
멀티캐스트로 송출되는 MPEG TS 스트림을 demuxing 하여 원하는 audio format을 출력 합니다. 

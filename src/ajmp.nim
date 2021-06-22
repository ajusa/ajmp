import strutils, os, bitops, sugar

import nimbass/bass
import nimbass/bass_fx

converter toInt(x: QWORD): int = cast[int](x)
converter toQWORD(x: int): QWORD = cast[QWORD](x)

var speedup = 1.5

echo "Starting"
echo BASS_Init(cint(-1), cast[DWORD](44100), cast[DWORD](0), nil, nil)
var file = BASS_StreamCreateFile(cast[BOOL](false), "./music.mp3".cstring, 0, 0, BASS_Stream_Decode)
file = BASS_FX_TempoCreate(file, BASS_FX_TEMPO_ALGO_CUBIC)
var skipFile = BASS_StreamCreateFile(cast[BOOL](false), "./music.mp3".cstring, 0, 0, BASS_Stream_Decode)
discard BASS_ChannelSetAttribute(cast[DWORD](file), cast[DWORD](BASS_ATTRIB_TEMPO), speedup * 100 - 100.cfloat)

proc skipToNoisePosition(file: DWORD, every = 0.5): int =
  var start = file.BASS_ChannelGetPosition(BASS_POS_BYTE)
  var secondsSkipped = 0.0
  while true:
    var bothVolumes = [0.0.cfloat, 0.0.cfloat]
    echo file.BASS_ChannelGetLevelEx(bothVolumes[0].addr, every, BASS_LEVEL_RMS)
    var volume = (bothVolumes[0] + bothVolumes[1]) / 2
    secondsSkipped += every
    if volume < 0.001 and secondsSkipped > 20: break
    # var bothVolume = cast[array[2, int16]](file.BASS_ChannelGetLevel())
    # var volume = (bothVolume[0].int + bothVolume[1].int) div 2
    var amount = file.BASS_ChannelSeconds2Bytes(every)
    # var buffer = newSeq[byte](amount.int)
    # if volume != 0:
    #   discard file.BASS_ChannelGetData(buffer[0].addr, cast[DWORD](amount))
    # if volume < 50 and volume > 0: break
  # while true:
  #   var bothVolume = cast[array[2, int16]](file.BASS_ChannelGetLevel())
  #   var volume = (bothVolume[0].int + bothVolume[1].int) div 2
  #   var amount = file.BASS_ChannelSeconds2Bytes(every)
  #   var buffer = newSeq[byte](amount.int)
  #   if volume != 0:
  #     discard file.BASS_ChannelGetData(buffer[0].addr, cast[DWORD](amount))
  #   if volume > 100: break
  result = file.BASS_ChannelGetPosition(BASS_POS_BYTE)
  echo "Skipped ", file.BASS_ChannelBytes2Seconds(result.int - start.int), " seconds"
  echo "At ", file.BASS_ChannelBytes2Seconds(result.int), " seconds"

proc skipToNextSong() =
  var currentFilePosition = file.BASS_ChannelGetPosition(BASS_POS_BYTE)
  var currentFileSeconds = file.BASS_ChannelBytes2Seconds(currentFilePosition)
  var newSkipFilePosition = skipFile.BASS_ChannelSeconds2Bytes(currentFileSeconds)
  discard skipFile.BASS_ChannelSetPosition(newSkipFilePosition, BASS_POS_BYTE)
  var skipFilePosition = skipFile.skipToNoisePosition()
  var positionResult = file.BASS_ChannelSetPosition(skipFilePosition, BASS_POS_BYTE)
  if positionResult == 0:
    # start next song
    discard

echo BASS_ChannelPlay(file, cast[BOOL](false));
while true:
  var command = readChar(stdin)
  case command:
    of 'n':
      skipToNextSong()
    of 'p':
      discard
    else:
      discard

# discard BASS_ChannelPlay(file, cast[BOOL](false))
# discard BASS_ChannelPause(file)
  # var levels = [0.0.cfloat, 0.0.cfloat]
  # discard BASS_ChannelGetLevelEx(file, levels[0].addr, 0.02, BASS_LEVEL_STEREO);
  # echo levels

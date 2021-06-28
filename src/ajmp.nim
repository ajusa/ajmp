import strutils, os, bitops, sugar, random

import nimbass/bass
import nimbass/bass_fx
import notify

converter toInt(x: QWORD): int = cast[int](x)
converter toQWORD(x: int): QWORD = cast[QWORD](x)
converter toBool(x: bool): BOOL = cast[BOOL](x)
var speedup = 1.5

proc main(songs: seq[string]) =
  if songs.len == 0:
    echo "No music provided to play!"
    quit()

  randomize() # Shuffle
  echo "Starting"
  echo BASS_Init(cint(-1), cast[DWORD](44100), cast[DWORD](0), nil, nil)
  var file, skipFile: HSTREAM
  proc playNextSong() =
    var nextSong = songs.sample()
    var n: Notification = newNotification("ajmp", "Playing " & nextSong.extractFilename, "dialog-information")
    discard n.show()
    if file != 0 and skipFile != 0: # free memory
      discard file.BASS_ChannelStop()
      discard skipFile.BASS_ChannelStop()

    file = BASS_StreamCreateFile(cast[BOOL](false), nextSong.cstring, 0, 0, BASS_Stream_Decode)
    file = BASS_FX_TempoCreate(file, BASS_FX_TEMPO_ALGO_CUBIC)
    skipFile = BASS_StreamCreateFile(cast[BOOL](false), nextSong.cstring, 0, 0, BASS_Stream_Decode)
    discard BASS_ChannelSetAttribute(cast[DWORD](file), cast[DWORD](BASS_ATTRIB_TEMPO), speedup * 100 - 100.cfloat)

  playNextSong()

  proc skipToNoisePosition(file: DWORD, every = 0.5): int =
    var start = file.BASS_ChannelGetPosition(BASS_POS_BYTE)
    var secondsSkipped = 0.0
    while true:
      var bothVolumes = [0.0.cfloat, 0.0.cfloat]
      discard file.BASS_ChannelGetLevelEx(bothVolumes[0].addr, every, BASS_LEVEL_RMS)
      var volume = (bothVolumes[0] + bothVolumes[1]) / 2
      secondsSkipped += every
      if volume < 0.001 and secondsSkipped > 20: break
      # var bothVolume = cast[array[2, int16]](file.BASS_ChannelGetLevel())
      # var volume = (bothVolume[0].int + bothVolume[1].int) div 2
      # var amount = file.BASS_ChannelSeconds2Bytes(every)
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
    var n: Notification = newNotification("ajmp", "Finished skipping to next song", "dialog-information")
    discard n.show()



  proc skipToNextSong() =
    var currentFilePosition = file.BASS_ChannelGetPosition(BASS_POS_BYTE)
    var currentFileSeconds = file.BASS_ChannelBytes2Seconds(currentFilePosition)
    var newSkipFilePosition = skipFile.BASS_ChannelSeconds2Bytes(currentFileSeconds)
    discard skipFile.BASS_ChannelSetPosition(newSkipFilePosition, BASS_POS_BYTE)
    var skipFilePosition = skipFile.skipToNoisePosition()
    var positionResult = file.BASS_ChannelSetPosition(skipFilePosition, BASS_POS_BYTE)
    if positionResult == 0:
      playNextSong()

  proc togglePlayPause() =
    if file.BASS_ChannelIsActive == BASS_ACTIVE_PAUSED:
      discard file.BASS_ChannelPlay(false)
    else:
      discard file.BASS_ChannelPause()

  echo BASS_ChannelPlay(file, cast[BOOL](false));
  while true:
    var command = readChar(stdin)
    case command:
      of 'n':
        skipToNextSong()
      of 'p':
        togglePlayPause()
      else:
        discard
import cligen; dispatch(main)

import strutils, os

import nimbass/bass
import nimbass/bass_fx

echo "Starting"

echo BASS_Init(cint(-1), cast[DWORD](44100), cast[DWORD](0), nil, nil)
var file = BASS_StreamCreateFile(cast[BOOL](false), "./music.mp3".cstring, 0, 0, BASS_Stream_Decode)
file = BASS_FX_TempoCreate(file, BASS_FX_TEMPO_ALGO_CUBIC)
discard BASS_ChannelSetAttribute(cast[DWORD](file), cast[DWORD](BASS_ATTRIB_TEMPO), 50.cfloat)
discard BASS_ChannelPlay(file, cast[BOOL](false));
proc skipPastSilence(file: HSTREAM) =
  var volume = cast[int16](BASS_ChannelGetLevel(file))
  while volume < 100:
    var skipAmount = BASS_ChannelSeconds2Bytes(file, 0.1)
    discard BASS_ChannelSetPosition(file, skipAmount, BASS_POS_RELATIVE)
    volume = cast[int16](BASS_ChannelGetLevel(file))

file.skipPastSilence()
while true:
  var command = readChar(stdin)
  case command:
    of 'n':
      file.skipPastSilence
    else:
      discard

# discard BASS_ChannelPlay(file, cast[BOOL](false))
# discard BASS_ChannelPause(file)

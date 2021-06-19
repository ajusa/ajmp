import strutils, os

import nimbass/bass
import nimbass/bass_fx

echo "Starting"

echo BASS_Init(cint(-1), cast[DWORD](44100), cast[DWORD](0), nil, nil)
var file = BASS_StreamCreateFile(cast[BOOL](false), "./music.mp3".cstring, 0, 0, BASS_Stream_Decode)
file = BASS_FX_TempoCreate(file, BASS_FX_TEMPO_ALGO_CUBIC)
discard BASS_ChannelSetAttribute(cast[DWORD](file), cast[DWORD](BASS_ATTRIB_TEMPO), 50.cfloat)
discard BASS_ChannelPlay(file, cast[BOOL](false));
while true:
  sleep(1000)

 # discard BASS_ChannelPlay(file, cast[BOOL](false))
 # discard BASS_ChannelPause(file)

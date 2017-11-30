# TranscoderScript

The aim of this script is to provide a simple way to transcode audio/video files into a defined-by-variables format

## Usage
transcode [ in out ] [ -l in [ in [...]]
## Description
This script transcode audio/video file(s) with ffmpeg into files compliant with ${OUTFILE_EXTENSION} type:
- If the video codecs of in file(s) is not one of ${SUPPORTED_VIDEO_FORMAT}, the output video codec will be transcoded with ${DEFAULT_VIDEO_LIB} lib
- If the audio codecs of in file(s) is not one of ${SUPPORTED_AUDIO_FORMAT}, the output audio codec will be transcoded with ${DEFAULT_AUDIO_LIB} lib
- If the subtitles codecs of in file(s) is not one of ${SUPPORTED_SUB_FORMAT}, the output subtitle codec will be transcoded with ${DEFAULT_SUB_LIB} lib
## Parameters
	transcode in out: Transcode in file
		in : Path to the file to transcode
		out: The output file name
	transcode -l in [ in [...]]
		in [ in .. ]: Transcode in file(s) with the same name into ${DEFAULT_OUT_BASE_PATH}
				  Spaces will be replaced by a dot
				  Extension will be replaced by ${OUTFILE_EXTENSION}
	transcode -s: Stop transcode processes
## Configuration
There are global variables at the beginning of this script, such as:
- the path of ffmpeg (${FFMPEG_PATH})
- the output file extension (${OUTFILE_EXTENSION})
- supported video formats (${SUPPORTED_VIDEO_FORMAT})
- etc...

If you want to configure this script with your need, please update these variables

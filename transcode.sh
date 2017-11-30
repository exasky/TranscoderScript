#!/bin/bash

OUTFILE_EXTENSION='.mp4'
DEFAULT_VIDEO_LIB='libx264'
SUPPORTED_VIDEO_FORMAT='x264 h264 x265 hevc'
DEFAULT_AUDIO_LIB='libfdk_aac'
SUPPORTED_AUDIO_FORMAT='aac ac3'
DEFAULT_SUB_LIB='mov_text'
SUPPORTED_SUB_FORMAT='mov_text tx3g ttxt text'

DEFAULT_OUT_BASE_PATH="$HOME/Documents/ConvertedFiles"
FFMPEG_PATH="$HOME/Documents/ffmpeg"

usage() {
    echo -e "Usage:"
    echo -e "\ttranscode [ <in> <out> ] [ -l <in> [ <in> [...]]"
    echo -e "Description:"
    echo -e "\tThis script transcode audio/video file(s) with ffmpeg into files compliant with ${OUTFILE_EXTENSION} type:"
    echo -e "\t\tIf the video codecs of in file(s) is not one of ${SUPPORTED_VIDEO_FORMAT}, the output video codec will be transcoded with ${DEFAULT_VIDEO_LIB} lib"
    echo -e "\t\tIf the audio codecs of in file(s) is not one of ${SUPPORTED_AUDIO_FORMAT}, the output video codec will be transcoded with ${DEFAULT_AUDIO_LIB} lib"
    echo -e "\t\tIf the subtitles codecs of in file(s) is not one of ${SUPPORTED_SUB_FORMAT}, the output video codec will be transcoded with ${DEFAULT_SUB_LIB} lib"
    echo -e "Parameters:"
    echo -e "\ttranscode <in> <out>: Transcode <in> file"
    echo -e "\t\t<in> : Path to the file to transcode"
    echo -e "\t\t<out>: The output file name"
    echo -e "\ttranscode -l <in> [ <in> [...]]"
    echo -e "\t\t<in> [ <in> .. ]: Transcode <in> file(s) with the same name into ${DEFAULT_OUT_BASE_PATH}"
    echo -e "\t\t\t\t  Spaces will be replaced by a dot"
    echo -e "\t\t\t\t  Extension will be replaced by ${OUTFILE_EXTENSION}"
    echo -e "\ttranscode -s: Stop transcode processes"
    echo -e "Configuration:"
    echo -e "\tThere is global variables at the beginning of this script, such as the path of ffmpeg, the output file extension, supported video formats, etc..."
    echo -e "\tIf you want to configure this script with your need, please update these variables"
    exit 0
}

getParameters() {
    local infile="$1"

    local avs_codecs="$(${FFMPEG_PATH} -i "$infile" 2>&1 | grep 'Audio:\|Video:\|Subtitle:')"

    local video_infos="$(echo "$avs_codecs" | grep "Video:")"
    local audio_infos="$(echo "$avs_codecs" | grep "Audio:")"
    local sub_infos="$(echo "$avs_codecs" | grep "Subtitle:")"

    local out_parameters="-c copy -map 0 "
    out_parameters+=$(extractParametersFromCodecInfos "${video_infos}" "Video" "-c:v" "${SUPPORTED_VIDEO_FORMAT}" "${DEFAULT_VIDEO_LIB}")
    out_parameters+=$(extractParametersFromCodecInfos "${audio_infos}" "Audio" "-c:a" "${SUPPORTED_AUDIO_FORMAT}" "${DEFAULT_AUDIO_LIB}")
    out_parameters+=$(extractParametersFromCodecInfos "${sub_infos}" "Subtitle" "-c:s" "${SUPPORTED_SUB_FORMAT}" "${DEFAULT_SUB_LIB}")
    out_parameters+=$(checkHevcSupport "${video_infos}")

    echo ${out_parameters}
}

extractParametersFromCodecInfos() {
    local codec_infos="$1"
    local codec_type="$2"
    local codec_flag="$3"
    local codec_supported_formats="$4"
    local codec_default_lib="$5"

    local cur_stream_position=0
    echo " $(echo "${codec_infos}" | while read -r info; do
        #cur_stream=$(echo ${info%%: ${codec_type}: *} | cut -d'#' -f2 | cut -d'(' -f1)
        cur_codec=$(echo ${info##*${codec_type}: } | cut -d' ' -f1 | cut -d',' -f1)

        if [[ ! ${codec_supported_formats} =~ (^| )${cur_codec}($| ) ]]; then
            cur_parameters="${codec_flag}:${cur_stream_position} ${codec_default_lib} "
        fi

        cur_stream_position=$((cur_stream_position+1))
        echo $cur_parameters
    done)"
}

checkHevcSupport() {
    local video_infos="$1"

    if [[ -n $(echo ${video_infos} | grep hevc) ]]; then
        echo " -tag:v hvc1 "
    fi
}

transcodeFile() {
    local infile="$1"
    local outfile="$2"
    local log_file="/tmp/$outfile.log"

    if [ -z "$infile" -o -z "$outfile" ]; then
        echo "Missing argument(s)"
        usage
    fi
    if [ ! -f "$infile" ]; then
        echo "Error while opening input file \"$infile\""
        usage
    fi
    if [ ! -d "$DEFAULT_OUT_BASE_PATH" ]; then
        echo "$DEFAULT_OUT_BASE_PATH is not a directory"
        usage
    fi

    local parameters=$(getParameters "$infile")
    ${FFMPEG_PATH} -i "${infile}" ${parameters} "${DEFAULT_OUT_BASE_PATH}/$outfile" 2> "$log_file"
    #${FFMPEG_PATH} -i "$infile" -c copy -c:s mov_text -map 0 "${DEFAULT_OUT_BASE_PATH}/$outfile" 2> "$log_file" #copy all streams and convert subtitles to be mp4 compliant (hyper fast)
    #${FFMPEG_PATH} -i "$infile" -c:v libx264 -c:a copy "${DEFAULT_OUT_BASE_PATH}/$outfile" 2> "$log_file" #DEFAULT x264 CONVERSION with audio copy
    #${FFMPEG_PATH} -i "$infile" -c:v libx264 -c:a libfdk_aac "${DEFAULT_OUT_BASE_PATH}/$outfile" 2> "$log_file" #DEFAULT x264 CONVERSION with aac audio
    #${FFMPEG_PATH} -i "$infile" -c:v libx265 -tag:v hvc1 -c:a libfdk_aac "${DEFAULT_OUT_BASE_PATH}/$outfile" 2> "$log_file" #HEVC (x265) CONVERSION. FourCC FLAG: hvc1
    #${FFMPEG_PATH} -i "$infile" -c:v libx265 -c:a libfdk_aac "${DEFAULT_OUT_BASE_PATH}/$outfile" 2> "$log_file" #DEFAULT HEVC (x265) CONVERSION with aac audio
    #Apple tv doesn't play  AAC 5.1 without convert (--mixdown 6ch option)
    if [ $? -ne 0 ]; then
        echo "Error with file $infile, please check $log_file"
        return 1
    fi
    rm $log_file
    return 0
}

if [ -n "$1" ] ; then
    if [ "$1" == "-l" ]; then
        shift;
        pidList=""
        for var in "$@"; do
            filename=$(echo ${var##*/} | sed "s/ /./g")
            ext=$(echo ${filename##*\.})
            filename=$(echo $filename | sed "s/\.$ext/${OUTFILE_EXTENSION}/")
            transcodeFile "${var}" "$filename" &
            pidList="$pidList $!"
        done
        for pid in $pidList; do
            wait $pid
        done
    elif [ "$1" == "-s" ]; then
        ps -ax | grep "ffmpeg" | grep -v grep | awk '{print $1}' | xargs kill -9
        ps -ax | grep "transcode.sh" | grep -v grep | awk '{print $1}' | xargs kill
    else
        transcodeFile "$1" "$2"
        exit $?
    fi
    exit 0
else
    usage
fi


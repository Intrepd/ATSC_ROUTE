#!/bin/bash

#This script:
#	1- The FLUTE receiver is activated and put in automatic mode using SDP
#	2- Reference Client is launched with google chrome and received MPD

if [ "$#" -ne 1 ]; then
  echo "client.sh <Channel number: 1 or 2>" >&2
  exit 1
fi

channel=$1
#Define Paths
Client=http://localhost
HTTPRoot=/var/www/
DASHContentBase=DASH_Content
DASHContentDir=$DASHContentBase$channel
DASHContent=$DASHContentDir
OriginalMPD=MultiRate_Dynamic.mpd
Delay=10	#How much would the AST of the patched MPD be lagging the current system time, i.e. how far in future is the AST (in seconds)?
PatchedMPD=MultiRate_Dynamic_Patched.mpd
FLUTEReceiver=./
RefClient=$Client/Player?mpd=$Client/$DASHContentDir/$PatchedMPD
HTMLLocalStorage="/home/nomor/.config/google-chrome-unstable/Default/Local Storage/"

#Variables

index=`expr $channel - 1`
index=`expr $index \\* 2`
index=`expr $index + 1`
sdp=SDP$index.sdp			#SDP to be used by sender
index=`expr $index + 1`
sdp2=SDP$index.sdp			#SDP to be used by sender

Log=Rcv_Log_Video$channel.txt			#Log containing delays corresponding to FLUTE receiver
Log2=Rcv_Log_Audio$channel.txt
encodingSymbolsPerPacket=1	#For Receiver, Only a value of zero makes a difference. Otherwise, it is ignored 
							#This means that more than one encoding symbol is included packet. This could be varying

#Clear HTML5 Local Storage
if [ -e "$HTMLLocalStorage"*${Client:7}*localstorage-journal -o -e "$HTMLLocalStorage"*${Client:7}*localstorage ]; then
  echo "Delete Old HTML Local Storage"
  rm "$HTMLLocalStorage"*${Client:7}*
fi

echo "Entering Ctrl+C after playback has been initiated would stop it and process any available logs"

#Initialize DASHContent Folder
if [ "$(ls -A $DASHContent)" ]; then
  rm $DASHContent/*
fi

chmod 777 $DASHContent/*

#Brackets are used to temporarily change working directory
echo "Starting FLUTE Receiver"
(cd $FLUTEReceiver && ./flute -A -B:$DASHContent -d:$sdp -Q -Y:$encodingSymbolsPerPacket -J:$Log&)
(cd $FLUTEReceiver && ./flute -A -B:$DASHContent -d:$sdp2 -Q -Y:$encodingSymbolsPerPacket -J:$Log2&)

#For using with the canned trace file, re-write the AST to current system time when MPD is received
./UpdateMPD_AST_ToSystemTime.sh $DASHContent/$OriginalMPD $Delay $DASHContent/$PatchedMPD

#Sleep is used to make sure that segments are received. Should be removed after optimzation of sending processes and setting of Availability Start Time (AST)
sleep 10
#Launching DASH reference client using google chrome
google-chrome-unstable $RefClient 2> /dev/null

cat


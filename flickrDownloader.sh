#!/bin/bash

# Flickr Album Downloader
# Input album url was album thumbnails url such as:
# http://www.flickr.com/photos/mozillataiwan/sets/72157630814677262/
# 2012/08/06	Denny
# 2012/11/05	fix every page photo download as same filename bug	Denny

TMP_FILE="/tmp/flickrDownloader.$$"
PHOTO_TMP="/tmp/flickrDownloaderPhoto.$$"

read -p "Input the album url(with http:// and / in the end): " url
read -p "Input the page of Album: " page
read -p "Input download directory: " dir

# check and create folder
if [ -d "$dir" ]; then
	echo "Folder exists"
	read -p "Continue use this folder? [y/n]" check
	if [ "$check" != "y" ]; then
		echo "Bye!"
		exit
	fi
else
	mkdir -p "$dir"
fi

cd "$dir"

ps=$(ps | wc -l)

# check album page
if [ $page -gt 0 ]; then
	echo "OK!!"
	for i in `seq $page`
	do
		echo -e "\nStart download page $i/$page ..."

		curl $url?page=$i |\
			sed '/photo-click/!d' > $TMP_FILE

		# check if $TMP_FILE is not empty
		if [ -s $TMP_FILE ]; then

			num=$(awk 'BEGIN {FS="photo-click\" href=\""} {print NF}' $TMP_FILE)

			for j in `seq 2 $num`
			do
				# click enter into photo detail
				link=$(awk 'BEGIN {FS="photo-click\" href=\""} {print $'$j'}' $TMP_FILE | awk 'BEGIN {FS="\" "} {print $1}')

#				echo $link

				# click right button get original size photo
				dllink=$(curl http://www.flickr.com$link 2> "/dev/null" | sed '/Original/!d' |\
					awk 'BEGIN {FS="Original"} NR==2 {print $2}' |\
					awk 'BEGIN {FS="\""} {print $9}' |\
					sed 's/\\//g')

				tmp=$(($j - 1))
				tmpp=`echo $tmp | awk '{printf "%02d", $1}'`
				echo -e "\rDownloading page $i $tmp/$(($num-1))\c"

				curl -o $i$tmpp.jpg $dllink &> "/dev/null" &

				# limit 10 process download
				while [ 1 ]
				do
					psn=$((`ps | wc -l` - $ps))

					if [ $psn -lt 10 ]; then
						break
					fi

					usleep 500000

				done
			done
		else
			rm $TMP_FILE
			rm $PHOTO_TMP
			exit		
		fi

	done
else
	exit
fi

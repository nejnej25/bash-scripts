#!/usr/bin/bash
D1=$1
D2=$2

# Download files
sudo wget -P /opt/build/ $D1 $D2

# extract slackbuild
echo $D1 | grep slackbuild > /dev/null
if [ $? -eq 0 ] ; then
	#slackbuild_pkg=`echo $D1 | awk -F/ '{ print $7 }'`
	slackbuild_pkg=`echo $D1 | rev | cut -d'/' -f 1 | rev`
	#source_pkg=`echo $D2 | awk -F/ '{ print $9 }'`
	source_pkg=`echo $D2 | rev | cut -d'/' -f 1 | rev`
else
	#slackbuild_pkg=`echo $D2 | awk -F/ '{ print $7 }'`
	slackbuild_pkg=`echo $D2 | rev | cut -d'/' -f 1 | rev`
	#source_pkg=`echo $D1 | awk -F/ '{ print $9 }'`
	source_pkg=`echo $D1 | rev | cut -d'/' -f 1 | rev`
fi
cd /opt/build
sudo tar -xvzf $slackbuild_pkg
slackbuild_pkg_dir=`echo $slackbuild_pkg | awk -F. '{ print $1 }'`
sudo mv $source_pkg $slackbuild_pkg_dir && cd $slackbuild_pkg_dir && sudo ./${slackbuild_pkg_dir}.SlackBuild

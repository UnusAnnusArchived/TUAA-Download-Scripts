#!/bin/bash

clear

wgetCommand="wget"

if [ ! -x "$(command -v wget)" ]; then
  echo "wget not installed."
  if [ "$(uname -s)" == "Linux" ]; then
    if [ -x "$(command -v curl)" ]; then
    echo "Downloading wget..."
      curl -# -Lo ./wget "https://raw.githubusercontent.com/yunchih/static-binaries/master/wget"
      if [ ! -x "./wget" ]; then
        echo "Allowing execution of wget. You may be asked for your password."
        sudo chmod +x ./wget
      fi
      wgetCommand="./wget"
    else
      echo "curl is not installed. Please install curl or wget into your path."
      exit
    fi
  elif [ "$(uname -s)" == "Darwin" ]; then
  echo "Would you like to install wget to your system?"
  select yn in "Yes" "No"; do
      case $yn in
        Yes ) 
          echo "Downloading wget..."
          # curl is included in macos
          curl -# -Lo wget.pkg "https://github.com/donmccaughey/wget_pkg/releases/download/v1.21.4-r3/wget-1.21.4-r3.pkg"
          echo "Installing wget. You may be asked for your password."
          sudo installer -pkg ./wget.pkg -target /
          rm wget.pkg
          clear
          echo 'To uninstall wget, run "sudo uninstall-wget" in your command line.'
          read -p "Press enter to continue..."
          break;;
        No ) exit;;
      esac
    done
  else
    echo "Unknown OS. Please install wget to your path by yourself and try again."
    exit
  fi
fi

if [ "$wgetCommand" == "./wget" ]; then
  if [ ! -x "./wget" ]; then
    echo "Allowing execution of wget."
    chmod +x ./wget
  fi
fi

startDl() {
  mirrorUrl=$1
  episodeListUrl=$2

  if [ -e "episode-list.txt" ]; then
    rm episode-list.txt 
  fi

  echo "Downloading episode list"
  eval `$wgetCommand "$episodeListUrl" -nv -O "episode-list.txt"`

  while read url; do
    if [[ "$url" =~ (s[0-9]{2}\.e[0-9]{3}) ]]; then
      episode="${BASH_REMATCH[1]}"
    else
      echo "Failed to find episode in filename for $url. Skipping."
      continue
    fi

    if [ -e "$episode.mp4" ]; then
      echo "$episode already downloaded. Skipping."
      continue
    fi

    if [ -e "$episode.mp4.download" ]; then
      echo "$episode already partially downloaded. Deleting and retrying."
      rm "$episode.mp4.download"
    fi

    eval `$wgetCommand "$mirrorUrl/$url" -q --show-progress -O "$episode.mp4.download"`
    mv "$episode.mp4.download" "$episode.mp4"
  done <"episode-list.txt"
}

custom() {
  clear
  echo "Press enter to return."
  read -p "URL: " url
  if [ $url == "" ]; then
    run
  else
    read -p "Episode list URL: " episodeList
    if [ $episodeList == "" ]; then
      custom
    else
      startDl $url $episodeList
    fi
  fi
}

run() {
  clear
  echo "Please make a pull request or DM me on Discord if you'd like your mirror to be added."
  echo ""
  echo "Which mirror would you like to download from? Please type the number and hit enter."
  PS3="Mirror: "
  select yn in "Custom (requires an episode list)" "https://r2.unusann.us/ (Official)" "https://rust-lore.dpaste.org/unusannus/" "https://qtqzrt.com/ua/files/ (does not include s01.e368)" "Exit"; do
    case ${REPLY::1} in
      1 )
        custom
        break;;
      2 )
        startDl "https://r2.unusann.us" "https://r2.unusann.us/episode-list.txt"
        break;;
      3 )
        startDl "https://rust-lore.dpaste.org/unusannus" "https://rust-lore.dpaste.org/unusannus/sorted_mp4_list.txt"
        break;;
      4 )
        startDl "https://qtqzrt.com/ua/files" "https://r2.unusann.us/qtqzrt-episode-list.txt"
        break;;
      5 ) exit;;
    esac
  done
}

run

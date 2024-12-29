# We want to download wget even if it's in the path bc powershell has a stupid ass alias to Invoke-WebRequest that acts nothing like wget but still calls itself wget.
if (!(Test-Path "wget.exe")) {
  clear
  Write-Host "Downloading wget..."
  try {
    Invoke-WebRequest "https://eternallybored.org/misc/wget/1.21.4/32/wget.exe" -O wget.exe
  } catch {
    Write-Host "Failed to download wget. Please download it manually and place it in the same folder as run.bat with the name wget.exe" -ForegroundColor Red
    Write-Host "https://eternallybored.org/misc/wget/1.21.4/32/wget.exe"
    Write-Host "Press enter to exit..."
    Read-Host
    exit
  }
}

function startDl {
  param (
    [string]$mirrorUrl,
    [string]$episodeListUrl
  )

  if (Test-Path "episode-list.txt") {
    Remove-Item "episode-list.txt"
  }

  Write-Host "Downloading episode list"
  try {
    .\wget.exe "$episodeListUrl" -nv -O "episode-list.txt"
    if (!($LASTEXITCODE -eq 0)) {
      clear
      Write-Host "Failed to download episode list. Is there a school/work firewall blocking your access? Please check your network connection and try again or try a different mirror!" -ForegroundColor Red
      Write-Host "Press enter to exit..."
      Read-Host
      exit
    }
    Write-Host "$LASTEXITCODE"
  } catch {
    clear
    Write-Host "Failed to download episode list. Is there a school/work firewall blocking your access? Please check your network connection and try again or try a different mirror!" -ForegroundColor Red
    Write-Host "Press enter to exit..."
    Read-Host
    exit
  }

  foreach($url in Get-Content .\episode-list.txt) {
    $episode = $url -Replace '(s\d{2}\.e\d{3})', '$1'
    if (Test-Path "$episode.mp4") {
      Write-Host "$episode already downloaded. Skipping."
      continue
    }

    if (Test-Path "$episode.mp4.download") {
      Write-Host "$episode already partially downloaded. Deleting and retrying."
      Remove-Item "$episode.mp4.download"
    }

    .\wget.exe "$mirrorUrl/$url" -q --show-progress -O "$episode.mp4.download"
    Rename-Item -Path "$episode.mp4.download" -NewName "$episode.mp4"
  }
}

function custom {
  clear
  Write-Host "Press enter to return."
  $url = Read-Host "URL"
  if ($url -eq "") {
    run
  } else {
    $episodeList = Read-Host "Episode list URL"
    if ($episodeList -eq "") {
      custom
    } else {
      startDl $url $episodeList
    }
  }
}

function run {
  clear
  Write-Host "Please make a pull request or DM me on Discord if you`'d like your mirror to be added."
  Write-Host ""
  Write-Host "Which mirror would you like to download from? Please type the number and hit enter."
  Write-Host "1. Custom (requires an episode list)"
  Write-Host "2. https://r2.unusann.us/ (Official)"
  Write-Host "3. https://rust-lore.dpaste.org/unusannus/"
  Write-Host "4. https://qtqzrt.com/ua/files/ (does not include s01.e368)"
  Write-Host "5. Exit"
  $mirror = Read-Host "Mirror"

  switch ($mirror[0]) {
    "1" {
      custom
    }
    "2" {
      # official
      startDl "https://r2.unusann.us" "https://r2.unusann.us/episode-list.txt"
    }
    "3" {
      # rust lore
      startDl "https://rust-lore.dpaste.org/unusannus" "https://rust-lore.dpaste.org/unusannus/sorted_mp4_list.txt"
    }
    "4" {
      # qtqzrt
      startDl "https://qtqzrt.com/ua/files" "https://r2.unusann.us/qtqzrt-episode-list.txt"
    }
    "5" {
      exit
    }
  }
}

run

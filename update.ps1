Import-Module AU
$releases = 'https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases'

function global:au_BeforeUpdate() {
    Get-RemoteFiles -Purge -NoSuffix
}

function global:au_GetLatest {
$latestRelease = ((Invoke-WebRequest $releases'/latest' -Headers @{"Accept"="application/json"}).Content | ConvertFrom-Json).tag_name
 $assets = $releases+'/expanded_assets/'+$latestRelease
    $download_page = Invoke-WebRequest -Uri $assets -UseBasicParsing
    
    $regex32 = 'qbittorrent_enhanced_[\d.]+_setup.exe$'
    $regex64 = '_x64_setup.exe$'
    $url32 = -Join ('https://github.com', ($download_page.links | ? href -match $regex32 | select -First 1 -expand href))
    $url64 = -Join ('https://github.com', ($download_page.links | ? href -match $regex64 | select -First 1 -expand href))
    
    $url64 -match '/release-v?([\d.]+)'
    $version = $matches[1]
	
    return @{ Version = $version; URL32 = $url32; URL64 = $url64 }
}

function global:au_SearchReplace {
    @{
        "tools\chocolateyInstall.ps1" = @{
            "(^[$]fileName32\s*=\s*)('.*')" = "`$1'$($Latest.FileName32)'"
            "(^[$]fileName64\s*=\s*)('.*')" = "`$1'$($Latest.FileName64)'"
        }

        "tools\verification.txt"      = @{
            "(?i)(32-Bit.+)\<.*\>"   = "`${1}<$($Latest.URL32)>"
            "(?i)(64-Bit.+)\<.*\>"   = "`${1}<$($Latest.URL64)>"
            "(?i)(checksum32:\s+).*" = "`${1}$($Latest.Checksum32)"
            "(?i)(checksum64:\s+).*" = "`${1}$($Latest.Checksum64)"
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') { update -ChecksumFor none }
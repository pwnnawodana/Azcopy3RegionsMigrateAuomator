# ⚠️ Follow ReadMe before Run the script

# CONSTANTS
# -- Runtime
$env:AZCOPY_CONCURRENCY_VALUE = 256 # Increase the number of concurrent requests (Windows)
#-- Application
$OLD_SHARE_FILE_LIST_TEXT = "old_share_files.txt" # Exported files old share
$NEW_SHARE_FILE_LIST_TEXT = "new_share_files.txt" # Exported files new share
$is_in_OLD_SHARE_TWO = $false # file available reigon
#-- Share
$NEW_SHARE = "https://newregion_region.file.core.windows.net/xxx/"
$OLD_SHARE_ONE = "https://old_some_one.file.core.windows.net/xxx/"
$OLD_SHARE_TWO = "https://old_some_two.file.core.windows.net/xxx/"
#-- SAS
$NEW_SHARE_SAS = "SAS-(Read, List)".Trim()
$OLD_SHARE_ONE_SAS = "SAS-(Read, List)".Trim()
$OLD_SHARE_TWO_SAS = "SAS-(Read, List, Write)".Trim()

# _______________________________ Functions start here _______________________________
function Leave_App {
    Write-Host "Leaving" -NoNewline
    for ($($i = 1; ); $i -le 2; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Milliseconds 100 
    }
    Write-Host "."
    Exit    
}

function IsAuthFailed {
    param (
        [string]$File_Content_Report
    )
    if ($File_Content_Report -match "ServiceCode=AuthenticationFailed") {
        return $true;
    }
    else {
        return $false;
    }
}

function Export_File_List {
    param (
        [string]$url,
        [string]$export_file
    )
    azcopy list $url --running-tally > $export_file # Export source files list to text file
}

# Get Total file count information from text file
function GetFileCount {
    param (
        [string]$Text_File
    )
    return [int]$(Get-Content $Text_File -tail 2 | Select-Object -First 1 ).Replace('INFO: File count: ', '') - 1
}

# Get Total file size information from text file
function GetTotalFileSize {
    param (
        [string]$Text_File
    )
    return [string]$(Get-Content $Text_File -tail 1 ).Replace('INFO: Total file size: ', '')
}

# _______________________________ Application start here _______________________________

# getting the book details as user input
[string]$root_folder_name = $(Read-Host -Prompt "Enter root folder name").Trim()
[int]$sub_folder_name = [int]$(Read-Host -Prompt "Enter subfolder name").Trim()


# setting up directories urls
$NEW_SHARE_URL = "$($NEW_SHARE)$($root_folder_name)?$($NEW_SHARE_SAS)"
$NEW_SHARE_DESTINATION_URL = "$($NEW_SHARE)$($root_folder_name)/$($sub_folder_name)?$($NEW_SHARE_SAS)"
$OLD_SHARE_ONE_URL = "$($OLD_SHARE_ONE)$($root_folder_name)/$($sub_folder_name)?$($OLD_SHARE_ONE_SAS)"
$OLD_SHARE_TWO_URL = "$($OLD_SHARE_TWO)$($root_folder_name)/$($sub_folder_name)?$($OLD_SHARE_TWO_SAS)"

Write-Host "`nChecking For Source"
Export_File_List -url $OLD_SHARE_ONE_URL -export_file $OLD_SHARE_FILE_LIST_TEXT # Export SHARE ONE source files list to text file
$OLD_SHARE_ONE_TEXT_FILE_CONTENT = Get-Content $OLD_SHARE_FILE_LIST_TEXT -Raw # Read raw text of SHARE ONE file list

# Check for errors in old share source
if ([string]$($OLD_SHARE_ONE_TEXT_FILE_CONTENT) -match "RESPONSE ERROR") {
    if (IsAuthFailed -File_Content_Report $OLD_SHARE_ONE_TEXT_FILE_CONTENT) {
        Write-Host "`tSHARE ONE       :  failed to authenticate" -ForegroundColor Red
    }
    # Check in SHARE TWO OLD for files
    Export_File_List -url $OLD_SHARE_TWO_URL -export_file $OLD_SHARE_FILE_LIST_TEXT
    $OLD_SHARE_TWO_TEXT_FILE_CONTENT = Get-Content $OLD_SHARE_FILE_LIST_TEXT -Raw
    if ([string]$($OLD_SHARE_TWO_TEXT_FILE_CONTENT) -match "RESPONSE ERROR") {
        if (IsAuthFailed -File_Content_Report $OLD_SHARE_TWO_TEXT_FILE_CONTENT) {
            Write-Host "`tSHARE TWO             :  failed to authenticate" -ForegroundColor Red
        }else{
            Write-Host "`tResource     : Not Found in both Regions" -ForegroundColor Yellow
        }
        Leave_App
    }
    else {
        $is_in_OLD_SHARE_TWO = $true
    }
}

Write-Host "`tFound In        :  SHARE$($is_in_OLD_SHARE_TWO ? " ONE" : " TWO")"  -ForegroundColor Green

[int]$File_Count = GetFileCount -Text_File $OLD_SHARE_FILE_LIST_TEXT
$Total_File_Size = GetTotalFileSize -Text_File $OLD_SHARE_FILE_LIST_TEXT

# Check file existance and start migration
if ($Total_File_Size -gt 0) {
    Write-Host "Information"
    Write-Host "`Root folder     : " $root_folder_name -ForegroundColor Cyan
    Write-Host "`Sub folder         : " $sub_folder_name -ForegroundColor Cyan
    Write-Host "`tFile Count      : " $File_Count -ForegroundColor DarkGray
    Write-Host "`tTotal File Size : " $Total_File_Size -ForegroundColor DarkGray
    Write-Host "`tDestination     :  " -NoNewline
    #Check if already files exist in destination
    Export_File_List -url $NEW_SHARE_DESTINATION_URL -export_file $NEW_SHARE_FILE_LIST_TEXT # Export SHARE ONE source files list to text file
    $NEW_SHARE_TEXT_FILE_CONTENT = Get-Content $NEW_SHARE_FILE_LIST_TEXT -Raw # Read raw text of SHARE ONE file list

    if ([string]$($NEW_SHARE_TEXT_FILE_CONTENT) -match "RESPONSE ERROR") {
        if (IsAuthFailed -File_Content_Report $NEW_SHARE_TEXT_FILE_CONTENT) {
            Write-Host "NEW SHARE failed to authenticate" -ForegroundColor Red
            Leave_App
        }
        else {
            Write-Host 'No files Exist' -ForegroundColor Green
        }
    }
    else {
        Write-Host "$(GetFileCount -Text_File $NEW_SHARE_FILE_LIST_TEXT) files exist | Size : $(GetTotalFileSize -Text_File $NEW_SHARE_FILE_LIST_TEXT)" -ForegroundColor Red
    }
    Start-Process powershell "azcopy copy '$($is_in_OLD_SHARE_TWO ? $OLD_SHARE_TWO_URL : $OLD_SHARE_ONE_URL)' '$($NEW_SHARE_URL)' --recursive" -Confirm -NoNewWindow -wait
}
else {
    Write-Host "Problem in file count"
    Leave_App
}

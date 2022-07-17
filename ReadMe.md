⚠️ Caution
This is a script template sample that used for specific migration requirement which communicate with 3 azure file shares. Highly suggest to reverify script before run because this script already modified to hide confidential information. Also, due to that can have some runtime errors as well.

### Process
This is a powershell template that used for migrating source files from one azure storage share to another.
Process
- check if the files in share one
- check if the files in share two (if step one false)
- throw message if files not found in both shares
- if found
  - check if the file already exist in the destination
  - if not copy the file to new share

Before run the process need to install the azcopy tool to the system and also require to add it to environment variable as will
You can follow below steps to configure this on windows
    
### AZCopy
AZ copy is the base tool use to perform whole task
- Step 1
  Download AZ Copy tool & Extract in preferred location (Ex : C:\Azcopy)
- Step 2
  Open start menu (windows).
  Click Environment variables.
  Under system variables select Path and click edit.
  Click new and place azcopy.exe parent directory (if exe at "C:\Azcopy\azcopy.exe" then place "C:\Azcopy\" as value without double quotes) path within then click ok on all windows.
- Step 3
  Open cmd and run "azcopy --version" in that. if you get version value, good to go. 

## If destination already exist
Make sure ready to remigrate all the destinations
⚠️ Possible issues
- Files may override
- Unnecessary files may contain after the migration 
Suggest to remove the destination if files doesn't match and if really required

## Read Texts in the script parent
Within parent directory can see text files which contains the files list information.
- Text file
  - File list information or
  - error logs
    - authentication error
    - files not found errors etc.

If uncommon behavior happen read the text files for further information.
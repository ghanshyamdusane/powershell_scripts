#This will archive the data from One Container to Another
$WorkDir="C:\Temp"
$IMPORT=Import-Csv -Path $WorkDir\StorageAccountDeatils.csv
$FileName=("files-$(Get-Date)" -split " ")[0]
$Days = 7
$CBCKDays = 2

foreach ( $data in $IMPORT ) { 

$STGACCNAME=$data.StorageAccountName
$STGACCNAMEKEY=$data.StorageAccountKey
$CONTAINERNAME=$data.SourceContainer
$DESTCONTAINERNAME=$data.DestinationContainer

$FileName=("$STGACCNAME-files-$(Get-Date)" -split " ")[0]
$finalname=$($FileName -replace "/" , "-")  + ".csv"
$finaltextname=$($FileName -replace "/" , "-")  + ".txt"
$FiletxtPath=$("$WorkDir"+ "\" + "$finaltextname") 

$FileCBCKName=("$STGACCNAME-CBCKfiles-$(Get-Date)" -split " ")[0]
$finalCBCKname=$($FileCBCKName -replace "/" , "-")  + ".csv"
$finalCBCKtextname=$($FileCBCKName -replace "/" , "-")  + ".txt"
$FileCBCKtxtPath=$("$WorkDir"+ "\" + "$finalCBCKtextname") 

New-Item -Path $WorkDir -Name $finaltextname -ItemType "file" -ErrorAction Ignore
New-Item -Path $WorkDir -Name $finalCBCKtextname -ItemType "file" -ErrorAction Ignore

$StorageAccountContext = New-AzureStorageContext -StorageAccountName $STGACCNAME -StorageAccountKey $STGACCNAMEKEY -ErrorAction Stop
$COPYDATAs = Get-AzureStorageBlob -Container $CONTAINERNAME -Context $StorageAccountContext | Where-Object { 
$_.LastModified.DateTime -lt ((Get-Date).AddDays(-$Days)) -and  ( $_.Name -notmatch 'CB|CK' )
}

foreach  ( $COPYDATA in $COPYDATAs ) { 
$COPYDATASTATUS = Get-AzureStorageBlobCopyState -Container $DESTCONTAINERNAME -Blob $COPYDATA.Name -Context $StorageAccountContext
$absolutepath=$COPYDATASTATUS.Source.AbsolutePath
if ( $COPYDATASTATUS.Status -notmatch "Success" ) {
Write-Host "Blob name $absolutepath with CopyID $($COPYDATASTATUS.CopyId) is Pending" -BackgroundColor DarkYellow
sleep 10
$COPYDATASTATUS = Get-AzureStorageBlobCopyState -Container $DESTCONTAINERNAME -Blob $COPYDATA.Name -Context $StorageAccountContext
}
elseif ( $COPYDATASTATUS.Status -match "Failed" ) {
Write-Host "Blob name $absolutepath with CopyID $($COPYDATASTATUS.CopyId) is Failed" -BackgroundColor Red
Write-Output "Blob name $absolutepath with CopyID $($COPYDATASTATUS.CopyId) is Failed" | Out-File $FiletxtPath -Append
exit 0
}
else {
Write-Host "Blob name $absolutepath with CopyID $($COPYDATASTATUS.CopyId) is Completed" -ForegroundColor Cyan
}

}

$count = Get-Content -Path $FiletxtPath | Measure-Object -Line -Character -Word

if ( $count.Words -eq 0 ){
Write-Host "Copy Operation Got Successful"
foreach  ( $COPYDATA in $COPYDATAs ) {
Remove-AzureStorageBlob -Container $CONTAINERNAME -Blob $COPYDATA.Name -Context $StorageAccountContext -Verbose
}
}
else {
Write-Host "Copy Operation Got Failed"
exit 0
}


#####################################################################################
$COPYCBCKDATAs = Get-AzureStorageBlob -Container $CONTAINERNAME -Context $StorageAccountContext | Where-Object { 
$_.LastModified.DateTime -lt ((Get-Date).AddDays(-$CBCKDays)) -and  ( $_.Name -match 'CB|CK' ) 
}

foreach  ( $COPYCBCKDATA in $COPYCBCKDATAs ) { 
$COPYCBCKDATASTATUS = Get-AzureStorageBlobCopyState -Container $DESTCONTAINERNAME -Blob $COPYCBCKDATA.Name -Context $StorageAccountContext
$absolutepathCBCK=$COPYCBCKDATASTATUS.Source.AbsolutePath
if ( $COPYCBCKDATASTATUS.Status -notmatch "Success" ) {
Write-Host "Blob name $absolutepathCBCK with CopyID $($COPYCBCKDATASTATUS.CopyId) is Pending" -BackgroundColor DarkYellow
sleep 10
$COPYCBCKDATASTATUS = Get-AzureStorageBlobCopyState -Container $DESTCONTAINERNAME -Blob $COPYCBCKDATA.Name -Context $StorageAccountContext
}
elseif ( $COPYCBCKDATASTATUS.Status -match "Failed" ) {
Write-Host "Blob name $absolutepathCBCK with CopyID $($COPYCBCKDATASTATUS.CopyId) is Failed" -BackgroundColor Red
Write-Output "Blob name $absolutepathCBCK with CopyID $($COPYCBCKDATASTATUS.CopyId) is Failed" | Out-File $FileCBCKtxtPath -Append
exit 0
}
else {
Write-Host "Blob name $absolutepathCBCK with CopyID $($COPYCBCKDATASTATUS.CopyId) is Completed" -ForegroundColor Cyan
}

}

$countCBCK = Get-Content -Path $FileCBCKtxtPath | Measure-Object -Line -Character -Word

if ( $countCBCK.Words -eq 0 ){
Write-Host "Copy Operation Got Successful"
foreach  ( $COPYCBCKDATA in $COPYCBCKDATAs ) {
Remove-AzureStorageBlob -Container $CONTAINERNAME -Blob $COPYCBCKDATA.Name -Context $StorageAccountContext -Verbose
}
}
else {
Write-Host "Copy Operation Got Failed"
exit 0
}

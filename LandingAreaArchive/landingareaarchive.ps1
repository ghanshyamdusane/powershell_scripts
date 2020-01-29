#This will archive the data from One Container to Another
$WorkDir="C:\Temp"
$IMPORT=Import-Csv -Path $WorkDir\StorageAccountDeatils.csv
$FileName=("files-$(Get-Date)" -split " ")[0]
$Days = 7
$CBCKDays = 2
$DTE = (Get-Date).Date
$DTE = $DTE.AddDays(-$Days)
Write-Host $DTE
$DTECBCK = (Get-Date).Date
$DTECBCK = $DTECBCK.AddDays(-$CBCKDays)
Write-Host $DTECBCK
$sgusername = "azure_<>@azure.com"
$sgpassword = "<>"
$secureStringPwd = $sgpassword | ConvertTo-SecureString -AsPlainText -Force 
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $sgusername, $secureStringPwd
$sub="Landing Area Archival Notification $(Get-Date)"
$body="Hello All, 
This is notification send by the Automation.
Kindly find the attached sheet which contains files moved on $(Get-Date)
Regards,
IIoT Automation"

$From = "LandingAreaArchiveAutomation@domain.com"
$To1 = "Ghanshyam.Dusane@.com"
$Cc = "ghanshyam.dusane@.com"

foreach ( $data in $IMPORT ) {

$STGACCNAME=$data.StorageAccountName
$STGACCNAMEKEY=$data.StorageAccountKey
$CONTAINERNAME=$data.SourceContainer
$DESTCONTAINERNAME=$data.DestinationContainer

$FileName=("$STGACCNAME-files-$(Get-Date)" -split " ")[0]
$finalname=$($FileName -replace "/" , "-")  + ".csv"
$FileCBCKName=("$STGACCNAME-CBCKfiles-$(Get-Date)" -split " ")[0]
$finalCBCKname=$($FileCBCKName -replace "/" , "-")  + ".csv"

$StorageAccountContext = New-AzureStorageContext -StorageAccountName $STGACCNAME -StorageAccountKey $STGACCNAMEKEY -ErrorAction Stop

$COPYDATAs = Get-AzureStorageBlob -Container $CONTAINERNAME -Context $StorageAccountContext | Where-Object { 
$_.LastModified.DateTime -lt ( $DTE ) -and  ( $_.Name -notmatch 'CB|CK' )
} 
$COPYDATAs | Export-Csv -Path $("$WorkDir"+ "\" + "$finalname")
$FilePath=$("$WorkDir"+ "\" + "$finalname") 

$COPYDATAs | Start-AzureStorageBlobCopy -DestContainer $DESTCONTAINERNAME -DestContext $StorageAccountContext -ErrorAction Stop -Force -Verbose

$COPYCBCKDATAs = Get-AzureStorageBlob -Container $CONTAINERNAME -Context $StorageAccountContext | Where-Object { 
$_.LastModified.DateTime -lt ( $DTECBCK ) -and  ( $_.Name -match 'CB|CK' ) 
}

$COPYCBCKDATAs | Export-Csv -Path $("$WorkDir"+ "\" + "$finalCBCKname")
$FilePathCBCK=$("$WorkDir"+ "\" + "$finalCBCKname")

$COPYCBCKDATAs | Start-AzureStorageBlobCopy -DestContainer $DESTCONTAINERNAME -DestContext $StorageAccountContext -ErrorAction Stop -Force -Verbose

Send-MailMessage -From $From -To $To1 -Cc $Cc -Subject $sub -Body $body -Priority High -Attachments $FilePath , $FilePathCBCK  -SmtpServer "smtp.sendgrid.net" -Credential $cred -UseSsl -Port 587
#foreach  ( $COPYDATA in $COPYDATAs ) {
#Remove-AzureStorageBlob -Container $CONTAINERNAME -Blob $COPYDATA.Name -Context $Destinationcontext -Verbose
#}
}

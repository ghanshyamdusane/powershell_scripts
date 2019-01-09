Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId "cef04a14-22ed-4db1-9785-ccc5bc19494c"
$ResourceGroupName="RG_OneShareDevTeam"
$VMName="OneShareInfraVM"
Invoke-AzureRmVMRunCommand -ResourceGroupName $ResourceGroupName -Name $VMName -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Users\gdusane\Documents\powershellscript.ps1'
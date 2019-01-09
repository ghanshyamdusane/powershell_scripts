Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId "<Subscription-ID>"
$ResourceGroupName="<RG-Name>"
$VMName="<VM-Name>"
Invoke-AzureRmVMRunCommand -ResourceGroupName $ResourceGroupName -Name $VMName -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Users\gdusane\Documents\powershellscript.ps1'

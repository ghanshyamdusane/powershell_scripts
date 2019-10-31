Connect-AzureRmAccount
Select-AzureRmSubscription -Subscription ""

$RGvirtualNetworkName = ""
$VMresourceGroupName = ""
$virtualNetworkName = ""
$VMName = ""
$PIPName = "-PIP"
$NICName = "-NIC"
$VmSize = "Standard_F8s_v2"
$destinationVhd = ""
$locationName = "westeurope"


$virtualNetwork = Get-AzureRmVirtualNetwork -ResourceGroupName $RGvirtualNetworkName -Name $virtualNetworkName
$publicIp = New-AzureRmPublicIpAddress -Name $PIPName -ResourceGroupName $VMResourceGroupName -Location $locationName -AllocationMethod Dynamic
$networkInterface = New-AzureRmNetworkInterface -ResourceGroupName $VMResourceGroupName -Name $NICName -Location $locationName -SubnetId $virtualNetwork.Subnets[1].Id -PublicIpAddressId $publicIp.Id

$vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $VMName -VhdUri $destinationVhd -CreateOption Attach -Linux
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $networkInterface.Id

$vm = New-AzureRmVM -VM $vmConfig -Location $locationName -ResourceGroupName $VMresourceGroupName

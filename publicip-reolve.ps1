$data = Import-Excel 'C:\temp\ENDPOINTS.xlsx'
foreach($u in $data) {
$A = Resolve-DNSName $u.Endpoints
$final =[pscustomobject]@{
      'Environment' =$u.Environment
      'Endpoints' = $u.Endpoints
      'PublicIP' = $A.IPAddress
      }
$final | Export-CSV 'C:\temp\ENDPOINTS.csv' -Append -NoTypeInformation -Force
Import-Csv 'C:\temp\ENDPOINTS.csv'
    }

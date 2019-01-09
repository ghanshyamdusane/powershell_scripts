$publicip = Get-Content C:\Users\ghanshyam\Desktop\linux-machines.txt 
foreach($u in $publicip) {
	$username = "sshadmin"
	$password = "Pass@1234567"
	$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
	$creds = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secureStringPwd
    $session = New-SSHSession -ComputerName $u -Credential ($creds)
    echo = $session
    Invoke-SSHCommand -Index $session.SessionID -Command "uptime"
    }

	
$publicip = Get-Content C:\Users\ghanshyam\Desktop\linux-machines.txt 
foreach($u in $publicip) {
	$username = "sshadmin"
	$password = "Pass@1234567"
	$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
	$creds = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secureStringPwd
    $session = New-SSHSession -ComputerName $u -Credential ($creds) | Export-Csv -Path C:\Users\ghanshyam\Desktop\output.csv -Append
	Invoke-SSHCommand -Index $session.SessionID -Command "uptime"
}

$publicip = Get-Content C:\Users\ghanshyam\Desktop\linux-machines.txt 
foreach($u in $publicip) {
	$username = "sshadmin"
	$password = "Pass@1234567"
	$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
	$creds = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secureStringPwd
    $session =  New-SSHSession -ComputerName $u -Credential ($creds)
    $session | Export-Csv -Path C:\Users\ghanshyam\Desktop\output.csv -Append
    Invoke-SSHCommand -Index $session.SessionID -Command "uptime"
}


for($counter = 1; $counter -le 10; $counter++)
	         {
	            Invoke-SSHCommand -Index $counter -Command "sudo systemctl status sshd"
	         }

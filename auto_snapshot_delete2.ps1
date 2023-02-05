#Setting Parameters
param(
    [parameter()]
    [switch]$query_snapshots,

    [parameter()]
    [switch]$delete_snapshots
)

$vCenter_IPorName='' #vcenter IP
$max_age = #maximum snapshot age in days as an integer
$snap_removed_count = 0 #variable that counts how many snapshots the script has deleted
$logs_file = "path\to\log_File"
$query_file = "path\to\query_File"

#importing specific modules
$modules = @('VMware.Vim','VMware.VimAutomation.Cis.Core', 'VMware.VimAutomation.Common','VMware.VimAutomation.Core','VMware.VimAutomation.Sdk') 
Import-Module -name $modules

echo ((Get-Date).ToString() + ' - Script Starts') | Out-File  -Append -FilePath $logs_file

function Main 
{ 
    $snapshots = Get-Snapshot *
    $snapshots_count = $snapshots.count
    $date = date

    if($query_snapshots.IsPresent) #checking for the 'query_snapshots' switch
    {

    echo 'query_snapshot switch has been selected'  | Out-File -Append -FilePath $query_file
    for($i=0 ; $i -le $snapshots_count - 1 ; $i++)
        {
        if (($date - $snapshots[$i].Created).days -ge $max_age)
          {
           echo 'The Snapshot: ' + $snapshots[$i].name 'of the VM: ' $snapshots[$i].vm.name + ' is older than '  $max_age ' and needs to be deleted' | Out-File -Append -FilePath $query_file
          }
        }
    }

    if($delete_snapshots.IsPresent) #checking for the 'delete_snapshots' switch
    {
     echo 'delete_snapshot switch has been selected'  | Out-File -Append -FilePath $query_file
    for($i=0 ; $i -le $snapshots_count - 1 ; $i++)
    {
        if (($date - $snapshots[$i].Created).days -ge $max_age)
          {
           remove-Snapshot -Snapshot $snapshots[$i] -Confirm:$false
           echo 'The Snapshot: ' + $snapshots[$i].name 'of the VM: ' $snapshots[$i].vm.name + ' has been deleted!' | Out-File -Append -FilePath $query_file 
           $snap_removed_count++
          }
    }
    }


    echo("")
    echo ($date + "Snapshots Removed " + $snap_removed_count)  | Out-File -Append -FilePath $logs_file

    echo '
    End of Script
    '  | Out-File -Append -FilePath $logs_file
 }
}


function Test_vCenter_Connection
{
{
	if (!$global:DefaultVIServer)
	{
        echo((Get-Date).ToString() + ' - Connecting...')
        echo ((Get-Date).ToString() + ' - attempting connection to vCenter with IP: ' + $vCenter_IP + ', with User: ' + $env:powercli_user) | Out-File  -Append -FilePath $logs_file
		Connect-VIServer -Server $vCenter_IPorName -Protocol https -User $env:powercli_user -Password  $env:powercli_password	 #this command uses credentials stored as enviorment variables to connect to Vcenter Server
	}
    else
    {
    echo ('All Ready Connected...') 
    echo ((Get-Date).ToString() + ' - Connection Succeeded') | Out-File  -Append -FilePath $logs_file
    }
   
}

else 
 {
 echo("No Connection")
 echo((Get-Date).ToString() + " - No Ping reachabillity") | Out-File -Append -FilePath $logs_file
 }
}


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>main code
#1. confirming the connection
Test_vCenter_Connection

#2. after confirming the connection we will execute the main code
Main

#3. Now we will disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenter_IPorName -Confirm:$false


<#
* view script logs in "C:\DCAuto\VMware\auto_snapshot_delete\logs.txt"

* view operational query logs in "C:\DCAuto\VMware\auto_snapshot_delete\Snapshots_logs.txt"

* testing commit
#>

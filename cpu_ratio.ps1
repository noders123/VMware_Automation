######################################################
#By Tomer Shahar                                     #
#                                                    #
#This Tool gives the administrator a brief summery   #
#of the resource allocation in is vsphere enviroment # 
#at the Cluster Level                                #
######################################################

# Setting Variables
$vCenter_IPorName = ''
$env_clusters = get-cluster
$num_env_clusters =  $env_clusters.count
$logs_file = "path\to\log_File"
$query_file = "path\to\query_File"


# importing specific modules
$modules = @('VMware.Vim','VMware.VimAutomation.Cis.Core', 'VMware.VimAutomation.Common','VMware.VimAutomation.Core','VMware.VimAutomation.Sdk') 
Import-Module -name $modules


# Testing(and if needed connecting) the connection to vCenter server
function Test_vCenter_Connection{
  {
	if (!$global:DefaultVIServer)
	  {
        echo((Get-Date).ToString() + ' - Connecting...')
        echo ((Get-Date).ToString() + ' - attempting connection to vCenter: ' + $vCenter_IPorName + ', with User: ' + $env:powercli_user) | Out-File  -Append -FilePath $logs_file
		Connect-VIServer -Server $vCenter_IPorName -Protocol https -User $env:powercli_user -Password  $env:powercli_password	 #this command uses credentials stored as enviorment variables to connect to Vcenter Server
	  }
    else
      {
      echo ('All Ready Connected...') 
      echo ((Get-Date).ToString() + ' - Connection Succeeded') | Out-File  -Append -FilePath $logs_file
      }
  }

 echo("No Connection")
 echo((Get-Date).ToString() + " - No Ping reachabillity") | Out-File -Append -FilePath $logs_file
}


function disconnect_session{
echo((Get-Date).ToString() + "Disconnecting the session from: " + $vCenter_IPorName) | Out-File -Append -FilePath $logs_file
Disconnect-VIServer -Server $vCenter_IPorName -Confirm:$false
}


function cpu_ratio_show {
  # Creating an object that will later be used to store the CPU data
  $cpu_info_Template = @{
    cluster_name = ''
    cluster_cpu = ''
    all_cpu = ''
    cpu_ratio = ''
  }

  # This variable will be defined by the object-template we created earlier
  # Each row in this object represent a differnt cluster in the envirnoment 
  $cpu_info = 0..($num_env_clusters - 1) 

  #Defining the objects with our template
  for($i=0 ; $i -lt $num_env_clusters ; $i++){
    $cpu_info[$i] = New-Object psobject -property $cpu_info_Template
  }

  for($i=0 ; $i -lt $num_env_clusters ; $i++){
  $cpu_info[$i].all_cpu = (Get-VM -Location $env_clusters[$i] |  Measure-Object 'numcpu' -Sum).sum 
  $cpu_info[$i].cluster_cpu =  (Get-VMHost -Location $env_clusters[$i] | Measure-Object 'numcpu' -sum).sum
  $cpu_info[$i].cpu_ratio = $cpu_info[$i].all_cpu/$cpu_info[$i].cluster_cpu
  $cpu_info[$i].cpu_ratio = [math]::Round($cpu_info[$i].cpu_ratio, 3)
  $cpu_info[$i].cluster_name = $env_clusters.name[$i]
  }
  $cpu_info | format-table
  echo ($cpu_info | format-table) | Out-File -Append -FilePath $query_file
}


function memory_provisioning_show{
 
  # Creating an object that will later be used to store the Memory data
  $memory_info_Template = @{
    cluster_name = ''
    cluster_memory = ''
    all_memory = ''
    memory_ratio = ''
  }

  # This variable will be defined by the object-template we created earlier
  # Each row in this object represent a differnt cluster in the envirnoment 
  $memory_info = 0..($num_env_clusters - 1)

  #Defining the objects with our template
  for($i=0 ; $i -lt $num_env_clusters ; $i++){
    $memory_info[$i] = New-Object psobject -property $memory_info_Template
  }

    for($i=0 ; $i -lt $num_env_clusters ; $i++){
    $memory_info[$i].all_memory = [math]::Round((Get-VM -Location $env_clusters[$i] |  Measure-Object 'MemoryGB' -Sum).sum)
    $memory_info[$i].cluster_memory =  [math]::Round((Get-VMHost -Location $env_clusters[$i] | Measure-Object 'MemoryTotalGB' -sum).sum)
    $memory_info[$i].memory_ratio = $memory_info[$i].all_memory/$memory_info[$i].cluster_memory
    $memory_info[$i].memory_ratio = [math]::Round($memory_info[$i].memory_ratio, 3)
    $memory_info[$i].cluster_name = $env_clusters.name[$i]
  }
  $memory_info |  format-table
  echo ($memory_info | format-table) | Out-File -Append -FilePath $query_file
}

#|>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>main code
#1. Confirming the connection
Test_vCenter_Connection

#2. querying and visualizing CPU data
cpu_ratio_show 

#3. querying and visualizing Memory data
memory_provisioning_show

#4. Disconnecting the session
disconnect_session

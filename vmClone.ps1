# Map the custom functions for OVF/vApp Options
. ./VMOvfProperty.ps1

# Set vHost Cluster
$cluster = $env:VSPHERE_NEW_VM_HOST

# Name of original VM(s)
$vmName = $env:VSPHERE_XC_CLUSTER_PREFIX

# Path to the sequence number file
$sequenceFilePath = "/tmp/working/sequenceNumber.txt"

# Initialize sequence number
if (Test-Path $sequenceFilePath) {
    $sequenceNumber = [int](Get-Content $sequenceFilePath)
} else {
    $sequenceNumber = 1
}

# Check if VM exists and increment sequence number if needed
do {
    $cloneName = "$env:VSPHERE_VAPP_PREFIX-$((Get-Date).ToString('MMddyy'))-$sequenceNumber"
    $sequenceNumber++
} while (Get-VM -Name $cloneName -ErrorAction SilentlyContinue)

# Paths to the used IPs file
$usedIpsFilePath = "/tmp/working/usedIPs.txt"

# Initialize used IPs list
$usedIPs = @()
if (Test-Path $usedIpsFilePath) {
    $usedIPs = Get-Content $usedIpsFilePath -Raw | ConvertFrom-Json
}

# Get the list of IPs from the ENV variable and filter out used IPs
$availableIPs = $env:XC_SITE_SCALE_IPS -split ',' | Where-Object { $_.Trim() -notin $usedIPs }

# If no available IPs, exit
if (-not $availableIPs) {
    Write-Error "No available IPs left."
    return
}

# Select the first available IP
$selectedIP = $availableIPs[0]

# Combine with the CIDR
$ipWithCIDR = "$selectedIP/$env:XC_SITE_SCALE_CIDR"

# Update the used IPs list and write back to file
$usedIPs += $selectedIP
$usedIPs | ConvertTo-Json | Out-File $usedIpsFilePath

# Query Controller node for values
$controller = Get-VM -Name "$($env:VSPHERE_XC_CLUSTER_PREFIX)*" | Select-Object -First 1
$controller_config = @{
    'NumCpu' = $controller.NumCpu
    'MemoryGB' = $controller.MemoryGB
    'NetworkAdapter' = $controller | Get-NetworkAdapter | ForEach-Object { $_.NetworkName }
}

# Select Datastore available on New VM Host
$ds = Get-Datastore -VMHost $env:VSPHERE_NEW_VM_HOST | Sort-Object -Property FreeSpaceGB -Descending | select -First 1

# Import OVA
$ovaURL = "https://downloads.volterra.io/releases/images/2022-09-15/centos-7.2009.27-202209150812.ova"

$localPath = "/tmp/working/centos-7.2009.27-202209150812.ova"

#$fileExists = Test-Path $datastorePath
$fileExists = Test-Path $localPath

if (-not $fileExists) {
    # Download the file from the web
    Invoke-WebRequest -Uri $ovaURL -OutFile $localPath
} else {
    Write-Host "OVA already exists on the local datastore."
}

# Export OVF / vApp Options from original VM and Map
$networkAdapters = Get-NetworkAdapter -VM $controller
$networkName1 = ($networkAdapters | Where-Object { $_.Name -eq "Network adapter 1" }).NetworkName
$networkName2 = ($networkAdapters | Where-Object { $_.Name -eq "Network adapter 2" }).NetworkName

$allProperties = Get-VMOvfProperty -VM $controller
$certified_hardware = ($allProperties | Where-Object { $_.Id -eq "guestinfo.ves.certifiedhardware" }).Value
$node_address = $ipWithCIDR
$default_route = ($allProperties | Where-Object { $_.Id -eq "guestinfo.interface.0.route.0.destination" }).Value
$cluster_name = ($allProperties | Where-Object { $_.Id -eq "guestinfo.ves.clustername" }).Value
$admin_password = $env:XC_SITE_ADMIN_PASSWORD
$dhcp = "no"
$default_gateway = ($allProperties | Where-Object { $_.Id -eq "guestinfo.interface.0.route.0.gateway" }).Value
$dns_one = ($allProperties | Where-Object { $_.Id -eq "guestinfo.dns.server.0" }).Value
$dns_two = ($allProperties | Where-Object { $_.Id -eq "guestinfo.dns.server.1" }).Value
$latitude = ($allProperties | Where-Object { $_.Id -eq "guestinfo.ves.latitude" }).Value
$longitude = ($allProperties | Where-Object { $_.Id -eq "guestinfo.ves.longitude" }).Value
$token = ($allProperties | Where-Object { $_.Id -eq "guestinfo.ves.token" }).Value
$cpu = $controller_config.NumCpu
$memory = ($controller_config.MemoryGB * 1024)

# Construct .tfvars content
$tfvarsContent = @"
vsphere_server="$env:VSPHERE_HOST"
user="$env:VSPHERE_USER"
password="$env:VSPHERE_PASS"
datacenter="$env:VSPHERE_DC"
datastore_one="$ds"
vsphere_host_one="$env:VSPHERE_NEW_VM_HOST"
resource_pool="$env:VSPHERE_RESOURCE_POOL"
outside_network="$networkName1"
inside_network="$networkName2"
sitelatitude="$latitude"
sitelongitude="$longitude"
xcsovapath="$localPath"
sitename="$cluster_name"
nodename="$cloneName"
sitetoken="$token"
dns_primary="$dns_one"
dns_secondary="$dns_two"
cpus="$cpu"
memory="$memory"
node_address="$node_address"
"@

# Write TFVars file for node
$tfvarsContent | Out-File -Encoding utf8 -FilePath "/tmp/working/$cloneName.tfvars"

#With Terraform
cp -rf /tmp/tf/. /tmp/working
cd /tmp/working

terraform workspace new $cloneName
terraform init
terraform plan -var-file="/tmp/working/$cloneName.tfvars"
terraform apply -var-file="/tmp/working/$cloneName.tfvars" --auto-approve
cd /

# Write the sequence number back to the file
$sequenceNumber | Out-File $sequenceFilePath

# Register Node
. ./xcRegistration.ps1

# Make sure to kill connections to host
#Disconnect-VIServer -Server $env:VSPHERE_HOST -Confirm:$false
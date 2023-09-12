# Uncomment once running, need to authenticate and estabish session
Connect-VIServer -Server $env:VSPHERE_HOST -User $env:VSPHERE_USER -Password $env:VSPHERE_PASS -Force

# pull in our high and low water mark
$high_percentage = $env:USAGE_HIGH_MARK
$low_percentage = $env:USAGE_LOW_MARK

# Split the comma-delimited list into an array
$vmNames = Get-VM -Name "$($env:VSPHERE_XC_CLUSTER_PREFIX)*" | Select-Object -ExpandProperty Name

$sStat = @{
    Entity = Get-VM -Name $vmNames
    Stat = 'cpu.usagemhz.average','cpu.usage.average','mem.granted.average','mem.usage.average','disk.usage.average', 'net.bytesRx.average', 'net.bytesTx.average', 'net.usage.average'
    Instance = ''
    MaxSamples = 1
    Realtime = $true
    ErrorAction = 'SilentlyContinue'
}

$flaggedCount = 0
$belowLowMarkCount = 0

Get-Stat @sStat | Group-Object -Property {$_.Entity.Name} -PipelineVariable group |
ForEach-Object -Process {
    $cpuPct = [math]::Round(($group.Group | where{$_.MetricId -eq 'cpu.usage.average'}).Value, 0)
    $memPct = [math]::Round(($group.Group | where{$_.MetricId -eq 'mem.usage.average'}).Value, 0)

    $netBytesRx = ($group.Group | where{$_.MetricId -eq 'net.bytesRx.average'}).Value
    $netBytesTx = ($group.Group | where{$_.MetricId -eq 'net.bytesTx.average'}).Value
    $netUsage = ($group.Group | where{$_.MetricId -eq 'net.usage.average'}).Value

    
    # Check if either CPU or Memory percentage exceeds the high percentage
    $flagged = $false
    if ($cpuPct -gt $high_percentage -or $memPct -gt $high_percentage) {
        $flagged = $true
        $flaggedCount++
        Write-Warning "High resource usage detected on VM $($group.Name)"
    }

    # Check if both CPU and Memory percentages are below the low percentage
    if ($cpuPct -lt $low_percentage -and $memPct -lt $low_percentage) {
        $belowLowMarkCount++
    }

    New-Object -TypeName PSObject -Property (
        [ordered]@{
            VmName = $group.Name
            'CPU GHz' = [math]::Round(($group.Group | where{$_.MetricId -eq 'cpu.usagemhz.average'}).Value / 1000,2)
            'CPU Pct' = $cpuPct
            'Mem GB'  = [math]::Round(($group.Group | where{$_.MetricId -eq 'mem.granted.average'}).Value / 1MB,2)
            'Mem Pct' = $memPct
            'Net Received KB/s' = $netBytesRx
            'Net Transmitted KB/s' = $netBytesTx
            'Net Total Usage KB/s' = $netUsage
            Flagged = $flagged
        }
    )
} | Format-Table -AutoSize

# Check if 2 or more VMs were flagged
$scale_out = $false
if ($flaggedCount -ge 2) {
    $scale_out = $true
    Write-Host "Scale out condition met." -ForegroundColor Red
    . ./vmClone.ps1
}

# Check if all VMs are below the low percentage
$scale_down = $false
if ($belowLowMarkCount -ge $vmNames.Count) {
    $scale_down = $true
    Write-Host "Scale down condition met." -ForegroundColor Green
    . ./vmDelete.ps1
}

if (-not $scale_out -and -not $scale_down) {
    Write-Host "All systems are operating within expected limits." -ForegroundColor Green
}

# Make sure to kill connections to host
#Disconnect-VIServer -Server $env:VSPHERE_HOST -Confirm:$false

# Path to the sequence number file
$sequenceFilePath = "/tmp/working/sequenceNumber.txt"

# Initialize sequence number
if (Test-Path $sequenceFilePath) {
    $sequenceNumber = [int](Get-Content $sequenceFilePath) -1
    Write-Host $sequenceNumber
} else {
    Write-Host "No VMs to destroy."
    return
}

# Check if VM exists and decrement sequence number if needed
do {
    $RMcloneName = "$env:VSPHERE_VAPP_PREFIX-$((Get-Date).ToString('MMddyy'))-$sequenceNumber"
    Write-Host $cloneName
    
    if (Get-VM -Name $RMcloneName -ErrorAction SilentlyContinue) {
        # Destroy the VM using Terraform
        cd /tmp/working
        terraform destroy --auto-approve -var-file="/tmp/working/$RMcloneName.tfvars"
        terraform workspace select default
        terraform workspace delete $RMcloneName
        rm -rf /tmp/working/$RMcloneName.tfvars
        # Decrement the sequence number
        $sequenceNumber--
    } else {
        # If the VM with that name doesn't exist, exit the loop
        break
    }
} while ($sequenceNumber -gt 0)

# Write the sequence number back to the file
$sequenceNumber | Out-File $sequenceFilePath
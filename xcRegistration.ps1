# Define the base URL
$baseUrl = $env:XC_TENANT_URL.TrimEnd('/')

# Define the namespace and site name
$namespace = "system"
$siteName = $env:XC_SITE_NAME

# Map API Token
$token = $env:XC_API_TOKEN

$headers = @{
    'Authorization' = "APIToken $token"
    'Content-Type' = 'application/json'
}

# We want to make sure that the VM is up and the registration is recieved so lets add some error control and looping.
# Define a maximum number of retries
$maxRetries = 20
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {

    # Fetch the site's UUID based on its name
    $response = Invoke-RestMethod -Uri "$baseUrl/api/register/namespaces/system/registrations_by_site/$siteName" -Headers $headers -Method GET

        # Check if the response contains the 'name' key with a value
        if ($response.items.name -eq "desired_value") {
            $success = $true

            # Define the registration name
            $siteUUID = $response.uuid
            $registrationName = "r-$siteUUID"

            # Approve the registration
            Invoke-RestMethod -Uri "$baseUrl/api/register/namespaces/system/registration/$registrationName/approve" -Headers $headers -Method POST

        } else {
            # Wait for a specified time (e.g., 5 seconds) before retrying
            Start-Sleep -Seconds 30
            $retryCount++
        }
}
if (-not $success) {
    Write-Warning "Failed to retrieve the desired response after $maxRetries attempts."
} else {
    Write-Host "Successful registration of node to $siteName"
}


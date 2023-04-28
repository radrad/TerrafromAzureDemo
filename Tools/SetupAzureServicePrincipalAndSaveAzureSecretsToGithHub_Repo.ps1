# Login to Azure
Connect-AzAccount

$env:GITHUB_TOKEN = "<Your PAT token>"

$remoteUrl = git config --get remote.origin.url
$regex = '.*[:/](.+)/(.+)\.git$'
if ($remoteUrl -match $regex) {
    $owner = $Matches[1]
    $repoName = $Matches[2]
    Write-Output "Owner: $owner"
    Write-Output "Repo Name: $repoName"
} else {
    Write-Output "Unable to extract repository name and owner from the remote URL"
}


# Get the subscription ID and tenant ID
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

# Create a new service principal with Contributor access to the subscription
$sp = New-AzADServicePrincipal -Role Contributor -Scope "/subscriptions/$subscriptionId"

# Get the service principal ID and secret
$appId = $sp.ApplicationId
$password = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-AzADSpCredential -ObjectId $sp.Id).Secret))

# Push the service principal ID and secret to Github secrets at the repository level
$secrets = @{
    AZURE_SUBSCRIPTION_ID = $subscriptionId
    AZURE_TENANT_ID = $tenantId
    AZURE_CLIENT_ID = $appId
    AZURE_CLIENT_SECRET = $password
}
$repoPath = "/repos/$owner/$repoName/actions/secrets"

$secrets.GetEnumerator() | ForEach-Object {
    $name = $_.Name
    $value = $_.Value
    $path = "$repoPath/$name"
    $body = @{
        "encrypted_value" = [System.Convert]::ToBase64String((ConvertTo-SecureString -String $value -AsPlainText -Force).ToByteArray())
    }
    Invoke-RestMethod -Method Put -Uri "https://api.github.com$path" -Headers @{
        "Authorization" = "Bearer $GITHUB_TOKEN"
        "Accept" = "application/vnd.github.v3+json"
    } -Body ($body | ConvertTo-Json)
}

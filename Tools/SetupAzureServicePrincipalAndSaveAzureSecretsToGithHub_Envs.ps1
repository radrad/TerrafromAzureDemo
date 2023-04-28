# Login to Azure
Connect-AzAccount

$env:GITHUB_TOKEN = "<Your PAT token>"

# Get the subscription ID and tenant ID
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

# Create a new service principal with Contributor access to the subscription
$sp = New-AzADServicePrincipal -Role Contributor -Scope "/subscriptions/$subscriptionId"

# Get the service principal ID and secret
$appId = $sp.ApplicationId
$password = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-AzADSpCredential -ObjectId $sp.Id).Secret))

# Push the service principal ID and secret to Github environments as secrets
$secrets = @{
    AZURE_SUBSCRIPTION_ID = $subscriptionId
    AZURE_TENANT_ID = $tenantId
    AZURE_CLIENT_ID = $appId
    AZURE_CLIENT_SECRET = $password
}
foreach ($env in "dev", "stage", "prod") {
    $secrets.GetEnumerator() | ForEach-Object {
        $name = $_.Name
        $value = $_.Value
        $path = "/repos/{owner}/{repo}/environments/$env/secrets/$name"
        $body = @{
            "encrypted_value" = [System.Convert]::ToBase64String((ConvertTo-SecureString -String $value -AsPlainText -Force).ToByteArray())
        }
        Invoke-RestMethod -Method Put -Uri "https://api.github.com$path" -Headers @{
            "Authorization" = "Bearer $env:GITHUB_TOKEN"
            "Accept" = "application/vnd.github.v3+json"
        } -Body ($body | ConvertTo-Json)
    }
}

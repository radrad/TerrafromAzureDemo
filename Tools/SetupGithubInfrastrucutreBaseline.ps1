#https://github.com/Azure-Samples/terraform-github-actions
#Create a new branch and check in the needed Terraform code modifications.
#Create a Pull Request (PR) in GitHub once you're ready to merge your changes into your environment.
#A GitHub Actions workflow will trigger to ensure your code is well formatted, internally consistent, and produces secure infrastructure. In addition, a Terraform plan will run to generate a preview of the changes that will happen in your Azure environment.
#Once appropriately reviewed, the PR can be merged into your main branch.
#Another GitHub Actions workflow will trigger from the main branch and execute the changes using Terraform.
#A regularly scheduled GitHub Action workflow should also run to look for any configuration drift in your environment and create a new issue if changes are detected.
#gh repo delete radrad/TerrafromAzureDemo --yes

# Get the current folder name
$folderName = (Get-Item -Path ".\").Name

$env:GITHUB_TOKEN = "<Your PAT token>"

# GitHub API variables
$repoName = $folderName
$description = "Infrastructure as Code for $folderName"

# GitHub API endpoint
$githubApiEndpoint = "https://api.github.com"

# GitHub API request headers
$headers = @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept = "application/vnd.github.v3+json"
}

# Create a new GitHub repository
$repoData = @{
    name = $repoName
    description = $description
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$githubApiEndpoint/user/repos" -Method Post -Headers $headers -Body $repoData

#git config --global init.defaultBranch dev
$localDefaultBranch = git config --get init.defaultBranch

# Initialize a Git repository locally in dev branch 
git init

git checkout -b main
git add .\README.md
git commit -m "Initial commit to main branch"

# Add remote origin to the GitHub repository and push files
$remoteUrl = $response.clone_url
git remote add origin $remoteUrl

git push -u origin main


git checkout -b $localDefaultBranch

git add .
git commit -m "Initial commit to dev branch"

git push -u origin $localDefaultBranch

git add .
git commit -m "Second commit to dev branch"

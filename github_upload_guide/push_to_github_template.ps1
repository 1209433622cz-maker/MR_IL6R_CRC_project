# PowerShell template: push MR_IL6R_CRC package to GitHub
# Run this inside the unzipped MR_IL6R_CRC_GitHub_repo_v47_public_upload folder.

$GITHUB_USER = "<YOUR_GITHUB_USERNAME>"
$REPO_NAME = "MR_IL6R_CRC_project"
$REMOTE = "https://github.com/$GITHUB_USER/$REPO_NAME.git"

git init
git branch -M main
git add .
git commit -m "Initial upload of MR_IL6R_CRC manuscript data package"
git remote add origin $REMOTE
git push -u origin main

echo "__DONE__ $(Get-Date)"

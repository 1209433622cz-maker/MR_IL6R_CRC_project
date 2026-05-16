# GitHub Upload Guide

## Option A — Web upload, easiest

1. On GitHub home, click **New** next to Top repositories.
2. Repository name: `MR_IL6R_CRC_project`.
3. Choose **Private** first if you are not ready to publicly release data.
4. Do not add a README online if you will upload this prepared package, because this package already has one.
5. Create repository.
6. Unzip `MR_IL6R_CRC_GitHub_repo_v47_public_upload.zip` locally.
7. Open the unzipped folder.
8. Drag the **contents** of `MR_IL6R_CRC_GitHub_repo_v47_public_upload/` into the GitHub repository upload page.
9. Commit message: `Initial upload of MR_IL6R_CRC manuscript data package`.
10. Click **Commit changes**.

Important: GitHub browser upload has a 25 MiB per-file limit and up to 100 files per upload. This prepared public upload package keeps individual files below that threshold, but if the browser refuses too many files at once, upload folders in batches.

## Option B — Command line, recommended

Open PowerShell in the unzipped repository folder and run:

```powershell
git init
git branch -M main
git add .
git commit -m "Initial upload of MR_IL6R_CRC manuscript data package"
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/MR_IL6R_CRC_project.git
git push -u origin main
```

## Create a stable release link

After pushing:

1. Open the repository on GitHub.
2. Click **Releases**.
3. Click **Draft a new release**.
4. Tag: `v1.0.0`.
5. Title: `MR_IL6R_CRC manuscript data package v1.0.0`.
6. Description: summarize manuscript, GEO validation, supplementary tables, and figure source data.
7. Publish release.

Then use this URL in the manuscript:

`https://github.com/<YOUR_GITHUB_USERNAME>/MR_IL6R_CRC_project/releases/tag/v1.0.0`

## Optional Zenodo DOI

After GitHub upload, you can link the repository to Zenodo and archive a GitHub release to obtain a DOI. Replace `[[INSERT_REPOSITORY_URL_OR_DOI]]` in the manuscript with the DOI if available.

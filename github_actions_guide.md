# Automating Archintosh ISO Builds with GitHub Actions

This guide explains how to set up an automated CI/CD pipeline using GitHub Actions. Whenever you create a new Release tag (e.g., `v1.0.0`) in GitHub, this workflow will automatically:

1. Spin up an Arch Linux container
2. Build the Archintosh ISO using `mkarchiso`
3. Split the resulting ISO into 2GB chunks (to bypass GitHub's 2GB file limit on releases)
4. Upload all chunks directly to the latest GitHub Release

## Step 1: Create the Workflow File

Create a new file in your repository at exactly this path:
`.github/workflows/build-iso.yml`

*Note: You may need to create the `.github` and `workflows` directories first.*

## Step 2: Add the Workflow Configuration

Copy and paste the following content into `.github/workflows/build-iso.yml`:

```yaml
name: Build Archintosh ISO

# Automatically trigger the workflow when a tag is pushed (e.g., git tag v1.0.0 && git push origin v1.0.0)
on:
  push:
    tags:
      - 'v*'
  # Also allow triggering the build manually from the Actions tab
  workflow_dispatch:

# Grant the necessary permissions to create releases and upload assets
permissions:
  contents: write

jobs:
  build:
    name: Build ISO
    runs-on: ubuntu-latest
    
    # Run the build inside an official Arch Linux container
    container:
      image: archlinux:latest
      options: --privileged

    steps:
      - name: Install dependencies
        run: |
          pacman -Syu --noconfirm
          pacman -S --noconfirm git archiso qemu-img base-devel dosfstools squashfs-tools mtools xorriso sudo grub

      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build ISO using mkarchiso
        run: |
          # Build the ISO
          mkarchiso -v -w work -o out iso_profile

      - name: Split ISO
        run: |
          # The output ISO will be in the out/ directory
          ISO_FILE=$(ls out/*.iso | head -n 1)
          
          # GitHub has a 2GB file limit for releases. 
          # Arch ISOs are often around 2.2GB. We split them into 1.5GB parts.
          # The prefix will be archintosh-part-
          split -b 1500M "$ISO_FILE" out/archintosh-part-
          
          # Print the checksum of the original ISO for reference
          sha256sum "$ISO_FILE" > out/sha256sum.txt
          cat out/sha256sum.txt
          
          # Remove the original ISO to save space
          rm "$ISO_FILE"

      - name: Create GitHub Release and Upload Assets
        uses: softprops/action-gh-release@v1
        with:
          files: |
            out/archintosh-part-*
            out/sha256sum.txt
          draft: true
          generate_release_notes: true
```

## Step 3: Commit and Push

Commit the new workflow file to your repository:

```bash
git add .github/workflows/build-iso.yml
git commit -m "Add GitHub Actions workflow for automatic ISO building"
git push origin main
```

## How to trigger a build

### Method 1: Pushing a Tag (Recommended)

When you are ready to make a release, simply tag your commit and push it:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will see the new tag starting with `v` and start the build process automatically.

### Method 2: Manual Trigger

1. Go to your repository on GitHub.
2. Click on the **Actions** tab.
3. On the left sidebar, click on **Build Archintosh ISO**.
4. Click the **Run workflow** dropdown on the right side and click the green **Run workflow** button.

## How to download the release

Once the Action completes, go to the **Releases** section of your GitHub repository. You will see a new Draft release containing the split files (`archintosh-part-aa`, `archintosh-part-ab`, etc.) and a `sha256sum.txt` file. You can then publish the release to make it public.

Users can combine the parts using the commands already documented in your `README.md`.

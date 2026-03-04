[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$version
)

BEGIN {

  if (-not $version -or [String]::IsNullOrWhitespace($version))
  {
      Write-Host "Please, specify a valid version number." -ForegroundColor Red
      throw;
  }

  Function Update-CsprojVersion {
    param([string]$path, [string]$version)
    [xml]$document = Get-Content -Path $path -Raw
    $newPrefix = $document.Project.PropertyGroup.VersionPrefix.Replace("42.43.44", $version)
    $document.Project.PropertyGroup.VersionPrefix = $newPrefix
    $document.Save($path)

    Write-Host "Updated version of $path to $version." -ForegroundColor Cyan
  }
  Function Update-NuspecVersion {
    param([string]$path, [string]$version)
    [xml]$document = Get-Content -Path $path -Raw
    $newPrefix = $document.package.metadata.version.Replace("42.43.44", $version)
    $document.package.metadata.version = $newPrefix
    $document.Save($path)

    Write-Host "Updated version of $path to $version." -ForegroundColor Cyan
  }
}

PROCESS {

  # remove leading `v` from the version number
  $version = $version -replace "^v", ""

  $SRC_DIR = (Resolve-Path -Path (
    Join-Path -Path $PSScriptRoot -ChildPath "..")).Path

  "$SRC_DIR/src/jmespath.net/jmespath.net.csproj", `
  "$SRC_DIR/src/jmespath.net.parser/jmespath.net.parser.csproj" |% {

    Update-CsprojVersion `
      -Version $version `
      -Path $_
  }

  "$SRC_DIR/src/jmespath.net.parser/jmespath.net.parser.nuspec" |% {

    Update-NuspecVersion `
      -Version $version `
      -Path $_
  }
}

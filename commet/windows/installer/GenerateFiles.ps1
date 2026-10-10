
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"

$SourceDir = (Resolve-Path $SourceDir).Path
$files = @(
    Get-ChildItem -LiteralPath $SourceDir -Recurse -File |
    Sort-Object FullName
)

if ($files.Count -eq 0) {
    throw "No application files found in '$SourceDir'."
}

$ns = [System.Xml.Linq.XNamespace]::Get(
    "http://wixtoolset.org/schemas/v4/wxs"
)

function Get-IdHash([string]$value) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(
            $value.Replace('\', '/').ToLowerInvariant()
        )
        $hash = [Convert]::ToHexString($sha.ComputeHash($bytes))
        return $hash.Substring(0, 24)
    }
    finally {
        $sha.Dispose()
    }
}

function New-FileComponent($file, [string]$relativePath) {
    $hash = Get-IdHash $relativePath
    $componentId = "CMP_$hash"
    $registryName = "File_$hash"

    # Generate a stable GUID from the file's relative path.
    $guidHash = [System.Security.Cryptography.MD5]::HashData(
        [System.Text.Encoding]::UTF8.GetBytes(
            "CommetInstallerComponent/$($relativePath.Replace('\', '/').ToLowerInvariant())"
        )
    )
    $guid = [guid]::new($guidHash).ToString("D")

    $component = [System.Xml.Linq.XElement]::new(
        $script:ns + "Component",
        [System.Xml.Linq.XAttribute]::new("Id", $componentId),
        [System.Xml.Linq.XAttribute]::new("Guid", $guid),
        [System.Xml.Linq.XElement]::new(
            $script:ns + "RegistryValue",
            [System.Xml.Linq.XAttribute]::new("Root", "HKCU"),
            [System.Xml.Linq.XAttribute]::new(
                "Key", "Software\Commet\Installer\Files"
            ),
            [System.Xml.Linq.XAttribute]::new("Name", $registryName),
            [System.Xml.Linq.XAttribute]::new("Type", "integer"),
            [System.Xml.Linq.XAttribute]::new("Value", "1"),
            [System.Xml.Linq.XAttribute]::new("KeyPath", "yes")
        ),
        [System.Xml.Linq.XElement]::new(
            $script:ns + "File",
            [System.Xml.Linq.XAttribute]::new(
                "Source", $file.FullName
            )
        )
    )

    $script:componentIds.Add($componentId)
    return ,$component
}


# Build an in-memory directory tree.
$root = @{
    Name = ""
    Files = [System.Collections.Generic.List[object]]::new()
    Children = [ordered]@{}
}

foreach ($file in $files) {
    $relative = [System.IO.Path]::GetRelativePath(
        $SourceDir, $file.FullName
    )
    $relative = $relative.Replace('\', '/')
    $parts = $relative.Split('/')

    $node = $root

    for ($i = 0; $i -lt ($parts.Length - 1); $i++) {
        $part = $parts[$i]

        if (-not $node.Children.Contains($part)) {
            $node.Children[$part] = @{
                Name = $part
                Files = [System.Collections.Generic.List[object]]::new()
                Children = [ordered]@{}
            }
        }

        $node = $node.Children[$part]
    }

    $node.Files.Add([pscustomobject]@{
        File = $file
        RelativePath = $relative
    })
}

$componentIds = [System.Collections.Generic.List[string]]::new()

function New-DirectoryElement($node, [string]$relativeDir) {
    $dirId = "DIR_$(Get-IdHash $relativeDir)"

    $directory = [System.Xml.Linq.XElement]::new(
        $script:ns + "Directory",
        [System.Xml.Linq.XAttribute]::new("Id", $dirId),
        [System.Xml.Linq.XAttribute]::new("Name", $node.Name)
    )

    # ICE64: register this per-user directory for removal on uninstall.
    $cleanupComponentId = "CLEAN_$((Get-IdHash $relativeDir))"

    $cleanupComponent = [System.Xml.Linq.XElement]::new(
        $script:ns + "Component",
        [System.Xml.Linq.XAttribute]::new(
            "Id", $cleanupComponentId
        ),
        [System.Xml.Linq.XAttribute]::new(
            "Guid",
            [guid]::new(
                [System.Security.Cryptography.MD5]::HashData(
                    [System.Text.Encoding]::UTF8.GetBytes(
                        "CommetInstallerCleanup/$($relativeDir.ToLowerInvariant())"
                    )
                )
            ).ToString("D")
        ),
        [System.Xml.Linq.XElement]::new(
            $script:ns + "RemoveFolder",
            [System.Xml.Linq.XAttribute]::new(
                "Id", "RM_$((Get-IdHash $relativeDir))"
            ),
            [System.Xml.Linq.XAttribute]::new("On", "uninstall")
        ),
        [System.Xml.Linq.XElement]::new(
            $script:ns + "RegistryValue",
            [System.Xml.Linq.XAttribute]::new("Root", "HKCU"),
            [System.Xml.Linq.XAttribute]::new(
                "Key", "Software\Commet\Installer\Folders"
            ),
            [System.Xml.Linq.XAttribute]::new(
                "Name", (Get-IdHash $relativeDir)
            ),
            [System.Xml.Linq.XAttribute]::new("Type", "integer"),
            [System.Xml.Linq.XAttribute]::new("Value", "1"),
            [System.Xml.Linq.XAttribute]::new("KeyPath", "yes")
        )
    )

    $directory.Add($cleanupComponent)
    $script:componentIds.Add($cleanupComponentId)

    foreach ($entry in $node.Files) {
        $component = New-FileComponent `
            $entry.File $entry.RelativePath
        $directory.Add($component)
    }

    foreach ($childName in $node.Children.Keys) {
        $childPath = "$relativeDir/$childName"
        $child = New-DirectoryElement `
            $node.Children[$childName] $childPath
        $directory.Add($child)
    }

    return $directory
}

# The first fragment defines the generated file components.
$directoryRef = [System.Xml.Linq.XElement]::new(
    $ns + "DirectoryRef",
    [System.Xml.Linq.XAttribute]::new("Id", "INSTALLFOLDER")
)

foreach ($entry in $root.Files) {
    $directoryRef.Add(
        (New-FileComponent $entry.File $entry.RelativePath)
    )
}

foreach ($childName in $root.Children.Keys) {
    $directoryRef.Add(
        (New-DirectoryElement $root.Children[$childName] $childName)
    )
}

$fragment1 = [System.Xml.Linq.XElement]::new(
    $ns + "Fragment", $directoryRef
)

# The second fragment groups all generated components for the Feature.
$componentGroup = [System.Xml.Linq.XElement]::new(
    $ns + "ComponentGroup",
    [System.Xml.Linq.XAttribute]::new("Id", "CommetFiles")
)

foreach ($componentId in $componentIds) {
    $componentGroup.Add(
        [System.Xml.Linq.XElement]::new(
            $ns + "ComponentRef",
            [System.Xml.Linq.XAttribute]::new("Id", $componentId)
        )
    )
}

$fragment2 = [System.Xml.Linq.XElement]::new(
    $ns + "Fragment", $componentGroup
)

$document = [System.Xml.Linq.XDocument]::new(
    [System.Xml.Linq.XDeclaration]::new("1.0", "UTF-8", "yes"),
    [System.Xml.Linq.XElement]::new(
        $ns + "Wix",
        $fragment1,
        $fragment2
    )
)

$OutputFile = [System.IO.Path]::GetFullPath($OutputFile)
$outputDirectory = [System.IO.Path]::GetDirectoryName($OutputFile)

[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)

$writer = [System.Xml.XmlWriter]::Create($OutputFile, $settings)
try {
    $document.Save($writer)
}
finally {
    $writer.Dispose()
}

Write-Host "Generated $($componentIds.Count) file components."
Write-Host "WiX source: $OutputFile"

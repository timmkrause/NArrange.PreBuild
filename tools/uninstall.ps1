# Copyright (c) 2013 Timm Krause (timm.krause1@gmail.com). All rights reserved.
# Kudos to Adam Ralph who allowed me to use some snippets of his PowerShell scripts within his StyleCop.MSBuild package.

param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath "remove.psm1")

# Save any unsaved changes before we start messing about with the project file.
$project.Save()

# Load project XML.
$doc = New-Object System.Xml.XmlDocument
$doc.Load($project.FullName)
$namespace = 'http://schemas.microsoft.com/developer/msbuild/2003'

# Remove changes.
Remove-Changes $doc $namespace

# Save changes.
$doc.Save($project.FullName)
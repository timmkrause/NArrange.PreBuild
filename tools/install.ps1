# Copyright (c) 2013 Timm Krause (timm.krause1@gmail.com). All rights reserved.
# Kudos to Adam Ralph who allowed me to use some snippets of his PowerShell scripts within his StyleCop.MSBuild package.

param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath "remove.psm1")

function Append-Property($doc, $namespace, $propertyGroup, $propertyName, $value)
{
    $property = $doc.CreateElement($propertyName, $namespace)
    $property.AppendChild($doc.CreateTextNode($value))
    $propertyGroup.AppendChild($property)
}

function Get-NArrangePreBuildEventCall
{
    $absolutePath = Join-Path $toolsPath "narrange-console.exe"
    $absoluteUri = New-Object -typename System.Uri -argumentlist $absolutePath
    $projectUri = New-Object -typename System.Uri -argumentlist $project.FullName
    $relativeUri = $projectUri.MakeRelativeUri($absoluteUri)
    $relativePath = [System.URI]::UnescapeDataString($relativeUri.ToString()).Replace([System.IO.Path]::AltDirectorySeparatorChar, [System.IO.Path]::DirectorySeparatorChar)
    
    # "$(SolutionDir)\packages\NArrange.PreBuild.{version}\tools\narrange-console.exe" "$(ProjectPath)"
    $narrangeCall = '"' + $relativePath.Replace('..', '$(SolutionDir)') + '"' + ' ' + '"$(ProjectPath)"'

    return $narrangeCall
}

# Remove content hook from project and delete file.
$hookName = "NArrange.PreBuild.ContentHook.txt"
$project.ProjectItems.Item($hookName).Remove()
Split-Path $project.FullName -parent | Join-Path -ChildPath $hookName | Remove-Item

# Save removal of content hook and any other unsaved changes to project before we start messing about with project file.
$project.Save()

# Load project XML.
$doc = New-Object System.Xml.XmlDocument
$doc.Load($project.FullName)
$namespace = 'http://schemas.microsoft.com/developer/msbuild/2003'

# Remove previous changes - executed here for safety, in case for some reason uninstall.ps1 hasn't been executed.
Remove-Changes $doc $namespace

$preBuildEventProperty = Get-PreBuildEventXmlNode $doc $namespace

if ($preBuildEventProperty)
{
    # Modifiy existing PreBuildEvent property.
    $nonEmptyLinesArray = StringToLineArray($preBuildEventProperty.ToString()) | where { $_.Trim() -ne "" }

    # Remove PreBuildEvent property.
    $propertyGroup = $preBuildEventProperty.Node.ParentNode
    $propertyGroup.RemoveChild($preBuildEventProperty.Node)

    # Add it again with added NArrange call which was previously removed by Remove-Changes.
    $newProperty = $doc.CreateElement("PreBuildEvent", $namespace)
    $nonEmptyLinesArray += Get-NArrangePreBuildEventCall
    $nonEmptyLinesString = LineArrayToString($nonEmptyLinesArray)
    $newProperty.AppendChild($doc.CreateTextNode($nonEmptyLinesString))
    $propertyGroup.AppendChild($newProperty)
}
else
{
    # Add PreBuildEvent property.
    $propertyGroup = $doc.CreateElement('PropertyGroup', $namespace)
    $narrangeCall = Get-NArrangePreBuildEventCall
    Append-Property $doc $namespace $propertyGroup 'PreBuildEvent' $narrangeCall
    $doc.Project.AppendChild($propertyGroup)
}

# Save changes.
$doc.Save($project.FullName)
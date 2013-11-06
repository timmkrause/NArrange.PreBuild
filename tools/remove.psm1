# Copyright (c) Timm Krause (timm.krause1@gmail.com). All rights reserved.
# Kudos to Adam Ralph who allowed me to use some snippets of his PowerShell scripts within his StyleCop.MSBuild package.

function StringToLineArray($string)
{
    return $string.Split("`r`n")
}

function LineArrayToString($lineArray)
{
    $returnValue = ""

    foreach ($line in $lineArray)
    {
        if ($returnValue -ne "")
        {
            $returnValue += "`r`n"
        }

        $returnValue += $line
    }

    return $returnValue
}

function Get-PreBuildEventXmlNode($doc, $namespace)
{
    $preBuildEventXmlNodes = Select-Xml "//msb:Project/msb:PropertyGroup/msb:PreBuildEvent" $doc -Namespace @{msb = $namespace}

    if ($preBuildEventXmlNodes)
    {
        return $preBuildEventXmlNodes[$preBuildEventXmlNodes.Count - 1]
    }
    else
    {
        return $null
    }
}

function Remove-Changes
{
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [System.Xml.XmlDocument]$doc,
        
        [parameter(Position = 1, Mandatory = $true)]
        [string]$namespace)

    $preBuildEventProperty = Get-PreBuildEventXmlNode $doc $namespace

    if ($preBuildEventProperty)
    {
        $nonEmptyLinesWithoutNarrangeLine = StringToLineArray($preBuildEventProperty.ToString()) |
            where { $_.Trim() -ne "" } |
            where { !$_.ToString().Contains("narrange-console.exe") }

        if ($nonEmptyLinesWithoutNarrangeLine.Length -eq 0)
        {
            # Remove whole PropertyGroup since no valid value was found.                        
            $propertyGroup = $preBuildEventProperty.Node.ParentNode
            $propertyGroup.RemoveChild($preBuildEventProperty.Node)
            
            if (!$propertyGroup.HasChildNodes)
            {
                $propertyGroup.ParentNode.RemoveChild($propertyGroup)
            }
        }
        else
        {
            # Remove PreBuildEvent property.
            $propertyGroup = $preBuildEventProperty.Node.ParentNode
            $propertyGroup.RemoveChild($preBuildEventProperty.Node)

            # Add it again with (maybe) deleted narrange-console.exe line.
            $newPreBuildEventProperty = $doc.CreateElement("PreBuildEvent", $namespace)
            $nonEmptyLinesWithoutNarrangeLineString = LineArrayToString($nonEmptyLinesWithoutNarrangeLine)
            $newPreBuildEventProperty.AppendChild($doc.CreateTextNode($nonEmptyLinesWithoutNarrangeLineString))
            $propertyGroup.AppendChild($newPreBuildEventProperty)
        }
    }
}
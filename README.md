# NArrange.PreBuild

Adds the official NArrange code formatter to your pre build event for unifying and beautifying your source files with every build.

## Allow external configuration file

Example to use this feature:

    <Import
	  Project="..\packages\NArrange.PreBuild.0.2.9.{x}\build\NArrange.PreBuild.targets"
	  Condition="Exists('..\packages\NArrange.PreBuild.0.2.9.{x}\build\NArrange.PreBuild.targets')" />
    <PropertyGroup>
      <NArrangePreBuildConfig>..\{Another}.NArrange.config.xml</NArrangePreBuildConfig>
    </PropertyGroup>
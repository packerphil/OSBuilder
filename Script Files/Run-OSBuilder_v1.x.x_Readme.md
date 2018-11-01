<b>CURRENT STABLE VERSION =</b> 1.0.5<br/><br/>
<b>DESCRIPTION</b><br/>
Wrapper script used to run OSBuilder module v10.10.26.0 (from David Segura) commands to<br/>
build Windows 10 installation media that is patched and has only the apps and features desired.<br/>

<b><i>NOTE:</b> Only works with Windows 10 Enterprise at this time.</i><br/>

----------------------------------------------------
<br/>

<b>PARAMETER -</b> <i>EnableNETFX</i><br/>
(OPTIONAL) - Switch parameter that will run the 'OSBuilder' command 'New-OSBuildTask' and append the 'TaskName', 'BuildName', 'EnableNetFX3' parameters to it.<br/>

<b>PARAMETER -</b> <i>BuildVer</i><br/>
(OPTIONAL) - Microsoft Windows 10 Build Number (1511, 1607, 1703, 1709, 1803, or 1809) - Default is '1803'<br/>

<b>PARAMETER -</b> <i>Customize</i><br/>
(OPTIONAL) - Switch parameter that will run the 'OSBuilder' command 'New-OSBuildTask' and append the 'TaskName', 'BuildName', 'RemoveAppxProvisionedPackage', 'EnableWindowsOptionalFeature', 'DisableWindowsOptionalFeature', 'RemoveWindowsPackage', and 'RemoveWindowsCapability' parameters to it.<br/>

<b>PARAMETER -</b> <i>CustomizeFX</i><br/>
(OPTIONAL) - Switch parameter that will run the 'OSBuilder' command 'New-OSBuildTask' and append the 'TaskName', 'BuildName', 'RemoveAppxProvisionedPackage', 'EnableWindowsOptionalFeature', 'DisableWindowsOptionalFeature', 'RemoveWindowsPackage', 'RemoveWindowsCapability', and 'EnableNetFX3' parameters to it.<br/>

<b>PARAMETER -</b> <i>SiteCode</i><br/>
(OPTIONAL) - Specifies the Configuration Manager Site Code<br/>

<b>PARAMETER -</b> <i>OSArch</i><br/>
(OPTIONAL) - Specifies the processor architecture of the OS Media you are building. Default is 'x64'<br/>

<b>PARAMETER -</b> <i>ImageBuildName</i><br/>
(OPTIONAL) - Specifies the Build Name of the OS Media you are building. Default is 'Win10-x64-1803'<br/>

<b>PARAMETER -</b> <i>SaveNewISO</i><br/>
(OPTIONAL) - Switch parameter, specifies to save the new ISO to a specific folder through dialog.<br/><br/>

----------------------------------------------------
<br/>

<b>EXAMPLE 1</b><br/>
Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation without NetFX3, names the build "Company-Win10Ent-1803"<br/>
<i>.\Run-OSBuilder.ps1 -Customize -BuildVer 1803 -OSArch x64 -ImageBuildName Company-Win10Ent-1803</i><br/><br/>

<b>EXAMPLE 2</b><br/>
Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation with NetFX3.<br/>
<i>.\Run-OSBuilder.ps1 -CustomizeFX -BuildVer 1803 -OSArch x64</i><br/><br/>

<b>EXAMPLE 3</b><br/>
Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, enables NetFX3, opens the save custom ISO dialog.<br/>
<i>.\Run-OSBuilder.ps1 -EnableNETFX -BuildVer 1803 -OSArch x64 -SaveNewISO</i><br/><br/>

<b>EXAMPLE 4</b><br/>
Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation with NetFX3. (Same as EXAMPLE 2)<br/>
<i>.\Run-OSBuilder.ps1 -Customize -EnableNETFX -BuildVer 1803 -OSArch x64</i><br/><br/>

<b>EXAMPLE 5</b><br/>
Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation without NetFX3, names the build "Company-Win10Ent-1803", sets SCCM Site Code to "LAB"<br/>
<i>.\Run-OSBuilder.ps1 -Customize -BuildVer 1803 -OSArch x64 -ImageBuildName Company-Win10Ent-1803 -SiteCode LAB</i><br/><br/>

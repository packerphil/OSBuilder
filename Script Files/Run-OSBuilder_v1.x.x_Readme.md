Scripts are created for use with the OSBuilder Module.<br/><br/>
<b>DESCRIPTION:</b><br/>
Wrapper script used to run OSBuilder module v10.10.26.0 (from David Segura) commands to<br/>
build Windows 10 installation media that is patched and has only the apps and features desired.<br/><br/>
<b><i>NOTE:</b> Only works with Windows 10 Enterprise at this time.</i><br/>
<br/>
<b>EXAMPLE 1 -</b> Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation without NetFX3, names the build and the resulting ISO "Company-Win10Ent-1803"<br/>
<i>.\Run-OSBuilder_v1.0.3.ps1 -Customize -BuildVer 1803 -OSArch x64 -ImageBuildName Company-Win10Ent-1803</i><br/><br/>

<b>EXAMPLE 2 -</b> Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation with NetFX3.<br/>
<i>.\Run-OSBuilder_v1.0.3.ps1 -CustomizeFX -BuildVer 1803 -OSArch x64</i><br/><br/>

<b>EXAMPLE 3 -</b> Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, enables NetFX3.<br/>
<i>.\Run-OSBuilder_v1.0.3.ps1 -EnableNETFX -BuildVer 1803 -OSArch x64</i><br/><br/>

<b>EXAMPLE 4 -</b> Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation with NetFX3. (Same as EXAMPLE 2)<br/>
<i>.\Run-OSBuilder_v1.0.3.ps1 -Customize -EnableNETFX -BuildVer 1803 -OSArch x64</i><br/><br/>

<b>EXAMPLE 5 -</b> Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation without NetFX3, names the build "Company-Win10Ent-1803", sets SCCM Site Code to "LAB"<br/>
<i>.\Run-OSBuilder.ps1 -Customize -BuildVer 1803 -OSArch x64 -ImageBuildName Company-Win10Ent-1803 -SiteCode LAB<br/><br/>

﻿<# 
<#
    .SYNOPSIS
        Running VMware OS Optimization Tool with default template
	.DESCRIPTION
      	search for existing VMwareOSOptimizationTool*.exe on system and use this one with default OS template
    .EXAMPLE
    .NOTES
		Author: Matthias Schlimm
      	Company: Login Consultants Germany GmbH
		
		History:
      	23.11.2016 MS: Script created
		Last Chnage: 06.12.2016 MS: Created folder if not exist -> $vmOSOTtemplatePath
		24.01.2017 MS: For faster search replaced $SearchFolders = @("C:") with $SearchFolders = @("C:\Program Files","C:\Program Files (x86)","C:\Windows\system32")
		28.01.2017 MS: Changed notice from CLI to ADMX
		06.03.2017 MS: Bugfix read Variable $varCLI = ...
		01.08.2017 MS: using custom searchfolder from ADMX if enabled
		01.08.2017 MS: specify OS template in ADMX
		04.08.2017 MS: Bugfix IF (!("$LIC_BISF_CLI_OT_Templ" -eq "") )
		07.11.2017 MS: enable 3rd Party Optimizations, if vmOSOT is executed, this disabled BIS-F own optimizations
	.LINK
        https://eucweb.com
#>


Begin {
	$PSScriptFullName = $MyInvocation.MyCommand.Path 
	$PSScriptRoot = Split-Path -Parent $PSScriptFullName 
	$PSScriptName = [System.IO.Path]::GetFileName($PSScriptFullName)
	IF ($LIC_BISF_CLI_OT_SF -eq "1") 
	{
		$SearchFolders = $LIC_BISF_CLI_OT_SF_CUS
	} ELSE {
		$SearchFolders = @("C:\Program Files","C:\Program Files (x86)","C:\Windows\system32")
	}
	
	IF (!($LIC_BISF_CLI_OT_Templ -eq "") )
	{
		$vmTemplateFullPath = "$($LIC_BISF_CLI_OT_Templ)"
	} ELSE {
		$vmTemplateFullPath = ""
	}
	
	$AppName = "VMware OS Optimization Tool (vmOSOT)"
	$vmOSOTtemplatePath = "C:\ProgramData\VMware\OSOT\VMware Templates" 
    $found = $false
    $tmpCMD = "C:\Windows\temp\vmOSOT.cmd"
}


Process {
    $varCLI = $LIC_BISF_CLI_OT
	IF (!($varCLI -eq "NO"))
	{
		Write-BISFLog -Msg "Searching for $AppName on local System" -ShowConsole -Color Cyan
		Write-BISFLog -Msg "This can run a long time based on the size of your root drive, you can skip this in the ADMX configuration (3rd Party Tools)" -ShowConsole -Color DarkCyan
		ForEach ($SearchFolder in $SearchFolders)
		{
			If ($found -eq $false)
			{
				Write-BISFLog -Msg "Looking in $SearchFolder"
				$FileExists = Get-ChildItem -Path "$SearchFolder" -filter "VMwareOSOptimizationTool*.exe" -Recurse -ErrorAction SilentlyContinue | % {$_.FullName}
		        
				IF (($FileExists -ne $null) -and ($found -ne $true))
				{ 
		 
					Write-BISFLog -Msg "Product $($AppName) installed" -ShowConsole -Color Cyan
					$found = $true
				
					Write-BISFLog -Msg "Check Silentswitch..."
				
					IF (($varCLI -eq "YES") -or ($varCLI -eq "NO")) 
					{
						Write-BISFLog -Msg "Silentswitch would be set to $varCLI"
					} ELSE {
           				Write-BISFLog -Msg "Silentswitch not defined, show MessageBox"
						$VMOptTool = Show-BISFMessageBox -Msg "Would you like to to run the $AppName ($FileExists) with the default template for the running OS? " -Title "$AppName" -YesNo -Question
        				Write-BISFLog -Msg "$VMOptTool would be choosen [YES = Optimize System with $AppName] [NO = No optimization by $AppName]"
					}
        
					If (($VMOptTool -eq "YES" ) -or ($varCLI -eq "YES"))
					{
						Write-BISFLog -Msg "Running $AppName... please Wait"
						Write-BISFLog -Msg "Create temporary CMD-File ($tmpCMD) to run $AppName from them" 
						"""$FileExists"" -r $LogFilePath" | out-file $tmpCMD -Encoding default
						IF (!($vmTemplateFullPath -eq "")) 
						{
							"""$FileExists"" -o -t ""$($vmTemplateFullPath)"" -v > C:\Windows\Logs\VMwOsOptTool.log" | out-file $tmpCMD -Encoding default -Append
						} ELSE {
							"""$FileExists"" -o  -v > C:\Windows\Logs\VMwOsOptTool.log" | out-file $tmpCMD -Encoding default -Append
						}
						
						
						if (!(Test-Path -Path $vmOSOTtemplatePath)) {
                            Write-BISFLog -Msg "Create Directory $vmOSOTtemplatePath"
                            New-Item -Path $vmOSOTtemplatePath -ItemType Directory -Force
                        }   
                        $Global:LIC_BISF_3RD_OPT = $true # BIS-F own optimization will be disabled, if 3rd Party Optimization is true
						Invoke-Expression -Command $tmpCMD | Out-Null
						Get-BISFLogContent -GetLogFile "C:\Windows\Logs\VMwOsOptTool.log"
						Remove-Item $tmpCMD -Force
						Write-BISFLog -Msg "The HTML-Report can be found on $LogFilePath" -ShowConsole -Color DarkCyan -SubMsg
					} ELSE {
						Write-BISFLog -Msg "No optimization by $AppName"
					}
				}	
			} 		
		}   
	} ELSE {
		Write-BISFLog -Msg "Skip searching and running $AppName"
	}   
}

End {
	If ($found -eq $false) {Write-BISFLog -Msg "Product $($AppName) NOT installed"}
	Add-BISFFinishLine
}



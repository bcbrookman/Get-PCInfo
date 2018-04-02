<#
.SYNOPSIS
    Used to gather workstation details from local and remote workstations. 
    Accepts Hostname, IP, or a CSV list as input. Can also be used with cmdlets such as Out-Gridview or Export-Csv to process output.

.DESCRIPTION
    Gathers and formats workstation details acquired primarily through Windows Management Instrumentation (WMI).
    
    Compatible with Powershell 3.0 or higher.
        
    Provides the following workstation information:
    - System Hostname
    - System Model Number
    - Last logged on account
    - Full Name of Last logged on account
    - Amount of Physical Memory
    - Operating System Bit-level
    - System Serial Number

.EXAMPLE
    Get-PCInfo
    
    Input      : localhost
    Hostname   : TT-WS1716
    Model      : HP EliteDesk G1 SFF
    RAM        : 8GB
    OS-Bitness : 64-bit
    Serial     : SFF7D9A56B2
    Error      : none

.EXAMPLE
    Get-PCinfo RemoteHost.example.com | Format-list *

    Input      : localhost
    Hostname   : TT-WS1716
    Model      : HP EliteDesk G1 SFF
    Last-Acct  : BKENOBI
    Last-User  : Ben Kenobi
    RAM        : 8GB
    OS-Bitness : 64-bit
    Serial     : SFF7D9A56B2
    Error      : none

.EXAMPLE
    Get-PCInfo -list ~\pcinfo-list.csv | Format-Table 'Hostname','Model','Serial','Error'

    Input               Hostname   Model                RAM   Serial       Error
    -----               --------   -----                ---   ------       -----
    localhost           TT-WS1716  HP EliteDesk G1 SFF  8GB   SFF7D9A56B2  none
    192.168.1.102       AD-WS2544  HP EliteDesk G1 SFF  4GB   SFF127A4C24  none
    yavin4.example.com  Y4-SV5433  HP Proliant G7 RFF   32GB  RFF9C0FE892  none
        
.EXAMPLE
    Get-PCInfo -list ./workstation-list.csv | Export-csv ./output-pcinfo.csv
    PS C:\>  

.NOTES
    Date: October 2016
    Version: 1.1
    Author: Brian C. Brookman
    Website: bcbrookman.com
    Copyright Brian C. Brookman 2016
#>

Function Get-PCInfo( $pc="localhost", $list=$null) {
  $ErrorActionPreference=’Stop’
  
  #Setup the properties that will be selected in the default output object
  $defaultProperties = @('Input','Hostname','Model','RAM','OS-Bitness','Serial','Error')
  $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties)
  $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

  #Codeblock which collects PC info and stores them in variables
  $GetInfo = {
    $cs = Get-WMIObject -class win32_ComputerSystem -computer $pc       
    $os = Get-WMIObject -class win32_OperatingSystem -computer $pc
    $RAM = Get-WMIObject -class Win32_PhysicalMemory -computer $pc | Measure-Object -Property Capacity -Sum
    $bios = Get-WMIObject -class win32_bios -computer $pc

    $lastlogon = Get-WMIObject -class win32_UserProfile -computer $pc | Sort-Object -Property LastUseTime -Descending | Select-Object -First 1
    $UserSID = New-Object System.Security.Principal.SecurityIdentifier($lastlogon.SID)
    $lastuser = $UserSID.Translate([System.Security.Principal.NTAccount]).value.split('\')
    $domain = $lastuser[0]
    $user = $lastuser[1]
    $lastusername = ([adsi]"WinNT://$domain/$user,user").FullName
    if ($lastusername) { $lastusername = $lastusername.ToString().Trim('{','}') }
  }

  #Codeblock which creates and calls output object
  $Output = {
    $outputobject = [pscustomobject]@{
      'Input' = "$pc" 
      'Hostname' = $cs.Name
      'Model' = $cs.Model
      'Last-Acct' = $lastuser[1]
      'Last-User' = $lastusername
      'RAM' = ([math]::Round($RAM.Sum/1GB)).ToString() + 'GB'
      'OS-Bitness' = $os.OSArchitecture
      'Serial' = $bios.SerialNumber
      'Error' = "none"
    }

    #Add previously defined properties used in default object ouput
    $Outputobject | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
    #Define a typename that can be used with a format.ps1xml file to override default formatting
    $Outputobject.PSObject.TypeNames.Insert(0,'Custom.PCInfo')
   
    $outputobject
  }

  #Codeblock which creates and calls output object for when exception occurs
  $ErrorOutput = {
    $ErrorObject = [pscustomobject]@{
      'Input' = "$pc" 
      'Hostname' = "---"
      'Model' = "---"
      'Last-Acct' = "---"
      'Last-User' = "---"
      'RAM' = "---"
      'OS-Bitness' = "---"
      'Serial' = "---"
      #Set Error property to the exception encountered, the current item in the pipeline.
      'Error' = $_
    }

    #Add previously defined properties used in default object ouput
    $ErrorObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers

    #Define a typename that can be used with a format.ps1xml file to override default formatting
    $ErrorObject.PSObject.TypeNames.Insert(0,'Custom.PCInfo')
    
    $ErrorObject
  }

  If (!$list) {
    . $GetInfo
    & $Output
  } elseif ($list) {
    Get-Content $list | Foreach-Object {
      $pc = $_
      Try {
        . $GetInfo
        . $Output
      } Catch {
        #If any exception occurs, stop processing and record no data for the current PC.
        #Assume that if an exception occurs for one GWMI cmdlet in $GetInfo, the same exception will occur
        #to all GWMI cmdlets in the $GetInfo codeblock.
        . $ErrorOutput
      }
    }
  }
}
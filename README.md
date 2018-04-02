# Get-PCInfo
Get-PCInfo is compatible with PowerShell 3.0 or higher. It accepts a hostname, IP, or CSV list as input and gathers information using primarily WMI (which means it may require elevated access). It then outputs a PowerShell object that can be piped to cmdlets such as Out-Gridview or Export-Csv.

Currently, it provides the following information:

* System Hostname (locally configured hostname)
* System Model Number
* Last logged on account
* Full name of Last logged on account (via domain lookup)
* Amount of Physical Memory
* Operating System Bit-level
* System Serial Number

##Examples
###Local workstation with Format-List
```
PS C:\> Get-PCInfo | format-list 'Hostname','Model','Serial','RAM','OS-Bitness'

Hostname   : TT-WS1716
Model      : HP EliteDesk G1 SFF
Serial     : SFF7D9A56B2
RAM        : 8GB
OS-Bitness : 64-bit
```

###Workstation list with Format-Table
```
PS C:\> Get-PCInfo -list ~\pcinfo-list.csv | Format-Table *

Input               Hostname   Model                Last-Acct  Last-User    RAM   OS-Bitness  Serial       Error
-----               --------   -----                ---------  ---------    ---   ----------  ------       -----
localhost           TT-WS1716  HP EliteDesk G1 SFF  BKENOBI    Ben Kenobi   8GB   64-bit      SFF7D9A56B2
192.168.1.102       AD-WS2544  HP EliteDesk G1 SFF  LORGANA    Leia Organa  4GB   32-bit      SFF127A4C24
deathstar           ---        ---                  ---        ---          ---   ---         ---          The RPC server is unavailable. (Exception from HRESULT: 0x800706BA)
yavin4.example.com  Y4-SV5433  HP Proliant G7 RFF   HSOLO      Han Solo     32GB  64-bit      RFF9C0FE892
```

###Workstation list with Export-Csv
```
PS C:\> Get-PCInfo -list ~\pcinfo-list.csv | Export-Csv ~\pcinfo-export.csv
PS C:\>
```

More Examples can also be found in the get-help documentation included in the function as well.

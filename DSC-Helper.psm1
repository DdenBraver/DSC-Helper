Function Get-ConfigurationData
{
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Nodename,

        [string]$PullserverDNS,

        [System.Management.Automation.PSCredential]$LocalAdministrator
    )
    
    <#
            .SYNOPSIS
            Generate Configuration
            .DESCRIPTION
            Generates a configuration data based on a template defined in the function
            .EXAMPLE
            $Configurationdata = Get-ConfigurationData
    #>

    if ($PullserverDNS)
    {
        $Pullserverurl = "https://$($PullserverDNS):8080/PSDSCPullServer.svc"
    }

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                    = $Nodename
                PSDscAllowPlainTextPassword = $true
                PSDscAllowDomainUser        = $true
                ConfigurationID             = [guid]::NewGuid()
                Pullserverurl               = $Pullserverurl
                LocalAdministrator          = $LocalAdministrator
            }
        )
    }
    $ConfigurationData
}
Function Show-Dropdownbox 
{
    <#
            .SYNOPSIS
            Gives a pop-up to select data, that can be used in other scripts
            .DESCRIPTION
            The Show-Dropdownbox function is used to provide a friendly way for users to input data into script variables.
            This script is for example used during the postbuild script, so that information can be injected in a friendly way.
            .PARAMETER Question
            The question you want to have displayed on screen.
            .PARAMETER Answers
            The answers you would like the users to have as options. (Static list)
            .EXAMPLE
            $variable1 = Show-Dropdownbox -question "Select one of the following:" -answers "A","B","C"
            Create a question and write the output to variable $variable1
            .NOTES
            This function was created for friendly input into scripts that are performed manually.
            Do not use this function in scripts that should run in the background.
            This script was written by Danny den Braver @2013, for questions please contact danny@denbraver.com
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Question,
        [Parameter(Mandatory = $true)]
        [array]$Answers
    )

    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') 

    $objForm = New-Object -TypeName System.Windows.Forms.Form 
    $objForm.Text = 'Take your selection'
    $objForm.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (300, 275) 
    $objForm.StartPosition = 'CenterScreen'
    $objForm.KeyPreview = $true
    $objForm.Add_KeyDown({
            if ($_.KeyCode -eq 'Enter') 
            {
                $objForm.Close()
            }
    })
    $objForm.Add_KeyDown({
            if ($_.KeyCode -eq 'Escape') 
            {
                $objForm.Close()
            }
    })
    
    $OKButton = New-Object -TypeName System.Windows.Forms.Button
    $OKButton.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (75, 200)
    $OKButton.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75, 23)
    $OKButton.Text = 'OK'
    $OKButton.Add_Click({
            $objForm.Close()
    })
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object -TypeName System.Windows.Forms.Button
    $CancelButton.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (150, 200)
    $CancelButton.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75, 23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.Add_Click({
            $objForm.Close()
    })
    $objForm.Controls.Add($CancelButton)

    $objLabel = New-Object -TypeName System.Windows.Forms.Label
    $objLabel.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 20) 
    $objLabel.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (280, 20) 
    $objLabel.Text = $Question
    $objForm.Controls.Add($objLabel) 

    $objListBox = New-Object -TypeName System.Windows.Forms.ListBox 
    $objListBox.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 40) 
    $objListBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (275, 20) 
    $objListBox.Height = 150
    foreach ($answer in $Answers) 
    {
        [void]$objListBox.Items.Add($answer)
    }

    $objListBox.SelectedItem = $objListBox.Items[0]
    $objForm.Controls.Add($objListBox) 
    $objForm.Topmost = $true
    $objForm.Add_Shown({
            $objForm.Activate()
    })
    [void]$objForm.ShowDialog()

    $objListBox.SelectedItem
}
Function Push-DSCRoleConfiguration
{
    <#
            .SYNOPSIS
            Pushes a DSC Role Configuration to a server.
            .DESCRIPTION
            The Push-DSCRoleConfiguration function will copy over your local modules over to the target server, and will push the selected DSC Role over to this server.
            .PARAMETER Nodename
            The server you want to configure
            .PARAMETER LocalAdministrator
            The local administrator account of the server
            .PARAMETER PullserverDNS
            The Pull Server DNS (currently not in use! Future feature)
            .PARAMETER skipmodules
            Boolean: Skips the copy modules step
            .EXAMPLE
            Push-DSCRoleConfiguration -Nodename Server1
            .NOTES
            This function was created to help people get started with DSC. It uses composite resources in the module to push a "Role" to a server using Desired State Configuration.
            Once the role is selected and the parameters are filled, it will send over the configuration and make it happen.
    #>

    Param(
        [Parameter(Mandatory = $true)]
        [string]$Nodename,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $LocalAdministrator,
        
        [string]$PullserverDNS,

        [switch]$skipmodules
    )

    Set-item wsman:localhost\client\trustedhosts -value * -Force

    $dnsresolve = (Resolve-DnsName -Name $Nodename -ErrorAction SilentlyContinue) -eq $null
    if ($dnsresolve)
    {
        Write-Warning -Message "$($Nodename): Server was NOT found using DNS, please provide an IP address!" -Verbose
        Add-Host -Hostname $Nodename -Verbose

    }
    else
    {
        Write-Verbose -Message "$($Nodename): Server was found using DNS" -Verbose
    }

    if (!$PullserverDNS -and !$skipmodules)
    {
        Write-Verbose -Message "$($Nodename): Enabling File and Printer Sharing" -Verbose
        Invoke-Command -ComputerName $Nodename -Credential $LocalAdministrator -ScriptBlock {
            Enable-NetFirewallRule -Name 'FPS-SMB-In-TCP'
        }
        
        Write-Verbose -Message "$($Nodename): Copying DSC Modules" -verbose
        $null = net.exe use "\\$Nodename\C$\Program Files\WindowsPowerShell\Modules" $LocalAdministrator.GetNetworkCredential().password /User:$($LocalAdministrator.username)
        $null = Get-ChildItem 'C:\Program Files\WindowsPowerShell\Modules' | Where-Object {$_.name -ne 'PackageManagement' -and $_.name -ne 'PowerShellGet'} | copy-item -Destination "\\$Nodename\C$\Program Files\WindowsPowerShell\Modules" -Force -Recurse
        $null = net.exe use "\\$Nodename\C$\Program Files\WindowsPowerShell\Modules" /delete

        $configdata = Get-ConfigurationData -Nodename $Nodename -LocalAdministrator $LocalAdministrator
    }
    else
    {
        $configdata = Get-ConfigurationData -Nodename $Nodename -PullserverDNS $PullserverDNS -LocalAdministrator $LocalAdministrator
    }

    $DSCHelperResources = Get-DscResource -Module DSC-Helper

    $LCMOption = ($DSCHelperResources | Where-Object -FilterScript {
            $_.Name -like '*PUSH*' -and $_.Name -notlike '*secure*'
    }).Name
    $LCMOption = $LCMOption.SubString(3)
    $LCMSelection = Show-Dropdownbox -Question 'Please select your Configuration Option:' -Answers $LCMOption
    $LCMSelection = 'DSC' + $LCMSelection
    
    $DSCRoles = ($DSCHelperResources | Where-Object -FilterScript {
            $_.Name -like '*ROLE*'
    }).Name
    $DSCRoles = $DSCRoles.SubString(7)
    $RoleSelection = Show-Dropdownbox -Question 'Please select your Role:' -Answers $DSCRoles
    $RoleSelection = 'DSCRole' + $RoleSelection

    & $LCMSelection -ConfigurationData $configdata -OutputPath 'c:\dsc\staging'
    & $RoleSelection -ConfigurationData $configdata -OutputPath 'c:\dsc\staging'

    Set-DscLocalConfigurationManager -Path C:\dsc\staging -ComputerName $Nodename -Credential $LocalAdministrator -Verbose
    Start-DscConfiguration -Path c:\dsc\staging -ComputerName $Nodename -Credential $LocalAdministrator -Force -Verbose -Wait

    if (!$ping)
    {
        Write-Verbose -Message "$($Nodename): Cleaning up hosts file" -Verbose
        Remove-Host -Hostname $Nodename -Verbose
    }
}
function Send-File
{
    ##############################################################################
    ##
    ## Send-File
    ##
    ## From Windows PowerShell Cookbook (O'Reilly)
    ## by Lee Holmes (http://www.leeholmes.com/guide)
    ##
    ##############################################################################

    <#

            .SYNOPSIS

            Sends a file to a remote session.

            .EXAMPLE

            PS >$session = New-PsSession leeholmes1c23
            PS >Send-File c:\temp\test.exe c:\temp\test.exe $session

    #>

    param(
        ## The path on the local computer
        [Parameter(Mandatory = $true)]
        $Source,

        ## The target path on the remote computer
        [Parameter(Mandatory = $true)]
        $Destination,

        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )

    Set-StrictMode -Version Latest

    ## Get the source file, and then get its content
    $sourcePath = (Resolve-Path $Source).Path
    $sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
    $streamChunks = @()

    ## Now break it into chunks to stream
    Write-Progress -Activity "Sending $Source" -Status 'Preparing file'
    $streamSize = 1MB
    for($position = 0; $position -lt $sourceBytes.Length;
    $position += $streamSize)
    {
        $remaining = $sourceBytes.Length - $position
        $remaining = [Math]::Min($remaining, $streamSize)

        $nextChunk = New-Object -TypeName byte[] -ArgumentList $remaining
        [Array]::Copy($sourceBytes, $position, $nextChunk, 0, $remaining)
        $streamChunks += ,$nextChunk
    }

    $remoteScript = {
        param($Destination, $length)

        ## Convert the destination path to a full filesytem path (to support
        ## relative paths)
        $Destination = $executionContext.SessionState.`
        Path.GetUnresolvedProviderPathFromPSPath($Destination)

        ## Create a new array to hold the file content
        $destBytes = New-Object -TypeName byte[] -ArgumentList $length
        $position = 0

        ## Go through the input, and fill in the new array of file content
        foreach($chunk in $input)
        {
            Write-Progress -Activity "Writing $Destination" `
            -Status 'Sending file' `
            -PercentComplete ($position / $length * 100)

            [GC]::Collect()
            [Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
            $position += $chunk.Length
        }

        ## Write the content to the new file
        [IO.File]::WriteAllBytes($Destination, $destBytes)

        ## Show the result
        Get-Item $Destination
        [GC]::Collect()
    }

    ## Stream the chunks into the remote script
    $streamChunks | Invoke-Command -Session $Session $remoteScript -ArgumentList $Destination, $sourceBytes.Length
}
Function Trace-Reboot
{
    <#
            .SYNOPSIS
            Display progress bars untill a server is online again
            .DESCRIPTION
            This function will check if a server is reachable by ping
            During the waiting duration, displaybars will be shown to show the progress
            .PARAMETER Computername
            The node name of the System
            .EXAMPLE
            Trace-Trace-Reboot -$Computername "Computername"
            Wait for a System to be fully available again
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    
    param(
        [parameter(Mandatory = $true)]
        $Computername
    )

    $sleepseconds = 3

    # Creating progress bar
    Write-Progress -Id 1 -Activity "Waiting for Computer $Computername"

    # Create a new instance of ping
    $ping = New-Object -TypeName System.Net.Networkinformation.Ping
    $currenttime = Get-Date -Format HH:mm:ss

    # Wait untill the Server is no longer Reachable
    Write-Verbose -Message "$($Computername): Testing Connectivity"

    $i = 0
    Do 
    { 
        $i = $i+5     
        Start-Sleep -Seconds $sleepseconds
        $result = $ping.send($Computername)
        Write-Progress -ParentId  1 -Activity "$currenttime | $Computername is still reachable on ICMP level" -PercentComplete $i
        if ($i -gt 94)
        {
            $i = 0
        }
    }
    Until($result.status -ne 'Success')

    Write-Progress -Id 1 -Activity "Waiting for Computer $Computername" -PercentComplete 50
    $i = 0
    $currenttime = Get-Date -Format HH:mm:ss

    # Wait untill the Server comes back online for PING.
    Write-Verbose -Message "$($Computername): Waiting for computer to be available again"

    Do 
    {
        $i = $i+5
        Start-Sleep -Seconds $sleepseconds
        $result = $ping.send($Computername)
        Write-Progress -ParentId  1 -Activity "$currenttime | $Computername is not reachable on ICMP level" -PercentComplete $i
        if ($i -gt 94)
        {
            $i = 0
        }
    }
    Until ($result.status -eq 'Success')
    Write-Progress -Id 1 -Activity "Waiting for Computer $Computername" -Completed
    $i = 0
    $currenttime = Get-Date -Format HH:mm:ss

    Write-Verbose -Message "$($Computername): Reboot has completed succesfully"
}
function Install-RemoteMSI
{
    <#
            .SYNOPSIS
            Install a MSI on a Remote Server
            .DESCRIPTION
            This function will attempt to install a remote MSI on a server
            .PARAMETER Computername
            The node name of the System
            .PARAMETER Credentials
            The credentials that have administrator permissions on the server
            .PARAMETER SourceDirectory
            The directory containing the MSI's you want to install
            .PARAMETER DestinationDirectory
            The directory the files will be temporary placed
            .EXAMPLE
            Install-RemoteMSI -Computername Server1 -sourcedirectory 'C:\Temp\MSIs' -destinationdirectory 'c:\Temp'
    #>

    param (
        [Parameter(Mandatory = $true)]
        [String]$ComputerName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter(Mandatory = $true)]
        [String]$SourceDirectory,

        [Parameter(Mandatory = $true)]
        [String]$DestinationDirectory
    )

    $Files = (Get-ChildItem $SourceDirectory | Where-Object -FilterScript {
            $_.Attributes -ne 'Directory'
    }).Name

    # Start new session
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credentials

    # Create directory at destination node
    Invoke-Command -Session $Session -ArgumentList $DestinationDirectory, $ComputerName -ScriptBlock {
        param (
        $DestinationDirectory,
        $ComputerName
        )
        if (!(Test-Path -Path $($DestinationDirectory)))
        {
            Write-Verbose -Message "$($ComputerName): Creating directory $DestinationDirectory" -Verbose
            $null = New-Item -ItemType Directory -Path $($DestinationDirectory)
        }
    }

    # Send Files to destination node
    $Files | ForEach-Object -Process {
        do 
        {
            $i = 1
            $error.clear()
            try
            {
                Write-Verbose -Message "$($ComputerName): Attempting to send $_ (attempt $i)" -Verbose
                $null = send-file "$SourceDirectory\$_" "$DestinationDirectory\$_" $Session
                $i++
            }
            catch
            {
                throw "Given file $_ is not copied to destination $DestinationDirectory"
                return $error[0]
            }
        }
        until (!$error -or $i -eq 3)
    }

    # Install MSU's at the destination server
    Invoke-Command -Session $Session  -ArgumentList $DestinationDirectory, $ComputerName -ScriptBlock { 
        param (
            [string]$DestinationDirectory, 
            [string]$ComputerName
        )

        $File = Get-ChildItem -Path $($DestinationDirectory) | Where-Object -FilterScript {
            $_.name -match 'msu'
        }                
        $Setup = "$($($File.name).split('.')[0]).cab"
        Write-Verbose -Message "$($ComputerName): Unpacking WMF5 to $DestinationDirectory" -Verbose
        $null = wusa.exe  "$($DestinationDirectory)\${File}" /extract:$($DestinationDirectory)   
        Write-Verbose -Message "$($ComputerName): Installing WMF5 from $($DestinationDirectory)\${Setup}" -Verbose     
        $null = Dism.exe /online /add-package /PackagePath:"$($DestinationDirectory)\${Setup}" /NoRestart
    }

    # Cleanup after install
    Invoke-Command -Session $Session -ArgumentList $ComputerName, $DestinationDirectory -ScriptBlock {
        param (
        $ComputerName,
        $DestinationDirectory
        )
        if (Test-Path -Path $DestinationDirectory)
        {
            Write-Verbose -Message "$($ComputerName): Cleaning up directory $DestinationDirectory" -Verbose
            $null = Remove-Item -Recurse -Path $DestinationDirectory -Force
        }
    }

    # Remove session
    Remove-PSSession -Session $Session
}
function Install-RemoteCertificate
{
    <#
            .SYNOPSIS
            Install a PFX Certificate on a Remote Server
            .DESCRIPTION
            This function will attempt to install a PFX Certificate on a remote server
            .PARAMETER Computername
            The node name of the System
            .PARAMETER Credentials
            The credentials that have administrator permissions on the server
            .PARAMETER SourceDirectory
            The file containing the PFX you want to install
            .PARAMETER DestinationDirectory
            The destination the PFX will be temporary placed
            .PARAMETER PFXPassword
            The password required for the PFX Certificate
            .EXAMPLE
            Install-RemoteMSI -Computername Server1 -sourcedirectory 'C:\Temp\Certificate.pfx' -destinationdirectory 'c:\Temp\certificate.pfx'
    #>

    param(
    [Parameter(Mandatory = $true)]
    [String]$Computername,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]
    $Credentials,

    [Parameter(Mandatory = $true)]
    [String]$Source,

    [Parameter(Mandatory = $true)]
    [String]$Destination,

    [Parameter(Mandatory = $true)]
    [System.Security.SecureString]
    $PFXPassword
    )

    # Start new session
    $Session = New-PSSession -ComputerName $Computername -Credential $Credentials

    # Create directory at destination node
    Invoke-Command -Session $Session -ArgumentList $Destination, $ComputerName -ScriptBlock {
        param (
        $Destination,
        $ComputerName
        )

        $directory = $destination.Trim(($Destination.Split('\') |  Select-Object -last 1))

        if (!(Test-Path -Path $($directory)))
        {
            Write-Verbose -Message "$($ComputerName): Creating directory $directory" -Verbose
            $null = New-Item -ItemType Directory -Path $($directory)
        }
    }

    # Copy Certificate
    Write-Verbose -Message "$($ComputerName): Attempting to send $Source" -Verbose
    $null = send-file "$Source" "$Destination" $Session

    # install certificate 
    Invoke-Command -Session $Session -ArgumentList $Destination, $PFXPassword, $Computername -ScriptBlock { 
        param (
        $Destination,
        $PFXPassword,
        $Computername
        )

        Write-Verbose -Message "$($Computername): Installing certificate from $Destination" -Verbose  
        $null = Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $Destination -Password $PFXPassword
    }

    # Cleanup after install
    Invoke-Command -Session $Session -ArgumentList $ComputerName, $Destination -ScriptBlock {
        param (
        $ComputerName,
        $Destination
        )

        $directory = $destination.Trim(($Destination.Split('\') |  Select-Object -last 1))

        if (Test-Path -Path $directory)
        {
            Write-Verbose -Message "$($ComputerName): Cleaning up directory $directory" -Verbose
            $null = Remove-Item -Recurse -Path $directory -Force
        }
    }

    # Remove session
    Remove-PSSession -Session $Session
}
function Remove-Host
{
    <#
            .SYNOPSIS
            Remove an entry from the windows hosts file.
            .DESCRIPTION
            Remove an entry from the windows hosts file at c:\windows\system32\drivers\etc\hosts
            .PARAMETER hostsfile
            The file you wish to manipulate (Default: c:\windows\system32\drivers\etc\hosts)
            .PARAMETER Hostname
            The DNS name of the host/server you wish to remove
            .EXAMPLE
            Remove-Host -Hostname Server1
    #>

     param
     (
         [Parameter(Mandatory = $false)]
         [string]$hostsfile = 'C:\Windows\System32\drivers\etc\hosts',

         [Parameter(Mandatory = $true)]
         [string]$Hostname
     )
 
    $content = Get-Content $hostsfile 
    $newLines = @() 
    foreach ($line in $content) 
    { 
        $bits = [regex]::Split($line, '\t+') 
        if ($bits.count -eq 2) 
        { 
            if ($bits[1] -ne $Hostname) 
            {
                $newLines += $line
            } 
        } 
        else 
        {
            $newLines += $line
        } 
    } 

    Clear-Content $hostsfile 
    foreach ($line in $newLines) 
    {
        $line | Out-File -Encoding ASCII -Append $hostsfile
    } 

    Write-Verbose -Message "$($Hostname): Entry has been removed from the local hosts file on $env:COMPUTERNAME"
} 
function Add-Host
{
    <#
            .SYNOPSIS
            Add an entry from the windows hosts file.
            .DESCRIPTION
            Remove an entry from the windows hosts file at c:\windows\system32\drivers\etc\hosts
            .PARAMETER hostsfile
            The file you wish to manipulate (Default: c:\windows\system32\drivers\etc\hosts)
            .PARAMETER IPAddress
            The IP address of the host/server you wish to add           
            .PARAMETER Hostname
            The DNS name of the host/server you wish to add
            .EXAMPLE
            Remove-Host -Hostname Server1
    #>

     param
     (
         [Parameter(Mandatory = $false)]
         [string]$hostsfile = 'C:\Windows\System32\drivers\etc\hosts',

         [Parameter(Mandatory = $true)]
         [string]$IPAddress,

         [Parameter(Mandatory = $true)]
         [string]$Hostname
     )
           
    $IPAddress + "`t`t" + $Hostname | Out-File -Encoding ASCII -Append $hostsfile
    Write-Verbose -Message "$($Hostname): IP address $IPAddress has been added to the hosts file on $env:COMPUTERNAME"
} 
configuration DSCDomainControllers
{
    [CmdletBinding()] 

    param( 
        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Destination Host'
        )]
        [string]$Nodename,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Domain Controller Role. [Primary] or [Additional]'
        )]
        [ValidateSet('Primary','Additional')] 
        [string]$Role,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Server DNS Address'
        )]
        [string[]]$DNSAddresses,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: DNS Interface Alias, for example [Ethernet]'
        )]
        [string]$DNSInterfaceAlias,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Domain Name'
        )]
        [string]$DomainName,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Domain Controller Database Path, for example C:\NTDS'
        )]
        [string]$DomainControllerDatabasePath,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Domain Controller Log Path, for example C:\NTDS'
        )]
        [string]$DomainControllerLogPath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SafemodeAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainAdminCredentials,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $LocalAdministrator
    )
    
    Import-DscResource -Module @{
        ModuleName    = 'PSDesiredStateConfiguration'
        ModuleVersion = '1.1'
    }
    Import-DscResource -ModuleName 'xActiveDirectory'
    Import-DscResource -ModuleName 'xNetworking'
    Import-DscResource -ModuleName 'xComputerManagement'

    Node $Nodename
    {      
        xComputer 'RenameComputer'
        { 
            Name = $Nodename
        }
        xDNSServerAddress 'DNSSettings'
        {
            Address = $DNSAddresses
            InterfaceAlias = $DNSInterfaceAlias
            AddressFamily = 'Ipv4'
        }
        WindowsFeature 'ADDSInstall'
        {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        }
        WindowsFeature 'RSAT-ADDS'
        {
            Ensure = 'Present'
            Name = 'RSAT-ADDS'
        }

        if ($LocalAdministrator)
        {
            User 'LocalAdministrator'
            {
                UserName = 'Administrator'
                Password = $LocalAdministrator
                Ensure = 'Present'
            }
        }

        File 'DomainControllerDatabasePath'
        {
            DestinationPath = $DomainControllerDatabasePath
            Type = 'Directory'
            Ensure = 'Present'
        }

        if (($DomainControllerDatabasePath) -ne ($DomainControllerLogPath))
        {
            File 'DomainControllerLogPath'
            {
                DestinationPath = $DomainControllerDatabasePath
                Type = 'Directory'
                Ensure = 'Present'
            }
        }

        if ($Role -eq "Primary")
        {

            xADDomain 'PrimaryDC'
            {
                DomainName = $DomainName
                DomainAdministratorCredential = $DomainAdminCredentials
                SafemodeAdministratorPassword = $SafemodeAdministratorCredential
                DatabasePath = $DomainControllerDatabasePath
                LogPath = $DomainControllerLogPath
                DependsOn = '[WindowsFeature]ADDSInstall'
            }
        }

        if ($Role -eq "Additional")
        {
            xWaitForADDomain 'DscForestWait'
            { 
                DomainName = $DomainName 
                DomainUserCredential = $DomainAdminCredentials
                RetryCount = '300'
                RetryIntervalSec = '5'
                DependsOn = '[WindowsFeature]ADDSInstall' 
            } 

            xADDomainController 'AdditionalDC'
            { 
                DomainName = $DomainName 
                DomainAdministratorCredential = $DomainAdminCredentials
                SafemodeAdministratorPassword = $SafemodeAdministratorCredential
                DatabasePath = $DomainControllerDatabasePath
                LogPath = $DomainControllerLogPath
                DependsOn = '[xWaitForADDomain]DscForestWait' 
            }
        }
    }
}
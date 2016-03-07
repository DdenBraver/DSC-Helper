Configuration DSCSQLManagementStudio
{
    Param(
        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Destination Host'
        )]
        [string]$Nodename,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Install folder \\<UNC>\Data'
        )]
        [string]$SQLSourcePath = '\\<UNC>\Data',

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Install files \SQLServer\2014'
        )]
        [string]$SQLSourceFolder = '\SQLServer\2014',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $LocalAdministrator
    )
    
    Import-DscResource -Module 'cSQLServer'
    Import-DscResource -Module @{
        ModuleName    = 'PSDesiredStateConfiguration'
        ModuleVersion = '1.1'
    }

    Node $Nodename
    {
        WindowsFeature 'NETFrameworkCore'
        {
            Ensure = 'Present'
            Name = 'NET-Framework-Core'
        }

        cSqlServerSetup 'SQLManagementStudio'
        {
            DependsOn = '[WindowsFeature]NETFrameworkCore'
            SourcePath = $SQLSourcePath
            SourceFolder = $SQLSourceFolder
            SetupCredential = $LocalAdministrator
            InstanceName = 'NULL'
            Features = 'SSMS,ADV_SSMS'
            UpdateSource = '.\MU'
        }
    }
}
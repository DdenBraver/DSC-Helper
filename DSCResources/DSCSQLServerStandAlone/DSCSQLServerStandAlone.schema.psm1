Configuration DSCSQLServerStandAlone
{
    Param(

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Destination Host'
        )]
        [string]$Nodename,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Instance Name'
        )]
        [string]$SQLInstanceName,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Administrator'
        )]
        [string[]]$SQLSysadmins,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Install folder \\<UNC>\Data'
        )]
        [string]$SQLSourcePath = '\\<UNC>\Data',

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Install files \\<UNC>\Data\SQLServer\<2014>'
        )]
        [string]$SQLSourceFolder = 'SQLServer\2014',

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Installation Volume: D:'}
        )]
        [string]$SQLInstallVolume,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Features needed to install SQLENGINE,FULLTEXT'
        )]
        [string]$SQLFeatures = 'SQLENGINE,FULLTEXT',

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Filestreamlevel: 0=Disable FILESTREAM / 1=Enable FILESTREAM for Transact-SQL /  2=Enable FILESTREAM for Transact-SQL and file I/O streaming access / 3=Allow remote clients to have streaming access to FILESTREAM data. '}        
        )]
        [int]$SQLFilestreamlevel,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $LocalAdministrator,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SQLServiceaccount,
    
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SAAccount,

        [switch]$SQLManagementTools

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

        Group MSSQL_Administrators
        {
            Ensure = 'Present'
            GroupName = 'MSSQL_Administrators'
            Description = 'sysadmin in MSSQL'
            MembersToInclude = $SQLSysadmins
            Credential = $LocalAdministrator
        }

        User ($SQLServiceaccount.Username)
        {
            DependsOn = '[Group]MSSQL_Administrators'
            UserName = $SQLServiceaccount.Username
            Description = 'service account MSSQL'
            Password = $SQLServiceaccount
            PasswordNeverExpires = $true
            Ensure = 'Present'
        }

        cSqlServerSetup SQLServer2014
        {
            DependsOn           = '[WindowsFeature]NETFrameworkCore'
            SourcePath          = $SQLSourcePath
            SourceFolder        = $SQLSourceFolder
            SetupCredential     = $LocalAdministrator
            InstanceName        = $SQLInstanceName
            Features            = $SQLFeatures
            SQLSysAdminAccounts = '.\MSSQL_Administrators'
            SQLSvcAccount       = $SQLServiceaccount
            SecurityMode        = 'SQL'
            SAPwd               = $SAAccount
            UpdateSource        = '.\MU'
            InstallSharedDir    = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir         = "$($SQLInstallVolume)\Microsoft SQL Server"
            InstallSQLDataDir   = "$($SQLInstallVolume)\Microsoft SQL Server"
            SQLUserDBDir        = "$($SQLInstallVolume)\Microsoft SQL Server\Data"
            SQLUserDBLogDir     = "$($SQLInstallVolume)\Microsoft SQL Server\Data"
            SQLTempDBDir        = "$($SQLInstallVolume)\Microsoft SQL Server\Data"
            SQLTempDBLogDir     = "$($SQLInstallVolume)\Microsoft SQL Server\Data"
            SQLBackupDir        = "$($SQLInstallVolume)\Microsoft SQL Server\Data"
            ASDataDir           = "$($SQLInstallVolume)\Microsoft SQL Server\OLAP\Data"
            ASLogDir            = "$($SQLInstallVolume)\Microsoft SQL Server\OLAP\Log"
            ASBackupDir         = "$($SQLInstallVolume)\Microsoft SQL Server\OLAP\Backup"
            ASTempDir           = "$($SQLInstallVolume)\Microsoft SQL Server\OLAP\Temp"
            ASConfigDir         = "$($SQLInstallVolume)\Microsoft SQL Server\OLAP\Config"
            Filestreamlevel     = $SQLFilestreamlevel
            Filestreamsharename = $SQLInstanceName
        }

        cSqlServerFirewall SQLServer2014
        {
            DependsOn    = ('[cSqlServerSetup]SQLServer2014')
            SourcePath   = $SQLSourcePath
            SourceFolder = $SQLSourceFolder
            InstanceName = $SQLInstanceName
            Features     = $SQLFeatures
        }

        Service SQLServer2014
        {
            DependsOn   = '[cSqlServerSetup]SQLServer2014'
            Name        = $SQLInstanceName
            StartupType = 'Automatic'
            State       = 'Running'
            Credential  = $SQLServiceaccount
        }

        # Install SQL Management Tools
        if($SQLManagementTools)
        {
            cSqlServerSetup 'SQLMT'
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
}
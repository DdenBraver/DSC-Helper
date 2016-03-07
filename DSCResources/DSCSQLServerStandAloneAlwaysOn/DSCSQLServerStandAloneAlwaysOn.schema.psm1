Configuration DSCSQLServerStandAloneAlwaysOn
{
    Param(

        [Parameter(Mandatory = $true,
        	       Helpmessage = {'Define node to be configured'}
        )]
        [string]$Nodename,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define if this node is: Primary or Additional'}			
        )]
        [ValidateSet('Primary','Additional')]
        [string]$ClusterNodeRole,

        [Parameter(Mandatory = $true,
        	       Helpmessage = {'Define Windows Cluster Object(WSFC): Cluster1'}
        )]
        [string]$ClusterNetworkName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define IP for Windows Cluster Object(WSFC): Cluster1'}
        )]
        [string]$ClusterIPAddress,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define all nodes being part of the Windows Cluster Object(WSFC)'}
        )]
        [string[]]$ClusterNodes,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define Primary node of the Windows Cluster Object(WSFC)'}
        )]
        [string]$PrimaryClusterNode,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define Instance name for MSSQL: Instance1'}
        )]
        [string]$SQLInstanceName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define source path SQL install: \\<UNC>\Data'}
        )]
        [string]$SQLSourcePath,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define source folder SQL install: \SQLServer\2014'}
        )]
        [string]$SQLSourceFolder,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Installation Volume: D:'}
        )]
        [string]$SQLInstallVolume,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define sqlfeatures: SQLENGINE,SSMS,FULLTEXT'}
        )]
        [string]$SQLFeatures,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define sql update source: .\MU'}
        )]
        [string]$SQLUpdateSource,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define users/groups: Administrator, DOMAIN\MSSQL_Administrators'}        
        )]
        [string[]]$SQLSysadmins,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Filestreamlevel: 0=Disable FILESTREAM / 1=Enable FILESTREAM for Transact-SQL /  2=Enable FILESTREAM for Transact-SQL and file I/O streaming access / 3=Allow remote clients to have streaming access to FILESTREAM data. '}        
        )]
        [string]$SQLFilestreamlevel,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Endpoint Name: Endpoint1'}        
        )]
        [string]$SQLEndpointName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Endpoint Port: default 5022'}        
        )]
        [string]$SQLEndpointPort,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define SQL Availability Group Name: ClusAG1'}        
        )]
        [string]$AvailabilityGroupName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Primary SQL Instance: Server1\Instance1'}        
        )]
        [string]$PrimarySQLInstance,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Secondary SQL Instance: Server2\Instance1'}        
        )]
        [string]$SecondarySQLInstance,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Availability Group Initialize Database Name: DefaultAGDB'}        
        )]
        [string]$AvailabilityGroupDatabase,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'SQL Always-On Backup directory \\fileserver\Backup'}        
        )]
        [string]$BackupDirectory,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'SQL Always-On listener name: Listener1'}        
        )]
        [string]$ListenerName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'SQL Always-On listener IP Address (must be unique!)'}        
        )]
        [string]$ListenerIpAddress,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'SQL Always-On listener Subnet mask'}        
        )]
        [string]$ListenerSubnetMask,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Automatic', 'Manual')]
        [string]$ReplicaFailoverMode,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'SQL Resource [FORCE] flag, if set to true, it will destroy and recreate the Always-On group if it fails.'}        
        )]
        [bool]$ForceFlagEnabled,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SQLServiceaccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainAdminCredentials,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SQLSAAccount

    )    
    
    Import-DscResource -Module @{
        ModuleName    = 'cSQLServer'
        ModuleVersion = '2.0.3.1'
    }
    Import-DscResource -Module @{
        ModuleName    = 'cFailoverCluster'
        ModuleVersion = '1.2.1.6'
    }
    Import-DscResource -Module @{
        ModuleName    = 'PSDesiredStateConfiguration'
        ModuleVersion = '1.1'
    }
    
    $AdditionalClusterNode = $ClusterNodes | Where-Object -FilterScript {
        $_ -ne $PrimaryClusterNode
    }

    Node $Nodename
    {
        WindowsFeature 'NETFrameworkCore'
        {
            Ensure = 'Present'
            Name   = 'NET-Framework-Core'
        }
        WindowsFeature 'FailoverClustering'
        {
            Ensure               = 'Present'
            Name                 = 'Failover-Clustering'
            IncludeAllSubFeature = $true
        }
        WindowsFeature 'RSATClusteringPowerShell'
        {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-PowerShell'
        }
        Group 'MSSQL_Administrators'
        {
            Ensure = 'Present'
            GroupName = 'MSSQL_Administrators'
            Description = 'sysadmin in MSSQL'
            MembersToInclude = $SQLSysadmins
            Credential = $DomainAdminCredentials
        }

        if ($ClusterNodeRole -eq 'Primary')
        {
            cCluster 'SQLCluster'
            {
                DependsOn = @(
                    '[WindowsFeature]FailoverClustering', 
                    '[WindowsFeature]RSATClusteringPowerShell'
                )
                Name                          = $ClusterNetworkName
                StaticIPAddress               = $ClusterIPAddress
                DomainAdministratorCredential = $DomainAdminCredentials
                Nostorage                     = $true
            }
            WaitForAll 'SQLCluster'
            {
                ResourceName     = '[cCluster]SQLCluster::[DSCSQLServerStandAloneAlwaysOn]DSCRoleSQLServerStandAlone_AlwaysOn'
                NodeName         = $AdditionalClusterNode
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cSqlServerSetup 'SQLServer2014'
            {
                DependsOn           = '[WindowsFeature]NETFrameworkCore'
                SourcePath          = $SQLSourcePath
                SourceFolder        = $SQLSourceFolder
                SetupCredential     = $DomainAdminCredentials
                InstanceName        = $SQLInstanceName
                Features            = $SQLFeatures
                SQLSysAdminAccounts = ".\MSSQL_Administrators"
                SQLSvcAccount       = $SQLServiceaccount
                SecurityMode        = 'SQL'
                SAPwd               = $SQLSAAccount
                UpdateSource        = $SQLUpdateSource
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
            cSqlServerFirewall 'SQLServer2014'
            {
                DependsOn    = ('[cSqlServerSetup]SQLServer2014')
                SourcePath   = $SQLSourcePath
                SourceFolder = $SQLSourceFolder
                InstanceName = $SQLInstanceName
                Features     = $SQLFeatures
            }
            cSqlHAService 'EnableSQLHA'
            {
                InstanceName               = $SQLInstanceName
                ServiceCredential          = $SQLServiceaccount
                SQLAdministratorCredential = $SQLSAAccount
                SQLServerName              = $Nodename
                PSDSCRunAsCredential       = $DomainAdminCredentials
                DependsOn                  = '[cSqlServerSetup]SQLServer2014'
            }
            WaitForAll 'ClusterHA'
            {
                NodeName         = $AdditionalClusterNode
                ResourceName     = '[cSqlHAService]EnableSQLHA::[DSCSQLServerStandAloneAlwaysOn]DSCRoleSQLServerStandAlone_AlwaysOn'
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cSqlHAEndPoint 'ConfigureEndpoint'
            {
                InstanceName         = $SQLInstanceName
                AllowedUser          = $SQLServiceaccount.Username
                Name                 = $SQLEndpointName
                PortNumber           = $SQLEndpointPort
                SQLServerName        = $Nodename
                DependsOn            = '[cSqlHAService]EnableSQLHA'
                PSDSCRunAsCredential = $DomainAdminCredentials
            }
            WaitForAll 'cSqlHAEndPoint'
            {
                NodeName         = $AdditionalClusterNode
                ResourceName     = '[cSqlHAEndPoint]ConfigureEndpoint::[DSCSQLServerStandAloneAlwaysOn]DSCRoleSQLServerStandAlone_AlwaysOn'
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cSqlAvailabilityGroup 'AvailabilityGroup'
            {
                AvailabilityGroupName     = $AvailabilityGroupName
                PrimarySQLInstance        = $PrimarySQLInstance
                SecondarySQLInstance      = $SecondarySQLInstance
                AvailabilityGroupDatabase = $AvailabilityGroupDatabase
                BackupDirectory           = $BackupDirectory
                ListenerName              = $ListenerName
                ListenerIpAddress         = $ListenerIpAddress
                ListenerSubnetMask        = $ListenerSubnetMask
                Force                     = $ForceFlagEnabled
                PSDSCRunAsCredential      = $DomainAdminCredentials
                ReplicaFailoverMode       = $ReplicaFailoverMode
            }
        }
        else
        {
            WaitForAll 'SQLCluster'
            {
                ResourceName     = '[cCluster]SQLCluster::[DSCSQLServerStandAloneAlwaysOn]DSCRoleSQLServerStandAlone_AlwaysOn'
                NodeName         = $PrimaryClusterNode
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cWaitForCluster 'SQLCluster'
            {
                DependsOn        = '[WaitForAll]SQLCluster'
                Name             = $ClusterNetworkName
                RetryIntervalSec = 10
                RetryCount       = 60
            }
            cCluster 'SQLCluster'
            {
                DependsOn                     = '[cWaitForCluster]SQLCluster'
                Name                          = $ClusterNetworkName
                StaticIPAddress               = $ClusterIPAddress
                DomainAdministratorCredential = $DomainAdminCredentials
                Nostorage                     = $true
            }
            cSqlServerSetup 'SQLServer2014'
            {
                DependsOn           = '[WindowsFeature]NETFrameworkCore'
                SourcePath          = $SQLSourcePath
                SourceFolder        = $SQLSourceFolder
                SetupCredential     = $DomainAdminCredentials
                InstanceName        = $SQLInstanceName
                Features            = $SQLFeatures
                SQLSysAdminAccounts = ".\MSSQL_Administrators"
                SQLSvcAccount       = $SQLServiceaccount
                SecurityMode        = 'SQL'
                SAPwd               = $SQLSAAccount
                UpdateSource        = $SQLUpdateSource
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
            cSqlServerFirewall 'SQLServer2014'
            {
                DependsOn    = ('[cSqlServerSetup]SQLServer2014')
                SourcePath   = $SQLSourcePath
                SourceFolder = $SQLSourceFolder
                InstanceName = $SQLInstanceName
                Features     = $SQLFeatures
            }
            WaitForAll 'ClusterHA'
            {
                NodeName         = $PrimaryClusterNode
                ResourceName     = '[cSqlHAService]EnableSQLHA::[DSCSQLServerStandAloneAlwaysOn]DSCRoleSQLServerStandAlone_AlwaysOn'
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cSqlHAService 'EnableSQLHA'
            {
                InstanceName               = $SQLInstanceName
                ServiceCredential          = $SQLServiceaccount
                SQLAdministratorCredential = $SQLSAAccount
                SQLServerName              = $Nodename
                PSDSCRunAsCredential       = $DomainAdminCredentials
                DependsOn                  = '[cSqlServerSetup]SQLServer2014'
            }
            cSqlHAEndPoint 'ConfigureEndpoint'
            {
                InstanceName         = $SQLInstanceName
                AllowedUser          = $SQLServiceaccount.Username
                Name                 = $SQLEndpointName
                PortNumber           = $SQLEndpointPort
                SQLServerName        = $Nodename
                DependsOn            = '[cSqlHAService]EnableSQLHA'
                PSDSCRunAsCredential = $DomainAdminCredentials
            }
        }
    }
}

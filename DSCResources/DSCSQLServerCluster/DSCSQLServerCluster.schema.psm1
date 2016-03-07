Configuration DSCSQLServerCluster
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
                   Helpmessage = {'Define a name for the SQL Cluster Service: ClusterNetwork1'}
        )]
        [string]$SQLFailoverClusterNetworkName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define an IP for the SQL Cluster Service: ClusterNetwork1'}
        )]
        [string]$SQLClusterIPAddress,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define a name for the SQL Cluster Service: ClusterGroup1'}
        )]
        [string]$SQLClusterGroupName,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define source path SQL install: \\<UNC>\Data'}
        )]
        [string]$SQLSourcePath,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define source folder SQL install: \SQLServer\2014'}
        )]
        [string]$SQLSourceFolder,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define sqlfeatures: SQLENGINE,SSMS,FULLTEXT'}
        )]
        [string]$SQLFeatures,

        [Parameter(Mandatory = $true, 
                   Helpmessage = {'Define SQL Install Volume ISCSI Driveletter (Preerq: Initialized & Online, driveletter assigned at destinations vm: E:'}        
        )]
        [string]$SQLInstallVolume,

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
        [int]$SQLFilestreamlevel,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SQLServiceaccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainAdminCredentials

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
            DependsOn            = '[WindowsFeature]NETFrameworkCore'
        }
        WindowsFeature 'RSATClusteringPowerShell'
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-PowerShell'
            DependsOn = '[WindowsFeature]FailoverClustering'
        }

        if ($ClusterNodeRole -eq 'Primary')
        {
            cCluster 'SQLCluster1'
            {
                DependsOn                     = '[WindowsFeature]RSATClusteringPowerShell'
                Name                          = $ClusterNetworkName
                StaticIPAddress               = $ClusterIPAddress
                DomainAdministratorCredential = $DomainAdminCredentials
            }
            WaitForAll 'SQLCluster1'
            {
                ResourceName     = '[cCluster]SQLCluster1::[DSCSQLServerCluster]DSCRoleSQLServerCluster'
                NodeName         = $AdditionalClusterNode
                RetryIntervalSec = 5
                RetryCount       = 720
            }
        }
        else
        {
            WaitForAll 'SQLCluster1'
            {
                ResourceName     = '[cCluster]SQLCluster1::[DSCSQLServerCluster]DSCRoleSQLServerCluster'
                NodeName         = $PrimaryClusterNode
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cWaitForCluster 'SQLCluster1'
            {
                DependsOn        = '[WaitForAll]SQLCluster1'
                Name             = $ClusterNetworkName
                RetryIntervalSec = 10
                RetryCount       = 60
            }
            cCluster 'SQLCluster1'
            {
                DependsOn                     = '[cWaitForCluster]SQLCluster1'
                Name                          = $ClusterNetworkName
                StaticIPAddress               = $ClusterIPAddress
                DomainAdministratorCredential = $DomainAdminCredentials
            }
        }

        cSQLServerFailoverClusterSetup ('PrepareMSSQLSERVER' + $SQLInstanceName)
        {
            DependsOn                  = '[cCluster]SQLCluster1'
            Action                     = 'Prepare'
            SourcePath                 = $SQLSourcePath
            SourceFolder               = $SQLSourceFolder
            SetupCredential            = $DomainAdminCredentials
            Features                   = $SQLFeatures
            InstanceName               = $SQLInstanceName
            FailoverClusterNetworkName = $SQLFailoverClusterNetworkName
            SQLSvcAccount              = $SQLServiceaccount
            FailoverClusterIPAddress   = $ClusterIPAddress
            SQLUserDBDir               = "$SQLInstallVolume\SQL\User\Database"
            SQLUserDBLogDir            = "$SQLInstallVolume\SQL\User\Log"
            SQLTempDBDir               = "$SQLInstallVolume\SQL\Temp\Database"
            SQLTempDBLogDir            = "$SQLInstallVolume\SQL\Temp\Log"
            SQLBackupDir               = "$SQLInstallVolume\SQL\Backup"
            UpdateSource               = $SQLUpdateSource
            Filestreamlevel            = $SQLFilestreamlevel
        }
        cSqlServerFirewall ('FirewallMSSQLSERVER' + $SQLInstanceName)
        {
            DependsOn    = '[cSQLServerFailoverClusterSetup]PrepareMSSQLSERVER' + $SQLInstanceName
            SourcePath   = $SQLSourcePath
            SourceFolder = $SQLSourceFolder
            InstanceName = $SQLInstanceName
            Features     = $SQLFeatures
        }

        if($ClusterNodeRole -eq 'Primary')
        {
            WaitForAll ('Cluster' + $SQLInstanceName)
            {
                NodeName         = $AdditionalClusterNode
                ResourceName     = '[cSQLServerFailoverClusterSetup]PrepareMSSQLSERVER' + $SQLInstanceName + '::[DSCSQLServerCluster]DSCRoleSQLServerCluster'
                RetryIntervalSec = 5
                RetryCount       = 720
            }
            cSQLServerFailoverClusterSetup ('CompleteMSSQLSERVER' + $SQLInstanceName)
            {
                DependsOn = @(
                    '[WaitForAll]Cluster' + $SQLInstanceName
                )
                Action                     = 'Complete'
                SourcePath                 = $SQLSourcePath
                SourceFolder               = $SQLSourceFolder
                SetupCredential            = $DomainAdminCredentials
                Features                   = $SQLFeatures
                InstanceName               = $SQLInstanceName
                FailoverClusterNetworkName = $SQLFailoverClusterNetworkName
                InstallSQLDataDir          = "$SQLInstallVolume\SQL"
                ISFileSystemFolder         = "$SQLInstallVolume\SQL\Packages"
                FailoverClusterIPAddress   = $SQLClusterIPAddress
                FailoverClusterGroup       = $SQLClusterGroupName
                SQLSvcAccount              = $SQLServiceaccount
                SQLSysAdminAccounts        = $SQLSysadmins
                ASSysAdminAccounts         = $SQLSysadmins
                UpdateSource               = $SQLUpdateSource
                Filestreamlevel            = $SQLFilestreamlevel
            }
        }
    }
}
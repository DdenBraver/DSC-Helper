Configuration DSCSQLServerClusterAlwaysOn
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
        [string[]]$SQLInstanceNames,
        
        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define a name for the SQL Cluster Service: ClusNetwork1'}
        )]
        [string[]]$SQLFailoverClusterNetworkNames,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define an IP for the SQL Cluster Service: ClusNetwork1'}
        )]
        [string[]]$SQLClusterIPAddresses,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define a name for the SQL Cluster Service: ClusGroup1'}
        )]
        [string[]]$SQLClusterGroupNames,

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
                   Helpmessage = {'Define SQL Install Volume ISCSI Driveletters (Preerq: Initialized & Online, driveletter assigned at destinations vm: E:'}        
        )]
        [string[]]$SQLInstallVolumes,

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
                   Helpmessage = {'Primary SQL Instance: ClusNetwork1\Instance1'}        
        )]
        [string]$PrimarySQLInstance,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Secondary SQL Instance: ClusNetwork2\Instance2'}        
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

        [Parameter(Mandatory = $true,
                   Helpmessage = {'SQL Resource [FORCE] flag, if set to true, it will destroy and recreate the Always-On group if it fails.'}        
        )]
        [bool]$ForceFlagEnabled,

        [Parameter(Mandatory = $true,
                   Helpmessage = {'Define: SQL Service [domain] account: DOMAIN\srv_mssql'})]
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
            cCluster 'SQLCluster'
            {
                DependsOn                     = '[WindowsFeature]RSATClusteringPowerShell'
                Name                          = $ClusterNetworkName
                StaticIPAddress               = $ClusterIPAddress
                DomainAdministratorCredential = $DomainAdminCredentials
            }
            WaitForAll 'SQLCluster'
            {
                ResourceName     = '[cCluster]SQLCluster::[DSCSQLServerClusterAlwaysOn]DSCRoleSQLServerClusterAlwaysOn'
                NodeName         = $AdditionalClusterNode
                RetryIntervalSec = 10
                RetryCount       = 720
            }
        }
        else
        {
            WaitForAll 'SQLCluster'
            {
                ResourceName     = '[cCluster]SQLCluster::[DSCSQLServerClusterAlwaysOn]DSCRoleSQLServerClusterAlwaysOn'
                NodeName         = $PrimaryClusterNode
                RetryIntervalSec = 10
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
            }
        }

        $count = ($ClusterNodes.Count)/($SQLInstanceNames.Count)
        $currentnodes = $ClusterNodes
        $currentgroups = $SQLClusterGroupNames
        $currentnames = $SQLFailoverClusterNetworkNames
        $currentvolumes = $SQLInstallVolumes
        $currentIPs = $SQLClusterIPAddresses

        Foreach ($SQLInstanceName in $SQLInstanceNames)
        {

            $SubNodes = $currentnodes | Select-Object -first $count
            $SubGroups = $currentgroups | Select-Object -First 1
            $SubNames = $currentnames | Select-Object -first 1
            $SubVolumes = $currentvolumes | Select-Object -first 1
            $SubIPs = $currentIPs | Select-Object -first 1

            cSQLServerFailoverClusterSetup ('PrepareMSSQLSERVER' + $SQLInstanceName)
            {
                DependsOn                  = '[cCluster]SQLCluster'
                Action                     = 'Prepare'
                SourcePath                 = $SQLSourcePath
                SourceFolder               = $SQLSourceFolder
                SetupCredential            = $DomainAdminCredentials
                Features                   = $SQLFeatures
                InstanceName               = $SQLInstanceName
                FailoverClusterNetworkName = $SubNames
                SQLSvcAccount              = $SQLServiceaccount
                FailoverClusterIPAddress   = $ClusterIPAddress
                SQLUserDBDir               = "$SubVolumes\SQL\User\Database"
                SQLUserDBLogDir            = "$SubVolumes\SQL\User\Log"
                SQLTempDBDir               = "$SubVolumes\SQL\Temp\Database"
                SQLTempDBLogDir            = "$SubVolumes\SQL\Temp\Log"
                SQLBackupDir               = "$SubVolumes\SQL\Backup"
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

            if ($ClusterNodeRole -eq 'Primary')
            {
                WaitForAll ('Cluster' + $SQLInstanceName)
                {
                    NodeName         = $AdditionalClusterNode
                    ResourceName     = '[cSQLServerFailoverClusterSetup]PrepareMSSQLSERVER' + $SQLInstanceName + '::[DSCSQLServerClusterAlwaysOn]DSCRoleSQLServerClusterAlwaysOn'
                    RetryIntervalSec = 10
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
                    FailoverClusterNetworkName = $SubNames
                    InstallSQLDataDir          = "$SubVolumes\SQL"
                    ISFileSystemFolder         = "$SubVolumes\SQL\Packages"
                    FailoverClusterIPAddress   = $SubIPs
                    FailoverClusterGroup       = $SubGroups
                    SQLSvcAccount              = $SQLServiceaccount
                    SQLSysAdminAccounts        = $SQLSysadmins
                    ASSysAdminAccounts         = $SQLSysadmins
                    UpdateSource               = $SQLUpdateSource
                    Filestreamlevel            = $SQLFilestreamlevel
                }
                cSqlHAService ('EnableSQLHA' + $SQLInstanceName)
                {
                    InstanceName = $SQLInstanceName
                    ServiceCredential = $SQLServiceaccount
                    SQLAdministratorCredential = $DomainAdminCredentials
                    SQLServerName = $SubNames
                    PSDSCRunAsCredential = $DomainAdminCredentials
                    DependsOn = '[cSQLServerFailoverClusterSetup]CompleteMSSQLSERVER' + $SQLInstanceName
                }
                WaitForAll ('ClusterHA' + $SQLInstanceName)
                {
                    NodeName = $AdditionalClusterNode
                    ResourceName = '[cSqlHAService]EnableSQLHA' + $SQLInstanceName + '::[DSCSQLServerClusterAlwaysOn]DSCRoleSQLServerClusterAlwaysOn'
                    RetryIntervalSec = 10
                    RetryCount = 720
                }
                cSqlHAEndPoint ('ConfigureEndpoint' + $SQLInstanceName)
                {
                    InstanceName = $SQLInstanceName
                    AllowedUser = $SQLServiceaccount.Username
                    Name = $SQLEndpointName
                    PortNumber = $SQLEndpointPort
                    SQLServerName = $SubNames
                    DependsOn = '[cSqlHAService]EnableSQLHA' + $SQLInstanceName
                    PSDSCRunAsCredential = $DomainAdminCredentials
                }
                cClusterPreferredOwner ('ClusterPreferredOwner' + $SQLInstanceName)
                {
                    Clustername = $SubNames
                    Nodes = $SubNodes
                    ClusterGroup = $SubGroups
                    ClusterResources = "*$($SQLInstanceName)*", "*$($SubNames)*"
                    Ensure = 'Present'
                    PSDSCRunAsCredential = $DomainAdminCredentials
                    DependsOn = '[cSqlHAEndPoint]ConfigureEndpoint' + $SQLInstanceName
                }
            }
            else
            {
                WaitForAll ('CompleteMSSQLSERVER' + $SQLInstanceName)
                {
                    ResourceName = '[cSQLServerFailoverClusterSetup]CompleteMSSQLSERVER' + $SQLInstanceName + '::[DSCSQLServerClusterAlwaysOn]DSCRoleSQLServerClusterAlwaysOn'
                    NodeName = $PrimaryClusterNode
                    RetryIntervalSec = 10
                    RetryCount = 720
                }
                WaitForAll ('ClusterHA' + $SQLInstanceName)
                {
                    NodeName = $PrimaryClusterNode
                    ResourceName = '[cSqlHAService]EnableSQLHA' + $SQLInstanceName + '::[DSCSQLServerClusterAlwaysOn]DSCRoleSQLServerClusterAlwaysOn'
                    RetryIntervalSec = 10
                    RetryCount = 720
                }
                cSqlHAService ('EnableSQLHA' + $SQLInstanceName)
                {
                    InstanceName = $SQLInstanceName
                    ServiceCredential = $SQLServiceaccount
                    SQLAdministratorCredential = $DomainAdminCredentials
                    SQLServerName = $SubNames
                    PSDSCRunAsCredential = $DomainAdminCredentials
                    DependsOn = '[WaitForAll]CompleteMSSQLSERVER' + $SQLInstanceName
                }
            }

            $currentnodes = $currentnodes | Where-Object {$SubNodes -notcontains $_}
            $currentgroups = $currentgroups | Where-Object {$SubGroups -notcontains $_}
            $currentnames = $currentnames | Where-Object {$SubNames -notcontains $_}
            $currentvolumes = $currentvolumes | Where-Object {$SubVolumes -notcontains $_}
            $currentIPs = $currentIPs | Where-Object {$SubIPs -notcontains $_}
        }

        if ($ClusterNodeRole -eq 'Primary')
        {
            cWaitforSqlHAService "$PrimarySQLInstance"
            {
                InstanceName = $PrimarySQLInstance.split('\')[1]
                SQLServerName = $PrimarySQLInstance.split('\')[0]
                RetryIntervalSec = 10
                RetryCount = 720
                PSDSCRunAsCredential = $DomainAdminCredentials
            }
            
            cWaitforSqlHAService "$SecondarySQLInstance"
            {
                InstanceName = $SecondarySQLInstance.split('\')[1]
                SQLServerName = $SecondarySQLInstance.split('\')[0]
                RetryIntervalSec = 10
                RetryCount = 720
                PSDSCRunAsCredential = $DomainAdminCredentials
            }
            
            cSqlAvailabilityGroup "$AvailabilityGroupName"
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
                ReplicaFailoverMode       = 'Manual'
            }
        }
    }
}
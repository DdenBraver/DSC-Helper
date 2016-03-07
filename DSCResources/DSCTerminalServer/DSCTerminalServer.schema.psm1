configuration DSCTerminalServer
{
    Param(
        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Destination Host'
        )]
        [string]$Nodename,
        
        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Fully Quallified DNS Name of the destination Host'
        )]
        [string]$FQDN,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Terminal Server Collection Name'
        )]
        [string]$CollectionName,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Terminal Server Collection Description'
        )]
        [string]$CollectionDescription

    )
    
    Import-DscResource -Module @{
        ModuleName    = 'PSDesiredStateConfiguration'
        ModuleVersion = '1.1'
    }
    Import-DscResource -Module 'xRemoteDesktopSessionHost'

    Node $Nodename {
        WindowsFeature RSATClustering
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering'
        }

        WindowsFeature RSATADTools
        {
            Ensure = 'Present'
            Name = 'RSAT-AD-Tools'
        }
                    
        WindowsFeature RSATADCS
        {
            Ensure = 'Present'
            Name = 'RSAT-ADCS'
        }

        WindowsFeature RSATDHCP
        {
            Ensure = 'Present'
            Name = 'RSAT-DHCP'
        }

        WindowsFeature RSATDNSServer
        {
            Ensure = 'Present'
            Name = 'RSAT-DNS-Server'
        }

        WindowsFeature RemoteDesktopServices
        {
            Ensure = 'Present'
            Name = 'Remote-Desktop-Services'
        }

        WindowsFeature RDSRDServer
        {
            Ensure = 'Present'
            Name = 'RDS-RD-Server'
        }

        WindowsFeature DesktopExperience
        {
            Ensure = 'Present'
            Name = 'Desktop-Experience'
        }

        WindowsFeature RSATRDSTools
        {
            Ensure = 'Present'
            Name = 'RSAT-RDS-Tools'
            IncludeAllSubFeature = $true
        }

        WindowsFeature RDSConnectionBroker
        {
            Ensure = 'Present'
            Name = 'RDS-Connection-Broker'
        }

        WindowsFeature RDSWebAccess
        {
            Ensure = 'Present'
            Name = 'RDS-Web-Access'
        }

        WindowsFeature RDSLicensing
        {
            Ensure = 'Present'
            Name = 'RDS-Licensing'
        }

        xRDSessionDeployment Deployment
        {
            SessionHost = $FQDN
            ConnectionBroker = $FQDN
            WebAccessServer = $FQDN
            DependsOn = '[WindowsFeature]RemoteDesktopServices', '[WindowsFeature]RDSRDServer'
        }

        xRDSessionCollection Collection
        {
            CollectionName = $CollectionName
            CollectionDescription = $CollectionDescription
            SessionHost = $FQDN
            ConnectionBroker = $FQDN
            DependsOn = '[cRDSessionDeployment]Deployment'
        }

        xRDSessionCollectionConfiguration CollectionConfiguration
        {
            CollectionName = $CollectionName
            CollectionDescription = $CollectionDescription
            ConnectionBroker = $FQDN   
            TemporaryFoldersDeletedOnExit = $false
            SecurityLayer = 'SSL'
            DependsOn = '[cRDSessionCollection]Collection'
        }

        xRDRemoteApp Mstsc
        {
            CollectionName = $CollectionName
            DisplayName = 'Remote Desktop'
            FilePath = 'C:\Windows\System32\mstsc.exe'
            Alias = 'mstsc'
            DependsOn = '[cRDSessionCollection]Collection'
        }
    }
}
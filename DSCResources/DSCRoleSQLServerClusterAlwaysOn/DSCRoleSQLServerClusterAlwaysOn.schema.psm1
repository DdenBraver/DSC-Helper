configuration DSCRoleSQLServerClusterAlwaysOn
{
    Import-DscResource -ModuleName DSC-Helper
    
    Node $Allnodes.NodeName
    {
        DSCJoinDomain 'DSCRoleSQLServerClusterAlwaysOn'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
        DSCSQLServerClusterAlwaysOn 'DSCRoleSQLServerClusterAlwaysOn'
        {
            NodeName = $Node.Nodename
            SQLFeatures = 'SQLENGINE,SSMS'
            SQLUpdateSource = '.\MU'
            SQLEndpointPort = '5022'
            ForceFlagEnabled = $true
        }
    }
}
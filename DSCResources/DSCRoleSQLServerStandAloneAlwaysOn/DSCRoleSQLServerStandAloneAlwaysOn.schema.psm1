configuration DSCRoleSQLServerStandAloneAlwaysOn
{
    Import-DscResource -ModuleName DSC-Helper
    
    Node $Allnodes.NodeName
    {
        DSCJoinDomain 'DSCRoleSQLServerStandAlone_AlwaysOn'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
        DSCSQLServerStandAloneAlwaysOn 'DSCRoleSQLServerStandAlone_AlwaysOn'
        {
            NodeName = $Node.Nodename
            SQLFeatures = 'SQLENGINE,SSMS'
            SQLUpdateSource = '.\MU'
            ReplicaFailoverMode = 'Automatic'
            SQLEndpointPort = '5022'
            ForceFlagEnabled = $true
        }
    }
}
configuration DSCRoleSQLServerCluster
{
    Import-DscResource -ModuleName DSC-Helper
    
    Node $Allnodes.NodeName
    {
        DSCJoinDomain 'DSCRoleSQLServerCluster'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
        DSCSQLServerCluster 'DSCRoleSQLServerCluster'
        {
            NodeName = $Node.Nodename
            SQLFeatures = 'SQLENGINE,SSMS'
            SQLUpdateSource = '.\MU'
        }
    }
}
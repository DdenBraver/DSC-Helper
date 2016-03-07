configuration DSCRoleSQLServerStandAlone
{
    Import-DscResource -ModuleName DSC-Helper
    
    Node $Allnodes.NodeName
    {
        DSCJoinDomain 'DSCRoleSQLServerStandAlone'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
        DSCSQLServerStandAlone 'DSCRoleSQLServerStandAlone'
        {
            NodeName = $Node.Nodename
            SQLManagementTools = $true
            SQLFeatures = 'SQLENGINE,FULLTEXT'
            LocalAdministrator = $Node.LocalAdministrator
        }
    }
}
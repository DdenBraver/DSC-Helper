configuration DSCRoleDomainJoinOnly
{  
    Import-DscResource -ModuleName DSC-Helper
    
    Node $Allnodes.NodeName
    {
        DSCJoinDomain 'DSCRoleDomainJoinOnly'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
    }
}
configuration DSCRoleDomainController
{
    Import-DscResource -ModuleName DSC-Helper

    Node $Allnodes.NodeName
    {
        DSCDomainControllers 'DSCRoleDomainController'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
    }
}
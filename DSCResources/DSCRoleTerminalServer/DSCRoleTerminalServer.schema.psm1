configuration DSCRoleTerminalServer
{
    param(
        [Parameter(
        Mandatory = $true,
        Helpmessage = 'Define: $true/$false, would you like to install SQL Management Studio?'
        )]
        [Bool]$SQLManagementStudio
    )

    Import-DscResource -ModuleName DSC-Helper

    Node $Allnodes.NodeName
    {
        DSCJoinDomain 'DSCRoleTerminalServer'
        {
            NodeName = $Node.Nodename
            DNSInterfaceAlias = 'Ethernet'
            LocalAdministrator = $Node.LocalAdministrator
        }
        DSCTerminalServer 'DSCRoleTerminalServer'
        {
            NodeName = $Node.Nodename
        }
        
        if ($SQLManagementStudio -eq $true){
            DSCSQLManagementStudio 'DSCRoleTerminalServer'
            {
                NodeName = $Node.Nodename
                LocalAdministrator = $Node.LocalAdministrator
            }
        }
    }
}
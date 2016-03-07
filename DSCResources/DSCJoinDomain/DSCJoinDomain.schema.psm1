configuration DSCJoinDomain
{
    [CmdletBinding()] 

    param(
    
        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Destination Host'
        )]
        [string]$Nodename,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Domain Name'
        )]
        [string]$DomainName,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: Server DNS Address'
        )]
        [array]$DNSAddresses,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: DNS Interface Alias, for example [Ethernet]'
        )]
        [string]$DNSInterfaceAlias,

        [Parameter(Mandatory = $true,
        Helpmessage = 'Define: DNS Suffix names'
        )]
        [string[]]$DNSSearchList,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainJoinAccount = (Get-Credential -UserName supportasp\_nxlog -Message 'NXLog Service credential'),

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $LocalAdministrator = (Get-Credential -UserName Administrator -Message 'Local Administrator credential')

    )

    Import-DscResource -Module @{
        ModuleName    = 'PSDesiredStateConfiguration'
        ModuleVersion = '1.1'
    }
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking

    node $Nodename
    {
        xDNSServerAddress DNSSettings
        {
            Address = $DNSAddresses
            InterfaceAlias = $DNSInterfaceAlias
            AddressFamily = 'Ipv4'
            PSDSCRunAsCredential = $LocalAdministrator
        }

        script DNSSuffix
        {
            GetScript = 
            {
                $Query = (Get-DnsClientGlobalSetting).suffixsearchlist
                if ($Query)
                {
                    $result = 'DNS Search List: {0}' -f $($Query.SearchList -join ',')
                }
                else
                {
                    $result = 'DNS Search List: Empty!'
                }
                return @{
                    GetScript  = $GetScript
                    SetScript  = $SetScript
                    TestScript = $TestScript
                    Result     = $result
                }
            }
            TestScript = 
            {               
                $Query = (Get-DnsClientGlobalSetting).suffixsearchlist
                if ($Query.length -ne 0)
                {
                    $Match = @( Compare-Object -ReferenceObject $((Get-DnsClientGlobalSetting).suffixsearchlist) -DifferenceObject $using:DNSSearchList -SyncWindow 0).Length -eq 0
                }
                else
                {
                    $Match = $false
                }
                Write-Verbose -Message "DNSSuffixList match is $Match"
                return $Match
            }
            SetScript = 
            {
                Set-DnsClientGlobalSetting -SuffixSearchList $using:DNSSearchList
            }
        }

        xComputer JoinDomain 
        { 
            Name          = $Nodename   
            DomainName    = $DomainName 
            Credential    = $DomainJoinAccount
            DependsOn     = @(
                '[xDNSServerAddress]DNSSettings'
                '[script]DNSSuffix'
            )
        }
                
        User LocalAdminUser
        {
            UserName = 'Administrator'
            Password = $LocalAdministrator
            Ensure = 'Present'
            DependsOn = '[xComputer]JoinDomain'
        }
    }
}
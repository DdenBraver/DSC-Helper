Configuration DSCConfigurePullServer
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$Nodename,

        [Parameter(Mandatory = $true)]
        [string] $certificateThumbPrint
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $Nodename
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = 'Present'
            Name   = 'DSC-Service'            
        }

        xDscWebService DSCPullServer
        {
            Ensure                  = 'Present'
            EndpointName            = 'DSCPullServer'
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\DSCPullServer"
            CertificateThumbPrint   = $certificateThumbPrint         
            ModulePath              = "$env:ProgramFiles\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration"            
            State                   = 'Started'
            DependsOn               = '[WindowsFeature]DSCServiceFeature'                        
        }

        xDscWebService DSCComplianceServer
        {
            Ensure                  = 'Present'
            EndpointName            = 'DSCComplianceServer'
            Port                    = 9080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\DSCComplianceServer"
            CertificateThumbPrint   = $certificateThumbPrint
            State                   = 'Started'
            IsComplianceServer      = $true
            DependsOn               = @('[WindowsFeature]DSCServiceFeature', '[xDSCWebService]DSCPullServer')
        }
    }
}
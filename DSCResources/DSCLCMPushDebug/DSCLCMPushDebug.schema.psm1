configuration DSCLCMPushDebug
{
    Node $Allnodes.NodeName
    {
        LocalConfigurationManager 
        {
            RefreshMode                    = 'PUSH'
            RebootNodeIfNeeded             = $true
            ActionAfterReboot              = 'StopConfiguration'
            RefreshFrequencyMins           = 30
            ConfigurationModeFrequencyMins = 30 
            ConfigurationMode              = 'ApplyAndMonitor'
            DebugMode                      = 'All'
        }
    }
}
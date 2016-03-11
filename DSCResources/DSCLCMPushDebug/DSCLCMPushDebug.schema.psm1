[DSCLocalconfigurationmanager()]
configuration DSCLCMPushDebug
{
    Node $Allnodes.NodeName
    {
        Settings 
        {
            RefreshMode                    = 'PUSH'
            RebootNodeIfNeeded             = $false
            ActionAfterReboot              = 'StopConfiguration'
            RefreshFrequencyMins           = 30
            ConfigurationModeFrequencyMins = 30 
            ConfigurationMode              = 'ApplyAndMonitor'
            DebugMode                      = 'All'
        }
    }
}
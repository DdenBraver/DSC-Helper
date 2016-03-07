configuration DSCLCMPushApplyOnly
{
    Node $Allnodes.NodeName
    {
        LocalConfigurationManager 
        {
            RefreshMode                    = 'PUSH'
            RebootNodeIfNeeded             = $true
            ActionAfterReboot              = 'ContinueConfiguration'
            RefreshFrequencyMins           = 30
            ConfigurationModeFrequencyMins = 30 
            ConfigurationMode              = 'ApplyOnly'
        }
    }
}
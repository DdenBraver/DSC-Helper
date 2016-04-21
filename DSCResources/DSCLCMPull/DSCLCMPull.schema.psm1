[DSCLocalconfigurationmanager()]
configuration DSCLCMPull
{
    Node $Allnodes.NodeName
    {
        Settings 
        {
            RefreshMode                    = 'PULL'
            RebootNodeIfNeeded             = $true
            ActionAfterReboot              = 'ContinueConfiguration'
            RefreshFrequencyMins           = 30
            ConfigurationModeFrequencyMins = 30 
            ConfigurationMode              = 'ApplyAndAutoCorrect'
        }

        ConfigurationRepositoryWeb Pull
	    {
		    ServerURL               = $Node.Pullserverurl
        }
    }
}

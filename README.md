# DSC-Helper

The **DSC-Helper** Module is created to simplify the creation of an environment using PowerShell DSC Resources (PUSH-Method).
This Module contains helper scripts and multiple composite resources to implement Role Based DSC in an easy way.
Do not use this helper in Production out of the box, since it uses unencrypted passwords!

## DSC Requirements
*All relying DSC resources to make use of the DSC Configurations:*
* **Windows Management Framework 5.0**: Required because the PSDSCRunAsCredential DSC Resource parameter is needed.
* **xActiveDirectory**
* **xComputerManagement**
* **xNetworking**
* **xRemoteDesktopSessionHost**
* **xSmbshare**
* **cSQLServer**
* **cFailoverCluster**

## DSC Roles

* **DomainController**
* **DomainJoinOnly**
* **SQLServerCluster**
* **SQLServerClusterAlwaysOn**
* **SQLServerStandAlone**
* **SQLServerStandAloneAlwaysOn**
* **TerminalServer**

## DSC Installers

* **DomainControllers**
* **JoinDomain**
* **SQLManagementStudio**
* **SQLServerCluster**
* **SQLServerClusterAlwaysOn**
* **SQLServerStandAlone**
* **SQLServerStandAloneAlwaysOn**
* **TerminalServer**

## DSC LCM Helpers
* **Push**
* **PushApplyOnly**
* **PushDebug**

## DSC Helper Functions
* **Get-ConfigurationData**
* **Show-Dropdownbox**
* **Push-DSCRoleConfiguration**
* **Send-File**
* **Trace-Reboot**
* **Install-RemoteMSI**
* **Install-RemoteCertificate**
* **Remove-Host**
* **Add-Host**
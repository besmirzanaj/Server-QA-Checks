﻿<#
    DESCRIPTION: 
        Ensure the system is set to reject attempts to enumerate accounts in the SAM by anonymous users.


    
    PASS:    Reject annonymous account enumeration is enabled
    WARNING:
    FAIL:    Reject annonymous account enumeration is disabled / Registry setting not found
    MANUAL:
    NA:

    APPLIES: All

    REQUIRED-FUNCTIONS:
#>

Function c-sec-06-reject-enumerate-accounts
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Reject Annonymous Account Enumeration'
    $result.check  = 'c-sec-06-reject-enumerate-accounts'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        $reg    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $serverName)
        $regKey = $reg.OpenSubKey('SYSTEM\CurrentControlSet\Control\Lsa')
        If ($regKey) { $keyVal = $regKey.GetValue('restrictanonymousSAM') }
        Try { $regKey.Close() } Catch { }
        $reg.Close()
    }
    Catch
    {
        $result.result  = 'Error'
        $result.message = 'SCRIPT ERROR'
        $result.data    = $_.Exception.Message
        Return $result
    }

    If ([string]::IsNullOrEmpty($keyVal) -eq $false)
    {
        If ($keyVal -eq $script:appSettings['RejectAnnonymousAccountEnumeration'])
        {
            $result.result  = 'Pass'
            $result.message = 'Reject annonymous account enumeration is enabled'
        }
        Else
        {
            $result.result  = 'Fail'
            $result.message = 'Reject annonymous account enumeration is disabled'
        }
    }
    Else
    {
        $result.result  = 'Fail'
        $result.message = 'Registry setting not found'
        $result.data    = ''
    }
    
    Return $result
}
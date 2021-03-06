﻿<#
    DESCRIPTION: 
        Ensure autorun is disabled.



    PASS:    Autorun is disabled
    WARNING:
    FAIL:    Autorun is enabled
    MANUAL:
    NA:

    APPLIES: All

    REQUIRED-FUNCTIONS:
#>

Function c-sys-11-autorun-disabled
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Drive Autorun'
    $result.check  = 'c-sys-11-autorun-disabled'

    #... CHECK STARTS HERE ...#

    Try
    {
        $reg    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $serverName)
        $regKey = $reg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer')
        If ($regKey) { $keyVal = $regKey.GetValue('NoDriveTypeAutoRun') }
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
        If ($keyVal -eq '255')
        {
            $result.result  = 'Pass'
            $result.message = 'Autorun is disabled'
        }
        Else
        {
            $result.result  = 'Fail'
            $result.message = 'Autorun is enabled'
        }
    }
    Else
    {
        $result.result  = 'Fail'
        $result.message = 'Autorun is enabled'
    }

    Return $result
}
﻿<#
    DESCRIPTION: 
        Ensure security ciphers are set correctly.  Settings taken from https://www.nartac.com/Products/IISCrypto/Default.aspx using "Best Practices/FIPS 140-2" settings



    PASS:    All ciphers set correctly
    WARNING:
    FAIL:    One or more ciphers set incorrectly
    MANUAL:
    NA:

    APPLIES: All

    REQUIRED-FUNCTIONS:
#>

Function c-sec-01-schannel-p1-ciphers
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Security Settings 1: Ciphers'
    $result.check  = 'c-sec-01-schannel-p1-ciphers'

    #... CHECK STARTS HERE ...#

    Try
    {
        $disabled = $true
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $serverName)

        For ($i = 0; $i -lt 2; $i++)
        {
            If ($i -eq 0) { $regPathCheck = $script:appSettings['EnabledCiphers'];  $regValue = 0xFFFFFFFF; $regResult = 'Enabled'  }
            If ($i -eq 1) { $regPathCheck = $script:appSettings['DisabledCiphers']; $regValue = 0;          $regResult = 'Disabled' }

            ForEach ($key In $regPathCheck)
            {
                $regKey = $reg.OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\' + $key)
                If ([string]::IsNullOrEmpty($keyKey) -eq $false)
                {
                    $keyVal = $regKey.GetValue('Enabled')
                    If ($keyVal -ne $regValue)
                    {
                        $disabled     = $false
                        $result.data += '{0} (Should be {1}),#' -f $key, $regResult
                    }        
                }
                Else
                {
                    # Only show MISSING for ciphers that should be disabled
                    If ($i -eq 1)
                    {
                        $disabled     = $false
                        $result.data += '{0} (Missing, should be {1}),#' -f $key, $regResult
                    }
                }
                Try { $regKey.Close() } Catch { }
            }
        }
        $reg.Close()
    }
    Catch
    {
        $result.result  = 'Error'
        $result.message = 'SCRIPT ERROR'
        $result.data    = $_.Exception.Message
        Return $result
    }

    If ($disabled -eq $true)
    {
        $result.result  = 'Pass'
        $result.message = 'All ciphers set correctly'
    }
    Else
    {
        $result.result  = 'Fail'
        $result.message = 'One or more ciphers set incorrectly'
    }

    Return $result
}
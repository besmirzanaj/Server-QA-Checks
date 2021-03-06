﻿<#
    DESCRIPTION: 
        Check windows is licensed.



    PASS:    Windows is licenced, Port 1688 open to KMS Server {0}
    WARNING:
    FAIL:    Windows is licenced, Port 1688 not open to KMS Server {0} / Windows licence check failed / Windows not licenced
    MANUAL:
    NA:

    APPLIES: All

    REQUIRED-FUNCTIONS: Test-Port
#>

Function c-sys-02-windows-license
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Windows License'
    $result.check  = 'c-sys-02-windows-license'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        If ((Get-WmiObject -ComputerName $serverName -Namespace ROOT\Cimv2 -List 'SoftwareLicensingProduct').Name -eq 'SoftwareLicensingProduct')
        {
            [string]$query1 = 'SELECT LicenseStatus FROM SoftwareLicensingProduct WHERE ApplicationID="55c92734-d682-4d71-983e-d6ec3f16059f" AND NOT LicenseStatus = "0"'
            [array] $check1 = Get-WmiObject -ComputerName $serverName -Query $query1 -Namespace ROOT\Cimv2 | Select-Object -ExpandProperty LicenseStatus
        }

        If ((Get-WmiObject -ComputerName $serverName -Namespace ROOT\Cimv2 -List 'SoftwareLicensingService').Name -eq 'SoftwareLicensingService')
        {
            [string]$query2 = "SELECT KeyManagementServiceMachine, DiscoveredKeyManagementServiceMachineName FROM SoftwareLicensingService"
            [object]$check2 = Get-WmiObject -ComputerName $serverName -Query $query2 -Namespace ROOT\Cimv2 | Select KeyManagementServiceMachine, DiscoveredKeyManagementServiceMachineName
        }
    }
    Catch
    {
        $result.result  = 'Error'
        $result.message = 'SCRIPT ERROR'
        $result.data    = $_.Exception.Message
        Return $result
    }

    [string]$kms    = ''
    [string]$status = ''
    If ($check1.Count -gt 0)
    {
        Switch ($check1[0])
        {
                  1 { $status = 'Licensed';                      Break }    # <-- Requried for PASS
                  2 { $status = 'Out-Of-Box Grace Period';       Break }
                  3 { $status = 'Out-Of-Tolerance Grace Period'; Break }
                  4 { $status = 'Non-Genuine Grace Period';      Break }
                  5 { $status = 'Notification';                  Break }
                  6 { $status = 'Extended Grace';                Break }
            Default { $status = 'Unknown'                              }
        }
    }
    Else
    {
        $status = 'Not Licensed'
    }    

    If ($check2.DiscoveredKeyManagementServiceMachineName -ne '') { $kms = $check2.DiscoveredKeyManagementServiceMachineName }
    If ($check2.KeyManagementServiceMachine               -ne '') { $kms = $check2.KeyManagementServiceMachine               }

    If ($kms -ne '')
    {
        [boolean]$portTest = Test-Port -serverName $kms -Port 1688
        If ($portTest -eq $true)
        {
            $result.result  = 'Pass'
            $result.message = (',#Port 1688 open to KMS Server {0}' -f $kms)
        }
        Else
        {
            $result.result  = 'Fail'
            $result.message = (',#Port 1688 not open to KMS Server {0}' -f $kms)
        }
    }
    Else
    {
        $result.result  = 'Warning'
        $result.message = ',#Not using a KMS server'
    }

    If ($status -eq 'Licensed')
    {
        $result.message = ('Windows is licenced' + $result.message)
        $result.data    = ''
    }
    ElseIf ($status -eq '')
    {
        $result.result  = 'Fail'
        $result.message = ('Windows licence check failed' + $result.message)
        $result.data    = ''
    }
    Else
    {
        $result.result  = 'Fail'
        $result.message = ('Windows not licenced' + $result.message)
        $result.data    = 'Status: {0}' -f $status
    }

    Return $result
}
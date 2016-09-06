﻿<#
    DESCRIPTION: 
        Check services and ensure all listed services are set to disabled and are stopped



    PASS:    All services are configured correctly
    WARNING:
    FAIL:    One or more services are configured incorrectly
    MANUAL:
    NA:

    APPLIES: All

    REQUIRED-FUNCTIONS:
#>

Function c-sys-04-services-not-stopped
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Services Not Stopped'
    $result.check  = 'c-sys-04-services-not-stopped'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$query = 'SELECT DisplayName, StartMode, State FROM Win32_Service WHERE DisplayName = "null"'
        $script:appSettings['CheckTheseServices'] | ForEach { $query += ' OR DisplayName = "{0}"' -f $_ }
        [array]$check = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Cimv2 | Select-Object DisplayName, StartMode, State
    }
    Catch
    {
        $result.result  = 'Error'
        $result.message = 'SCRIPT ERROR'
        $result.data    = $_.Exception.Message
        Return $result
    }

    If ($check.Count -gt 0)
    {
        ForEach ($service In $check)
        {
            $st = ''; $sm = ''
            If ($service.State     -ne 'Stopped' ) { $st = $service.State     }
            If ($service.StartMode -ne 'Disabled') { $sm = $service.StartMode }
            If (($st -ne '') -or ($sm -ne ''))     { $result.data += '{0} ({1}/{2}),#' -f $service.DisplayName, $sm, $st }
        }

        If ($result.data.Length -gt 1)
        {
            $result.result  = 'Fail'
            $result.message = 'One or more services are configured incorrectly'
        }
        Else
        {
            $result.result  = 'Pass'
            $result.message = 'All services are configured correctly'
        }
    }
    Else
    {
        $result.result  = 'Pass'
        $result.message = 'All services are configured correctly'
    }
    
    Return $result
}
﻿<#
    DESCRIPTION: 
        Check Hyper-V is the only one installed



    PASS:    No extra server roles or features exist
    WARNING:
    FAIL:    One or more extra server roles or features exist
    MANUAL:
    NA:      Not a Hyper-V server

    APPLIES: Hyper-V Hosts

    REQUIRED-FUNCTIONS: Check-NameSpace
#>

Function c-hvh-02-no-other-server-roles
{
    Param ( [string]$serverName, [string]$resultPath )

    # Default Result Object
    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'No Other Server Roles'
    $result.check  = 'c-hvh-02-no-other-server-roles'
 
    # ...
    If ((Check-NameSpace -serverName $serverName -namespace 'virtualization') -and (Check-NameSpace -serverName $serverName -namespace 'virtualization\v2') -eq $true)
    {
        Try
        {
            # This will need to be change to use "Get-WindowsFeature" in 2012+
            [string]$query = "Select Name, ID FROM Win32_ServerFeature WHERE ParentID = '0'"
            [array] $check = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Cimv2
            [System.Collections.ArrayList]$check2 = @()
            $check | ForEach { $check2 += $_ }

            ForEach ($ck In $check)
            {
                ForEach ($exc In $script:appSettings['IgnoreTheseRoleIDs'])
                {
                    If ($ck.ID -eq $exc) { $check2.Remove($ck) }
                }
            }
        }
        Catch
        {
            $result.result  = 'Error'
            $result.message = 'SCRIPT ERROR'
            $result.data    = $_.Exception.Message
            Return $result
        }

        If ($check2.Count -ne 0)
        {
            $result.result  = 'Fail'
            $result.message = 'One or more extra server roles or features exist'
            $check2 | ForEach { $result.data += '{0},#' -f $_.Name }
        }
        Else
        {
            $result.result  = 'Pass'
            $result.message = 'No extra server roles or features exist'
        }
    }
    Else
    {
        $result.result  = 'N/A'
        $result.message = 'Not a Hyper-V server'
    }

    Return $result
}
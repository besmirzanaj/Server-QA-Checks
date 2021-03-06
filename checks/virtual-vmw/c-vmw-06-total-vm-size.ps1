﻿<#
    DESCRIPTION: 
        Checks to see if the total VM size is less than 1tb

        

    PASS:    VM is smaller than 1TB
    WARNING: VM is larger than 1TB.  Make sure there is an engineering exception in place for this
    FAIL:
    MANUAL:
    NA:      Not a virtual machine

    APPLIES: Virtuals

    REQUIRED-FUNCTIONS: Check-VMware
#>

Function c-vmw-06-total-vm-size
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Total VM Size'
    $result.check  = 'c-vmw-06-total-vm-size'

    #... CHECK STARTS HERE ...#

    If ((Check-VMware $serverName) -eq $true)
    {
        Try
        {
            [string]$query = "SELECT Size FROM Win32_LogicalDisk WHERE DriveType = '3'"
            [array] $check = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Cimv2 | Select-Object -ExpandProperty Size
        }
        Catch
        {
            $result.result  = 'Error'
            $result.message = 'SCRIPT ERROR'
            $result.data    = $_.Exception.Message
            Return $result
        }

        [int]$size = 0
        $check | ForEach { $size += ($_ / 1GB) }
        If ($size -gt '1023')
        {
            $result.result  = 'Warning'
            $result.message = 'VM is larger than 1TB.  Make sure there is an engineering exception in place for this'
            $result.data    = $size.ToString() + ' GB'
        }
        Else
        {
            $result.result  = 'Pass'
            $result.message = 'VM is smaller than 1TB'
            $result.data    = $size.ToString() + ' GB'
        }
    }
    Else
    {
        $result.result  = 'N/A'
        $result.message = 'Not a virtual machine'
    }

    Return $result
}
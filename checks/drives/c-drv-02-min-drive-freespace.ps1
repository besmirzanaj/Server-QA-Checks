﻿<#
    DESCRIPTION: 
        Ensure all drives have a minimum % of free space.  The default value is 17%



    PASS:    All drives have the required minimum free space of {0}%
    WARNING:
    FAIL:    One or more drives were found with less than {0}% free space
    MANUAL:  Unable to get drive information, please check manually
    NA:

    APPLIES: All

    REQUIRED-FUNCTIONS:
#>

Function c-drv-02-min-drive-freespace
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = 'Min Drive % Freespace'
    $result.check  = 'c-drv-02-min-drive-freespace'
 
    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$query = 'SELECT * FROM Win32_LogicalDisk WHERE DriveType = "3"'    # Filter on DriveType = 3 (Fixed Drives)
        $script:appSettings['IgnoreTheseDrives'] | ForEach { $query += ' AND NOT Name = "{0}"' -f $_ }
        [array]$check = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Cimv2 | Select-Object Name, FreeSpace, Size
    }
    Catch
    {
        $result.result  = 'Error'
        $result.message = 'SCRIPT ERROR'
        $result.data    = $_.Exception.Message
        Return $result
    }

    $countFailed = 0
    If ($check -ne $null)
    {
        ForEach ($drive In $check)
        {
            $free = $drive.FreeSpace
            $size = $drive.Size
            If ($size -ne $null)
            {
                $percentFree  = [decimal]::Round(($free / $size) * 100)
                $result.data += $drive.Name + ' (' + $percentFree + '% free),#'
                If ($percentFree -lt $script:appSettings['MinimumDrivePercentFree']) { $countFailed += 1 }
            }
        }
    
        If ($countFailed -ne 0)
        {
            $result.result  = 'Fail'
            $result.message = 'One or more drives were found with less than ' + $script:appSettings['MinimumDrivePercentFree'] + '% free space'
        }
        Else
        {
            $result.result  = 'Pass'
            $result.message = 'All drives have the required minimum free space of ' + $script:appSettings['MinimumDrivePercentFree'] + '%'
        }
    }
    Else
    {
        $result.result  = 'Manual'
        $result.message = 'Unable to get drive information, please check manually'
        $result.data    = 'All drives need to have ' + $script:appSettings['MinimumDrivePercentFree'] + '% or more free'
    }
    Return $result
}
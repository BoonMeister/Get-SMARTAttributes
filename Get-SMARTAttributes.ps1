$ModuleName = "SMARTData"
If ((Get-Module).Name -contains $ModuleName) {Remove-Module -Name $ModuleName}
New-Module -Name $ModuleName -ScriptBlock {
    $AliasName = "gsa"
    Function Get-SMARTAttributes {
    <#
        .SYNOPSIS
            Retrieves hard drive SMART attributes
        .DESCRIPTION
            The Get-SMARTAttributes function can be used to retrieve SMART (Self-Monitoring, Analysis
            and Reporting Technology) attributes from one or more hard drives on the local computer by
            querying the MSStorageDriver_ATAPISmartData & MSStorageDriver_FailurePredictThresholds
            classes, provided SMART is supported and enabled on the drive(s). The results include the
            attribute ID, attribute name, current/worse/threshold values, status (current > threshold),
            the raw value and a converted 'real value' for selected attributes (e.g. temperature).
            The function must be run as Admin or with an account that has the necessary privileges.

            Advisory: Whilst great care has gone into making this function as accurate as possible, 
            due to the variance of SMART attribute definitions and measurements between different 
            manufacturers you are advised to thoroughly test it before use, as drives may use different 
            codes for the same attribute or vice versa. The ID to attributes hash table in this function 
            has been taken from the SMART page on wikipedia with the intention of being the best possible 
            fit for common/general use, but for true clarification you are highly encouraged to check
            with your vendor for details on their SMART implementation. This function was mainly tested
            on Seagate & Samsung SATA drives and the results compared against several different programs
            to determine accuracy, such as CrystalDiskInfo, Speccy & smartmontools/smartctl.
        .PARAMETER DiskIndex
            The index number of a disk to query. This is the number detailed in diskmgmt,
            diskpart or a related PowerShell function/command such as Get-Disk on Win10.
        .PARAMETER SerialNumber
            The serial number of a disk to query. This is an alternative filtering
            parameter to the disk index.
        .INPUTS
            System.Int32, System.String
            You can pipe an object to this function with a valid property name & type
            representing either the disk index or serial number.
        .OUTPUTS
            System.Management.Automation.PSCustomObject
            This function generates an array of PsObjects with each object
            representing a different SMART attribute
        .NOTES
            Release Date: 2018-06-22
            Author: Francis Hagyard
        .EXAMPLE
            Get-SMARTAttributes -DiskIndex 0

            This command gets the SMART attributes of the disk with index 0
        .EXAMPLE
            Get-SMARTAttributes -SerialNumber "S2Y9NB0J636098" | Format-Table

            This command gets the SMART attributes of the disk by serial and formats the results as a table
        .EXAMPLE
            Get-Disk | Get-SMARTAttributes | Format-Table

            This commands pipes the objects from the Get-Disk function to get the SMART attributes of all
            disks on the system provided they are all supported
        .EXAMPLE
            Get-CimInstance -ClassName Win32_DiskDrive | Get-SMARTAttributes | Format-Table

            This command behaves the same as the last example but is for pre-Windows 10 systems that do
            not have the Get-Disk function available. You can also use 'Get-WmiObject -Class Win32_DiskDrive'
            for systems with PowerShell version 1 or 2.
        .LINK
            Project page: https://github.com/BoonMeister/Get-SMARTAttributes
    #>
        [CmdletBinding(DefaultParameterSetName="Index",
                        PositionalBinding=$True,
                        HelpUri="https://github.com/BoonMeister/Get-SMARTAttributes")]
        [OutputType("System.Management.Automation.PSCustomObject")]
        Param(
            [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName="Index",Position=0)]
            [Alias("Index","Number","DiskNumber")]
            [int]$DiskIndex,
            [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName="Serial")]
            [Alias("Serial Number","Serial")]
            [string]$SerialNumber
        )
        Begin {
            $RealValueArray = @(3,4,5,9,10,12,171,172,173,174,176,177,179,180,181,182,183,184,187,188,189,190,193,194,196,197,198,199,235,240,241,242,243)
            $AttIDToName = @{
                1 = 'RawReadErrorRate'
                2 = 'ThroughputPerformance'
                3 = 'SpinUpTime'
                4 = 'StartStopCount'
                5 = 'ReallocatedSectorCount'
                6 = 'ReadChannelMargin'
                7 = 'SeekErrorRate'
                8 = 'SeekTimePerformance'
                9 = 'PowerOnHoursCount'
                10 = 'SpinRetryCount'
                11 = 'CalibrationRetryCount'
                12 = 'PowerCycleCount'
                170 = 'AvailableReservedSpace'
                171 = 'ProgramFailCount'
                172 = 'EraseFailCount'
                173 = 'WearLevelingCount'
                174 = 'UnexpectedPowerLoss'
                175 = 'PowerLossProtectionFailure'
                176 = 'EraseFailCount(Chip)'
                177 = 'WearRangeDelta'
                179 = 'UsedReservedBlockCountTotal'
                180 = 'UnusedReservedBlockCountTotal'
                181 = 'ProgramFailCountTotal'
                182 = 'EraseFailCount'
                183 = 'RuntimeBadBlockTotal'
                184 = 'EndToEndError'
                185 = 'HeadStability'
                186 = 'InducedOpVibrationDetection'
                187 = 'UncorrectableErrorCount'
                188 = 'CommandTimeout'
                189 = 'HighFlyWrites'
                190 = 'AirflowTemperature'
                191 = 'G-senseErrorRate'
                192 = 'PoweroffRetractCount'
                193 = 'LoadCycleCount'
                194 = 'Temperature'
                195 = 'HardwareECCRecovered'
                196 = 'ReallocationEventCount'
                197 = 'CurrentPendingSectorCount'
                198 = 'OfflineUncorrectableSectorCount'
                199 = 'UltraDMACRCErrorCount'
                200 = 'Multi-ZoneErrorRate'
                201 = 'SoftReadErrorRate'
                202 = 'DataAddressMarkErrors'
                203 = 'RunOutCancel'
                204 = 'SoftECCCorrection'
                205 = 'ThermalAsperityRate'
                206 = 'FlyingHeight'
                207 = 'SpinHighCurrent'
                208 = 'SpinBuzz'
                209 = 'OfflineSeekPerformance'
                210 = 'VibrationDuringWrite'
                211 = 'VibrationDuringWrite'
                212 = 'ShockDuringWrite'
                220 = 'DiskShift'
                221 = 'G-SenseErrorRate'
                222 = 'LoadedHours'
                223 = 'Load/UnloadRetryCount'
                224 = 'LoadFriction'
                225 = 'Load/UnloadCycleCount'
                226 = 'LoadInTime'
                227 = 'TorqueAmplificationCount'
                228 = 'Power-OffRetractCycle'
                230 = 'GMRHeadAmplitude/DriveLifeProtectionStatus'
                231 = 'LifeLeft'
                232 = 'EnduranceRemaining/AvailableReservedSpace'
                233 = 'MediaWearoutIndicator'
                234 = 'Average/MaximumEraseCount'
                235 = 'Good/FreeBlockCount'
                240 = 'HeadFlyingHours'
                241 = 'TotalLBAsWritten'
                242 = 'TotalLBAsRead'
                243 = 'TotalLBAsWrittenExpanded'
                244 = 'TotalLBAsReadExpanded'
                249 = 'NANDWrites'
                250 = 'ReadErrorRetryRate'
                251 = 'MinimumSparesRemaining'
                252 = 'NewlyAddedBadFlashBlock'
                254 = 'FreeFallProtection'
            }
        }
        Process {
            # Determine disk
            If ($PSBoundParameters.ContainsKey("DiskIndex")) {$FilterQuery = "Index = '$DiskIndex'"}
            ElseIf ($PSBoundParameters.ContainsKey("SerialNumber")) {$FilterQuery = "SerialNumber = '$SerialNumber'"}
            Else {$FilterQuery = "Index = '$DiskIndex'"}
            Try {$SelectedDisk = Get-CimInstance -ClassName Win32_DiskDrive -Filter $FilterQuery -ErrorAction Stop}
            Catch {Throw "An exception has occurred - The latest error in the stream is:`r`n'$($Error[0].Exception)'"}
            If (($SelectedDisk | Measure).Count -eq 0) {Throw "No disk was found that matched the filter query '$FilterQuery'"}
            ElseIf (($SelectedDisk | Measure).Count -gt 1) {Throw "More than one disk was found that matched the filter query '$FilterQuery'"}
            Else {
                # Get SMART & threshold data
                Try {
                    $SMARTAttributeData = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_ATAPISmartData -ErrorAction Stop | Where {$_.InstanceName -like "*$($SelectedDisk.PNPDeviceID)*"}
                    $ThresholdData = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictThresholds -ErrorAction Stop | Where {$_.InstanceName -like "*$($SelectedDisk.PNPDeviceID)*"}
                }
                Catch {Throw "An exception has occurred - The latest error in the stream is:`r`n'$($Error[0].Exception)'"}
            }
            If (($SMARTAttributeData | Measure).Count -eq 0) {Throw "Could not retrieve SMART data for the specified disk. Please ensure the disk is capable and SMART is enabled"}
            ElseIf (($SMARTAttributeData | Measure).Count -eq 1) {
                # Select threshold data and determine loop count
                $AttributeThresholds = ($ThresholdData.VendorSpecific)[2..($ThresholdData.VendorSpecific.Count - 1)]
                $ThresholdLoopCount = [System.Math]::Floor($AttributeThresholds.Count/12)
                $AttIDToThreshold = @{}
                # Create hash table of attribute IDs to threshold values
                For ($ThreshIterate = 0; $ThreshIterate -lt $ThresholdLoopCount; $ThreshIterate++) {
                    If ($AttributeThresholds[($ThreshIterate*12)] -ne 0) {
                        $AttIDToThreshold.Add($AttributeThresholds[($ThreshIterate*12)],$AttributeThresholds[($ThreshIterate*12+1)])
                    }
                }
                # Select SMART data and determine loop count
                $VendorSpecData = $SMARTAttributeData.VendorSpecific
                $AttLoopCount = [System.Math]::Floor($VendorSpecData.Count/12)
                $StartIndex,$EndIndex = 1,12
                $ResultArray = @()
                # Construct data 
                For ($AttIterate = 0; $AttIterate -lt $AttLoopCount; $AttIterate++) {
                    $CurrentAtt = $VendorSpecData[$StartIndex..$EndIndex]
                    If ($CurrentAtt[1] -ne 0) {
                        $RawValue = [System.BitConverter]::ToString([byte[]]($CurrentAtt[11],$CurrentAtt[10],$CurrentAtt[9],$CurrentAtt[8],$CurrentAtt[7],$CurrentAtt[6])) -replace "-"
                        $AttributeIDHex = "0x" + [System.BitConverter]::ToString([byte]$CurrentAtt[1])
                        $ThresholdValue = $AttIDToThreshold.([byte]$CurrentAtt[1])
                        If ($CurrentAtt[4] -ge $ThresholdValue) {$ThresholdStatus = "OK"}
                        Else {$ThresholdStatus = "FAIL"}
                        If ($AttIDToName.ContainsKey([int]$CurrentAtt[1])) {$AttributeName = $AttIDToName.([int]$CurrentAtt[1])}
                        Else {$AttributeName = "VendorSpecific/Unknown"}
                        # Real values
                        If ($RealValueArray -contains [int]$CurrentAtt[1]) {
                            If (9,240 -contains [int]$CurrentAtt[1]) {$RawInt = [System.Convert]::ToInt64($RawValue.Substring(4),16)}
                            Else {$RawInt = [System.Convert]::ToInt64($RawValue,16)}
                            Switch ([int]$CurrentAtt[1]) {
                                3 { # Spin up time
                                    $RealValue = "$RawInt ms"
                                    Break
                                }
                                9 { # Power on hours
                                    $TimeSpan = [timespan]::FromDays($RawInt/24)
                                    $RealValue = "$($TimeSpan.Days)d $($TimeSpan.Hours)h"
                                    Break
                                }
                                190 { # Airflow temperature
                                    $RealValue = "$($CurrentAtt[6])C"
                                    If (($CurrentAtt[8] -gt 0) -and ($CurrentAtt[9] -gt 0)) {$RealValue += " (Min=$($CurrentAtt[8]),Max=$($CurrentAtt[9]))"}
                                    Break
                                }
                                194 { # Temperature
                                    $RealValue = "$($CurrentAtt[6])C"
                                    If (($CurrentAtt[7] -gt 0) -and ($CurrentAtt[8] -gt 0)) {$RealValue += " (Min=$($CurrentAtt[7]),Max=$($CurrentAtt[8]))"}
                                    Break
                                }
                                240 { # Head flying hours
                                    $TimeSpan = [timespan]::FromDays($RawInt/24)
                                    $RealValue = "$($TimeSpan.Days)d $($TimeSpan.Hours)h"
                                    Break
                                }
                                Default {
                                    $RealValue = $RawInt.ToString('N0')
                                    Break
                                }
                            }
                        }
                        Else {$RealValue = "0"}
                        # Create object and add to final array
                        $AttributeObj = New-Object PsObject
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name SerialNo -Value "$($SelectedDisk.SerialNumber.Trim())"
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name Index -Value "$($SelectedDisk.Index)"
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name AttID -Value "$AttributeIDHex"
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name AttName -Value $AttributeName
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name RealValue -Value $RealValue
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name Current -Value "$($CurrentAtt[4])"
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name Worst -Value "$($CurrentAtt[5])"
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name Threshold -Value "$($ThresholdValue)"
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name Status -Value $ThresholdStatus
                        $AttributeObj | Add-Member -MemberType NoteProperty -Name RawValue -Value $RawValue
                        $ResultArray += $AttributeObj
                    }
                    $StartIndex += 12
                    $EndIndex += 12
                }
                $ResultArray
            }
        }
    }
    Set-Alias -Name $AliasName -Value Get-SMARTAttributes
    Export-ModuleMember -Function Get-SMARTAttributes -Alias $AliasName
} | Import-Module
Get-Module -Name $ModuleName

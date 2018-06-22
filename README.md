# Get-SMARTAttributes

SYNOPSIS
--------
Retrieves hard drive SMART attributes

DESCRIPTION
-----------
The Get-SMARTAttributes function can be used to retrieve SMART (Self-Monitoring, Analysis
and Reporting Technology) attributes from one or more hard drives on a computer by
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

SYNTAX
------
    Get-SMARTAttributes -DiskIndex <Int32>
    Get-SMARTAttributes -SerialNumber <String>

PARAMETERS
----------
-DiskIndex (Int32)

The index number of a disk to query. This is the number detailed in diskmgmt,
diskpart or a related PowerShell function/command such as Get-Disk on Win10.

-SerialNumber (String)

The serial number of a disk to query. This is an alternative filtering
parameter to the disk index.

-ComputerName (String)

The name or IP address of a computer to query. The default is the local PC.

INPUTS
------
System.Int32, System.String

You can pipe an object to this function with a valid property name & type
representing either the disk index or serial number.

OUTPUTS
-------
System.Management.Automation.PSCustomObject

This function generates an array of PsObjects with each object
representing a different SMART attribute

EXAMPLES
--------

- Get attributes of disk with index 0:

      Get-SMARTAttributes -DiskIndex 0

- Get attributes of disk by serial and format results as a table:

      Get-SMARTAttributes -SerialNumber "S2Y9NB0J636098" | Format-Table

- Pipe results/objects from Get-Disk to get attributes of all disks on system, provided they are all supported:

      Get-Disk | Get-SMARTAttributes | Format-Table

- Same as last example for pre-Windows 10 systems or for PowerShell version 1/2:

      Get-WmiObject -Class Win32_DiskDrive | Get-SMARTAttributes | Format-Table

NOTES
-----
Release Date: 2018-06-22

Author: Francis Hagyard

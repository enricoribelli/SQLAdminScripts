# Imports ===============================================================================================================================
import-module dbatools;

# =======================================================================================================================================
# 
# 	Author			: Lutfi Uzun
# 	Create date		: 22 januari 2020
# 	Description		: Use this script to find and replace sql names in stored procedures and views 
# 				      First create a generate script from database in SQL Server Management Studio
# 					  Then add keys to replace the values like below
# 					  after wards run the script
# =======================================================================================================================================

Function StartMigration($params)
{

    $p = [PSCustomObject]@{
        Source         = $params.Source
        Destination    = $params.Destination 
        Databases      = $params.Databases
        SharedPath     = $params.SharedPath
        Jobs           = $params.Jobs
        LinkedServers  = $params.LinkedServers
        ExcludeLogin   = 
            'NT AUTHORITY\SYSTEM',
            'NT Service\MSSQLSERVER',
            'NT SERVICE\SQLSERVERAGENT',
            'NT SERVICE\SQLWriter',
            'NT SERVICE\Winmgmt', 
            '##MS_PolicyEventProcessingLogin##', 
            '##MS_PolicyTsqlExecutionLogin##'
        LoginUsers     = $params.LoginUsers
        ProcessMails   = $params.ProcessMails
    }
    
    # ======================================================================================================================================
    # Do not change below unless you know what your dowing =================================================================================
    # ======================================================================================================================================
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host ">> Is running as user: $user" -ForegroundColor Yellow

    # start stop watch
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()

    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    POST migration tasks
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # stop jobs
    # Stop-DbaService -ComputerName $p.source -Type Agent
    # Before migrate stop usage of database by setting database in read only
    # Set-DbaDbState -SqlInstance $p.source -Database $p.Databases -ReadOnly 

    # -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    Migrate logins
    # -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Get-DbaLogin -SqlInstance dev5ams8 -ExcludeSystemLogin -ExcludeLogin $ExcludeLogin | Out-GridView
    Copy-DbaLogin -Source $p.Source -Destination $p.Destination -ExcludeSystemLogins -KillActiveConnection -Force -Login $p.LoginUsers -ExcludeLogin $p.ExcludeLogin 


    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    Migration of mails
    # 
    #    Migrates Mail Profiles, Accounts, Mail Servers and Mail Server Configs from one SQL Server to another.
    #    Copies all database mail objects from $SrcSQLInstance to $DestSQLInstance using Windows credentials. If database mail objects with the same name exist on $DestSQLInstance, they will be skipped.
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if ($p.ProcessMails -eq $true)
    {
        Copy-DbaDbMail -Source $p.Source -Destination $p.Destination
    }


    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    Migration databases
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Copy-DbaDatabase -Source $p.Source -Destination $p.Destination -Database $p.Databases -BackupRestore -SharedPath $p.SharedPath -WithReplace -Force # -SetSourceReadOnly 
    # Set-DbaDbOwner -SqlInstance $p.Destination -Database $p.Databases -TargetLogin 'BIS-IS\lutuzu'


    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    Migration of database JOBS 
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if ($p.jobs -ne $null)
    {
        # Copies all operators from sqlserver2014a to sqlcluster using Windows credentials. If operators with the same name exist on sqlcluster, they will be skipped.
	    Copy-DbaAgentOperator -Source $p.Source -Destination $p.Destination
	    #Copies all operator categories from $p.Source to $p.Destination using Windows authentication. If operator categories with the same name exist on sqlcluster, they will be skipped.
	    Copy-DbaAgentJobCategory -Source $p.Source -Destination $p.Destination 
	    #copies list of jobs in $jobs
	    Copy-DbaAgentJob -Source $p.Source -Destination $p.Destination -Job $p.jobs
    } else {
        Write-Output 'No sql agent jobs given, skipped task copy jobs, operators, job categories.';
    }


    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    Migration of linked servers
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if ($p.LinkedServers -ne $null)
    {
        Copy-DbaLinkedServer -Source $p.Source -Destination $p.Destination -LinkedServer $p.LinkedServers -Force
    } else {
        Write-Output 'No linkedServers given, skipped task copy linked servers.';
    }


    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    After migration repair orphanUser 
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Get-DbaDbOrphanUser -SqlInstance $p.Destination -Database $p.Databases
    Repair-DbaDbOrphanUser -SqlInstance $p.Destination -Database $p.Databases

    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #    POST migration tasks
    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # Get list of database in source and make them read/write 
    # Set-DbaDbState -SqlInstance $p.Source -Database $p.Databases -ReadWrite

    # start jobs again
    # Start-DbaService -ComputerName $p.Source -Type Agent

    # stop stopwatch and give info
    $totalMins =  [math]::Round($stopwatch.Elapsed.TotalMinutes,0)
    write-host 'This process took: ' $totalMins 'Minutes to complete'

    # stop stopwatch
    $stopwatch.Stop()

}

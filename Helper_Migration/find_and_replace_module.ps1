# =======================================================================================================================================
# 
# 	Author			: Lutfi Uzun
# 	Create date		: 03 february 2020
# 	Description		: Use this script to find and replace sql names in stored procedures and views 
# 				      First create a generate script from database in SQL Server Management Studio
# 					  Then add keys to replace the values like below
# 					  after wards run the script
# =======================================================================================================================================

Function FindAndReplace($params)
{    

	$p = [PSCustomObject]@{
        Source              = "$PSScriptRoot\$params.Source" 
        Destination         = "$PSScriptRoot\$params.Destination" 
		KeyDictionary       = $params.KeyDictionary
		KeyDictionarySimple = $params.KeyDictionarySimple
    }

    if ($psISE)
    {
        $p.Source = $(Split-Path -Path $psISE.CurrentFile.FullPath) + '\'
        $p.Source +=  $params.Source
        $p.Destination = (Split-Path -Path $psISE.CurrentFile.FullPath) + '\'
        $p.Destination += $params.Destination
    }
    else
    {
        $p.Source = $global:PSScriptRoot + '\' + $params.Source
        $p.Destination = "$global:PSScriptRoot\$params.Destination"
    }

	Write-Output "Source file      : $($p.Source)"
	Write-Output "Destination file : $($p.Destination)"

	if (!(Test-Path $p.Source)) {
		Write-Error "Missing source file in target path: $p.Source."
	} else { 
	
		$file = (Get-Content -path $p.Source)
	
		foreach ($key in $p.KeyDictionary.Keys) {    

			$file = $file.replace(".[$key].", ".[$($p.KeyDictionary.Item($key))]." )

			$file = $file.replace(" [$key].", " [$($p.KeyDictionary.Item($key))]." )
        
			$file = $file.replace("$Tab[$key].", "$Tab[$($p.KeyDictionary.Item($key))]." )
               
			$file = $file.replace(" $key.", " $($p.KeyDictionary.Item($key))."  )

			$file = $file.replace("$Tab$key.", "$Tab$($p.KeyDictionary.Item($key))." )
        
			$file = $file.replace(".$key.", ".$($p.KeyDictionary.Item($key))."  )
		}

		foreach ($key in $p.KeyDictionarySimple.Keys) {    

			$file = $file.replace("$key", "$($p.KeyDictionarySimple.Item($key))" )
		}

		Set-Content -Path $p.Destination -Value $file
	}	

}

#run as local admin in usmt folder
#$sourceDomain is the sourceDomain eg AGR. default value is AGR
#$sourceUsername is the AGR username, eg JohnC
#$destDomain is the domain you want to move to, eg TAD,LUNA
#destUsername is the username in the destination domain, eg m0044914, u0044914
#share is networkshare to store the usmt files. If not specified, c:\scanstore is used
function move-profile([string] $sourceDomain = 'AGR',[string] $sourceUsername,[string] $destDomain,[string] $destUsername, [string] $share ='c:\scanstore'){
    #cf http://www.edugeek.net/forums/scripts/132912-powershell-running-external-commands-variables-arguments.html
    $backupLocation = "c:\scanstore"+ "\" + $sourceUsername
    if($share -ne $null){
        #$share parameter is supplied, use this one
        $backupLocation = $share + "\" + $sourceUsername
    }
    $fullSource = $sourceDomain + "\" + $sourceUsername
    if($sourceDomain -eq '.'){
        $fullSource = $sourceUsername
    }
    $ArgumentList = '{1} /o /i:miguser.xml /ue:*\* /ui:{0}' -f $fullSource,$backupLocation
    Start-Process -Wait -FilePath .\scanstate.exe -ArgumentList $ArgumentList
    $fullDest = $destDomain + "\" + $destUsername
    $ArgumentList = '{2} /i:miguser.xml /ue:*\* /ui:{0} /mu:{0}:{1}' -f $fullSource,$fullDest,$backupLocation
     Start-Process -Wait -FilePath .\loadstate.exe -ArgumentList $ArgumentList
     Write-Warning "Check My Documents folder, and reset to default if need be"

}





function add-accessToAGRShare([string]$lab,[string] $agrUsername, [string] $domain='TAD',[string] $domainUsername){
    $folder = get-agrShare $lab $agrUsername
    if($folder -ne $null){
        Set-UserAccess -Path $folder -User ($domain +'\'+$domainUsername) -Permission 'Modify'
    }

}

function get-agrshare([string]$lab,[string] $agrUsername){
    #if necessary, remove agr\ prefix (2 slashes required because it is a regular expression)
    $agrUsername = $agrUsername -replace 'agr\\',''
    $dfs = $null
    switch($lab){
        "COK"{$dfs = "\\agr-srv-st03\COK\COK COWORKERS\" + $agrUsername}
  
    }
    return $dfs

}
function Set-UserAccess {
	param (
		[String]$Path,
		[String]$User,
		[String]$Permission
	)
	if (Test-Path -Path $Path -PathType Container) {
		## Get the current ACL.
		$acl = Get-Acl -Path $Path
 
		## Setup the access rule.
		#PJD: original inherit settings: $allInherit = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit", "ObjectInherit"
        #PJD: op file servers geen inheritance nodig
        $allInherit = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit", "ObjectInherit"
		$allPropagation = [System.Security.AccessControl.PropagationFlags]"None"
		$AR = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $Permission, $allInherit, $allPropagation, "Allow")
 
		## Check if Access already exists.
		if ($acl.Access | Where { $_.IdentityReference -eq $User}) {
			$accessModification = New-Object System.Security.AccessControl.AccessControlModification
			$accessModification.value__ = 2
			$modification = $false
			$acl.ModifyAccessRule($accessModification, $AR, [ref]$modification) | Out-Null
		} else {
			$acl.AddAccessRule($AR)
		}
		Set-Acl -AclObject $acl -Path $Path
		Return $true
	} else {
		Return $false
	}
}
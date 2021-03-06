function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountKey,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountContainer,

        [parameter(Mandatory = $false)]
        [System.String]
        $Blob = $null
    )

    Write-Verbose ("In Get Function")

    $returnValue = @{
    Path = $Path
    StorageAccountName = $StorageAccountName
    StorageAccountContainer = $StorageAccountContainer
    Blob = $Blob
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountKey,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountContainer,

        [parameter(Mandatory = $false)]
        [System.String]
        $Blob = $null
    )

        <#
            Function to download blobs from a container.
            It will recurse through all folders in the container and if any blob is newer than the local version then
            it will download the file. It looks at the MD5 hash of the blob in storage and compares to the MD5 hash of the local file
            to determine if it should download.

        #>
        function Download-Blobs
        {
        Param (
            [parameter(Mandatory = $true)]
            [System.Object]
            $Blobs
            )

            foreach ($BlobItem in $Blobs) 
            {  
                # If the blob is a directory, recurively download blobs in the directory
                if ($BlobItem.GetType().Name -eq "CloudBlobDirectory")
                {
                    $Blobs = $BlobItem.ListBlobs()
                    Download-Blobs($Blobs)
                }
                if ($BlobItem.GetType().Name -eq "CloudBlockBlob")
                {
                    $BlobFile = $BlobContainer.GetBlobReference($BlobItem.Name)
                    # Create local path to download blob from and remove drive if there is one in the blob path in storage
                    $Dir = Join-Path $Path (Split-Path $BlobItem.Name -NoQualifier)
                    if (!(Test-Path $Dir))
                    {
                        Write-Verbose ("Downloading " + $BlobItem.Name)
                        if (!(Test-Path(Split-Path $Dir -Parent)))
                        {
                           New-Item -ItemType Directory -Force -Path (Split-Path $Dir -Parent) | Write-Verbose
                        }
                        $BlobFile.DownloadToFile($Dir,[System.IO.FileMode]::Create)
                    }
                    else
                    {
                        $MD5Hash = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
                        $LocalHash = [System.Convert]::ToBase64String($MD5Hash.ComputeHash([System.IO.File]::ReadAllBytes(($Dir))))
                        $StorageHash = $BlobItem.Properties.ContentMD5

                        if ($LocalHash -ne $StorageHash) 
                        {
                            Write-Verbose ("Downloading newer file " + $BlobItem.Name)
                            if (!(Test-Path(Split-Path $Dir -Parent)))
                            {
                                New-Item -ItemType Directory -Force -Path (Split-Path $Dir -Parent) | Write-Verbose
                            }
                            $BlobFile.DownloadToFile($Dir,[System.IO.FileMode]::Create)
                        }
                    }
                }
            }
        }


        Write-Verbose "In Set Function"

        try
        {
            $Creds = New-Object Microsoft.WindowsAzure.Storage.Auth.StorageCredentials($StorageAccountName, $StorageAccountKey)
            $CloudStorageAccount = New-Object Microsoft.WindowsAzure.Storage.CloudStorageAccount($Creds, $true)
            $CloudBlobClient = $CloudStorageAccount.CreateCloudBlobClient()

            $BlobContainer = $CloudBlobClient.GetContainerReference($StorageAccountContainer)

            if ($Blob -eq $null -or $Blob -eq "")
            {
                $Blobs = $BlobContainer.ListBlobs()
            }
            else
            {
                $Blobs = $BlobContainer.ListBlobs($Blob)
            }
        
            Download-Blobs($Blobs)
        }
        catch
        {
            Write-Verbose ($_.Exception)
            throw $_
        }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountKey,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountContainer,
                
        [parameter(Mandatory = $false)]
        [System.String]
        $Blob = $null
    )

        # Set Test result to $True by default and will set to $False if any files need to be downloaded
        $Global:Result = $True

        <#
            Function to list blobs from a container.
            It will recurse through all folders in the container and if any blob is newer than the local version then
            it will set $Result to $False. It looks at the MD5 hash of the blob in storage and compares to the MD5 hash of the local file
            to determine if it should be downloaded.

        #>
        function List-Blobs
        {
        Param (
            [parameter(Mandatory = $true)]
            [System.Object]
            $Blobs
            )

            foreach ($BlobItem in $Blobs) 
            {  
                # If the blob is a directory, recurively download blobs in the directory
                if ($BlobItem.GetType().Name -eq "CloudBlobDirectory")
                {
                    $Blobs = $BlobItem.ListBlobs()
                    List-Blobs($Blobs)
                }
                if ($BlobItem.GetType().Name -eq "CloudBlockBlob")
                {
                    # Create local path to download blob from and remove drive if there is one
                    $Dir = Join-Path $Path (Split-Path $BlobItem.Name -NoQualifier)
                    if (!(Test-Path $Dir))
                    {
                        Write-Verbose ("Need to download " + $BlobItem.Name + " as it does not exist on the local path")
                        $Global:Result = $false
                    }
                    else
                    {
                        $MD5Hash = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
                        $LocalHash = [System.Convert]::ToBase64String($MD5Hash.ComputeHash([System.IO.File]::ReadAllBytes(($Dir))))
                        $StorageHash = $BlobItem.Properties.ContentMD5

                        if ($LocalHash -ne $StorageHash) 
                        {
                            Write-Verbose ("Need to download " + $BlobItem.Name + "as it is different then the local file")
                            $Global:Result = $false
                        }
                    }
                }
            }
        }

        Write-Verbose "In Test Function"
        Write-Verbose ("Storage Account is: " + $StorageAccountName)
        Write-Verbose ("Local Path is: " + $Path)
        Write-Verbose ("Container is: " + $StorageAccountContainer)
        Write-Verbose ("Blob is: " + $Blob)

        try
        {
            # Need to import the module here since the module which has RequiredAssemblies listed does not seem to get called for DSC resources
            # Was calling load from before but I think Import-Module is a little cleaner
            # [System.Reflection.Assembly]::LoadFrom("$env:ProgramFiles\WindowsPowerShell\Modules\cAzureStorage\Microsoft.WindowsAzure.Storage.dll") | Write-Verbose
            Import-Module cAzureStorage
            $Creds = New-Object Microsoft.WindowsAzure.Storage.Auth.StorageCredentials($StorageAccountName, $StorageAccountKey)
            $CloudStorageAccount = New-Object Microsoft.WindowsAzure.Storage.CloudStorageAccount($Creds, $true)
            $CloudBlobClient = $CloudStorageAccount.CreateCloudBlobClient()

            $BlobContainer = $CloudBlobClient.GetContainerReference($StorageAccountContainer)
            if ($Blob -eq $null -or $Blob -eq "")
            {
                $Blobs = $BlobContainer.ListBlobs()
            }
            else
            {
                $Blobs = $BlobContainer.ListBlobs($Blob)
            }

            List-Blobs($Blobs)
        }
        catch
        {
            Write-Verbose ($_.Exception)
            throw $_
        }
    
        $Global:Result
}


Export-ModuleMember -Function *-TargetResource


<#
.SYNOPSIS
    Modifies text files on a Linux machine. The composite module contains two resources: addstring and replacestring.
    Shows how to write composite resources in python and use them in a configuration.

.DESCRIPTION
    Modifies text files on a Linux machine. The composite module contains two resources: addstring and replacestring.
    The composite resources have a dependency on nxScript that must be available when compiling configurations that 
    reference these resources. The nxScript module is available on the PowerShellGallery.com site.
    These resources use the nxScript resource to call Python code to implement the addstring and replacestring composite
    resources.
        
    addstring parameters
    [Parameter(Mandatory)]
    [string]$path, # This is the path to the text file to modify

    [Parameter(Mandatory)]
    [string]$addstring, # This the new string to add

    [Parameter(Mandatory=$false)]
    [string]$afterstring = "", # This is the string to search for and add the new string after this is found
        
    [Parameter(Mandatory=$false)]
    [int]$linenumber = -1 # Add string after this line number only

        
    replacestring parameters
    [Parameter(Mandatory)]
    [string]$path, # This is the path to the text file to modify

    [Parameter(Mandatory)] 
    [string]$sourcestring, # This is the string to replace

    [Parameter(Mandatory)]
    [string]$destinationstring, # This the new string to replace the existing string
        
    [Parameter(Mandatory=$false)]
    [int]$linenumber = -1 # Modify the string only at this line number


.NOTES
    AUTHOR: Eamon O'Reilly
    LASTEDIT: January 25th, 2018 
#>

Configuration SampleLinuxfileContent { 
    param (
    )
    Import-DscResource -ModuleName fileContent -ModuleVersion 1.0

    # Path to file to modify.
    $FilePath = "/tmp/testlog.log"
    <# File sample could look like below:

    warning "This is a warning"
    warning "This is a really bad issue"
    warning "This is a warning"

    and it should instead look like:

    warning "This is a warning"
    error "This is a really bad issue"
    Info "This is an informational message"
    warning "This is a warning"

    #>


    # Set up replacestring parameters
    $SourceString = "warning"
    $DestinationString = "error"
    $ReplaceAtLineNumber = 2 # Optional line number to only replace strings found on
  
  
    # Set up addstring parameters
    $AddString = 'Info "This is an informational message"'
    $AfterString = "error" # Optional location to add new string to a line if this string is found. Otherwise, it will be added to the end of file.
    $AddAtLineNumber= 2 # Optional line number to add string found on        

    Node "localhost" {
        
        replacestring FixErrorLog{
            path = $FilePath
            sourcestring = $SourceString
            destinationstring = $DestinationString   
            linenumber = $ReplaceAtLineNumber
        }
        
        addstring AddInfoMessage{
            path = $FilePath
            addstring = $AddString
            afterstring = $AfterString
            linenumber = $AddAtLineNumber

        }
    }
}

# Generate mof that can be applied to the Linux server
SampleLinuxfileContent
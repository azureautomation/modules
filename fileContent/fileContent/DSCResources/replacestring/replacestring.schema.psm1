Configuration replacestring
{
param
    (
        [Parameter(Mandatory)]
        [string]$path,

        [Parameter(Mandatory)]
        [string]$sourcestring,

        [Parameter(Mandatory)]
        [string]$destinationstring,
        
        [Parameter(Mandatory=$false)]
        [int]$linenumber = -1
)



    Import-DscResource -Module nx -ModuleVersion 1.0

        nxScript test
{          
GetScript = @"
#!/usr/bin/python
print "In GetScript"
"@

TestScript = @"
#!/usr/bin/python
# Return 0 if in desired state
import os
linenumber = 1
with open('$path', 'r') as inputfile:
    if $linenumber <> -1:
        for line in inputfile:
            if linenumber == ${linenumber}:
                if '$destinationstring' not in line:
                    exit(1)
                else:
                    exit(0)
            linenumber += 1
    else:
        wholefile = inputfile.read()
        if '$destinationstring' not in wholefile:
            exit(1)
        else:
            exit(0)
"@

SetScript = @"
#!/usr/bin/python
import os
linenumber = 1
content = ""
with open('$path', 'r') as inputfile:
    if $linenumber <> -1:
        for line in inputfile:
            if linenumber == ${linenumber}:
                line = line.replace('$sourcestring', '$destinationstring')
            content = content + line
            linenumber += 1
    else:
        wholefile = inputfile.read()
        content = wholefile.replace('$sourcestring', '$destinationstring')
# Write out the content to the file
with open('$path', 'w') as inputfile:
    inputfile.write(content)
"@
}
}
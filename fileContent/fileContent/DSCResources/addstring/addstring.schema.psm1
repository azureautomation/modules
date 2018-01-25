Configuration addstring
{
param
    (
        [Parameter(Mandatory)]
        [string]$path,

        [Parameter(Mandatory)]
        [string]$addstring,

        [Parameter(Mandatory=$false)]
        [string]$afterstring = "",
        
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
foundstring = False
with open('$path', 'r') as inputfile:
    # if no line number is specified and no after string, then add to end of file
    if $linenumber == -1 and '$afterString' == '':
        for line in inputfile:
            content = line
        if '$addString' in content:
            exit(0)
        else:
            exit(1)
    # if a line number is specified, but no after string, add after line number
    elif $linenumber <> -1 and '$afterString' == '':
        for line in inputfile:
            if linenumber == (${linenumber} + 1):
                if '$addString' in line:
                    exit(0)
                else:
                    exit(1)
            linenumber += 1
        exit(1)
    # if a line number is not specified, and there is an after string, add new string when afterString is found.
    elif $linenumber == -1 and '$afterString' <> '':
        for line in inputfile:
            if foundstring:
                if '$addString' in line:
                    exit(0)
                else:
                    exit(1)           
            if '$afterString' in line:
                    foundstring = True
        exit(1)
    # if a line number is specified, and an after string, add at that line number if afterString is present
    else:
        for line in inputfile:
            if linenumber == (${linenumber} + 1):
                if '$addString' in line:
                    exit(0)
                else:
                    exit(1)
            linenumber += 1
        exit(1)
"@

SetScript = @"
#!/usr/bin/python
import os
linenumber = 1
content = ""
with open('$path', 'r') as inputfile:
    # if no line number is specified and no after string, then add to end of file
    if $linenumber == -1 and '$afterString' == '':
        for line in inputfile:
            content = content + line
        content = content + '$addString' + "\n"
    # if a line number is specified, but no after string, add after line number
    elif $linenumber <> -1 and '$afterString' == '':
        for line in inputfile:
            if linenumber == ${linenumber}:
                line = line + '$addString' + "\n"
            content = content + line
            linenumber += 1
    # if a line number is not specified, but there is an after string, add new string when afterString is found.
    elif $linenumber == -1 and '$afterString' <> '':
        for line in inputfile:
            if '$afterString' in line:
                line = line + '$addString' + "\n"
            content = content + line
    # if a line number is specified, and an after string, add at that line number if afterString is present
    else:
        for line in inputfile:
            if linenumber == ${linenumber}:
                if '$afterString' in line:
                    line = line + '$addString' + "\n"
            content = content + line
            linenumber += 1
# Write out the content to the file
with open('$path', 'w') as inputfile:
    inputfile.write(content)
"@
}
}
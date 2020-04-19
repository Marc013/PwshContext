---
external help file: PwshContext-help.xml
Module Name: PwshContext
online version:
schema: 2.0.0
---

# New-PwshContext

## SYNOPSIS
Create a new PowerShell context configuration file.

## SYNTAX

```
New-PwshContext [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
Create a new PowerShell context configuration file containing the current loaded PowerShell modules (PowerShell build-in modules excluded) and any PowerShell module that is present in directory 'Modules' in the context directory.
The file will be stored in directory Context at the specified path (which is created if not present).

## EXAMPLES

### EXAMPLE 1
```
New-PwshContext -Path C:\pwsh\DevEnv01
```

Creates a new PowerShell configuration describing the current loaded PowerShell modules (PowerShell build-in modules excluded) and any PowerShell module that is present in directory 'Modules' in the context directory.
The PowerShell context configuration is saved at C:\pwsh\DevEnv01\Context\PwshContext_DevEnv01.json.

## PARAMETERS

### -Path
Context path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

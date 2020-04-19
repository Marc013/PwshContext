---
external help file: PwshContext-help.xml
Module Name: PwshContext
online version:
schema: 2.0.0
---

# Set-PwshContext

## SYNOPSIS
Set PowerShell context

## SYNTAX

```
Set-PwshContext [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
Set PowerShell context specified in the context configuration file or current loaded modules.
When no context configuration file is present a context directory structure will be created and a new context configuration file describing the current loaded modules (PowerShell build-in modules excluded).

## EXAMPLES

### EXAMPLE 1
```
Set-PwshContext -Path C:\pwsh\DevEnv01
```

This command will load configuration file C:\pwsh\DevEnv01\Context\PwshContext_DevEnv01.json and configure a new PowerShell session with the described context.
When no configuration file is present it will trigger module 'New-PwshContext' creating a new PowerShell context configuration file.

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

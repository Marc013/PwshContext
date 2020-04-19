---
external help file: PwshContext-help.xml
Module Name: PwshContext
online version:
schema: 2.0.0
---

# Install-PwshModule

## SYNOPSIS

Installs the PowerShell module in the specified directory.

## SYNTAX

```text
Install-PwshModule [-Name] <String> [-Condition] <String> [[-Version] <Version>] [-Path] <String>
 [<CommonParameters>]
```

## DESCRIPTION

Installs the PowerShell module and all dependencies in the specified directory.

## EXAMPLES

### EXAMPLE 1

```text
Install-PwshModule -Name 'Az' -Path 'C:\pwsh\modules1'
```

Installs PowerShell module Az and all dependencies in directory C:\pwsh\modules1.

## PARAMETERS

### -Name

PowerShell module name.

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

### -Condition

PowerShell module version condition.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version

PowerShell module version.

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Path to install the module.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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

[char]$Separator = [System.IO.Path]::DirectorySeparatorChar

[string]$ModuleName = 'PwshContext'
[string]$ModuleManifestName = "$ModuleName.psd1"
[string]$ModuleManifestPath = "..$($Separator)src$($Separator)$ModuleManifestName"

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $ModuleManifestPath) -PassThru

InModuleScope 'PwshContext' {

    Describe 'Module Manifest Tests' {
        $ModuleManifestPath = "$PSScriptRoot$($Separator)..$($Separator)src$($Separator)$ModuleManifestName"

        It 'Passes Test-ModuleManifest' {
            Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
            $? | Should -Be $true
        }
    }

    Describe 'Function New-Directory' {
        [string]$Path = "C:$($Separator)Test$($Separator)Mock$($Separator)"

        Context 'Path already exist' {

            [psobject]$PathMock = New-Object -TypeName psobject
            [psobject]$PathMock | Add-Member -MemberType NoteProperty -Name Path -Value $Path
            Mock -CommandName Resolve-Path -MockWith { return $PathMock }

            it "Should return found path object" {
                New-Directory -Path $Path | Should -Be $PathMock
            }
        }

        Context 'Path does not exist' {

            [hashtable]$PathMock = @{ FullName = $Path }

            Mock -CommandName Resolve-Path -MockWith { return $Null }
            Mock -CommandName New-Item -MockWith { return $PathMock }

            it "Should return created path full name" {
                (New-Directory -Path $Path).FullName | Should -Be $Path
            }
        }
    }

    Describe 'Function New-VersionNumber' {
        # CONTINUE HERE
    }
}
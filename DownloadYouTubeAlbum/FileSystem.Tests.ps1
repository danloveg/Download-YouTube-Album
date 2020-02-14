. $PSScriptRoot\FileSystem.ps1

Describe 'File System Tests' {
    Context 'CleanFolderIfEmpty: Folder is empty' {
        Mock Get-ChildItem { } -ParameterFilter { $Path -eq 'TestFolder' }
        Mock Remove-Item { } -ParameterFilter { $Path -eq 'TestFolder'}

        It 'Remove folder if empty' {
            CleanFolderIfEmpty 'TestFolder'
            Assert-MockCalled Remove-Item
        }
    }

    Context 'CleanFolderIfEmpty: Folder is not empty' {
        Mock Get-ChildItem { return @{FullName = 'a folder'}} -ParameterFilter { $Path -eq 'TestFolder' }
        Mock Remove-Item { } -ParameterFilter { $Path -eq 'TestFolder'}

        It 'Do not remove folder if not empty' {
            CleanFolderIfEmpty 'TestFolder'
            { Assert-MockCalled Remove-Item } | Should -Throw
        }
    }

    Context 'CreateNewFolder: Folder does not exist' {
        Mock Test-Path { return $False } -ParameterFilter { $Path -eq 'TestFolder'}
        Mock New-Item { }

        It 'Create folder if it does not exist' {
            CreateNewFolder 'TestFolder'
            Assert-MockCalled New-Item
        }
    }

    Context 'CreateNewFolder: Folder already exists' {
        Mock Test-Path { return $True } -ParameterFilter { $path -eq 'TestFolder' }
        Mock New-Item { }

        It 'Do not create folder if it exists' {
            CreateNewFolder 'TestFolder'
            { Assert-MockCalled New-Item } | Should -Throw
        }
    }
}
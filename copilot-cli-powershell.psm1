<#
.SYNOPSIS
    A PowerShell module to interact with the GitHub Copilot in the CLI.

.DESCRIPTION
    This module provides a convenient way to generate and execute code suggestions
    from the GitHub Copilot in the CLI in a PowerShell environment.
#>

function Invoke-GitAlias {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, HelpMessage = "The remaining arguments for the Copilot command.")]
        [string[]]$RemainingArguments
    )
    Invoke-CopilotCommand @("suggest", "--target", "git") ($RemainingArguments -join " ")
}
function Invoke-GHAlias {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, HelpMessage = "The remaining arguments for the Copilot command.")]
        [string[]]$RemainingArguments
    )
    Invoke-CopilotCommand @("suggest", "--target", "gh") ($RemainingArguments -join " ")
}

function Invoke-GitHubCopilot {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, HelpMessage = "The remaining arguments for the Copilot command.")]
        [string[]]$RemainingArguments
    )
    Invoke-CopilotCommand @("suggest", "--target", "shell") ($RemainingArguments -join " ")
}

function Invoke-CopilotExplain {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, HelpMessage = "The remaining arguments for the Copilot command.")]
        [string[]]$RemainingArguments
    )
    Invoke-CopilotCommand @("explain") ($RemainingArguments -join " ")
}

function Invoke-CopilotCommand {
    param (
        [Parameter(Mandatory)][string[]]$SubCommands,
        [Parameter(Mandatory)][string]$Instruction
    )

    # $tempFile = Join-Path -Path $Env:TEMP -ChildPath "copilot_$((Get-Date).ToString('yyyyMMddHHmmss'))_$(Get-Random -Maximum 9999).txt"

    gh copilot $SubCommands $Instruction

    if ($LASTEXITCODE -eq 0) {
        # $fileContentsArray = Get-Content $tempFile
        # $fileContents = [string]::Join("`n", $fileContentsArray)
        # Write-Host $fileContents
        # Invoke-Expression $fileContents
    }
    else {
        Write-Host "User cancelled the command."
    }
}

function Test-EscapedString {
    param (
        [Parameter(Mandatory)][string]$String
    )

    $startChar = $String.Substring(0, 1)
    $endChar = $String.Substring($String.Length - 1, 1)

    if (($startChar -eq "'") -and ($endChar -eq "'")) {
        $unescapedQuotes = $String.Substring(1, $String.Length - 2) -replace "''", ""
        if (-not ($unescapedQuotes -like "*'*")) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Sets aliases '??', 'git?', 'gh?' and 'cmd?'
#>
function Set-PassiveGitHubCopilotAliases {
    Set-Alias -Name '??' -Value Invoke-GitHubCopilot -Scope Global
    Set-Alias -Name 'gh?' -Value Invoke-GHAlias -Scope Global
    Set-Alias -Name 'git?' -Value Invoke-GitAlias -Scope Global
    Set-Alias -Name 'cmd?' -Value Invoke-CopilotExplain -Scope Global
}

<#
.SYNOPSIS
    Sets aliases '??', 'git?', 'gh?' and 'cmd?' and hooks the Enter key to escape commands.
#>
function Set-GitHubCopilotAliases {
    Set-PassiveGitHubCopilotAliases

    Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        $elems = $line.Split(' ', 2)
        $command = $elems[0]
        $question = $elems[1]

        if ($command -in "??", "git?", "gh?", "cmd?") {
            Write-Output (Test-EscapedString -String $elems[1])
            if (-not (Test-EscapedString -String $elems[1])) {
                $question = $elems[1].Replace("'", "''")
                $question = "'$question'"
            }
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, "$command $question")
        }


        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

# Export-ModuleMember -Function Set-PassiveGitHubCopilotAliases, Set-GitHubCopilotAliases, Invoke-CopilotCommand, Invoke-GitHubCopilot, Invoke-GHAlias, Invoke-GitAlias, Invoke-CopilotExplain

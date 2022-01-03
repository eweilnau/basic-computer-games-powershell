#Requires -Version 7
#Requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

BeforeAll {
    . $PSScriptRoot/AceyDucey.ps1
    Mock Write-Host
}

Describe 'Invoke-Game' {
    It 'Calls Invoke-Bet until you are out of money' {
        Mock Invoke-Bet { New-Bet -Outcome Lose -Amount 25 }
        Invoke-Game
        Should -Invoke -CommandName Invoke-Bet -Times 4 -Exactly
    }
}

Describe 'Invoke-Bet' {
    BeforeAll {
        Mock Read-BetAmount { 25 }
        Mock New-BoundaryCards { @(2, 9) }
    }

    It "Returns <outcome> given <card>" -ForEach @(
        @{ Outcome = 'Win'; Card = 5 }
        @{ Outcome = 'Lose'; Card = 9 }
    ) {
        Mock New-Card { $Card }
        $bet = Invoke-Bet -Money 100
        $bet.Outcome | Should -Be $Outcome
    }

    It 'Returns the bet amount' {
        $bet = Invoke-Bet -Money 100
        $bet.Amount | Should -Be 25
    }

    It 'Returns skip outcome for zero amount' {
        Mock Read-BetAmount { 0 }
        $bet = Invoke-Bet -Money 100
        $bet.Outcome | Should -Be Skip
    }
}

Describe 'Complete-Bet' {
    Context 'Winning bet' {
        It 'Returns the sum of Bet.Amount and Money' {
            $bet = New-Bet -Outcome Win -Amount 25
            Complete-Bet -Bet $bet -Money 100 | Should -Be 125
        }
    }

    Context 'Losing bet' {
        It 'Returns the value of Money minus Bet.Amount' {
            $bet = New-Bet -Outcome Lose -Amount 25
            Complete-Bet -Bet $bet -Money 100 | Should -Be 75
        }
    }

    Context 'Skip bet' {
        BeforeAll {
            $bet = New-Bet -Outcome Skip -Amount 0
        }

        It 'Insults the player' {
            Complete-Bet -Bet $bet -Money 100
            Should -Invoke Write-Host -ParameterFilter { $Object -eq "CHICKEN!!`n" } -Times 1 -Exactly
        }

        It 'Returns Money' {
            Complete-Bet -Bet $bet -Money 100 | Should -Be 100
        }
    }
}

Describe 'Confirm-NewGame' {
    It 'Returns <expected> for "<answer>"' -ForEach @(
        @{ Answer = "yes"; Expected = $true }
        @{ Answer = "y"; Expected = $true }
        @{ Answer = "Yes"; Expected = $true }
        @{ Answer = "YES"; Expected = $true }
        @{ Answer = "Y"; Expected = $true }
        @{ Answer = "Yowser"; Expected = $false }
        @{ Answer = "no"; Expected = $false }
        @{ Answer = "n"; Expected = $false }
        @{ Answer = "No"; Expected = $false }
        @{ Answer = "NO"; Expected = $false }
        @{ Answer = "N"; Expected = $false }
        @{ Answer = "asdf"; Expected = $false }
        @{ Answer = 23894; Expected = $false }
    ) {
        Mock Read-Host { return $answer }
        Confirm-NewGame | Should -Be $expected
    }
}
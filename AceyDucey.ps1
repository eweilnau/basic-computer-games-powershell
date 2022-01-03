#Requires -Version 7

function Invoke-Main {
    Write-Intro
    do {
        Invoke-Game
    } while (Confirm-NewGame)
    Write-Host "OK HOPE YOU HAD FUN"
}

function Write-Intro {
    Write-Host ("{0}ACEY DUCY CARD GAME" -f (' ' * 13))
    Write-Host "  CREATIVE COMPUTING  MORRISTOWN, NEW JERSEY`n`n`n"

    @"
ACEY-DUCEY IS PLAYED IN THE FOLLOWING MANNER
THE DEALER (COMPUTER) DEALS TWO CARDS FACE UP
YOU HAVE AN OPTION TO BET OR NOT BET DEPENDING
ON WHETHER OR NOT YOU FEEL THE CARD WILL HAVE
A VALUE BETWEEN THE FIRST TWO.
IF YOU DO NOT WANT TO BET, INPUT A 0
"@ | Write-Host
}

function Invoke-Game {
    $money = 100
    Write-Money -Money $money
    do {
        $bet = Invoke-Bet -Money $money
        $money = Complete-Bet -Bet $bet -Money $money
    } while ($money -gt 0)
    Write-Host "`nSORRY, FRIEND, BUT YOU BLEW YOUR WAD."
}

function Write-Money([uint]$Money) {
    Write-Host "YOU NOW HAVE $money DOLLARS`n"
}

function Invoke-Bet {
    [OutputType('Bet')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [uint] $Money
    )

    $boundaryCards = New-BoundaryCards
    $bet = Read-BetAmount -Money $Money
    if ($bet -eq 0) {
        return New-Bet -Outcome Skip -Amount $bet
    }
    $betCard = New-Card
    Write-Card -Card $betCard
    if ($boundaryCards[0] -lt $betCard -and $betCard -lt $boundaryCards[1]) {
        New-Bet -Outcome Win -Amount $bet
    } else {
        New-Bet -Outcome Lose -Amount $bet
    }
}

function New-BoundaryCards {
    Write-Host "HERE ARE YOUR NEXT TWO CARDS: "
    do {
        $first = New-Card
        $second = New-Card
    } while ($first -ge $second)
    Write-Card -Card $first
    Write-Card -Card $second
    Write-Host
    @( $first, $second)
}

function New-Card {
    # Return a random integer between 2 and 14 inclusive
    # The Minimum parameter of Get-Random is inclusive while the Maximum parameter is exclusive
    Get-Random -Minimum 2 -Maximum 15
}

function Write-Card([uint] $Card) {
    $name = switch ($Card) {
        11 { 'Jack' }
        12 { 'Queen' }
        13 { 'King' }
        14 { 'Ace' }
        default { "$Card" }
    }

    Write-Host $name
}

function Read-BetAmount([uint]$Money) {
    do {
        $amount = (Read-Host "WHAT IS YOUR BET") -as [uint]
        if (!$amount -and $amount -ne 0) {
            Write-Host "SORRY, MY FRIEND, BUT THAT IS NOT A VALID BET.`nPLEASE ENTER A VALUE BETWEEN 0 AND $Money.`n"
        }
        if ($amount -gt $Money) {
            Write-Host "SORRY, MY FRIEND, BUT YOU BET TOO MUCH.`nYOU HAVE ONLY $Money DOLLARS TO BET.`n"
        }
    } until (0 -le $amount -and $amount -le $Money)
    $amount
}

function New-Bet {
    [OutputType('Bet')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [Outcome] $Outcome,
        [Parameter(Mandatory = $true)] [uint] $Amount
    )

    [PSCustomObject]@{
        PSTypeName = 'Bet'
        Outcome = $Outcome
        Amount = $Amount
    }
}

enum Outcome {
    Win
    Lose
    Skip
}

function Complete-Bet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [PSTypeName('Bet')] $Bet,
        [Parameter(Mandatory = $true)] [int] $Money
    )

    switch ($Bet.Outcome) {
        Win {
            Write-Host "YOU WIN!!!"
            $result = $Money + $Bet.Amount
            Write-Money -Money $result
            $result
        }
        Lose {
            Write-Host "SORRY, YOU LOSE"
            $result = $Money - $Bet.Amount
            if ($result -ne 0) { Write-Money -Money $result }
            $result
        }
        Skip {
            Write-Host "CHICKEN!!`n"
            $Money
        }
    }
}

function Confirm-NewGame {
    $answer = Read-Host "TRY AGAIN (YES OR NO)"
    $answer -eq 'y' -or $answer -eq 'yes'
}

# This allows us to dot source the script for testing the functions with Pester
# Refer to this answer on Stack Overflow about the use of InvocationName and Line
# https://stackoverflow.com/questions/4875912/determine-if-powershell-script-has-been-dot-sourced#33855217
$isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) { Invoke-Main }
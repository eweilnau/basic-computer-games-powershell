#Requires -Version 7

# This script is a port of a game by Bill Palmby of Prairie View, Illinois
# published in 1978 in BASIC Computer Games edited by David H. Ahl.

# Invoke-Main is the entry point for this script and implements the entire original application.
# It delegates all but the last 3 instructions to the Write-Intro, Invoke-Game, and Confirm-NewGame functions.
function Invoke-Main {
    Write-Intro
    do {
        Invoke-Game
    } while (Confirm-NewGame) # replaces the conditional goto on line 1030
    Write-Host "OK HOPE YOU HAD FUN"
}

# Write-Intro implements the 10 instructions at lines 10-80.
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

# Invoke-Game implements the majority of the original application covering lines 110-1010.
# It's primary responsibility is managing the M variable which has been renamed $money.
# The game starts by setting $money to 100 and ends when it is equal to 0.
#
# While the original application intermixes the instructions for determining
# whether the player won the bet and updating the players money,
# I split those between the Invoke-Bet and Complete-Bet functions respectively.
# I did this to make it easier for unit testing.
function Invoke-Game {
    $money = 100
    Write-Money -Money $money
    do {
        $bet = Invoke-Bet -Money $money
        $money = Complete-Bet -Bet $bet -Money $money
    } while ($money -gt 0) # replaces the conditional goto on line 980
    Write-Host "`nSORRY, FRIEND, BUT YOU BLEW YOUR WAD."
}

# Write-Money implements the instruction at line 120.
function Write-Money([uint]$Money) {
    Write-Host "YOU NOW HAVE $money DOLLARS`n"
}

# Invoke-Bet implements the 65 instructions at lines 260-670 and 680-930.
# Much of this is delegated to the New-BoundaryCards, Read-BetAmount, New-Card and Write-Card functions.
# It's primary resposibility is to return the bet PSCustomObject
# with the outcome (Win/Lose/Skip) and the amount.
# The original C variable has been renamed $betCard
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

# New-BoundaryCards implements the 37 instructions at lines 260-640.
# It is responsible for the initialization and display of the first two cards
# which are returned as an array.
# Much of this is delegated to the New-Card and Write-Card functions.
# The original variables A and B have been renamed $first and $second respectively.
function New-BoundaryCards {
    Write-Host "HERE ARE YOUR NEXT TWO CARDS: "
    do {
        $first = New-Card
        $second = New-Card
    } while ($first -ge $second) # replaces the conditional goto on line 330
    Write-Card -Card $first
    Write-Card -Card $second
    Write-Host
    @( $first, $second)
}

# New-Card implements the 3 instructions at lines 270-290
# which are repeated at lines 300-320 and lines 730-750.
function New-Card {
    # Return a random integer between 2 and 14 inclusive.
    # The Minimum parameter of Get-Random is inclusive while the Maximum parameter is exclusive.
    Get-Random -Minimum 2 -Maximum 15
}

# Write-Card implements the 14 instructions at lines 350-480
# which are repeated at lines 500-630 and lines 760-890.
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

# Read-BetAmount implements the 7 instructions at lines 650-670 and 680-710.
# The 3 instructions at lines 675-677 were moved to the Invoke-Bet and Complete-Bet functions.
# The original variable M has been renamed to $amount and is returned by the function.
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

# Complete-Bet implements the 11 instructions at lines 210-250, 675-677, and 950-980.
# It returns the players current amount of money based on the supplied bet and money.
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

# Confirm-NewGame implements the instruction at line 1020
# and the boolean expression of the instruction at line 1030.
# The boolean expression has been expanded to include 'Yes', 'yes', 'Y', and 'y'.
# String comparisons in PowerShell are case-insensitive by default.
# For details run: Get-Help about_Comparison_Operators
function Confirm-NewGame {
    $answer = Read-Host "TRY AGAIN (YES OR NO)"
    $answer -eq 'y' -or $answer -eq 'yes'
}

# This allows us to dot source the script for testing the functions with Pester
# Refer to this answer on Stack Overflow about the use of InvocationName and Line
# https://stackoverflow.com/questions/4875912/determine-if-powershell-script-has-been-dot-sourced#33855217
$isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) { Invoke-Main }
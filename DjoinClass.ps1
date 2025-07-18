# Predefined ClassRoom Name
$ClassRoom = "SCAS-"

# Domain Join Configuration
$Domain = "scasa4.com"
$OUPath = "OU=test,DC=scasa4,DC=com"
$AdminUser = "scasa4\karthik"
$AdminPassword = "kareht7Uuu343"

# Computer Naming Section
do {
    do {
        Write-Host -NoNewline "Enter the PC Number: $ClassRoom"
        $PcNumber = Read-Host
        $PcNumber = $PcNumber.Trim()
    } while ([string]::IsNullOrWhiteSpace($PcNumber))

    $newComputerName = "$ClassRoom$PcNumber"
    $currentComputerName = $env:COMPUTERNAME

    Write-Host "`nNEW PC NAME IS : $newComputerName" -ForegroundColor Green
    
    if ($currentComputerName -eq $newComputerName) {
        Write-Host "Computer already has this name. Rename will be skipped." -ForegroundColor Yellow
    }
    
    Write-Host "If the name is OK, press ENTER to continue." -ForegroundColor Cyan
    Write-Host "If NOT OK, press ESC to Re-Enter PC Number." -ForegroundColor Yellow

    $key = [System.Console]::ReadKey($true)
} while ($key.Key -eq 'Escape')

Write-Host "`nNow $newComputerName system will join domain. Please wait..." -ForegroundColor Cyan

# Domain Join Execution
try {
    # Create Credential Object
    $securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($AdminUser, $securePassword)

    # Only rename if needed
    if ($currentComputerName -ne $newComputerName) {
        try {
            Rename-Computer -NewName $newComputerName -Force -ErrorAction Stop
            Write-Host "Computer renamed to $newComputerName successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to rename computer: $_" -ForegroundColor Red
            exit
        }
    }

    # Attempt Domain Join
    $joinParams = @{
        DomainName = $Domain
        Credential = $cred
        OUPath = $OUPath
        ErrorAction = 'Stop'
    }

    # Try joining with existing account first
    try {
        Add-Computer @joinParams -Force
        Write-Host "Successfully joined domain using existing computer account." -ForegroundColor Green
    }
    catch {
        # Fall back to creating new account
        Write-Host "Attempting to create new computer account..." -ForegroundColor Yellow
        try {
            Add-Computer @joinParams -Options 'AccountCreate'
            Write-Host "Successfully created new computer account and joined domain." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to join domain: $_" -ForegroundColor Red
            exit
        }
    }

    # Cleanup Tasks
    schtasks /delete /tn "Djoin" /f 2>$null
    Remove-Item -Path "C:\Windows\SCAS\Djoin" -Recurse -Force -ErrorAction SilentlyContinue

    # Restart Prompt
    Write-Host "`nDomain join process completed successfully." -ForegroundColor Green
    Write-Host "Press ANY KEY to restart the computer..." -ForegroundColor Cyan
    [void][System.Console]::ReadKey($true)
    
    Write-Host "Restarting computer now..." -ForegroundColor Yellow
    Restart-Computer -Force
}
catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    Write-Host "Domain join failed. Please check errors and try again." -ForegroundColor Red
    exit 1
}
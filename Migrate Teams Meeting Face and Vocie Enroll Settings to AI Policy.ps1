﻿# Script gets current EnrollUserOverride setting from Teams Meeting Policy
# and compares it to current Teams AI Policy settings.
# It migrates the current Teams Meeting settings to AI Policies
#
# created by Thorsten Pickhan
# Initial script created on 12.01.2025 (01/12/2025)
# 20250112 - Initial version
#
# Version 1.0


# Install the Microsoft Teams PowerShell module if not already installed
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "$($TimeStamp) - Check Microsoft Teams Module"
if (-not (Get-InstalledModule -Name "MicrosoftTeams" -MinimumVersion 6.6.0 -ErrorAction SilentlyContinue)) {
    try {
        Install-Module -Name "MicrosoftTeams" -Force -AllowClobber -ErrorAction Stop
    }
    catch {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Error "$($TimeStamp) - Microsoft Teams Module is not installed and could not be installed. Stopping Skript now. Error messsage for module installation: $($_)"
        Exit
    }

}


# Import the Microsoft Teams module
Import-Module MicrosoftTeams

try {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$($TimeStamp) - Connecting to Microsoft Teams"
    $tmp = Connect-MicrosoftTeams -ErrorAction Stop # Use of variable to suppress output
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$($TimeStamp) - Connected to Microsoft Teams"
}
catch {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Error "$($TimeStamp) - Error connecting to Microsoft Teams"
} 

# Define AI Policy Name and Description
# if the script needs to create a new AI Policy
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "$($TimeStamp) - Defining AI Policy Name and Description"
$NewAiPolicyEnableName = "Enable Voice Face Enrollment"
$NewAiPolicyDisableName = "Disable Voice Face Enrollment"
#$TeamsMeetingFaceVoiceEnrollmentEnable = $false
#$TeamsMeetingFaceVoiceEnrollmentDisable = $false

$UserAiPolicyVoiceFaceEnabled = $false
$UserAiPolicyVoiceFaceDisabled = $false

# Gather current Teams Meeting Policies and AI Policies
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "$($TimeStamp) - Gathering current Teams Meeting Policies and AI Policies"

$CurrentMeetingPolicies = Get-CsTeamsMeetingPolicy | Select-Object Identity,Description,EnrollUserOverride
$CurrentAIPolicies = Get-CsTeamsAIPolicy

# Check if there are multiple AI Policies
# if so, stop the script


if ($CurrentAIPolicies.Length -gt 1) {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$($TimeStamp) - Multiple AI Policies found"
    Write-Host "$($TimeStamp) - It seems that the AI Policies has been already modified"
    Write-Host "$($TimeStamp) - Please check your current Tenant configuration"
    Write-Host ""
    
    Write-Host ""
    Write-Host "==============================================="
    Write-Host ""
    Write-Host "Your current Teams Meeting Policies and Face and Voice Enrollment settings are:"
    Write-Host ""
    Write-Host "==============================================="
    Write-Host ""
    Write-Output $CurrentMeetingPolicies | Select-Object Identity,EnrollUserOverride | Format-Table -AutoSize
    Write-Host ""
    Write-Host "==============================================="
    Write-Host ""
    Write-Host "Your current AI Policies are:"
    Write-Host ""
    Write-Host "==============================================="
    Write-Host ""
    $CurrentAIPolicies | Format-Table -AutoSize
    Write-Host ""
    Write-Host "==============================================="
    Write-Host ""
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$($TimeStamp) - Stopping script now"
    break
}




ForEach ($Policy in $CurrentMeetingPolicies) {
    #region Global Policy Block
    if (($Policy.Identity -eq "Global")) {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "$($TimeStamp) - Checking the the Global Teams Meeting policy"
        if ($Policy.EnrollUserOverride -eq "Disabled") {
            Write-Host "$($TimeStamp) - EnrollUserOverride is set to Disabled in Teams Meeting Policy"
            Write-Host "$($TimeStamp) - Will check if the Global AI Policy is set to Disabled"
            $CurrentAIPolicy = Get-CsTeamsAiPolicy -Identity Global
            if ($CurrentAIPolicy) {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - AI Policy found"
                Write-Host "$($TimeStamp) - Identity: $($CurrentAIPolicy.Identity)"
                Write-Host "$($TimeStamp) - VoiceEnrollment: $($CurrentAIPolicy.EnrollVoice)"
                Write-Host "$($TimeStamp) - FaceEnrollment: $($CurrentAIPolicy.EnrollFace)"
                Write-Host ""
                if (($CurrentAIPolicy.EnrollFace -eq "Enabled") -Or ($CurrentAIPolicy.EnrollVoice -eq "Enabled")) {
                    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Write-Host "$($TimeStamp) - VoiceEnrollment or FaceEnrollment is set to Enabled"
                    Write-Host "$($TimeStamp) - To reflect Global Teams Meeting Policy, these settings need to be Disabled" -ForegroundColor Yellow
                    Write-Host "$($TimeStamp) - Should the script update the AI Policy? (y)es/(n)o"
                    $response = Read-Host
                    while ($response -ne "y" -And $response -ne "n") {
                        Write-Host "Invalid response. Please enter 'y' or 'n'"
                        $response = Read-Host

                    }
                    if ($response -eq "y") {
                        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Host "$($TimeStamp) - Will update the AI Policy"
                        Set-CsTeamsAIPolicy -Identity $Policy.Identity -EnrollFace "Disabled" -EnrollVoice "Disabled"
                        $GlobalAiPolicyVoiceFaceDisabled = $true
                        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Host "$($TimeStamp) - AI Policy updated" -ForegroundColor Green
                    }
                    if ($response -eq "n") {
                        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Host "$($TimeStamp) - No further action required"
                        Write-Host "$($TimeStamp) - Skipping Global AI Policy modification"
                        $GlobalAiPolicyVoiceFaceDisabled = $false
                    } 
                } else {
                    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Write-Host "$($TimeStamp) - VoiceEnrollment and FaceEnrollment are both set to Disabled"
                    Write-Host "$($TimeStamp) - The Global AI Policy settings reflect the Global Teams Meeting Policy" -ForegroundColor Green
                    Write-Host "$($TimeStamp) - No further action required" -ForegroundColor Green
                    Write-Host ""
                    $GlobalAiPolicyVoiceFaceDisabled = $True
                }
            } else {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Global AI Policy not found" -ForegroundColor Red
                Write-Host "$($TimeStamp) - Stopping script now" -ForegroundColor Red
                Write-Host "$($TimeStamp) - Check your current Tenant configuration" -ForegroundColor Red
                break
            }
        } else {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - EnrollUserOverride in Teams Meeting Policy is set to Enabled"
            Write-Host "$($TimeStamp) - No further action required for Global Teams AI Policy"
            $GlobalAiPolicyVoiceFaceDisabled = $false
        }
    #endregion Block Global Policy
    }

    #region Block for Non-Global Policies
    else {
        $PolicyName = $Policy.Identity.Split(':')[1]
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "$($TimeStamp) - Checking the the Teams Meeting policy"
        Write-Host "$($TimeStamp) - $($PolicyName)"
        Write-Host ""
        
        if (($Policy.EnrollUserOverride -eq "Enabled") -and ($UserAiPolicyVoiceFaceEnabled -eq $false) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $false)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - The Teams Meeting policy $($PolicyName) enables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - The Global AI Policy enables Voice and Face enrollment" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - There is no need to create a new AI Policy enabling Voice and Face enrollment" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - You can assign the Global AI policy to your users"
            Write-Host ""
            continue
        }

        if (($Policy.EnrollUserOverride -eq "Enabled") -and ($UserAiPolicyVoiceFaceEnabled -eq $false) -And ($GlobalAiPolicyVoiceFaceDisabled -eq $true)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - The Teams Meeting policy $($PolicyName) enables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - The script will create a new AI Policy to enable Voice and Face enrollment for specific users"
            Write-Host "$($TimeStamp) - You need to assign the policy afterwards" -ForegroundColor Yellow
            Write-Host ""
            try {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Creating new AI Policy - $($NewAiPolicyEnableName)"
                New-CsTeamsAIPolicy -Identity $NewAiPolicyEnableName -EnrollVoice Enabled -EnrollFace Enabled -ErrorAction Stop
                #$TeamsMeetingFaceVoiceEnrollmentEnable = $true
                $UserAiPolicyVoiceFaceEnabled = $true
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - New AI Policy created"
                Write-Host ""
            }
            catch {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Error creating new AI Policy" -ForegroundColor Red
                $Error[0]
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Stopping script now" -ForegroundColor Red
                break
            }
            continue
            
        }

        if (($Policy.EnrollUserOverride -eq "Enabled") -and ($UserAiPolicyVoiceFaceEnabled -eq $true) -And ($GlobalAiPolicyVoiceFaceDisabled -eq $true)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - The Teams Meeting policy $($PolicyName) enables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - The script will NOT create a new AI Policy as there already exists a new AI Policy enabling Voice and Face enrollment named $($NewAiPolicyEnableName)" -ForegroundColor Green
            Write-Host "$($TimeStamp) - You need to assign the policy to your users" -ForegroundColor Yellow
            Write-Host ""
            continue
        } 

        if (($Policy.EnrollUserOverride -eq "Disabled") -and ($UserAiPolicyVoiceFaceDisabled -eq $false) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $true)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - The Teams Meeting policy $($PolicyName) disables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - The Global AI Policy disables Voice and Face enrollment" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - There is no need to create a new AI Policy disabling Voice and Face enrollment" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - You can assign the Global AI policy to your users"
            Write-Host ""
            continue
        }

        if (($Policy.EnrollUserOverride -eq "Disabled") -and ($UserAiPolicyVoiceFaceDisabled -eq $false) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $false)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - The Teams Meeting policy $($PolicyName) disables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - The Global AI Policy enables Voice and Face enrollment"
            Write-Host "$($TimeStamp) - The script will create a new AI Policy to disable Voice and Face enrollment for specific users"
            Write-Host "$($TimeStamp) - You need to assign the policy afterwards" -ForegroundColor Yellow
            Write-Host ""
            try {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Creating new AI Policy - $($NewAiPolicyDisableName)"
                New-CsTeamsAIPolicy -Identity $NewAiPolicyDisableName -EnrollVoice Disabled -EnrollFace Disabled -ErrorAction Stop
                #$TeamsMeetingFaceVoiceEnrollmentDisable = $true
                $UserAiPolicyVoiceFaceDisabled = $true
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - New AI Policy created"
                Write-Host ""
            }
            catch {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Error creating new AI Policy" -ForegroundColor Red
                $Error[0]
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$($TimeStamp) - Stopping script now" -ForegroundColor Red
                break
            }
            continue
        }

        if (($Policy.EnrollUserOverride -eq "Disabled") -and ($UserAiPolicyVoiceFaceDisabled -eq $true) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $false)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "$($TimeStamp) - The Teams Meeting policy $($PolicyName) disables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Host "$($TimeStamp) - The script will NOT create a new AI Policy as there already exists a new AI Policy disabling Voice and Face enrollment named $($NewAiPolicyEnableName)" -ForegroundColor Green
            Write-Host "$($TimeStamp) - You need to assign the policy to your users" -ForegroundColor Yellow
            Write-Host ""            
            continue
        }
    }
    #endregion Block for Non-Global Policies
    
}

Get-CsTeamsAIPolicy | Format-Table -AutoSize


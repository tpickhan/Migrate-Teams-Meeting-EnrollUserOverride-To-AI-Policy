# Script gets current EnrollUserOverride setting from Teams Meeting Policy
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
Write-Output "$($TimeStamp) - Check Microsoft Teams Module"
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
    Write-Output "$($TimeStamp) - Connecting to Microsoft Teams"
    $tmp = Connect-MicrosoftTeams -ErrorAction Stop # Use of variable to suppress output
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$($TimeStamp) - Connected to Microsoft Teams"
}
catch {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Error "$($TimeStamp) - Error connecting to Microsoft Teams"
} 

# Define AI Policy Name and Description
# if the script needs to create a new AI Policy
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "$($TimeStamp) - Defining AI Policy Name and Description"
$NewAiPolicyEnableName = "Enable Voice Face Enrollment"
$NewAiPolicyDisableName = "Disable Voice Face Enrollment"


$UserAiPolicyVoiceFaceEnabled = $false
$UserAiPolicyVoiceFaceDisabled = $false

# Gather current Teams Meeting Policies and AI Policies
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "$($TimeStamp) - Gathering current Teams Meeting Policies and AI Policies"

$CurrentMeetingPolicies = Get-CsTeamsMeetingPolicy | Select-Object Identity,Description,EnrollUserOverride
$CurrentAIPolicies = Get-CsTeamsAIPolicy

# Check if there are multiple AI Policies
# if so, stop the script


if ($CurrentAIPolicies.Length -gt 1) {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$($TimeStamp) - Multiple AI Policies found"
    Write-Output "$($TimeStamp) - It seems that the AI Policies has been already modified"
    Write-Output "$($TimeStamp) - Please check your current Tenant configuration"
    Write-Output ""
    
    Write-Output ""
    Write-Output "==============================================="
    Write-Output ""
    Write-Output "Your current Teams Meeting Policies and Face and Voice Enrollment settings are:"
    Write-Output ""
    Write-Output "==============================================="
    Write-Output ""
    Write-Output $CurrentMeetingPolicies | Select-Object Identity,EnrollUserOverride | Format-Table -AutoSize
    Write-Output ""
    Write-Output "==============================================="
    Write-Output ""
    Write-Output "Your current AI Policies are:"
    Write-Output ""
    Write-Output "==============================================="
    Write-Output ""
    $CurrentAIPolicies | Format-Table -AutoSize
    Write-Output ""
    Write-Output "==============================================="
    Write-Output ""
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$($TimeStamp) - Stopping script now"
    break
}




ForEach ($Policy in $CurrentMeetingPolicies) {
    #region Global Policy Block
    if (($Policy.Identity -eq "Global")) {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "$($TimeStamp) - Checking the Global Teams Meeting policy"
        if ($Policy.EnrollUserOverride -eq "Disabled") {
            Write-Output "$($TimeStamp) - EnrollUserOverride is set to Disabled in Teams Meeting Policy"
            Write-Output "$($TimeStamp) - Will check if the Global AI Policy is set to Disabled"
            $CurrentAIPolicy = Get-CsTeamsAiPolicy -Identity Global
            if ($CurrentAIPolicy) {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - AI Policy found"
                Write-Output "$($TimeStamp) - Identity: $($CurrentAIPolicy.Identity)"
                Write-Output "$($TimeStamp) - VoiceEnrollment: $($CurrentAIPolicy.EnrollVoice)"
                Write-Output "$($TimeStamp) - FaceEnrollment: $($CurrentAIPolicy.EnrollFace)"
                Write-Output ""
                if (($CurrentAIPolicy.EnrollFace -eq "Enabled") -Or ($CurrentAIPolicy.EnrollVoice -eq "Enabled")) {
                    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Write-Output "$($TimeStamp) - VoiceEnrollment or FaceEnrollment is set to Enabled"
                    Write-Output "$($TimeStamp) - To reflect Global Teams Meeting Policy, these settings need to be Disabled" -ForegroundColor Yellow
                    Write-Output "$($TimeStamp) - Should the script update the AI Policy? (y)es/(n)o"
                    $response = Read-Host
                    while ($response -ne "y" -And $response -ne "n") {
                        Write-Output "Invalid response. Please enter 'y' or 'n'"
                        $response = Read-Host

                    }
                    if ($response -eq "y") {
                        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Output "$($TimeStamp) - Will update the AI Policy"
                        Set-CsTeamsAIPolicy -Identity $Policy.Identity -EnrollFace "Disabled" -EnrollVoice "Disabled"
                        $GlobalAiPolicyVoiceFaceDisabled = $true
                        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Output "$($TimeStamp) - AI Policy updated" -ForegroundColor Green
                    }
                    if ($response -eq "n") {
                        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Output "$($TimeStamp) - No further action required"
                        Write-Output "$($TimeStamp) - Skipping Global AI Policy modification"
                        $GlobalAiPolicyVoiceFaceDisabled = $false
                    } 
                } else {
                    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Write-Output "$($TimeStamp) - VoiceEnrollment and FaceEnrollment are both set to Disabled"
                    Write-Output "$($TimeStamp) - The Global AI Policy settings reflect the Global Teams Meeting Policy" -ForegroundColor Green
                    Write-Output "$($TimeStamp) - No further action required" -ForegroundColor Green
                    Write-Output ""
                    $GlobalAiPolicyVoiceFaceDisabled = $true
                }
            } else {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Global AI Policy not found" -ForegroundColor Red
                Write-Output "$($TimeStamp) - Stopping script now" -ForegroundColor Red
                Write-Output "$($TimeStamp) - Check your current Tenant configuration" -ForegroundColor Red
                break
            }
        } else {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - EnrollUserOverride in Teams Meeting Policy is set to Enabled" -ForegroundColor Green
            Write-Output "$($TimeStamp) - No further action required for Global Teams AI Policy" -ForegroundColor Green
            $GlobalAiPolicyVoiceFaceDisabled = $false
        }
    #endregion Block Global Policy
    }

    #region Block for Non-Global Policies
    else {
        $PolicyName = $Policy.Identity.Split(':')[1]
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "$($TimeStamp) - Checking the Teams Meeting policy"
        Write-Output "$($TimeStamp) - $($PolicyName)"
        Write-Output ""
        
        if (($Policy.EnrollUserOverride -eq "Enabled") -and ($UserAiPolicyVoiceFaceEnabled -eq $false) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $false)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - The Teams Meeting policy $($PolicyName) enables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - The Global AI Policy enables Voice and Face enrollment" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - There is no need to create a new AI Policy enabling Voice and Face enrollment" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - You can assign the Global AI policy to your users"
            Write-Output ""
            continue
        }

        if (($Policy.EnrollUserOverride -eq "Enabled") -and ($UserAiPolicyVoiceFaceEnabled -eq $false) -And ($GlobalAiPolicyVoiceFaceDisabled -eq $true)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - The Teams Meeting policy $($PolicyName) enables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - The script will create a new AI Policy to enable Voice and Face enrollment for specific users"
            Write-Output "$($TimeStamp) - You need to assign the policy afterwards" -ForegroundColor Yellow
            Write-Output ""
            try {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Creating new AI Policy - $($NewAiPolicyEnableName)"
                New-CsTeamsAIPolicy -Identity $NewAiPolicyEnableName -EnrollVoice Enabled -EnrollFace Enabled -ErrorAction Stop
                #$TeamsMeetingFaceVoiceEnrollmentEnable = $true
                $UserAiPolicyVoiceFaceEnabled = $true
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - New AI Policy created"
                Write-Output ""
            }
            catch {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Error creating new AI Policy" -ForegroundColor Red
                $Error[0]
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Stopping script now" -ForegroundColor Red
                break
            }
            continue
            
        }

        if (($Policy.EnrollUserOverride -eq "Enabled") -and ($UserAiPolicyVoiceFaceEnabled -eq $true) -And ($GlobalAiPolicyVoiceFaceDisabled -eq $true)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - The Teams Meeting policy $($PolicyName) enables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - The script will NOT create a new AI Policy as there already exists a new AI Policy enabling Voice and Face enrollment named $($NewAiPolicyEnableName)" -ForegroundColor Green
            Write-Output "$($TimeStamp) - You need to assign the policy to your users" -ForegroundColor Yellow
            Write-Output ""
            continue
        } 

        if (($Policy.EnrollUserOverride -eq "Disabled") -and ($UserAiPolicyVoiceFaceDisabled -eq $false) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $true)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - The Teams Meeting policy $($PolicyName) disables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - The Global AI Policy disables Voice and Face enrollment" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - There is no need to create a new AI Policy disabling Voice and Face enrollment" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - You can assign the Global AI policy to your users"
            Write-Output ""
            continue
        }

        if (($Policy.EnrollUserOverride -eq "Disabled") -and ($UserAiPolicyVoiceFaceDisabled -eq $false) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $false)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - The Teams Meeting policy $($PolicyName) disables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - The Global AI Policy enables Voice and Face enrollment"
            Write-Output "$($TimeStamp) - The script will create a new AI Policy to disable Voice and Face enrollment for specific users"
            Write-Output "$($TimeStamp) - You need to assign the policy afterwards" -ForegroundColor Yellow
            Write-Output ""
            try {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Creating new AI Policy - $($NewAiPolicyDisableName)"
                New-CsTeamsAIPolicy -Identity $NewAiPolicyDisableName -EnrollVoice Disabled -EnrollFace Disabled -ErrorAction Stop
                #$TeamsMeetingFaceVoiceEnrollmentDisable = $true
                $UserAiPolicyVoiceFaceDisabled = $true
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - New AI Policy created"
                Write-Output ""
            }
            catch {
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Error creating new AI Policy" -ForegroundColor Red
                $Error[0]
                $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "$($TimeStamp) - Stopping script now" -ForegroundColor Red
                break
            }
            continue
        }

        if (($Policy.EnrollUserOverride -eq "Disabled") -and ($UserAiPolicyVoiceFaceDisabled -eq $true) -and ($GlobalAiPolicyVoiceFaceDisabled -eq $false)) {
            $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Output "$($TimeStamp) - The Teams Meeting policy $($PolicyName) disables Voice and Face enrollment for users" -ForegroundColor Yellow
            Write-Output "$($TimeStamp) - The script will NOT create a new AI Policy as there already exists a new AI Policy disabling Voice and Face enrollment named $($NewAiPolicyEnableName)" -ForegroundColor Green
            Write-Output "$($TimeStamp) - You need to assign the policy to your users" -ForegroundColor Yellow
            Write-Output ""            
            continue
        }
    }
    #endregion Block for Non-Global Policies
    
}

#region Summary Block
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "$($TimeStamp) - Script completed" -ForegroundColor Green
Write-Output ""
Write-Output "$($TimeStamp) - Your current Teams Meeting Policy Settings:"
Write-Output ""
Write-Output $CurrentMeetingPolicies | Select-Object Identity,EnrollUserOverride | Format-Table -AutoSize
Write-Output ""
Write-Output "Your AI Policies before running the script:"
Write-Output ""
Write-Output $CurrentAIPolicies | Format-Table -AutoSize
Write-Output ""
Write-Output "Your current AI Policies after running the script:"
Write-Output ""
Get-CsTeamsAIPolicy | Format-Table -AutoSize

#endregion Summary Block


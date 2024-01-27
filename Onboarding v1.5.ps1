<#

#      || LANDRY LABS - ONBOARDING SCRIPT (Updated 04/08/2023)
#      || SUMMARY: 1. Creates on-prem user object and populates with verified user information.;
# #    || -------- 2. Provisions mailbox and cloud group SSO access;
####   || -------- 3. Pushes out email to mi-t2 with transcription note & separate email to HR with initial password.;
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

#>

<#----------TO DO:
-BUILD:
-FIX:
-IMPROVE:
----------#>

<#----------Change Log:
5/4/23 - The new hire's manager is now CC'ed with MI-T2 in the final email push to HR.
5/6/23 - An 'Archive' folder is now used to house previously processed onboarding transcript files.
5/6/23 - A togglable option to be granted Connectwise Manage SSO access has been added.
10/24/23 - Added a value override to the Manager function for submissions of 'DJ Evans' to 'DeWayne.Evans'.
10/24/23 - Added a value override to the Practice function for submissions of 'Digital Transformation' to return that string immediately.
10/24/23 - Added OU Path Overriding for HR template: "OU=Business Process Management,OU=Digital Transformation"
10/24/23 - Added overriding to the Manager function for submissions of 'Vidya Shankar Ramanagara Seshadri' to return 'vidyashankar.rs' without verification.

----------#>

$Host.UI.RawUI.WindowTitle = "Sparkhound Onboarding v1.5"
# 5/5/23 - TESTING TRANSCRIPT RENAMING AND ARCHIVING.
    $DefaultTranscriptFile = "$(Get-Location)\Onboardings\OnboardingTranscript.txt"
    $TranscriptArchivePath = "$(Get-Location)\Onboardings\Archive"
    mkdir $TranscriptArchivePath
    Write-Host "Please ignore the possible error of: 'An item with the specified name already exists.'"
    Start-Transcript -Path $DefaultTranscriptFile
    $LastUpdatedDate = "5/28/2023";
    #Start-Transcript -Path "$(Get-Location)\Onboardings\OnboardingTranscript.txt"
$TimeStart = Get-Date

#==========^==========#
#START OF FUNCTIONS
#==========V==========#

function ObtainTicketNumber
{
    $ticketNumber = Read-Host "Enter Connectwise Ticket Number (Don't include the '#')";
        #if ($ticketNumber.Length -ne "6") {Write-Host "Ticket Number must be 6 characters long."; $ticketNumber = $Null; ObtainTicketNumber};
    Write-Host "Submitted Ticket Number: $ticketNumber";
    $ticketNumber = "#$ticketNumber";
    Return $ticketNumber;
}

function ObtainTicketNumberWithVerification
{
    $arrayOfNumbers = @("0", "1", "2", "3", "4", "5", "6", "7", "8", "9");

    $ticketNumber = Read-Host "Enter Connectwise Ticket Number";
        if ($ticketNumber.Length -ne "6") {Write-Host "Ticket Number must be 6 characters long."};
        foreach ($num in $arrayOfNumbers) 
        {
            $i = 0;
            if ($num -eq $ticketNumber[$i]) {Write-Host ""}}



    Write-Host "Submitted Ticket Number: $ticketNumber";
    Return $ticketNumber;
}

function ObtainFirstName
{
            
    $FirstName = Read-Host "First Name";
    Write-Host "Submitted First Name: $FirstName"
    Return $FirstName;
}
function ObtainLastName
{
            
    $LastName = Read-Host "Last Name";
    Write-Host "Submitted Last Name: $LastName"
    Return $LastName;
}
function ObtainFullName
{
    $Name = "$FirstName $LastName";
    Write-Host "Declared Full Name: $Name"
    Return $Name;
}
function ObtainUserName #Only changes through input of first and last name functions.
{
            $usernameAvailable = "N"
            $username = "$FirstName.$LastName";
            $userExistsCheck = (get-aduser -filter {samaccountname -like $username}).samaccountname #Verify if username is already in use.
            Write-Host "Verifying '$username'..." -NoNewline
            start-sleep 1
                if ($username -eq $userExistsCheck)
                {
                    $usernameAvailable = "N";
                    $existinguserproperties = Get-ADUser -Identity $username;
                    Write-Host "ALREADY IN USE!" -ForegroundColor Red;
                    $existinguserproperties
                    ObtainFirstName;
                    ObtainLastName;
                    ObtainUserName;
                }
                else 
                {
                    $usernameAvailable = "Y";
                    Write-Host "AVAILABLE TO USE!" -ForegroundColor Green;
                    return $username
                }
}
function ObtainEmailAddress
{
    $EmailAddress = "$username@sparkhound.com";
    Write-Host "Declared Email: $EmailAddress"
    return $EmailAddress;
}
function ObtainTitle
{
    $Title = Read-Host "Title";
    Write-Host "Submitted Title $Title"
    $TitleUKGCheck = $Title.IndexOf("-");
    if ($TitleUKGCheck -ne "-1")
        {
            $Title = $Title.Split("-")
            $Title = $Title[1];
        }
    Write-Host "Verified Title: $Title"
    Return $Title;
    #Do not allow the acroymn titles in UKG to be submitted.
    #Will need to strip away UKG prefix.
}
function ObtainRegion
{
    #ONLY accept the following regions: Baton Rouge(BTR), Birmingham(BHM), Dallas(DFW), Houston(HOU), N/A;
    $Region = Read-Host "Region (Baton Rouge, Houston, Dallas, Birmingham)";
    Write-Host "Submitted Region: $Region"
    $RegionUKGCheck = $Region.IndexOf("-");
    if ($RegionUKGCheck -ne "-1")
        {
            $Region = $Region.Split("-")
            $Region = $Region[1];
        }
    if ($Region -eq "Baton Rouge" -or $Region -eq "Birmingham" -or $Region -eq "Dallas" -or $Region -eq "Houston")
        {
            Write-Host "Verified Region: $Region"
            Return $Region;
        }
    else 
        {
            Write-Host "Invalid region. Try again."
            ObtainRegion
        }
}
function ObtainPhoneNumber
{
    #OPTIONAL/EXTRA: Force Formatting restrictions on submission.
    $PhoneNumber = Read-Host "Phone Number";
    Write-Host "Submitted Phone Number: $PhoneNumber"
    Return $PhoneNumber;        
}
function ObtainPersonalEmail
{
    #OPTIONAL/EXTRA: Force Formatting restrictions on submission.
    $PersonalEmail = Read-Host "Personal Email";
    Write-Host "Submitted Personal Email: $PersonalEmail"
    Return $PersonalEmail;
    
}
function ObtainCompany
{
    $Company = Read-Host "Company ('Sparkhound' or Contracting Company)";
    Write-Host "Submitted Company: $Company"
    if ($company -ne "Sparkhound")
        {
            "Setting $username as a contractor";
            $Contractor = "Y"; 
            $Title = "Contractor ($company)";
        } 
    else 
        {
            $Contractor = "N"
        };
    Return $Company;
}
function ObtainManager
{
    $Manager = Read-Host "Manager's username (Enter 'N' to not assign a manager)"; #Verify manager. Allow option to process without.
    
    Write-Host "Verifying manager '$Manager'..." -NoNewline
    if ($Manager -eq 'Lisa Stambaugh-Mencer')
        {$Manager = "Lisa.Mencer"}
    if ($Manager -eq 'DJ Evans')
        {$Manager = "DeWayne.Evans"}
    if ($Manager -eq "Vidya Shankar Ramanagara Seshadri")
        {$Manager = "vidyashankar.rs"};
    Start-sleep 1
    if ($Manager -eq 'N') #Manual bypass of manager assignment.
        {
            Write-Host "NO MANAGER ASSIGNED. SKIPPING." -ForegroundColor Green;
            $Manager = "$Null"
            $managerAssigned = "Y"
            return $manager
        }
    else
        {
            $managerExistsVerification = (get-aduser -filter {samaccountname -like $Manager}).samaccountname
                if ($Null -ne $managerExistsVerification) #Manager automatically matched.
                    {
                        $Manager = $managerExistsVerification;
                        $managerUpper = $Manager.ToUpper();
                        Write-Host "..." -NoNewline
                        Write-Host "'$ManagerUpper' ASSIGNED SUCCESSFULLY." -ForegroundColor Green;
                        $managerAssigned = "Y"
                        return $manager
                    }   
                elseif ($managerExistsVerification -eq $Null)
                    {
                        #Write-Host "UNABLE TO VERIFY" -ForegroundColor Red -NoNewline
                        Start-sleep 1
                        Write-Host "..." -NoNewline
                        $managerFormattingCheck1 = $manager.indexOf("."); #Checking if '.' (period) character is present (standard username formatting) to use it as delimmiter.
                        $managerFormattingCheck2 = $manager.indexOf(" "); #Checking if ' ' (space) character is present (standard UKG name formatting) to use it as delimmiter.
                            if ($managerFormattingCheck1 -ne "-1")
                                {
                                    $managerString = "$Manager";
                                    $managerStringSplit = $managerString.Split(".");
                                        foreach ($string in $managerStringSplit)
                                            {
                                                $managerWildcard = "*$string*";
                                                $managerExistsVerification = (get-aduser -filter {samaccountname -like $managerWildcard}).samaccountname
                                                    $i = 0;
                                                    foreach ($entry in $managerExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as manager.
                                                        {
                                                            $i++
                                                        }
                                                if ($i -eq 0)
                                                    {
                                                        Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                        $managerAssigned = "N"
                                                        break
                                                    }
                                                elseif ($i -eq 1)
                                                    {
                                                
                                                        Write-Host "MATCH FOUND ($managerExistsVerification)" -ForegroundColor Green -NoNewline
                                                        start-sleep 1
                                                        Write-Host "..." -NoNewline
                                                        Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                        $manager = $managerExistsVerification
                                                        $managerAssigned = "Y"
                                                        break
                                                    }
                                                elseif ($i -gt 1)
                                                    {
                                                        start-sleep 1
                                                        Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                        Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the manager."
                                                        start-sleep 1
                                                            foreach ($name in $managerExistsVerification)
                                                                {
                                                                    $name = $name.ToLower();
                                                                    Write-Host "$name;"
                                                                }
                                                        Write-Host "`n"
                                                        $managerAssigned = "N"
                                                        break
                                                        #Kicks back to the start to enter the proper name of the manager and allows a final validation before declaration.
                                                    }
                                            }
                                    
                                    if ($managerAssigned -eq "Y")
                                        {
                                            return $manager
                                        }
                                    else 
                                        {
                                            ObtainManager;
                                        } 
                                }
                            elseif ($managerFormattingCheck2 -ne "-1")
                                {
                                    $manager = $manager.Replace(" ",".")
                                    $managerString = "$Manager";
                                        foreach ($string in $managerString)
                                            {
                                                $managerWildcard = "*$string*";
                                                $managerExistsVerification = (get-aduser -filter {samaccountname -like $managerWildcard}).samaccountname
                                                    $i = 0;
                                                    foreach ($entry in $managerExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as manager.
                                                        {
                                                            $i++
                                                        }
                                                if ($i -eq 0)
                                                    {
                                                        Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                        $managerAssigned = "N"
                                                        break
                                                    }
                                                elseif ($i -eq 1)
                                                    {
                                                
                                                        Write-Host "MATCH FOUND ($managerExistsVerification)" -ForegroundColor Green -NoNewline
                                                        start-sleep 1
                                                        Write-Host "..." -NoNewline
                                                        Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                        $manager = $managerExistsVerification
                                                        $managerAssigned = "Y"
                                                        break
                                                    }
                                                elseif ($i -gt 1)
                                                    {
                                                        start-sleep 1
                                                        Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                        Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the manager."
                                                        start-sleep 1
                                                            foreach ($name in $managerExistsVerification)
                                                                {
                                                                    $name = $name.ToLower();
                                                                    Write-Host "$name;"
                                                                }
                                                        Write-Host "`n"
                                                        $managerAssigned = "N"
                                                        break
                                                        #Kicks back to the start to enter the proper name of the manager and allows a final validation before declaration.
                                                    }
                                            }
                                    if ($managerAssigned -eq "Y")
                                        {
                                            return $manager
                                        }
                                    else 
                                        {
                                            $managerString = $managerString.Split(".");
                                            foreach ($string in $managerString)
                                                {
                                                    $managerWildcard = "*$string*";
                                                    $managerExistsVerification = (get-aduser -filter {samaccountname -like $managerWildcard}).samaccountname
                                                        $i = 0;
                                                        foreach ($entry in $managerExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as manager.
                                                            {
                                                                $i++
                                                            }
                                                    if ($i -eq 0)
                                                        {
                                                            Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                            $managerAssigned = "N"
                                                            break
                                                        }
                                                    elseif ($i -eq 1)
                                                        {
                                                    
                                                            Write-Host "MATCH FOUND ($managerExistsVerification)" -ForegroundColor Green -NoNewline
                                                            start-sleep 1
                                                            Write-Host "..." -NoNewline
                                                            Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                            $manager = $managerExistsVerification
                                                            $managerAssigned = "Y"
                                                            break
                                                        }
                                                    elseif ($i -gt 1)
                                                        {
                                                            start-sleep 1
                                                            Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                            Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the manager."
                                                            start-sleep 1
                                                                foreach ($name in $managerExistsVerification)
                                                                    {
                                                                        $name = $name.ToLower();
                                                                        Write-Host "$name;"
                                                                    }
                                                            Write-Host "`n"
                                                            $managerAssigned = "N"
                                                            break
                                                            #Kicks back to the start to enter the proper name of the manager and allows a final validation before declaration.
                                                        }
                                                }
                                        
                                        if ($managerAssigned -eq "Y")
                                            {
                                                return $manager
                                            }
                                        else 
                                            {
                                                ObtainManager;
                                            }
                                        }


                                    
                                }
                    }
        }
}
function ObtainMirrorUser
{
    $MirrorUser = Read-Host "MirrorUser's username (Enter 'N' to not assign a mirrorUser)"; #Verify mirrorUser. Allow option to process without.
    Write-Host "Verifying mirrorUser '$MirrorUser'..." -NoNewline
    Start-sleep 1
    if ($MirrorUser -eq 'N') #Manual bypass of mirrorUser assignment.
        {
            Write-Host "NO MIRROR-USER ASSIGNED. SKIPPING." -ForegroundColor Green;
            $MirrorUser = "$Null"
            $mirrorUserAssigned = "Y"
            return $mirrorUser
        }
    else
        {
            $mirrorUserExistsVerification = (get-aduser -filter {samaccountname -like $MirrorUser}).samaccountname
                if ($Null -ne $mirrorUserExistsVerification) #MirrorUser automatically matched.
                    {
                        $MirrorUser = $mirrorUserExistsVerification;
                        $mirrorUserUpper = $MirrorUser.ToUpper();
                        Write-Host "..." -NoNewline
                        Write-Host "'$MirrorUserUpper' ASSIGNED SUCCESSFULLY." -ForegroundColor Green;
                        $mirrorUserAssigned = "Y"
                        return $mirrorUser
                    }   
                elseif ($mirrorUserExistsVerification -eq $Null)
                    {
                        #Write-Host "UNABLE TO VERIFY" -ForegroundColor Red -NoNewline
                        Start-sleep 1
                        Write-Host "..." -NoNewline
                        $mirrorUserFormattingCheck1 = $mirrorUser.indexOf("."); #Checking if '.' (period) character is present (standard username formatting) to use it as delimmiter.
                        $mirrorUserFormattingCheck2 = $mirrorUser.indexOf(" "); #Checking if ' ' (space) character is present (standard UKG name formatting) to use it as delimmiter.
                            if ($mirrorUserFormattingCheck1 -ne "-1")
                                {
                                    $mirrorUserString = "$MirrorUser";
                                    $mirrorUserStringSplit = $mirrorUserString.Split(".");
                                        foreach ($string in $mirrorUserStringSplit)
                                            {
                                                $mirrorUserWildcard = "*$string*";
                                                $mirrorUserExistsVerification = (get-aduser -filter {samaccountname -like $mirrorUserWildcard}).samaccountname
                                                    $i = 0;
                                                    foreach ($entry in $mirrorUserExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as mirrorUser.
                                                        {
                                                            $i++
                                                        }
                                                if ($i -eq 0)
                                                    {
                                                        Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                        $mirrorUserAssigned = "N"
                                                        break
                                                    }
                                                elseif ($i -eq 1)
                                                    {
                                                
                                                        Write-Host "MATCH FOUND ($mirrorUserExistsVerification)" -ForegroundColor Green -NoNewline
                                                        start-sleep 1
                                                        Write-Host "..." -NoNewline
                                                        Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                        $mirrorUser = $mirrorUserExistsVerification
                                                        $mirrorUserAssigned = "Y"
                                                        break
                                                    }
                                                elseif ($i -gt 1)
                                                    {
                                                        start-sleep 1
                                                        Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                        Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the mirrorUser."
                                                        start-sleep 1
                                                            foreach ($name in $mirrorUserExistsVerification)
                                                                {
                                                                    $name = $name.ToLower();
                                                                    Write-Host "$name;"
                                                                }
                                                        Write-Host "`n"
                                                        $mirrorUserAssigned = "N"
                                                        break
                                                        #Kicks back to the start to enter the proper name of the mirrorUser and allows a final validation before declaration.
                                                    }
                                            }
                                    
                                    if ($mirrorUserAssigned -eq "Y")
                                        {
                                            return $mirrorUser
                                        }
                                    else 
                                        {
                                            ObtainMirrorUser;
                                        } 
                                }
                            elseif ($mirrorUserFormattingCheck2 -ne "-1")
                                {
                                    $mirrorUserString = "$MirrorUser";
                                    $mirrorUserStringSplit = $mirrorUserString.Split(" ");
                                        foreach ($string in $mirrorUserStringSplit)
                                            {
                                                $mirrorUserWildcard = "*$string*";
                                                $mirrorUserExistsVerification = (get-aduser -filter {samaccountname -like $mirrorUserWildcard}).samaccountname
                                                    $i = 0;
                                                    foreach ($entry in $mirrorUserExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as mirrorUser.
                                                        {
                                                            $i++
                                                        }
                                                if ($i -eq 0)
                                                    {
                                                        Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                        $mirrorUserAssigned = "N"
                                                        break
                                                    }
                                                elseif ($i -eq 1)
                                                    {
                                                
                                                        Write-Host "MATCH FOUND ($mirrorUserExistsVerification)" -ForegroundColor Green -NoNewline
                                                        start-sleep 1
                                                        Write-Host "..." -NoNewline
                                                        Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                        $mirrorUser = $mirrorUserExistsVerification
                                                        $mirrorUserAssigned = "Y"
                                                        break
                                                    }
                                                elseif ($i -gt 1)
                                                    {
                                                        start-sleep 1
                                                        Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                        Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the mirrorUser."
                                                        start-sleep 1
                                                            foreach ($name in $mirrorUserExistsVerification)
                                                                {
                                                                    $name = $name.ToLower();
                                                                    Write-Host "$name;"
                                                                }
                                                        Write-Host "`n"
                                                        $mirrorUserAssigned = "N"
                                                        break
                                                        #Kicks back to the start to enter the proper name of the mirrorUser and allows a final validation before declaration.
                                                    }
                                            }
                                    
                                    if ($mirrorUserAssigned -eq "Y")
                                        {
                                            return $mirrorUser
                                        }
                                    else 
                                        {
                                            ObtainMirrorUser;
                                        }
                                }
                    }
        }
}
function ObtainStartDate
{
    $StartDate = Read-Host "Start Date"
    Write-Host "Submitted Start Date: $StartDate"
    Return $StartDate;
}
function ObtainPractice
{
    

    #Verify the given OU exists.
    #Example UKG Practice: 'AUTSVC-Automation Services'
    #"OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
    $Practice = Read-Host "Practice";
    $PracticeOUPath = "OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com" 
    Write-Host "Verifying Practice '$Practice'..." -NoNewline
    Start-sleep 1
    $practiceOUCHeck1 = (Get-ADObject -Filter "identity -like '$PracticeOUPath'").distinguishedname #VERIFY CHECK 1
    Write-Host "..." -NoNewline
    if ($Practice -eq "Digital Transformation") # 10/24: This practice doens't exist as an OU. Returing immediately and overriding in 'Department' function.
        {
            Write-Host "Skipping verification. Returning allowed override of Practice 'Digital Transformation'"
            return $Practice;
        }
    if ($Practice -eq "CALLCT-Contact Center Operations")
        {
            $Practice = "Contact Center Operations"
            Write-Host "Skipping verification. Returning allowed override of Practice 'Digital Transformation'"
            return $Practice;
        }
    if ($Null -ne $practiceOUCHeck1)
        {
            
            Write-Host "ASSIGNED SUCCESSFULLY" -ForegroundColor Green;
            $PracticeOUAssigned = "Y";
            return $practiceOUCHeck1;
        }
    else 
        {
            #Write-Host "UNABLE TO VERIFY" -NoNewline -ForegroundColor Red
            Write-Host "..." -NoNewline
            $practiceFormattingCheckDash = $practice.IndexOf("-"); #Checks if the UKG formatted practice was submitted.
            $PracticeString = "$Practice"
            if ($practiceFormattingCheckDash -ne "-1")
                {
                    $PracticeStringSplit = $PracticeString.Split("-"); #Breaks apart the UKG prefix string from the actual OU name.
                    $PracticeStringSplit = $PracticeStringSplit[1]#.Split(" ");
                }
            <# else 
                {
                    $PracticeStringSplit = $PracticeString.Split(" "); #Breaks apart the OU name into separate searchable words.
                    $PracticeStringSplit
                } #>
                foreach ($string in $PracticeStringSplit)
                    {
                        $practiceSearchWildcard = "*$string*";
                        $practiceSearchVerification = (Get-ADObject -filter "name -like '$practiceSearchWildcard'" -SearchBase "OU=Domain Users,DC=sparkhound,DC=com" -SearchScope OneLevel).name
                            $i = 0;
                            foreach ($item in $practiceSearchVerification)
                                {
                                    $i++
                                }
                        if ($i -eq 0)
                            {
                                Write-Host "NO PRACTICE WAS FOUND. TRY AGAIN." -ForegroundColor Red;
                                $PracticeAssigned = "N"
                                break
                            }
                        elseif ($i -eq 1)
                            {
                        
                                Write-Host "MATCH FOUND ($practiceSearchVerification)" -ForegroundColor Green -NoNewline
                                start-sleep 1
                                Write-Host "..." -NoNewline
                                Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                $Practice = $practiceSearchVerification
                                $PracticeAssigned = "Y"
                                break
                            }
                        elseif ($i -gt 1)
                            {
                                start-sleep 1
                                Write-Host "DETECTED MULTIPLE PRACTICES`n"
                                Write-Host "Generating list of references (ignore duplicates). Please enter your submission again using the reference."
                                start-sleep 1
                                    foreach ($name in $practiceSearchVerification)
                                        {
                                            $name = $name.ToLower();
                                            Write-Host "$name;"
                                        }
                                Write-Host "`n"
                                $PracticeAssigned = "N"
                                break
                            }
                    }
                if ($PracticeAssigned -eq "Y")
                    {
                        return $Practice
                    }
                else 
                    {
                        ObtainPractice;
                    } 
                    
        }                    
}
function ObtainDepartment ($Practice)
{
    #Verify the given OU exists.
    #Example UKG Department: 'SVCDSK-Tier 1'
    #"OU=$department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
    $Department = Read-Host "Department";
    $DepartmentWildcard = "*$Department*"
    $DepartmentOUPath = "OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
    Write-Host "Verifying Department '$Department'..." -NoNewline

    if ($Department -eq "SVCDSK-Tier 1")
        {
            $Department = "Tier I"
            #$DepartmentWildCard = "$Department"
            return $Department
        }
    if ($Department -eq "Support Service-Tier 1")
        {
            $Department = "Tier I"
            return $Department
        }
    if ($Department -eq "Business Process Management")
        {
            Write-Host "Skipping verification. Returning allowed override of Department 'Business Process Management'"
            return $Department;
        }
    if ($Department -eq "Partner") # 01/08/24: Added to support CWM ticket #918395.
        {
            $Department = "Executive";
            Write-Host "Skipping verification. Returning allowed override of department 'Partner' to 'Executive'."
            return $Department;
        }
    if ($Department -eq "CALLCR-Contact Center Operations")
        {
            $Department = "Contact Center Operations";
            Write-Host "Skipping verification. Returning allowed override of department 'Contact Center Operations'."
            return $Department;
        }
    Start-sleep 1
    $departmentOUCheck0 = Get-ADObject -Filter "name -eq '$department'" -SearchBase "$DepartmentOUPath" -SearchScope OneLevel
    if ($Null -ne $departmentOUCHeck0)
        {
            Write-Host "..." -NoNewline
            Write-Host "ASSIGNED SUCCESSFULLY" -ForegroundColor Green;
            $DepartmentOUAssigned = "Y";
            return $departmentOUCHeck0;
        }
    $departmentOUCHeck1 = (Get-ADObject -Filter "name -like '$DepartmentWildcard'" -SearchBase "$DepartmentOUPath" -SearchScope OneLevel).name #VERIFY CHECK 1    
    if ($Null -ne $departmentOUCHeck1)
        {
            Write-Host "..." -NoNewline
            Write-Host "ASSIGNED SUCCESSFULLY" -ForegroundColor Green;
            $DepartmentOUAssigned = "Y";
            return $departmentOUCHeck1;
        }
    else 
        {
            #Write-Host "UNABLE TO VERIFY" -NoNewline -ForegroundColor Red
            Write-Host "..." -NoNewline
            $departmentFormattingCheckDash = $department.IndexOf("-"); #Checks if the UKG formatted department was submitted.
            $DepartmentString = "$Department"
            if ($departmentFormattingCheckDash -ne "-1")
                {
                    $DepartmentStringSplit = $DepartmentString.Split("-"); #Breaks apart the UKG prefix string from the actual OU name.
                    $DepartmentStringSplit = $DepartmentStringSplit[1]#.Split(" ");
                }
            <# else 
                {
                    $DepartmentStringSplit = $DepartmentString.Split(" "); #Breaks apart the OU name into separate searchable words.
                    $DepartmentStringSplit
                } #>
                foreach ($string in $DepartmentStringSplit)
                    {
                        $departmentSearchWildcard = "*$string*";
                        $departmentSearchVerification = (Get-ADObject -filter "name -like '$departmentSearchWildcard'" -SearchBase "$DepartmentOUPath" -SearchScope OneLevel).name
                            $i = 0;
                            foreach ($item in $departmentSearchVerification)
                                {
                                    $i++
                                }
                        if ($i -eq 0)
                            {
                                Write-Host "NO MATCH WAS FOUND. TRY AGAIN." -ForegroundColor Red;
                                $DepartmentAssigned = "N"
                                break
                            }
                        elseif ($i -eq 1)
                            {
                        
                                Write-Host "MATCH FOUND ($departmentSearchVerification)" -ForegroundColor Green -NoNewline
                                start-sleep 1
                                Write-Host "..." -NoNewline
                                Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                $Department = $departmentSearchVerification
                                $DepartmentAssigned = "Y"
                                break
                            }
                        elseif ($i -gt 1)
                            {
                                start-sleep 1
                                Write-Host "DETECTED MULTIPLE MATCHES`n"
                                Write-Host "Generating list of references (ignore duplicates). Please enter your submission again using the reference."
                                start-sleep 1
                                    foreach ($name in $departmentSearchVerification)
                                        {
                                            $name = $name.ToLower();
                                            Write-Host "$name;"
                                        }
                                Write-Host "`n"
                                $DepartmentAssigned = "N"
                                break
                            }
                    }
                if ($DepartmentAssigned -eq "Y")
                    {
                        return $Department
                    }
                else 
                    {
                        ObtainDepartment;
                    } 
                    
        }                    
}

function ObtainBusinessUnit ($Practice)
{
    if ($Practice -eq "Automation Services" -or $Practice -eq "Business Process Mgt")
        {
            $BusinessUnit = "Digital Automation";
        }
    if ($Practice -eq "Contact Center Operations")
        {
            $BusinessUnit = "Contact Center Operations";
        }
    if ($Practice -eq "Support Services" -or $Practice -eq "IT Modernization Services")
        {
            $BusinessUnit = "Managed Infrastructure";
        }
    if ($Practice -eq "Shared Services" -or "Corp")
        {
            $BusinessUnit = "Corporate";
        }
    return $BusinessUnit
}
function ObtainUserOUPath ($Department, $Practice)
{
    # (10/24/23) OU Path Overriding for HR template: "OU=Business Process Management,OU=Digital Transformation"
    $UserOUPath = "OU=$Department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
    if ($Practice -eq "Digital Transformation" -and $Department -eq "Business Process Management")
        {
            $UserOUPath = "OU=Business Process Management,OU=Domain Users,DC=sparkhound,DC=com";
            return $UserOUPath;
        }
    if ($Practice -eq "Contact Center Operations" -and $Department -eq "Contact Center Operations")
        {
            $UserOUPath = "OU=Contact Center Operations,OU=Domain Users,DC=sparkhound,DC=com";
            return $UserOUPath;
        }
    Write-Host "Declared OU Path: $userOUPath"
    return $UserOUPath;
}
function ObtainCloudItemUKG
{
    #Only allow "Yes" or "No".
    $UKGSSO = Read-Host "UKG SSO Yes/No"
    Write-Host "Submitted UKG Selection: $UKGSSO"
    $UGKSSOCheck = $UKGSSO.IndexOf(" ")
    if ($UKGSSOCheck -ne "-1")
        {
            $UKGSSO = $UKGSSO.Split(" ");
        }
    foreach ($item in $UKGSSO)
        {
            switch ($item)
                {
                    "Yes" 
                        {
                            $UKGVerified = "Y"
                            $UKGSSO = $item
                            break
                        }
                    "No" 
                        {
                            $UKGVerified = "Y"
                            $UKGSSO = $item
                            break
                        }
                    default 
                        {
                            $UKGVerified = "N"
                            break
                        }
                }
        }
    if ($UKGVerified -eq "Y")
        {
            Return $UKGSSO;
        }
    else
        {
            ObtainCloudItemUKG
        }
}
function ObtainCloudItemOA
{
        #Only allow "Yes" or "No".
        $OpenAirSSO = Read-Host "OpenAir SSO Yes/No"
        Write-Host "Submitted OpenAir Selection: $OpenAirSSO"
        $OpenAirSSOCheck = $OpenAirSSO.IndexOf(" ")
        if ($OpenAirSSOCheck -ne "-1")
            {
                $OpenAirSSO = $OpenAirSSO.Split(" ");
            }
        foreach ($item in $OpenAirSSO)
            {
                switch ($item)
                    {
                        "Yes" 
                            {
                                $OpenAirVerified = "Y"
                                $OpenAirSSO = $item
                                break
                            }
                        "No" 
                            {
                                $OpenAirVerified = "Y"
                                $OpenAirSSO = $item
                                break
                            }
                    }
                }
            if ($OpenAirVerified -eq "Y")
                {
                    Return $OpenAirSSO;
                }
            else
                {
                    ObtainCloudItemOA
                }
}
function ObtainCloudItemNetSuite
{
    #Only allow "Yes" or "No".
    $NetSuiteSSO = Read-Host "NetSuite SSO Yes/No"
    Write-Host "Submitted NetSuite Selection: $NetSuiteSSO"
    $NetSuiteSSOCheck = $NetSuiteSSO.IndexOf(" ")
    if ($NetSuiteSSOCheck -ne "-1")
        {
            $NetSuiteSSO = $NetSuiteSSO.Split(" ");
        }
    foreach ($item in $NetSuiteSSO)
        {
            switch ($item)
                {
                    "Yes" 
                        {
                            $NetSuiteVerified = "Y"
                            $NetSuiteSSO = $item
                            break
                        }
                    "No" 
                        {
                            $NetSuiteVerified = "Y"
                            $NetSuiteSSO = $item
                            break
                        }
                }
            }
        if ($NetSuiteVerified -eq "Y")
            {
                Return $NetSuiteSSO;
            }
        else
            {
                ObtainCloudItemNetSuite
            }
}
function ObtainCloudItemConnectwiseSSO
{
    #Only allow "Yes" or "No".
    $ConnectwiseSSO = Read-Host "Connectwise SSO? (Yes/No)"
    Write-Host "Submitted Connectwise Selection: $ConnectwiseSSO"
    switch ($ConnectwiseSSO)
                {
                    "Yes" 
                        {
                            $ConnectwiseVerified = "Y"
                            $ConnectwiseSSO = $ConnectwiseSSO
                            break
                        }
                    "No" 
                        {
                            $ConnectwiseVerified = "Y"
                            $ConnectwiseSSO = $ConnectwiseSSO
                            break
                        }
                }
        if ($ConnectwiseVerified -eq "Y")
            {
                Return $ConnectwiseSSO;
            }
        else
            {
                ObtainCloudItemConnectwiseSSO
            }
}
function ObtainTempPassword
{
    $PasswordRequest = Read-Host "New User Password (Only 'Welcome@123' is accepted)"
    if ($PasswordRequest -ne "Welcome@123")
        {
            Write-Host "Invalid. Enter 'Welcome@123' to continue." -ForegroundColor Red
            ObtainTempPassword
        }
    $Password = ConvertTo-SecureString $PasswordRequest -AsPlainText -Force
    Return $Password;
}

Function Menu # SCRIPT GREETING AND REQUESTING CONFIRMATION TO START ONBOARDING OR EXIT.
{
    "`n"
    "--------------------------------------------------"
    Write-Host "'Y': Begin a standard onboarding."
    Write-Host "'T': Test mode." #Might just become 'TEST MODE' with further options.
    Write-Host "'R': Restore standard security levels (MFA and temp password)"
    Write-Host "'X': Exit"
    "--------------------------------------------------"
    $Begin = Read-Host "(Y/R/X)"
    do 
        {
            if ($Begin -eq "Y")
                {
                    "`n"
                    Write-Host "Logging into 'AzureAD' powershell module (Azure Active Directory)"
                    Connect-AzureAD
                    Import-module -name ActiveDirectory
                    return;
                    
                }
            elseif ($Begin -eq "X")
                {
                    Stop-Transcript
                    exit;
                }
            elseif ($Begin -eq "T")
                {
                    "`n"
                    Write-Host "NOTE: Test mode is not yet available. Returning to main menu."
                    Menu;
                    # TEST ONBOARDING - Intended functions:
                    # Requests technician email to push results of onboarding test and CC's daniel.landry@sparkhound.com for visibililty.
                    # Disables onboarding email push to HR.
                    #TESTEmailExtractor
                }
            elseif ($Begin -eq "R")
                {
                    "`n"
                    # TODO 5/5/23 - RESTORES SECURITY LEVELS
                    # Requests username and checks for the following:
                        #Removes the user from cloud group "MFA Exemptions" to prevent bypassing MFA.
                        #Restores active toggle of "user must change password at next login" in on-prem account.
                    Write-Host "Security Restoration"
                    #Connect-AzureAD
                    Import-module -name ActiveDirectory
                    RestoreSecurity
                }
            else
                {
                    "Invalid option."
                    Menu;
                }
        }
    until ($Begin -eq "Y" -or $Begin -eq "T" -or $Begin -eq "R" -or $Begin -eq "N") 
}

function RestoreSecurity
{
    #"Step 5.2 - Joining $username to 'MFA_Exemptions' cloud group."
    #$MailboxGroupMFAexemptions = (get-azureadgroup -SearchString "MFA_Exemptions").objectid
    #Add-AzureADGroupMember -objectid "$MailboxGroupMFAexemptions" -RefObjectId "$NewUserObjectID";
    #$AddedToMFAExemptions = "Added to temporary 'MFA_Exemptions' cloud group.";
    $EmailPass = Read-Host "Enter LandryLabs.Bot password"
    $username = Read-Host "Username"
    $emailAddress = (get-aduser -identity $username).userprincipalname
    $newUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
    $MailboxGroupMFAexemptions = (get-azureadgroup -SearchString "MFA_Exemptions").objectid
    Write-Host "RESTORING USER ACCOUNT TO PROPER SECURITY LEVELS!";
    Write-Host "REMOVING USER FROM 'MFA_Exemptions' CLOUD GROUP"
    Remove-AzureADGroupMember -MemberId $NewUserObjectID -ObjectId $MailboxGroupMFAexemptions
    $RemovedfromMFAExemptions = "$username has been successfully removed from the MFA_Exemptions cloud group."
    $RemovedfromMFAExemptions

    Write-Host "RESTORING TEMPORARY PASSWORD TO ON-PREM ACCOUNT."
    Set-ADUser -Identity $username -ChangePasswordAtLogon $true
    $TempPass = "$username's password is now temporary and will need to be changed at next login."
    $TempPass

    $PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
    $from = "landrylabs.bot@sparkhound.com";
    $To = "mi-t2@sparkhound.com";
    $Port = 587
    $Subject = "Onboarding - Account Security Restored | $EmailAddress"
    $SMTPserver = "smtp.office365.com"
    $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
    $Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nQuestions? Email 'mi-t2@sparkhound.com'."

    $Body = "====================`n"
    $Body += "$RemovedfromMFAExemptions`n"
    $Body += "$TempPass`n"
    $Body += "====================`n"
    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port


    Write-Host "Returning to Main Menu."
    Menu
}

function CsvImport
{
    $csvHeader = 'Property', 'Value';
    $OnboardingCsvImport = Import-Csv -Path .\NewHireSheet.csv -Header $csvHeader
    return $OnboardingCsvImport
}

function CreateNewUser
{
    "Step 2 - Starting account creation..."
    New-ADUser -Name "$Name" -samaccountname $username -UserPrincipalName $EmailAddress -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $false -GivenName $FirstName -Surname $LastName -DisplayName $Name -City $Region -Office $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Title -OfficePhone $PhoneNumber -OtherAttributes @{'info'=$PersonalEmail}
    #-OtherAttributes @{'notes'=$PersonalEmail}
    Start-Sleep 3
    $CheckAccountCreation = (get-aduser -Identity $username -properties *).userprincipalname
        if ($CheckAccountCreation -eq $EmailAddress)
            {
                "Account created for $Name. Information populated."
            } 
        else 
            {
                "Account not created. Please investigate."
            }
    Start-sleep 3
}

function ModifyExistingUser
{

}

function MirrorSecurityGroups
{
    #==========^==========#
    #Step 3: Mirror security groups from target user
    #==========V==========#
    "Step 3 - Starting on-prem security group mirroring..."
    if ($MirrorUser -ne "N")
    {
        "$name will mirror the security groups of $MirrorUser."
        $MirrorGroups = (get-aduser -Identity $MirrorUser -properties *).Memberof #Fetches that user's on-prem groups
        $MirrorFunction = foreach ($MirrorGroupEntry in $MirrorGroups) 
            {
                "Adding $username to $MirrorGroupEntry"
                Add-ADGroupMember $MirrorGroupEntry $username
            }
        $PostMirrorNewUserGroups = (get-aduser -Identity $username -properties *).Memberof
        $MirrorFunction
            if ($PostMirrorNewUserGroups = $MirrorUser)
                {
                    "------------------------------"
                    "All groups have been successfully mirrored from $MirrorUser."
                }
            else
                {
                    "The mirroring was not successful."
                }
    }
    Else
    {
        "No groups are requested to be mirrored."
    }

        #Still need to work on auto switching primary group for contractors so that 'domain users' can be auto deleted.
    if ($Contractor -eq "Y")
    {
        "Adding contractor $username to Contract Labor security group..."
        Add-ADGroupMember $ContractLabor $username
    }
    else {"Not a contractor...Skipping contract labor group."}

    Write-Host "Adding to 'Employee VPN - Meraki VPN' security group..."
    Add-ADGroupMember $EmployeeVPN $UserName;

    Start-sleep 3
}

Function TestOnboarding
{

}

function TESTAdjustSubmissions ($SubmissionArray) #5/31/23: Migrated to main script as a 'TEST' function.
    {
        "Adjusting Submission"
        #$SubmissionArray
        #Generate fixed list of fields to request the tech to submit to bounce them to the proper field function to adjust and re-verify.
        $SubmissionFields = @(
            "1) FirstName (" + $SubmissionArray[0] + ")`n", 
            "2) LastName (" + $SubmissionArray[1] + ")`n", 
            "5) Title (" + $SubmissionArray[2] + ")`n", 
            "6) Region (" + $SubmissionArray[3] + ")`n", 
            "7) PhoneNumber (" + $SubmissionArray[4] + ")`n", 
            "8) PersonalEmail (" + $SubmissionArray[5] + ")`n", 
            "9) Company (" + $SubmissionArray[6] + ")`n", 
            "10) Manager (" + $SubmissionArray[7] + ")`n", 
            "11) MirrorUser (" + $SubmissionArray[8] + ")`n", 
            "12) Practice (" + $SubmissionArray[9] + ")`n", 
            "13) Department (" + $SubmissionArray[10] + ")`n", 
            "15) UKG (" + $SubmissionArray[11] + ")`n", 
            "16) OpenAirSSO (" + $SubmissionArray[12] + ")`n", 
            "17) NetSuiteSSO (" + $SubmissionArray[13] + ")`n")
        $SubmissionFields
        Write-Host "FOR EACH FIELD YOU WISH TO ADJUST, ENTER THE NUMBER(S) IN THE (1,2,3,4,5,6) FORMAT BELOW"
        $RequestedFields = Read-Host " "
        $RequestedFields = $RequestedFields.Split(",")
        foreach ($field in $RequestedFields)
            {
                switch ($field)
                    {
                        "1" {
                                $SubmissionArray[0] = ObtainFirstName
                                $SubmissionArray[2] = ObtainFullName -FirstName $SubmissionArray[0] -LastName $SubmissionArray[1]
                                $SubmissionArray[3] = ObtainUserName -FirstName $SubmissionArray[0] -LastName $SubmissionArray[1]
                                $SubmissionArray[4] = ObtainEmailAddress -UserName $SubmissionArray[3];
                            }
                        "2" {
                                $SubmissionArray[1] = ObtainLastName
                                $SubmissionArray[2] = ObtainFullName -FirstName $SubmissionArray[0] -LastName $SubmissionArray[1]
                                $SubmissionArray[3] = ObtainUserName -FirstName $SubmissionArray[0] -LastName $SubmissionArray[1]
                                $SubmissionArray[4] = ObtainEmailAddress -UserName $SubmissionArray[3];
                            }
                        "5" {$SubmissionArray[5] = ObtainTitle}
                        "6" {$SubmissionArray[6] = ObtainRegion}
                        "7" {$SubmissionArray[7] = ObtainPhoneNumber}
                        "8" {$SubmissionArray[8] = ObtainPersonalEmail}
                        "9" {$SubmissionArray[9] = ObtainCompany}
                        "10" {$SubmissionArray[10] = ObtainManager}
                        "11" {$SubmissionArray[11] = ObtainMirrorUser}
                        "12" {$SubmissionArray[12] = ObtainPractice}
                        "13" {$SubmissionArray[13] = ObtainDepartment}
                        "15" {$SubmissionArray[15] = ObtainCloudItemUKG}
                        "16" {$SubmissionArray[16] = ObtainCloudItemOA}
                        "17" {$SubmissionArray[17] = ObtainCloudItemNetSuite}
                    }
            }
    Write-Host "ADJUSTMENTS COMPLETE!"
    return $SubmissionArray
    }

function TESTInformationApproval #5/31/23: Migrated to main script as a 'TEST' function.
{
    Write-Host "TO BEGIN PROCESSING THIS ONBOARDING, ENTER 'Y'"
    Write-Host "TO MAKE ANY CHANGES/CORRECTIONS TO ANY OF THE ABOVE SUBMISSIONS, ENTER 'N'."
    do
        {
            $EntriesApproved = Read-Host "APPROVE 'Y'/ ADJUST 'N'"

            if ($EntriesApproved -eq "N")
                {
                    #Enter adjustment function.
                    AdjustSubmissions -SubmissionArray $SubmissionArray
                    InformationReview -SubmissionArray $SubmissionArray
                }
            elseif ($EntriesApproved -eq "Y")
                {
                    #Proceed to user object creation.
                }
            else
                {
                    #Loop back due to invalid submission.
                }
        }
    until ($EntriesApproved -eq "Y")
}

function TESTInformationReview ($SubmissionArray) #5/31/23: Migrated to main script as a 'TEST' function.
{

    $FirstName = $SubmissionArray[0];
    $LastName = $SubmissionArray[1];
    $Name = $SubmissionArray[2];
    $username = $SubmissionArray[3];
    $EmailAddress = $SubmissionArray[4];
    $Title = $SubmissionArray[5];
    $Region = $SubmissionArray[6];
    $PhoneNumber = $SubmissionArray[7];
    $PersonalEmail = $SubmissionArray[8];
    $Company = $SubmissionArray[9];
    $Manager = $SubmissionArray[10];
    $MirrorUser = $SubmissionArray[11];
    $Practice = $SubmissionArray[12];
    $Department = $SubmissionArray[13];
    $UserOUPath = $SubmissionArray[14];
    $UKG = $SubmissionArray[15];
    $OpenAirSSO = $SubmissionArray[16];
    $NetSuiteSSO = $SubmissionArray[17];


    Write-Host "`nPLEASE REVIEW USER INFORMATION SUMMARY BELOW."
    "========================================"
    Write-Host "First Name: $FirstName"
    Write-Host "Last Name: $LastName"
    Write-Host "Name: $Name"
    Write-Host "Username: $username"
    Write-Host "Email Address: $EmailAddress"
    Write-Host "Title: $Title"
    Write-Host "Region: $Region"
    Write-Host "Phone Number: $PhoneNumber"
    Write-Host "Personal Email: $PersonalEmail"
    Write-Host "Company: $Company"
    Write-Host "Manager: $Manager"
    Write-Host "Mirror User: $MirrorUser"
    Write-Host "Practice: $Practice"
    Write-Host "Department: $Department"
    Write-Host "UserOUPath: $UserOUPath"
    Write-Host "UltiPro/UKG Requested: $UKG"
    Write-Host "OpenAir Requested: $OpenAirSSO"
    Write-Host "NetSuite Requested: $NetSuiteSSO"
    "========================================`n"
}

function TESTEmailExtractor #5/31/23: Migrated to main script as a 'TEST' function.
{
    "`n"
    $pwd = "$(Get-Location)\Onboardings"
    Write-Host "PLEASE ENSURE ONLY THE DESIRED 'WELCOME NEW SPARKIE' .MSG FILE EXISTS IN THE FOLLOWING DIRECTORY '$PWD' BEFORE PROCEEDING."
    $emailExtractionStart = Read-Host "EMAIL EXTRACTION READY? (Y/N)"
    if ($emailExtractionStart -ne "Y")
    {
        TESTEmailExtractor
    }
    else
    {
        $EmailFileName = (Get-ChildItem -Path "$pwd\*.msg").name
        $EmailFilePath = @();
        $FolderTESTParent = "$pwd\OnboardingEmailExtractions"
        $FolderStageOne = "$FolderTESTParent\Stage1"
        $FolderStageTwo = "$FolderTESTParent\Stage2"
        $FolderStageThree = "$FolderTESTParent\Stage3"
        mkdir "$FolderTESTParent"
        if ($Null -eq $FolderTESTParent) { mkdir "$FolderTESTParent" } #OUTPUT TEST FOLDER 
        if ($Null -eq $FolderStageOne) { mkdir "$FolderStageOne" }
        if ($Null -eq $FolderStageTwo) { mkdir "$FolderStageTwo" }
        if ($Null -eq $FolderStageThree) { mkdir "$FolderStageThree" }
        foreach ($email in $EmailFileName)
            {
                $EmailFilePath += "$pwd\" + $email
            }
        #$EmailFilePath += "$pwd\" + (Get-ChildItem -Path $pwd\*.msg).name


        $z = 0;
        foreach ($email in $EmailFilePath)
            {
                $Email
                #$ProcessTimeStart = Get-Date;
                #"Processing"
                $EmailDataDump = Get-Content -Path $Email
                $EmailDataArray = $EmailDataDump.split(" ");

                #Locate Start and End of Onboarding Table.
                $i = 0;
                $StringScanNew = @();
                $StringScanUser = @(); #Actively Using
                $StringScanRequest = @();
                $StringScanThank = @();
                $StringScanYou = @(); #Actively Using
                <# $NewUserRequest = $EmailDataArray[280];
                $NewUserRequest.Length
                $NewUserRequest[0]
                do
                    {
                        $NewUserRequest[$i]
                        $i++
                    }
                until ($i -eq $NewUserRequest.Length) #>
                foreach ($item in $EmailDataArray)
                    {
                        if ($item -eq "User")
                            {
                                #"User"
                                $StringScanUser += $i;
                            }
                        if ($item -eq "You!")
                            {
                                #"You!"
                                $StringScanYou += $i;
                            }
                        $i++
                
                    
                    }
                $StringScanUserCount = $StringScanUser.Count;
                if ($StringScanUserCount -eq "1")
                    {
                        $OnboardingInfoStart = --$StringScanUser[0]
                    }
                else
                    {
                        $i2 = 0;
                        foreach ($item in $StringScanNew)
                            {
                                if (++$item -eq $StringScanUser[$i2])
                                    {
                                        "Information Starts at line $item"
                                    }
                                else
                                    {
                                        $i2++
                                    }
                            }    
                    }

                $StringScanYouCount = $StringScanYou.Count;
                if ($StringScanYouCount -eq "1")
                    {
                        $OnboardingInfoEnd = $StringScanYou[0];
                    }
                $StageOneOutput = "$FolderStageOne\Stage1_" + $EmailFileName[$z] + ".txt"
                $OnboardingTable = @($EmailDataArray[$OnboardingInfoStart..$OnboardingInfoEnd]) | Tee-Object -FilePath $StageOneOutput

                $OnboardingList = $OnboardingTable.Split("$Null");
                #$OnboardingList

                $i = 0;
                $OnboardingTableVoid = @();
                $OnboardingTableRevised = @();
                foreach ($item in $OnboardingTable)
                    {
                        if ($item.Length -eq 1)
                            {
                                $OnboardingTableVoid += $item
                            }
                        else
                            {
                                $OnboardingTableRevised += $item
                            }
                    }
                #$OnboardingTableRevised

                #$OnboardingTableRevised
                $i = 0
                $OnboardingListFinal = @();
                foreach ($item in $OnboardingList)
                    {
                        if ($item -ne "$Null")
                            {
                                $OnboardingListFinal += $item
                            }
                    }
            $StageTwoOutput = "$pwd\OnboardingEmailInfo\Stage2\Stage2_" + $EmailFileName[$z] + ".txt"
            $OnboardingListFinal | Out-File -FilePath $StageTwoOutput;
                $i = 0
                foreach ($item in $OnboardingListFinal)
                    {
                        $itemwildcard = "*$item*"
                        switch ($itemwildcard)
                            {
                                "*First*" {
                                    $FirstNameStart = $i;
                                    $i++;
                                }
                                "*Last*" {
                                    $LastNameStart = $i;
                                    $i++;
                                }
                                "*Phone*" {
                                    $PhoneNumberStart = $i;
                                    $i++;
                                }
                                "*Email*" {
                                    $PersonalEmailStart = $i;
                                    $i++;
                                }
                                "*Start*" {
                                    $StartDateStart = $i;
                                    $i++;
                                }
                                "*Region*" {
                                    $RegionStart = $i;
                                    $i++;
                                }
                                "*Practice*" {
                                    $PracticeStart = $i;
                                    $i++;
                                }
                                "*Competency/Department*" {
                                    $DepartmentStart = $i;
                                    $i++;   
                                }
                                "*Supervisor*" {
                                    $ManagerStart = $i;
                                    $i++;
                                }
                                "*Title*" {
                                    $TitleStart = $i;
                                    $i++;
                                }
                                "*Employment*" {
                                    $EmploymentStatusStart = $i;
                                    $i++;
                                }
                                "*Other*" {
                                    $OtherSetUpStart = $i;
                                    $i++;
                                }
                                "*Mirror:*" {
                                    $MirrorUserStart = $i;
                                    $i++;
                                }
                                "*Business*" {
                                    $BusinessUnitStart = $i;
                                    $i++;
                                }
                                "*Credit*" {
                                    $CreditCardStart = $i;
                                    $i++;
                                }
                                "*Direct*" {
                                    $DirectReportStart = $i;
                                    $i++;
                                }
                                "*UKG*" {
                                    $UKGStart = $i;
                                    $i++;
                                }
                                "*Open*" {
                                    $OpenAirStart = $i;
                                    $i++;
                                }
                                "*NetSuite*" {
                                    $NetSuiteStart = $i;
                                    $i++;
                                }
                                "*Sparkhound*" {
                                    $SparkhoundReferralStart = $i;
                                    $i++;
                                }
                                "*Work*" {
                                    $WorkStationStart = $i;
                                    $i++;
                                }
                                default {$i++} 
                            }
                    }

                #First Name Capture
                #$FirstNameStart;
                $FirstNameEnd = $LastNameStart - 1;
                $EmailObtainedFirstName = ($OnboardingListFinal[$FirstNameEnd])
                

                #First Name Capture
                #$LastNameStart;
                $LastNameEnd = $PhoneNumberStart - 1;
                $EmailObtainedLastName = ($OnboardingListFinal[$LastNameEnd])
                

                #Phone Number Capture
                #$PhoneNumberStart
                $PhoneNumberEnd = $PersonalEmailStart - 1;
                $EmailObtainedPhoneNumber = ($OnboardingListFinal[$PhoneNumberStart..$PhoneNumberEnd])
                

                #Personal Email Capture
                #$PersonalEmailStart
                $PersonalEmailEnd = $StartDateStart - 1;
                $EmailObtainedPersonalEmail = ($OnboardingListFinal[$PersonalEmailEnd])
                

                #Start Date Capture
                #$StartDateStart
                $StartDateEnd = $RegionStart - 1;
                $EmailObtainedStartDate = ($OnboardingListFinal[$StartDateStart..$StartDateEnd])
                

                #Region Capture
                #$RegionStart
                $RegionEnd = $PracticeStart - 1;
                $EmailObtainedRegion = ($OnboardingListFinal[$RegionStart..$RegionEnd])
                

                #Practice Capture
                #$PracticeStart
                $PracticeEnd = $DepartmentStart - 1;
                $EmailObtainedPractice = ($Onboardinglistfinal[$PracticeStart..$PracticeEnd])
                

                #Department Capture
                #$DepartmentStart
                $DepartmentEnd = $ManagerStart - 1;
                $EmailObtainedDepartment = ($OnboardingListFinal[$DepartmentStart..$DepartmentEnd])
                

                #Manager Capture
                #$ManagerStart
                $ManagerEnd = $TitleStart - 1;
                $EmailObtainedManager = ($onboardinglistfinal[$ManagerStart..$ManagerEnd])
                

                #Title Capture
                #$TitleStart
                $TitleEnd = $EmploymentStatusStart - 1;
                $EmailObtainedTitle = ($OnboardingListFinal[$TitleStart..$TitleEnd])
                

                #Employment Status Capture
                #$EmploymentStatusStart
                $EmploymentStatusEnd = $OtherSetUpStart - 1;
                $EmailObtainedEmploymentStatus = ($OnboardingListFinal[$EmploymentStatusStart..$EmploymentStatusEnd])
                

                #Other Set Up Capture
                #$OtherSetUpStart
                $OtherSetUpEnd = $MirrorUserStart - 1;
                $EmailObtainedOtherSetUp = ($OnboardingListFinal[$OtherSetUpStart..$OtherSetUpEnd])
                

                #Mirror User Capture
                #$MirrorUserStart
                $MirrorUserEnd = $BusinessUnitStart - 1;
                $EmailObtainedMirrorUser = ($OnboardingListFinal[$MirrorUserStart..$MirrorUserEnd])
                

                #Business Unit Capture
                #$BusinessUnitStart
                $BusinessUnitEnd = $CreditCardStart - 1;
                $EmailObtainedBusinessUnit = ($OnboardingListFinal[$BusinessUnitStart..$BusinessUnitEnd])
                

                #Credit Card Capture
                #$CreditCardStart
                $CreditCardEnd = $DirectReportStart - 1;
                $EmailObtainedCreditCard = ($OnboardingListFinal[$CreditCardStart..$CreditCardEnd])
                

                #Direct Report Capture
                #$DirectReportStart
                $DirectReportEnd = $UKGStart - 1;
                $EmailObtainedDirectReport = ($OnboardingListFinal[$DirectReportStart..$DirectReportEnd])
                

                #UKG/Ultipro Capture
                #$UKGStart
                $UKGEnd = $OpenAirStart - 1;
                $EmailObtainedUKG = ($OnboardingListFinal[$UKGStart..$UKGEnd])
                

                #Open Air Capture
                #$OpenAirStart
                $OpenAirEnd = $NetSuiteStart - 1;
                $EmailObtainedUKG = ($OnboardingListFinal[$OpenAirStart..$OpenAirEnd])
                

                #NetSuite Capture
                #$NetSuiteStart
                $NetSuiteEnd = $SparkhoundReferralStart - 1;
                $EmailObtainedNetSuite = ($OnboardingListFinal[$NetSuiteStart..$NetSuiteEnd])
                

                #Sparkhound Referral Capture
                #$SparkhoundReferralStart
                $SparkhoundReferralEnd = $WorkStationStart - 1;
                $EmailObtainedSparkhoundReferral = ($OnboardingListFinal[$SparkhoundReferralStart..$SparkhoundReferralEnd])
                

                #Workstation Request Capture
                #$WorkStationStart
                $WorkStationEnd = $WorkStationStart + 4;
                $EmailObtainedWorkStation = ($OnboardingListFinal[$WorkStationStart..$WorkStationEnd])
                
                

                #FINAL INFO TABLE BEFORE VERIFICATION
                $ListToBeVerified = @(
                    "First Name: $EmailObtainedFirstName",
                    "Last Name: $EmailObtainedLastName", 
                    "Phone Number: $EmailObtainedPhoneNumber",
                    "Personal Email: $EmailObtainedPersonalEmail",
                    "Start Date: $EmailObtainedStartDate",
                    "Region: $EmailObtainedRegion",
                    "Practice: $EmailObtainedPractice",
                    "Department: $EmailObtainedDepartment",
                    "Manager: $EmailObtainedManager",
                    "Title: $EmailObtainedTitle",
                    "Employment Status: $EmailObtainedEmploymentStatus",
                    "Other Set Up Instructions: $EmailObtainedOtherSetUp",
                    "Mirror User: $EmailObtainedMirrorUser",
                    "Business Unit: $EmailObtainedBusinessUnit",
                    "Credit Card: $EmailObtainedCreditCard",
                    "Direct Report: $EmailObtainedDirectReport",
                    "UKG Requested: $EmailObtainedUKG",
                    "OpenAir Requested: $EmailObtainedUKG",
                    "NetSuite Requested: $EmailObtainedNetSuite",
                    "Sparkhound Referral: $EmailObtainedSparkhoundReferral",
                    "Workstation Requested: $EmailObtainedWorkStation"
                );
            $StageThreeOutput = "$pwd\OnboardingEmailInfo\Stage3\Stage3_" + $EmailFileName[$z] + ".txt"
            $ListToBeVerified | Out-File -FilePath $StageThreeOutput;
            $ListToBeVerified
            "========================================"
            $z++
            }
        }
    
}



#==========^==========#
#END OF FUNCTIONS
#==========V==========#

cls
    Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| LANDRY LABS - ONBOARDING SCRIPT (Updated $LastUpdatedDate)"
    Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| SUMMARY: 1. Creates on-prem user object and populates with verified user information."
    Write-Host "  # #    " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- 2. Provisions mailbox and cloud group SSO access"
    Write-Host "  ####   " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- 3. Pushes out email to mi-t2 with transcription note & separate email to HR with initial password."
    Write-Host "    #    " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| " 
    Write-Host "    #### " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| Written by Daniel Landry (daniel.landry@sparkhound.com)`n"
Menu; #Script starts interaction with this 'Program' function.

#==========^==========#
#Step 1 - REQUESTING ONBOARDING INFORMATION
#==========v==========#
    $EmailPass = Read-Host "Enter LandryLabs.Bot password"
    Write-Host "Step 1 - Supply onboarding user information for verification";
    $ticketNumber = ObtainTicketNumber;
    $FirstName = ObtainFirstName;
    $LastName = ObtainLastName;
    $Name = ObtainFullName;
    $UserName = ObtainUserName;
    $EmailAddress = ObtainEmailAddress;
    $PhoneNumber = ObtainPhoneNumber;
    $PersonalEmail = ObtainPersonalEmail;
    $StartDate = ObtainStartDate;
    $Region = ObtainRegion;
    $Practice = ObtainPractice 
    $Department = ObtainDepartment -Practice $Practice;
    $UserOUPath = ObtainUserOUPath -Practice $Practice -Department $Department
    $Manager = ObtainManager;
    $Title = ObtainTitle;
    $Company = ObtainCompany;
    $BusinessUnit = ObtainBusinessUnit -Practice $Practice;
    $MirrorUser = ObtainMirrorUser;
    $UKGSSO = ObtainCloudItemUKG;
    $OpenAirSSO = ObtainCloudItemOA;
    $NetSuiteSSO = ObtainCloudItemNetSuite;
    $ConnectwiseSSO = ObtainCloudItemConnectwiseSSO;
    $Password = ObtainTempPassword;
    $ContractLabor = "CN=Contract Labor,OU=Contract Labor,OU=Sharepoint Groups,OU=Security Groups,DC=sparkhound,DC=com"
    $EmployeeVPN = "CN=Employee VPN - Meraki VPN,OU=Network,OU=Security Groups,DC=sparkhound,DC=com"
    $DuoMFA = "CN=DUO MFA,OU=Network,OU=Security Groups,DC=sparkhound,DC=com"
    #$SubmissionArray = @($FirstName, $LastName, $Name, $Username, $EmailAddress, $Title, $Region, $PhoneNumber, $PersonalEmail, $Company, $Manager, $MirrorUser, $practice, $Department, $UserOUPath, $UKG, $OpenAirSSO, $NetSuiteSSO)
    #InformationReview -SubmissionArray $SubmissionArray; #Testing
    #InformationApproval #Testing
    $InfoField = "$PersonalEmail`nProvisioned per CWM ticket $ticketNumber"

#==========^==========#
#Step 2: Create user object
#==========V==========#
    "Step 2 - Starting account creation..."
    New-ADUser -Name "$Name" -samaccountname $username -UserPrincipalName $EmailAddress -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $false -GivenName $FirstName -Surname $LastName -DisplayName $Name -City $Region -Office $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Title -OfficePhone $PhoneNumber -OtherAttributes @{'info'=$InfoField}
    #-OtherAttributes @{'notes'=$PersonalEmail}
    $CheckAccountCreation = (get-aduser -Identity $username -properties *).userprincipalname
        if ($CheckAccountCreation -eq $EmailAddress) 
            {
                "Account created for $Name. Information populated."
            } 
        else 
            {
                "Account not created. Please investigate."
            }

    Start-sleep 3
#==========^==========#
#Step 3: Mirror security groups from target user
#==========V==========#
    "Step 3 - Starting on-prem security group mirroring..."
        if ($MirrorUser -ne "N")
            {
            "$name will mirror the security groups of $MirrorUser."
            $MirrorGroups = (get-aduser -Identity $MirrorUser -properties *).Memberof #Fetches that user's on-prem groups
            $MirrorFunction = foreach ($MirrorGroupEntry in $MirrorGroups) 
                {
                    "Adding $username to $MirrorGroupEntry"
                    Add-ADGroupMember $MirrorGroupEntry $username
                }
            $PostMirrorNewUserGroups = (get-aduser -Identity $username -properties *).Memberof
            $MirrorFunction
                if ($PostMirrorNewUserGroups = $MirrorUser)
                    {
                        "------------------------------"
                        "All groups have been successfully mirrored from $MirrorUser."
                    }
                else
                    {
                        "The mirroring was not successful."
                    }
            }
        Else
            {
                "No groups are requested to be mirrored."
            }

            #Still need to work on auto switching primary group for contractors so that 'domain users' can be auto deleted.
        if ($Contractor -eq "Y")
            {
                "Adding contractor $username to Contract Labor security group..."
                Add-ADGroupMember $ContractLabor $username
            }
        else {"Not a contractor...Skipping contract labor group."}

        Write-Host "Adding to 'Employee VPN - Meraki VPN' security group..."
        Add-ADGroupMember $EmployeeVPN $UserName;

        Write-Host "Adding to 'DUO MFA' security group..."
        Add-ADGroupMember $DuoMFA $UserName;

    Start-sleep 3
#==========^==========#
#Step 4: Move new user object to department OU to allow AADSyncing.
#==========V==========#
    "Step 4 - Moving $username to designated OU for $Department to allow AADSync."
    $UserPath = (get-aduser -identity $username -properties *).distinguishedname
    move-adobject -identity $UserPath -targetpath $UserOUPath


#==========^==========#
#CONNECTING TO AZURE-AD TO CONFIRM OBJECT SYNC
#==========V==========#
    "Establishing AzureAD Connection for cloud items..."

        ##Confirms detection of new user object being synced to cloud AD.
        ##If unable to locate user, wait 60 and scan again. Once found, proceed with adding the groups.
        "Waiting for $username to sync to AzureAD to proceed. Checking every 60s."
        "Entering remote session with SH-AZSYNC02 to run automatic delta sync."
        $s = New-PSSession -ComputerName sh-azsync02
        Start-Sleep 5
        Invoke-Command -Session $s -ScriptBlock {hostname
            Start-ADSyncSyncCycle -PolicyType Delta}
        #hostname
        #Start-ADSyncSyncCycle -PolicyType Delta
        Remove-PSSession $s
        "Visit 'SH-AZSYNC02'(172.25.1.14) and run 'Start-ADSyncSyncCycle -PolicyType Delta' to perform manual sync."
        do
            {
                Write-Host "#" -NoNewline
                #Add "(Get-AzureADTenantDetail).companylastdirsynctime" timestamp into waiting output.
                $NewUserCLoudSynced = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").userprincipalname
                sleep 60
            }
        Until ($NewUserCloudSynced -eq "$EmailAddress")

    "`n$username detected in AzureAD."


#==========^==========#
#Step 5: Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
#==========V==========#
    "Step 5 - Joining $username to applicable cloud groups." 

    ##Add new user to Business Premium license group.
    "Step 5.1 - Joining $username to 'Microsoft 365 Business Premium (Cloud Group)' for mailbox access."
    $MailboxGroup = (get-azureadgroup -SearchString "sg.microsoft 365 Business Premium (Cloud Group)").objectid
    $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
    Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
    $MSLicense = "Provisioned license for MS Office and Mailbox (sg.microsoft 365 Business Premium)";

    "Step 5.2 - Joining $username to 'MFA_Exemptions' cloud group."
    $MailboxGroupMFAexemptions = (get-azureadgroup -SearchString "MFA_Exemptions").objectid
    Add-AzureADGroupMember -objectid "$MailboxGroupMFAexemptions" -RefObjectId "$NewUserObjectID";
    $AddedToMFAExemptions = "Added to temporary 'MFA_Exemptions' cloud group.";


Start-sleep 3
    ##Add new user to UKG SSO group.
    If ($UKGSSO -eq "Yes")
        {
            "Joining $username to 'UKG' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "UltiPro_Users").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $UKGString = "Added to UKG SSO cloud group (UltiPro_Users)."
        }
    Else 
        {
            $UKGString = "UKG not requested..."
        }

    ##Add new user to OpenAir SSO group.
    If ($OpenAirSSO -eq "Yes")
        {
            "Joining $username to 'OpenAir' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "OpenAir_Users_Prod").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $OpenAirString = "Added to OpenAir SSO cloud group (OpenAir_Users_Prod)."
        }
    Else 
        {
            $OpenAirString = "OpenAir not requested..."
        }

    ##Add new user to NetSuite SSO group.
    If ($NetSuiteSSO -eq "Yes")
        {
            "Joining $username to 'NetSuite' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "NetSuiteERP_Users").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $NetsuiteString = "Added to NetSuite SSO cloud group (NetSuiteERP_Users)."
        }
    Else 
        {
            $NetsuiteString = "NetSuite not requested..."
        }
    ## Add new user to Connectwise SSO group.
    If ($ConnectwiseSSO -eq "Yes")
        {
            "Joining $username to 'Connectwise' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "ConnectWise Manage SSO").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $ConnectwiseString = "Added to Connectwise SSO cloud group (ConnectWise Manage SSO)."
        }
    Else 
        {
            $ConnectwiseString = "Connectwise Manage Access not requested..."
        }
$TimeEnd = Get-Date;
Stop-Transcript
# TODO 5/5/23 - Remane transcript to 'OnboardingTranscript_<Firstname>-<LastName>.txt; (DONE IN TEST 5/5)
    # Then process it into $LOGFile (DONE IN TEST 5/5)
    # Then move it to 'Archive' folder under new name. (DONE IN TEST 5/5)
    $UniqueTranscriptFileName = "OnboardingTranscript_$Firstname-$LastName.txt"
    Rename-Item -Path $DefaultTranscriptFile -NewName $UniqueTranscriptFileName;
    $LOGFile = Get-Content -Path "$(Get-Location)\Onboardings\OnboardingTranscript_$Firstname-$LastName.txt"
    $LOGArray = @()
        foreach ($item in $LOGFile)
            {
                $LogArray += "$item`n";
            }
    Move-Item -Path "$(Get-Location)\Onboardings\OnboardingTranscript_$Firstname-$LastName.txt" -Destination "$(Get-Location)\Onboardings\ARCHIVE\$UniqueTranscriptFileName";

#Mailing info below
#$EmailPass = Read-Host "Enter LandryLabs.Bot password"
$PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
$from = "landrylabs.bot@sparkhound.com";
#$To = "daniel.landry@sparkhound.com";
$To = "mi-t2@sparkhound.com";
#$Cc = "joshua.chilton@sparkhound.com";
#$Cc = "mi-t2@sparkhound.com";
$Port = 587

#$Subject = "Onboarding - Account Provisioning Complete | $EmailAddress | CWM$ticketNumber."
$Subject = "New Sparkie Account Activated - $Firstname $LastName - $Department $Title - CWM#$ticketNumber"
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
$Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nQuestions? Email 'mi-t2@sparkhound.com'."

#==========^==========#
#Technician note for CWM ticket/HR..
#==========V==========#
$CWMnote = "Start Time: $TimeStart`n"
$CWMnote = ($CWMnote + "End Time: $TimeEnd`n");
$CWMnote = ($CWMnote + "Generated note for ConnectwiseManage ticket below`n")
$CWMnote = ($CWMnote + "====================`n")
$CWMnote = ($CWMnote + "Hello HR,`n");
$CWMnote = ($CWMnote + "$EmailAddress account has been created for $Name.`n");
$CWMnote = ($CWMnote + "Initial password has been emailed directly to HR.`n");
    if ($MirrorUser -ne "N")
        {
            $CWMnote = ($CWMnote + "Mirrored security groups from $MirrorUser`n");
        } 
    else 
        {
            $CWMnote = ($CWMnote + "No user assigned to mirror security groups.`n");
        }
$CWMnote += "$MSLicense`n"
$CWNote += "$AddedToMFAExemptions`n"
$CWMnote += "$UKGString`n" #"Added to UKG SSO cloud group (UltiPro_Users)." \ "UKG not requested..."
$CWMnote += "$OpenAirString`n" #"Added to OpenAir SSO cloud group (OpenAir_Users_Prod)." \ "OpenAir not requested..."
$CWMnote += "$NetsuiteString`n" #"Added to NetSuite SSO cloud group (NetSuiteERP_Users)." \ "NetSuite not requested..."
$CWMnote += "$ConnectwiseString`n" #"Added to Connectwise Manage SSO cloud group (Connectwise Manage SSO)." \ "Connectwise Manage Access not requested..."
$CWMnote = ($CWMnote + "Assigned to OU: $UserOUPath`n");
$CWMnote = ($CWMnote + "====================`n");
$CWMnote
$LogTranscriptStart = "TRANSCRIPT BELOW"
Send-MailMessage -from $From -To $To -Subject $Subject -Body "$CWMnote`n$LogTranscriptStart`n$LOGArray`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port


#Separate email alert pushed to HR@sparkhound.com
#$ToHR = "daniel.landry@sparkhound.com";

# TODO 5/4/23: Add manager of hire to this email.
    # Take verified manager username string, append '@sparkhound' into mailing variable; add to $HRCc array.
    # UPDATE 5/4/23: Change was made and was successful.
$ManagerEmail = (get-aduser -identity $manager).userprincipalname
$ToHR = "HR@sparkhound.com";
$HRCc = @("mi-t2@sparkhound.com", $ManagerEmail);
$BodyHR = "Hello Hr,`n`n$EmailAddress has been created for $Name. Forwarding their initial password of 'Welcome@123'."
Send-MailMessage -from $From -To $ToHR -Cc $HRCc -Subject $Subject -Body $BodyHR`n$signature -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port


<#Division Field:
    "Digital Automation" ('Digital Transformation' in UKG)
        'GRP_DA_ALL'
        'GRP_DA_INDUSTRY' (Department -eq 'Industry')
        'GRP_DA_PROJECT MANAGEMENT (Department -eq 'Project Management')
        'GRP_DA_Packaged SW/LCNC/RPA' (Department -eq 'Packaged Software')
        'GRP_DA_Technology' (ExtensionAttribute4 -eq 'Technology')
        'GRP_DA_Web & Mobile' (Department -eq 'Web & Mobile')
        'GRP_DA_Analytics/ML/AI' (Department -eq 'Analytics')
        'GRP_DA_Strategy' (Department -eq 'Strategy')
        'GRP_DA_Process' (ExtensionAttribute4 -eq 'Process')
        'GRP_DA_Sales' (Department -eq 'Sales')

    "Managed Infrastructure" ('Managed Services' in UKG)
        'GRP_MI_ALL'
        'GRP_MI_Tier III' (Department -eq 'Tier III')
        'GRP_MI_Field Services' (Department -eq 'Field Services')
        'GRP_MI_Support Services' (extensionAttribute4 -eq 'Support Services')
        'GRP_MI_Consulting Services' (department -eq "Consulting" OR extensionAttribute3 -match 'MI')
        'GRP_MI_Tier II' (Department -eq 'Tier II')
        'GRP_MI_Service Desk' (Department -eq 'Service Desk')
        'GRP_MI_Sales' (Department -eq 'Sales')

    "Corporate" ('Corporate' in UKG)
        'GRP_Corporate_ALL'
        'GRP_Corporate_Accounting' (Department -eq 'Accounting')
        'GRP_Corporate_ELT' (Department -eq 'asdf')
        'GRP_Corporate_SLED' (ExtensionAttribute4 -eq 'SLED')
        'GRP_Corporate_Sales/Partnerships' (ExtensionAttribute4 -eq 'Sales/Partnerships')
    "Contact Center Operations" ('Contact Center Operations' in UKG)
#>


<# OLD CODE. ONLY HERE INCASE I NEED ANYTHING FROM IT.

"Please provide the following information for this onboarding:"
$TimeStart = Get-Date
$FirstName = Read-Host "First Name"; 
$LastName = Read-Host "Last Name"; 
$Name = "$FirstName $LastName"; 
$Title = Read-Host "Title"; 
$Region = Read-Host "City"; 
$PhoneNumber = Read-Host "Phone Number";
$username = "$FirstName.$LastName"; 
$EmailAddress = "$username@sparkhound.com"; 
$PersonalEmail = Read-Host "Personal Email";
$Company = Read-Host "Company";
    if ($company -ne "Sparkhound") 
        {
            "Setting $username as a contractor"; 
            $Contractor = "Y"; 
            $Title = "Contractor ($company)";
        } 
    else 
        {
            $Contractor = "N"
        };
$Manager = Read-Host "Manager's username (First.Last)";
$MirrorUser = Read-Host "User to Mirror ('N' if not mirroring)"
$StartDate = Read-Host "Start Date"
$BusinessUnit = Read-Host "Business Unit"
$Department = Read-Host "Department";
$DepartmentConvert = "*$Department*"
$Practice = Read-Host "Practice";
$UserOUPath = "OU=$department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com" 
$DepartmentLookup = (Get-ADOrganizationalUnit -Identity $UserOUPath)
    if ($DepartmentLookup -ne "Null") 
        {
            "Department OU of $UserOUPath confirmed and assigned."
        }
$UKGSSO = Read-Host "UKG SSO Y/N"
$OpenAirSSO = Read-Host "OpenAir SSO Y/N"
$NetSuiteSSO = Read-Host "NetSuite SSO Y/N"
$PasswordRequest = Read-Host "New User Password"
$Password = ConvertTo-SecureString $PasswordRequest -AsPlainText -Force 

OLD CODE. ONLY HERE INCASE I NEED ANYTHING FROM IT. #>


function TESTObtainVerifiedUser ($ManagerCheck, $MirrorUserCheck)
{
    if ($ManagerCheck -eq "Y")
        {
            $OutputReference = "Manager";
            $OutputReferenceUpper = "MANAGER";
        }
    elseif ($MirrorUserCheck -eq "Y")
        {
            $OutputReference = "MirrorUser";
            $OutputReferenceUpper = "MIRROR USER";
        }
    
    $SubmttedUserToVerify
    $SubmttedUserToVerify = Read-Host "$OutputReference username (Enter 'N' to not assign a $OutputReference)"; #Verify submission. Allow option to process without.
    Write-Host "Verifying $OutputReference '$SubmttedUserToVerify'..." -NoNewline
    Start-sleep 1
    if ($SubmttedUserToVerify -eq 'N') #Manual bypass of assignment.
        {
            Write-Host "NO $OutputReferenceUpper ASSIGNED. SKIPPING." -ForegroundColor Green;
            $SubmttedUserToVerify = "$Null"
            $SubmissionAssigned = "Y"
            return $SubmttedUserToVerify
        }
    else
        {
            $SubmissionExistsVerification = (get-aduser -filter {samaccountname -like $SubmttedUserToVerify}).samaccountname
                if ($Null -ne $SubmissionExistsVerification) #Manager automatically matched.
                    {
                        $SubmttedUserToVerify = $SubmissionExistsVerification;
                        $SubmttedUserToVerifyUpper = $SubmttedUserToVerify.ToUpper();
                        Write-Host "..." -NoNewline
                        Write-Host "'$SubmttedUserToVerifyUpper' ASSIGNED SUCCESSFULLY." -ForegroundColor Green;
                        $SubmissionAssigned = "Y"
                        return $SubmttedUserToVerify
                    }   
                elseif ($SubmissionExistsVerification -eq $Null) #No automatic match.
                    {
                        Start-sleep 1
                        Write-Host "..." -NoNewline
                        $SubmissionFormattingCheck1 = $SubmttedUserToVerify.indexOf("."); #Checking if '.' (period) character is present (standard username formatting) to use it as delimmiter.
                        $SubmissionFormattingCheck2 = $SubmttedUserToVerify.indexOf(" "); #Checking if ' ' (space) character is present (standard UKG name formatting) to use it as delimmiter.
                            if ($SubmissionFormattingCheck1 -ne "-1") #Detecting possible username format (first.last) due to '.' character present.
                                {
                                    $SubmttedUserToVerifyString = "$SubmttedUserToVerify";
                                    $SubmttedUserToVerifyStringSplit = $SubmttedUserToVerifyString.Split("."); #Splitting first and last name to process inquires of each.
                                        foreach ($string in $SubmttedUserToVerifyStringSplit)
                                            {
                                                $SubmttedUserToVerifyWildcard = "*$string*";
                                                $SubmttedUserToVerifyExistsVerification = (get-aduser -filter {samaccountname -like $SubmttedUserToVerifyWildcard}).samaccountname
                                                    $i = 0;
                                                    foreach ($entry in $SubmttedUserToVerifyExistsVerification) #Checking number of results. If '=0', request resubmission; If '=1', automatically assign; If '>1', generate list and request resubmission; 
                                                        {
                                                            $i++
                                                        }
                                                if ($i -eq 0)
                                                    {
                                                        Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                        $SubmissionAssigned = "N" #Flagged to bounce back to resubmit.
                                                        break
                                                    }
                                                elseif ($i -eq 1)
                                                    {
                                                
                                                        Write-Host "MATCH FOUND ($SubmttedUserToVerifyExistsVerification)" -ForegroundColor Green -NoNewline
                                                        start-sleep 1
                                                        Write-Host "..." -NoNewline
                                                        Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                        $SubmttedUserToVerify = $SubmttedUserToVerifyExistsVerification
                                                        $SubmissionAssigned = "Y" #Flagged to exit with valid assignment.
                                                        break
                                                    }
                                                elseif ($i -gt 1)
                                                    {
                                                        start-sleep 1
                                                        Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                        Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm submission."
                                                        start-sleep 1
                                                            foreach ($name in $SubmttedUserToVerifyExistsVerification)
                                                                {
                                                                    $name = $name.ToLower();
                                                                    Write-Host "$name;"
                                                                }
                                                        Write-Host "`n"
                                                        $SubmissionAssigned = "N" #Flagged to bounce back to resubmit.
                                                        break
                                                    }
                                            }
                                    
                                    if ($SubmissionAssigned -eq "Y")
                                        {
                                            return $SubmttedUserToVerify
                                        }
                                    else 
                                        {
                                            ObtainVerifiedUser;
                                        } 
                                }
                            elseif ($SubmissionFormattingCheck2 -ne "-1") #Detecting possible UKG format (first last) due to ' ' (space) character present.
                                {
                                    $SubmttedUserToVerify = $SubmttedUserToVerify.Replace(" ",".") #Attempts to convert submission into standard username format for a quick match.
                                    $SubmttedUserToVerifyString = "$SubmttedUserToVerify";
                                        foreach ($string in $SubmttedUserToVerifyString)
                                            {
                                                $SubmttedUserToVerifyWildcard = "*$string*";
                                                $SubmttedUserToVerifyExistsVerification = (get-aduser -filter {samaccountname -like $SubmttedUserToVerifyWildcard}).samaccountname
                                                    $i = 0;
                                                    foreach ($entry in $SubmttedUserToVerifyExistsVerification) #Checking number of results. If '=0', request resubmission; If '=1', automatically assign; If '>1', generate list and request resubmission; 
                                                        {
                                                            $i++
                                                        }
                                                if ($i -eq 0)
                                                    {
                                                        Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                        $SubmissionAssigned = "N" #Flagged to bounce back to resubmit.
                                                        break
                                                    }
                                                elseif ($i -eq 1)
                                                    {
                                                
                                                        Write-Host "MATCH FOUND ($SubmttedUserToVerifyExistsVerification)" -ForegroundColor Green -NoNewline
                                                        start-sleep 1
                                                        Write-Host "..." -NoNewline
                                                        Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                        $SubmttedUserToVerify = $SubmttedUserToVerifyExistsVerification
                                                        $SubmissionAssigned = "Y" #Flagged to exit with valid assignment.
                                                        break
                                                    }
                                                elseif ($i -gt 1)
                                                    {
                                                        start-sleep 1
                                                        Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                        Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the submission."
                                                        start-sleep 1
                                                            foreach ($name in $SubmttedUserToVerifyExistsVerification)
                                                                {
                                                                    $name = $name.ToLower();
                                                                    Write-Host "$name;"
                                                                }
                                                        Write-Host "`n"
                                                        $SubmissionAssigned = "N" #Flagged to bounce back to resubmit.
                                                        break
                                                    }
                                            }
                                    if ($SubmissionAssigned -eq "Y")
                                        {
                                            return $SubmttedUserToVerify
                                        }
                                    else 
                                        {
                                            $SubmttedUserToVerifyString = $SubmttedUserToVerifyString.Split("."); #No matches found. Spliting into smaller strings if able.
                                            foreach ($string in $SubmttedUserToVerifyString)
                                                {
                                                    $SubmttedUserToVerifyWildcard = "*$string*";
                                                    $SubmttedUserToVerifyExistsVerification = (get-aduser -filter {samaccountname -like $SubmttedUserToVerifyWildcard}).samaccountname
                                                        $i = 0;
                                                        foreach ($entry in $SubmttedUserToVerifyExistsVerification) #Checking number of results. If '=0', request resubmission; If '=1', automatically assign; If '>1', generate list and request resubmission;
                                                            {
                                                                $i++
                                                            }
                                                    if ($i -eq 0)
                                                        {
                                                            Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                            $SubmissionAssigned = "N" #Flagged to bounce back to resubmit.
                                                            break
                                                        }
                                                    elseif ($i -eq 1)
                                                        {
                                                    
                                                            Write-Host "MATCH FOUND ($SubmttedUserToVerifyExistsVerification)" -ForegroundColor Green -NoNewline
                                                            start-sleep 1
                                                            Write-Host "..." -NoNewline
                                                            Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                            $SubmttedUserToVerify = $SubmttedUserToVerifyExistsVerification
                                                            $SubmissionAssigned = "Y" #Flagged to exit with valid assignment.
                                                            break
                                                        }
                                                    elseif ($i -gt 1)
                                                        {
                                                            start-sleep 1
                                                            Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                            Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the submission."
                                                            start-sleep 1
                                                                foreach ($name in $SubmttedUserToVerifyExistsVerification)
                                                                    {
                                                                        $name = $name.ToLower();
                                                                        Write-Host "$name;"
                                                                    }
                                                            Write-Host "`n"
                                                            $SubmissionAssigned = "N" #Flagged to bounce back to resubmit.
                                                            break
                                                        }
                                                }
                                        
                                        if ($SubmissionAssigned -eq "Y")
                                            {
                                                return $SubmttedUserToVerify
                                            }
                                        else 
                                            {
                                                ObtainVerifiedUser;
                                            }
                                        }


                                    
                                }
                    }
        }
    #$Manager = ObtainVerifiedUser -ManagerCheck "Y";
    #$MirrorUser = ObtainVerifiedUser -MirrorUserCheck "Y";
}

function TESTObtainPractice
{
    #Verify the given OU exists.
    #Example UKG Practice: 'AUTSVC-Automation Services'
    #"OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
    $Practice = Read-Host "Practice";
    $PracticeOUPath = "OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com" 
    Write-Host "Verifying Practice '$Practice'..." -NoNewline
    Start-sleep 1
    $practiceOUCHeck1 = (Get-ADObject -Filter "distinguishedname -like '$PracticeOUPath'").distinguishedname #VERIFY CHECK 1
    Write-Host "..." -NoNewline
    if ($Null -ne $practiceOUCHeck1)
        {
            
            Write-Host "ASSIGNED SUCCESSFULLY" -ForegroundColor Green;
            $PracticeOUAssigned = "Y";
            return $practiceOUCHeck1;
        }
    else 
        {
            #Write-Host "UNABLE TO VERIFY" -NoNewline -ForegroundColor Red
            Write-Host "..." -NoNewline
            $practiceFormattingCheckDash = $practice.IndexOf("-"); #Checks if the UKG formatted practice was submitted.
            $PracticeString = "$Practice"
            if ($practiceFormattingCheckDash -ne "-1")
                {
                    $PracticeStringSplit = $PracticeString.Split("-"); #Breaks apart the UKG prefix string from the actual OU name.
                    $PracticeStringSplit = $PracticeStringSplit[1]#.Split(" ");
                }
            <# else 
                {
                    $PracticeStringSplit = $PracticeString.Split(" "); #Breaks apart the OU name into separate searchable words.
                    $PracticeStringSplit
                } #>
                foreach ($string in $PracticeStringSplit)
                    {
                        $practiceSearchWildcard = "*$string*";
                        $practiceSearchVerification = (Get-ADObject -filter "name -like '$practiceSearchWildcard'" -SearchBase "OU=Domain Users,DC=sparkhound,DC=com" -SearchScope OneLevel).name
                            $i = 0;
                            foreach ($item in $practiceSearchVerification)
                                {
                                    $i++
                                }
                        if ($i -eq 0)
                            {
                                Write-Host "NO PRACTICE WAS FOUND. TRY AGAIN." -ForegroundColor Red;
                                $PracticeAssigned = "N"
                                break
                            }
                        elseif ($i -eq 1)
                            {
                        
                                Write-Host "MATCH FOUND ($practiceSearchVerification)" -ForegroundColor Green -NoNewline
                                start-sleep 1
                                Write-Host "..." -NoNewline
                                Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                $Practice = $practiceSearchVerification
                                $PracticeAssigned = "Y"
                                break
                            }
                        elseif ($i -gt 1)
                            {
                                start-sleep 1
                                Write-Host "DETECTED MULTIPLE PRACTICES`n"
                                Write-Host "Generating list of references (ignore duplicates). Please enter your submission again using the reference."
                                start-sleep 1
                                    foreach ($name in $practiceSearchVerification)
                                        {
                                            $name = $name.ToLower();
                                            Write-Host "$name;"
                                        }
                                Write-Host "`n"
                                $PracticeAssigned = "N"
                                break
                            }
                    }
                if ($PracticeAssigned -eq "Y")
                    {
                        return $Practice
                    }
                else 
                    {
                        ObtainPractice;
                    } 
                    
        }                    
}


#  OSD FrondEnd 
#  oneil.jim@gmail.com
#  10/13/2024

#===========================================================================
# Load XAML for UI
#===========================================================================
cd $PSScriptRoot
$xmlFilePath = ".\Forms\UI.xml"
[xml]$inputXML = Get-Content -Path $xmlFilePath

$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    write-host $error[0].Exception.Message -ForegroundColor Red
    if ($error[0].Exception.Message -like "*button*"){
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
}
catch{#if it broke some other way <img draggable="false" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg" scale="0">
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

#Get-FormVariables
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}

#===========================================================================
# Load the Task Sequence Environment and start logging
#===========================================================================


Try
    {
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    }
Catch
    {
    $wpfbuttonFinish.Content = 'Finish!!!'
    }

Try
    {
    Start-Transcript X:\Windows\Temp\SMSTSLog\FrontEnd.log
    Write-Information 'WinPE (X:\) Drive Present'
    }
Catch
    {
    Start-Transcript C:\Files\Image\FrontEnd.log
    Write-Information 'WinPE (X:\) Drive not found using C:\ for logging'
    }


#===========================================================================
# Banner
#===========================================================================

#Set window style
#$WPFwinOSDFront.WindowStyle = 'None'
$WPFwinOSDFront.ResizeMode = 'NoResize'

#Set color
$WPFborderTop.Background = '#2D6AA7'

#set Logo
cd $PSScriptRoot

$logo = Get-ChildItem -Recurse | Where-Object name -eq 'Logo.png'
$WPFimgLogo.Source = $logo.FullName

#Add a timer and set the time and date for real-time time :)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({$WPFtxtDate.Text = Get-Date})
$timer.Enabled = $True

# Model, Serial, BIOS Ver
$WPFtxtModel.Text = (Get-WmiObject Win32_computersystem).Model
$wpftxtserial.text = 'Serial: ' + (Get-WmiObject Win32_bios).serialnumber
$WPFtxtBiosVer.Text = 'BIOS: ' + (Get-WmiObject Win32_bios).smbiosbiosversion

#Obtain IP Address
$WPFtxtIP.Text = 'IP Address: ' + (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.Ipaddress.length -gt 1} | Where-Object {$_.DHCPEnabled -eq $true}).IPAddress[0]

#grab UEFI state
If ($tsenv -ne $null){
    $wpftxtUEFI.Text = 'UEFI Enabled: ' + $tsenv.value('_SMSTSBootUEFI')
    }
    Else{
    $wpftxtUEFI.Text = 'UEFI Enabled: Not Known'
    }


#===========================================================================
# Options Tab
#===========================================================================


#Populate Configuration drop down with items from .\Forms\Time.csv
$comboboxTimeColleciton = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$wpfcmbTimeZone.ItemsSource = $comboboxTimeColleciton
$timeZones = Import-Csv .\Forms\TimeZone.csv
foreach($line in $timeZones) 
    {
     $tmpObject = New-Object PSObject
     $tmpObject | Add-Member -MemberType NoteProperty -Name Name -Value $line.Name
     $tmpObject | Add-Member -MemberType NoteProperty -Name Value -Value $line.Tag
     $comboboxTimeColleciton.Add($tmpObject)
    }
$wpfcmbTimeZone.SelectedItem = $wpfcmbTimeZone.ItemsSource[0]

#Populate Configuration drop down with items from .\Forms\Region.csv
$comboboxRegionColleciton = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$wpfcmbRegion.ItemsSource = $comboboxRegionColleciton
$Regions = Import-Csv .\Forms\Region.csv
foreach($line in $Regions) 
    {
     $tmpObject = New-Object PSObject
     $tmpObject | Add-Member -MemberType NoteProperty -Name Name -Value $line.Name
     $tmpObject | Add-Member -MemberType NoteProperty -Name Value -Value $line.Tag
     $comboboxRegionColleciton.Add($tmpObject)
    }
$wpfcmbRegion.SelectedItem = $wpfcmbRegion.ItemsSource[0]

#Populate Configuration drop down with items from .\Forms\containers.csv
$comboboxColleciton = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$wpfcmbcontainer.ItemsSource = $comboboxColleciton
$containers = Import-Csv .\Forms\Containers.csv
foreach($line in $containers) 
    {
     $tmpObject = New-Object PSObject
     $tmpObject | Add-Member -MemberType NoteProperty -Name Name -Value $line.Name
     $tmpObject | Add-Member -MemberType NoteProperty -Name Value -Value $line.Value
     $comboboxColleciton.Add($tmpObject)
    }


#Pull optional app info from .\Forms\AppInfo.csv and populate checkbox objects
$appinfo = Import-Csv .\Forms\AppInfo.csv
$WPFchkApp01.Content = $appinfo[0].DisplayName
$WPFchkApp01.Tag = $appinfo[0].Tag
$WPFchkApp01.Visibility = $appinfo[0].Visibility
$WPFchkApp02.Content = $appinfo[1].DisplayName
$WPFchkApp02.Tag = $appinfo[1].Tag
$WPFchkApp02.Visibility = $appinfo[1].Visibility
$WPFchkApp03.Content = $appinfo[2].DisplayName
$WPFchkApp03.Tag = $appinfo[2].Tag
$WPFchkApp03.Visibility = $appinfo[2].Visibility
$WPFchkApp04.Content = $appinfo[3].DisplayName
$WPFchkApp04.Tag = $appinfo[3].Tag
$WPFchkApp04.Visibility = $appinfo[3].Visibility
$WPFchkApp05.Content = $appinfo[4].DisplayName
$WPFchkApp05.Tag = $appinfo[4].Tag
$WPFchkApp05.Visibility = $appinfo[4].Visibility
$WPFchkApp06.Content = $appinfo[5].DisplayName
$WPFchkApp06.Tag = $appinfo[5].Tag
$WPFchkApp06.Visibility = $appinfo[5].Visibility
$WPFchkApp07.Content = $appinfo[6].DisplayName
$WPFchkApp07.Tag = $appinfo[6].Tag
$WPFchkApp07.Visibility = $appinfo[6].Visibility
$WPFchkApp08.Content = $appinfo[7].DisplayName
$WPFchkApp08.Tag = $appinfo[7].Tag
$WPFchkApp08.Visibility = $appinfo[7].Visibility

#EventHandler that sets the default apps for each DropDown
$wpfcmbcontainer.Add_SelectionChanged({
    
    $wpfchkAppList = Get-Variable -Name "WPFchkApp0*" -ErrorAction SilentlyContinue

    Foreach($wpfchkApp in $wpfchkAppList)
    {
        $wpfchkApp.Value.IsChecked = $false 
    }
})

$wpfcmbcontainer.SelectedItem = $wpfcmbcontainer.ItemsSource[0]

#Action taken when Next button is clicked
$wpfbuttonNext.Add_Click({ 
    $wpftxtvariable01.Text = 'Region - ' + $WPFcmbregion.SelectedItem.Name
    $wpftxtvariable02.Text = 'TimeZone - ' + $WPFcmbtimezone.SelectedItem.Name
    $wpftxtvariable03.Text = $WPFcmbContainer.SelectedItem.Name
    If ($wpfchkapp01.Visibility -eq 'Visible')
        {
        $wpftxtvariable04.Text = $wpfchkapp01.Content + " - " + $WPFchkApp01.IsChecked
        }
    If ($wpfchkapp02.Visibility -eq 'Visible')
        {
        $wpftxtvariable05.Text = $wpfchkapp02.Content + " - " + $WPFchkApp02.IsChecked
        }
    If ($wpfchkapp03.Visibility -eq 'Visible')
        {
        $wpftxtvariable06.Text = $wpfchkapp03.Content + " - " + $WPFchkApp03.IsChecked
        }
    If ($wpfchkapp04.Visibility -eq 'Visible')
        {
        $wpftxtvariable07.Text = $wpfchkapp04.Content + " - " + $WPFchkApp04.IsChecked
        }
    If ($wpfchkapp05.Visibility -eq 'Visible')
        {
        $wpftxtvariable08.Text = $wpfchkapp05.Content + " - " + $WPFchkApp05.IsChecked
        }
    If ($wpfchkapp05.Visibility -eq 'Visible')
        {
        $wpftxtvariable09.Text = $wpfchkapp06.Content + " - " + $WPFchkApp06.IsChecked
        }
    If ($wpfchkapp05.Visibility -eq 'Visible')
        {
        $wpftxtvariable10.Text = $wpfchkapp07.Content + " - " + $WPFchkApp07.IsChecked
        }
    
    #moveto next tab
    $wpftab02.IsEnabled = 'True'
    $WPFtab02.Focus()
    $wpfbuttonFinish.IsDefault = 'True'
    $WPFbuttonNext.Focus()
    })


#===========================================================================
# Variables Tab
#===========================================================================

#Action taken when the Finish Button is clicked
$wpfbuttonFinish.add_click({
        If ($tsenv -ne $null)
            {
            $tsenv.Value('OSDLocation') = $WPFcmbregion.SelectedItem.Value
            Write-Information $tsenv.Value('OSDLocation')
            $tsenv.Value('OSDTime') = $WPFcmbTimeZone.SelectedItem.Value
            Write-Information $tsenv.Value('OSDTime')
            $tsenv.Value('OSDContainer') = $wpfcmbcontainer.SelectedItem.Value
            Write-Information $tsenv.Value('OSDContainer')
            $tsenv.Value('OSDComputername')
            $appvariables = Get-Variable -Name wpfchkapp*
            foreach ($appvariable in $appvariables)
                {
                if ($appvariable.value.Content.Length -ge 1)
                    {
                    $tsenv.value($appvariable.value.tag) = $appvariable.value.IsChecked
                    $TmpAppVariable =   $appvariable.Value.Content  +' = ' + $appvariable.Value.IsChecked
                    Write-Information    $TmpAppVariable   ##$appvariable.Value.Content '=' $appvariable.Value.IsChecked
                    } 
                }
                #===========================================================================
                # Close Form
                #===========================================================================
                Write-Information "Closing form..."
                $WPFwinOSDFront.Close()
                
                Stop-Transcript
             }
          Else
            {
            Write-Information 'FrontEnd not Running in TSEnvironment, closing form'
            Write-Information $WPFcmbregion.SelectedItem.Value
            Write-Information $WPFcmbTimeZone.SelectedItem.Value
            Write-Information $wpfcmbcontainer.SelectedItem.Value
            $appvariables = Get-Variable -Name wpfchkapp* 
            foreach ($appvariable in $appvariables)
               {
               if ($appvariable.value.Content.Length -ge 1)
                   {
                   $TmpAppVariable =   $appvariable.Value.Content  +' = ' + $appvariable.Value.IsChecked
                   Write-Information    $TmpAppVariable   ##$appvariable.Value.Content '=' $appvariable.Value.IsChecked
                   }   
               }
            Stop-Transcript
            $WPFwinOSDFront.Close()
            }
    })


#===========================================================================
# Tools Tab
#===========================================================================

$WPFbuttonIP.add_click({
    $WPFtxtIP.Text = 'IP Address: ' + (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.Ipaddress.length -gt 1} | Where-Object {$_.DHCPEnabled -eq $true}).IPAddress[0]
    })

$WPFbuttonCMTrace.add_click({
    If (test-path $env:SystemDrive\sms\bin\x64\cmtrace.exe){
        Start-Process  $env:SystemDrive\sms\bin\x64\cmtrace.exe -ArgumentList $env:SystemDrive\Windows\Temp\smstslog\smsts.log
        }
        else{
        Write-Information 'cmtrace.exe not found'
        $WPFtxtCMTRace.Text = 'Not Found!'
        $WPFtxtCMTRace.foreground = 'Red'
        }
    })

$WPFbuttonCMD.add_click({
    Start-Process -FilePath $env:SystemDrive\windows\system32\cmd.exe -WorkingDirectory $env:SystemDrive\windows\System32
    })

$WPFbuttonPOSH.add_click({
    Start-Process -FilePath $env:SystemDrive\windows\system32\WindowsPowerShell\V1.0\powershell.exe -WorkingDirectory  $env:SystemDrive\windows\System32
    })

$WPFbuttonReboot.add_click({
    Restart-Computer
    })

$wpfbuttonRemRecov.add_click({
    If (Test-Path $env:SystemDrive\windows\system32\remoterecovery.exe)
        {
        Start-Process -FilePath $env:SystemDrive\windows\system32\remoterecovery.exe -WorkingDirectory $env:SystemDrive\windows\System32
        }
    Else
        {
        $wpfbuttonRemRecov.Foreground = 'Red'
        $wpfbuttonRemRecov.content = 'RR NotExist'
        }
    })

$WPFbuttonBack.add_click({
    $WPFtab01.Focus()
    })



#===========================================================================
# About Tab - Save for Future Use!!!
#===========================================================================
#Load HelpDoc.txt
#$WPFtxtHelp.Text =  Get-Content .\Forms\HelpDoc.txt

#===========================================================================
# Shows the form
#===========================================================================

$Form.ShowDialog() | out-null
#Requires -RunAsAdministrator


##How to use
##powershell -executionpolicy bypass -file C:\L2AI\powershell\custom-macro-001.ps1


$job = Start-Job -ScriptBlock {

    function Util-DisableMaxButton {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory)]
            $hWnd
        )

        Process {
            $menu = [System.Win32Util]::GetSystemMenu($hWnd, $false)
            [System.Win32Util]::DeleteMenu($menu, 0xF030, 0x00000000)
        }
    }


    function Util-PressKey {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory)]
            $hWnd,

            [Parameter(Mandatory)]
            [uint32]
            $key
        )

        Process {
            [System.Win32Util]::PostMessage($hWnd, 0x100, [System.IntPtr]$key, [System.IntPtr]::Zero)
            [System.Win32Util]::PostMessage($hWnd, 0x101, [System.IntPtr]$key, [System.IntPtr]::Zero)
        }
    }



    function Main {

        $Win32UtilMethodsDefinations = @"
            [DllImport("user32.dll")]
            public static extern int DeleteMenu(IntPtr hWnd, int nPosition, int wFlag);

            [DllImport("User32")]
            public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);

            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool IsIconic(IntPtr hWnd);
            
            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
            
            public enum WM_EventFlag:uint
            {
                WM_CHAR = 0x0102,
                WM_UNICHAR = 0x0109,

                WM_LBUTTONDOWN = 0x201,
                WM_LBUTTONUP = 0x202,
                WM_RBUTTONDOWN = 0x204,
                WM_RBUTTONUP = 0x205,
                WM_MOUSEMOVE = 0x200,
                WM_MOUSEWHEEL = 0x020A,

                WM_KEYDOWN = 0x100,
                WM_KEYUP = 0x101,
                WM_SYSKEYDOWN = 0x104,
                WM_SYSKEYUP = 0x105,
                WM_SETTEXT = 0x000C,

                WM_COPYDATA = 0x4A,

                WM_CAPTURECHANGED = 0x0215,
            }

"@

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -MemberDefinition $Win32UtilMethodsDefinations -Name Win32Util -Namespace System
        
        $VK = [System.Windows.Forms.Keys]
        
        $l2Process = Get-Process -Name "L2.bin" -ErrorAction SilentlyContinue | Where-Object { [System.Win32Util]::IsIconic($_.MainWindowHandle) -eq $false }
                
        Write-Host "L2 Process: " @($l2Process).Count
        if ($l2Process -eq $null -or @($l2Process).Count -le 0) { return }

        $l2Process | ForEach-Object {
            if ($_.MainWindowHandle -ne 0) {
                Util-DisableMaxButton $_.MainWindowHandle
            }
        }


        # $VK options:
        # 3rd Row: NumPad1 .. NumPad0 .. DIVIDE .. MULTIPLY
        # 2nd Row: VK_1 .. VK_0 ..
        # 1st Row: F1 .. F12
        $secondsWaiting = @{
            "20 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 20 - 3); key = $VK::F9; start = $null }
            "5 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 5 - 3); key = $VK::F10; start = $null }
            "6 sec attack" = New-Object PSOBJECT -Property @{ wait = (3); key = $VK::F11; start = $null }
        }
        
        
        #=============================================================
        foreach($key in $secondsWaiting.keys) {
            $secondsWaiting[$key].start = (Get-Date).AddSeconds(-$secondsWaiting[$key].wait)
        }

        
        $switchProgress = 0
        while($true) {
                
            #=============================================================
            foreach($key in $secondsWaiting.keys) {
                $thisObject = $secondsWaiting[$key]
                if ($thisObject -eq $null -or $thisObject.key -eq 0) { continue; }

                $secondsRemaining = [int32] ($thisObject.wait - ((Get-Date) - $thisObject.start).TotalSeconds)
                if ($secondsRemaining -le 0) {
                    $thisObject.start = Get-Date

                    $l2Process | ForEach-Object {
                        if ($_.MainWindowHandle -ne [System.IntPtr]::Zero) {
                            Util-PressKey $_.MainWindowHandle $thisObject.key
                        }
                    }

                }
                
                if ($switchProgress -eq $($secondsWaiting.Keys).IndexOf($key)) {
                    Write-Progress -Activity $key -Status "Processing" -SecondsRemaining $secondsRemaining
                }
            }
            
            #=============================================================
            $switchProgress = [int32](($switchProgress + 1) % $secondsWaiting.Count)
            Start-Sleep -Seconds 1
        }

    }
    
    Main
}

Clear-Host
Write-Host "Press Ctrl+C to End this macro" -ForegroundColor Yellow

#Wait-Job $job
while($true) {
    $jobStatus = Receive-Job $job
    #Write-Host $jobStatus
    Start-Sleep -Seconds 1
}


Clear-Host
Write-Host "End"
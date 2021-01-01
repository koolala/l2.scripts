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
            [System.IntPtr]
            $hWnd,

            [Parameter(Mandatory)]
            [uint32]
            $key
        )

        Process {

            #Write-Host $key
            #[System.IntPtr]

            [System.Win32Util]::SendNotifyMessage($hWnd, 0x100, $key, [System.IntPtr]::Zero)
            #Start-Sleep -Milliseconds 100
            [System.Win32Util]::SendNotifyMessage($hWnd, 0x101, $key, [System.IntPtr]::Zero)


        }
    }


    function L2Windows-Refresh {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory)]
            $hWnd
        )

        Process {
            [System.Win32Util]::ShowWindowAsync($hWnd, 4)
            Start-Sleep -Seconds 1
            [System.Win32Util]::ShowWindowAsync($hWnd, 7)
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
            
            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

            
            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            [return: MarshalAs(UnmanagedType.U2)]
            public static extern short GetKeyState(int lpKeyState);
                        
            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
            

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


            
            [DllImport("user32.dll", SetLastError = true)]
            public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);


            [DllImport("user32.dll")]
            public static extern IntPtr FindWindowEx(IntPtr parentWindow, IntPtr previousChildWindow, string windowClass, string windowTitle);


            public static IntPtr[] GetProcessWindows(int process) {
                List<IntPtr> apRet = new List<IntPtr>();
                IntPtr pLast = IntPtr.Zero;
                do {
                    pLast = FindWindowEx(IntPtr.Zero, pLast, null, null);
                    int iProcess_;
                    GetWindowThreadProcessId(pLast, out iProcess_);
                    if(iProcess_ == process) apRet.Add(pLast);
                } while(pLast != IntPtr.Zero);

                return apRet.ToArray();
            }


            const int GWL_EXSTYLE = (-20);
            const uint WS_EX_APPWINDOW = 0x40000;

            const uint WM_SHOWWINDOW = 0x0018;
            const int SW_PARENTOPENING = 3;


            [DllImport("user32.dll")]
            private static extern bool EnumDesktopWindows(IntPtr hWnd, EnumWindowsProc procFunc, int lParam);
                        
            [DllImport("user32.dll")]
            private static extern bool EnumChildWindows(IntPtr hWnd, EnumWindowsProc procFunc, int lParam);

            [DllImport("user32.dll")]
            static extern uint GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);

            [DllImport("user32.dll")]
            private static extern uint GetWindowTextLength(IntPtr hWnd);

            [DllImport("user32.dll")]
            private static extern uint GetWindowText(IntPtr hWnd, StringBuilder lpString, uint nMaxCount);

            [DllImport("user32.dll", CharSet = CharSet.Auto)]
            static extern bool GetClassName(IntPtr hWnd, System.Text.StringBuilder lpClassName, int nMaxCount);

            [DllImport("user32.dll")]
            static extern int GetWindowLong(IntPtr hWnd, int nIndex);

            delegate bool EnumWindowsProc(IntPtr hWnd, int lParam);

            static bool IsApplicationWindow(IntPtr hWnd) {
              return (GetWindowLong(hWnd, GWL_EXSTYLE) & WS_EX_APPWINDOW) != 0;
            }

            public static IntPtr[] GetWindowHandle(int pid, string title) {
              var result = IntPtr.Zero;
              var outputResult = new List<IntPtr>();


              EnumWindowsProc enumerateHandle = delegate(IntPtr hWnd, int lParam)
              {
                

                int id;
                GetWindowThreadProcessId(hWnd, out id);

                if (pid == 0 || id == 0 || pid == id) {

                  var clsName = new System.Text.StringBuilder(256);
                  var hasClass = GetClassName(hWnd, clsName, 256);
                  if (hasClass) {

                    var maxLength = (int)GetWindowTextLength(hWnd);
                    var builder = new System.Text.StringBuilder(maxLength + 1);
                    
                    //var maxLength = (int)GetWindowTextLength(hWnd);
                    //var builder = new System.Text.StringBuilder(256);
                    GetWindowText(hWnd, builder, (uint)builder.Capacity);

                    var text = builder.ToString(); 
                    var className = clsName.ToString();
                    
                    
                    if (text.StartsWith(title) && className.StartsWith("L2UnrealWWindowsViewportWindow") && IsApplicationWindow(hWnd))
                    {
                      //outputResult.Add(text + ":" + hWnd + ":"+ className);
                      outputResult.Add(hWnd);
                      result = hWnd;

                      if (outputResult.Count >= 30) return false;
                    }

                  }
                  
                }
                return true;
              };

              EnumDesktopWindows(IntPtr.Zero, enumerateHandle, 0);

              // return result;
              return outputResult.ToArray();

            }

"@


        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -MemberDefinition $Win32UtilMethodsDefinations -Name Win32Util -Namespace System -UsingNamespace @("System.Text", "System.Collections.Generic")
        
        $VK = [System.Windows.Forms.Keys]


        
        #=== Editable Setting ======================================
        $refreshL2WindowsEnabled = $true
        $fefreshL2WindowsExtendMinutes = 40


        # $VK options:
        # 3rd Row: NumPad1 .. NumPad0 .. DIVIDE .. MULTIPLY
        # 2nd Row: VK_1 .. VK_0 ..
        # 1st Row: F1 .. F12
        $secondsWaiting = @{
            "20 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 20 - 3); key = $VK::F9; start = $null }
            "5 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 5 + 6); key = $VK::F10; start = $null }
            "6 sec attack" = New-Object PSOBJECT -Property @{ wait = (6); key = $VK::F11; start = $null }
        }
        

        #=== System Setting ====
        foreach($key in $secondsWaiting.keys) {
            $secondsWaiting[$key].start = (Get-Date).AddSeconds(-$secondsWaiting[$key].wait)
        }

        $refreshL2Windows = (Get-Date).AddMinutes($fefreshL2WindowsExtendMinutes);
        

        #=== Get L2 Process(es) ===
        #$l2Process = Get-Process -Name "L2.bin" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and [System.Win32Util]::IsIconic($_.MainWindowHandle) -eq $false }
        
        
        #Retrieve window handle by Title
        $l2Process = @()
        [System.Win32Util]::GetWindowHandle(0, "Lineage II") | ForEach-Object {
            if ([System.Win32Util]::IsIconic($_) -eq $false) {
                $l2Process += (NEW-OBJECT PSOBJECT -Property @{ MainWindowHandle=$_; })
            }
        }
        
        
        #=== Init Window ===        
        Write-Host "L2 Process: " @($l2Process).Count
        if ($l2Process -eq $null -or @($l2Process).Count -le 0) { return }
        

        $l2Process | ForEach-Object {
            if ($_.MainWindowHandle -ne 0) {
                Util-DisableMaxButton $_.MainWindowHandle
                Write-Host $_.MainWindowHandle
            }
            
        }

        
        $switchProgress = 0
        while($true) {
            
            #=============================================================
            if ($refreshL2WindowsEnabled -eq $true) {
                $isRefreshL2Windows = [int32] ($refreshL2Windows - (Get-Date)).TotalSeconds
            
                if ($isRefreshL2Windows -le 0) {
                    $l2Process | ForEach-Object {
                        if ($_.MainWindowHandle -ne [System.IntPtr]::Zero) {
                            if ([System.Win32Util]::IsIconic($_.MainWindowHandle)) {
                                L2Windows-Refresh $_.MainWindowHandle
                            }
                        }
                    }

                    $refreshL2Windows = (Get-Date).AddMinutes($fefreshL2WindowsExtendMinutes);
                }
            }

            #=============================================================
            foreach($key in $secondsWaiting.keys) {
                $thisObject = $secondsWaiting[$key]
                if ($thisObject -eq $null -or $thisObject.key -eq 0) { continue; }
                
                $status = "Processing"
                $secondsRemaining = [int32] ($thisObject.wait - ((Get-Date) - $thisObject.start).TotalSeconds)

                if ($secondsRemaining -le 0) {
                    $thisObject.start = Get-Date

                    $isPressedAlt = [bool]([System.Win32Util]::GetKeyState(0x12) -band 0x80)
                    if ($isPressedAlt -eq $true) {
                        
                        $thisObject.start = (Get-Date).AddSeconds(-$secondsWaiting[$key].wait + 6)
                        $secondsRemainging = 6
                        $status = "Hold"

                    }
                    else {

                        $l2Process | ForEach-Object {
                            if ($_.MainWindowHandle -ne [System.IntPtr]::Zero) {
                                Util-PressKey $_.MainWindowHandle $thisObject.key
                            }
                        }

                    }

                }
                

                if ($switchProgress -eq $($secondsWaiting.Keys).IndexOf($key)) {
                    Write-Progress -Activity $key -Status $status -SecondsRemaining $secondsRemaining
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
# l2.scripts
Script for Lineage II gaming automation

# The tutorial videos
https://www.youtube.com/watch?v=GIWqDpPDeH4



> Default Setting
``` powershell
$secondsWaiting = @{
    "20 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 20 - 3); key = $VK::F9; start = $null }
    "5 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 5 + 6); key = $VK::F10; start = $null }
    "6 sec attack" = New-Object PSOBJECT -Property @{ wait = (6); key = $VK::F11; start = $null }
}
```

> Model
``` powershell
"20 mins ++" = New-Object PSOBJECT -Property @{ wait = (60 * 20 - 3); key = $VK::F9; start = $null }
```

**"Label"** = @{ \
  **wait** = **{number}**;   \# Waiting seconds \
  **key** = **{number}**;    \# Press which key (See the microsoft Virtual Key reference. or below virtual key sections) \
  start = $null;             \# Keep this pattern as well \
}


# Virtual Key
Lineage 2 keys setting \
3rd Row: NumPad1 .. NumPad0 .. DIVIDE .. MULTIPLY \
2nd Row: VK_1 .. VK_0 .. \
1st Row: F1 .. F12

Virtual Key Enum in C#
https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.keys?view=netframework-4.8


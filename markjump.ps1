#
## :: # Leon Bambrick's Powershell implementation of Mark & Jump!
## :: inspired by this: http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
##
## # MIT License.
## > "dot this file" !!
## (for example) add++ this to your $profile # powershell profile
##     . .\markjump.ps1  # dot load the markjump.ps1 file.
## # USAGE
## > mark "fred"   <-- mark the current location as "fred"
## > marks         <-- list all marks.
## > jump "fred"   <-- 'cd' to the location known as "fred"
## > unmark "fred" <-- remove "fred" from the list of marks.
##
## # Note that marks are persisted across sessions. They are **permanenty!**
#
# Prefix any helpful comment that you wish to output via `markjump_help` with TWO HASHES
#
# TODO:
# [ ] STORE THESE THINGS ABOUT EACH MARK:
#    - date created -- mark-created
#    - date last used
#    - number of times used
#
#

$marks = $null;
# 4 shell functions: jump, mark, unmark, and marks:

function Write-TokenyTokens {
  Param(
    [Parameter(
      ValueFromPipeline = $true,
      HelpMessage = 'Tokens to be highlighted',
      Position = 0)]
    [string[]]$Tokens
  )
  Begin {

  }
  Process {
    ForEach ($token in $tokens) {
      #Pipeline input
      if ($token -eq "...") {
        Write-Host "..." -f DarkBlue -n;
      }
      else {
        Write-Host $token -f darkgray -n;
      }
    }
  }
  End {
  }
}

function Write-Filler($filler, $front, $back) {
  function elips($in, $maxLen, $front, $back) {
    # private function
    if ($in.length -gt $maxLen) {
      # $front
      # $in.substring(0, $maxLen)
      # $back;

      $in.substring(0, $maxLen / 2)
      $back;
      $in.substring($in.length - ($maxLen / 2), $maxLen / 2);
      #$back;
      return;
    }
    $in
    return;
  }

  Write-TokenyTokens (elips $filler 50 $front $back)
}

function Store-Jump ($jumpName) {
  # write-host "$(get-date -f "yyyy-MM-dd HH:mm:ss"),$jumpName to $( $env:localappdata + "\mark-log.csv" )" -f yellow;
  if ((Test-Path $env:localappdata"\mark-log.csv") -eq $false) {
    "Date,Token" | Out-File ($env:localappdata + "\mark-log.csv") -Encoding utf8;
  }

  "$(Get-Date -f "yyyy-MM-dd HH:mm:ss"),$jumpName"  | Out-File ($env:localappdata + "\mark-log.csv") -Encoding utf8 -Append;
}

## rank-jumps    -- list the 10 most popular locations to jump to
function rank-jumps () {
  if ((Test-Path $env:localappdata"\mark-log.csv") -eq $false) {
    "Date,Token" | Out-File ($env:localappdata + "\mark-log.csv") -Encoding utf8;
  }

  $jumpsMade = Import-Csv ($env:localappdata + "\mark-log.csv");
  $jumpsMade | 
    Group-Object -prop Token | 
    Sort-Object -prop count -desc | 
    Select-Object -First 10 | 
    ForEach-Object { 
      show-code "j $($_.Name.PadRight(15))  # $($_.Count)"; wh ""; 
    }
}

# TODO: Move this to another file!
function Write-MarkedPatternInline($pattern, $line, $Raw, $CaseSensitive, $newLine = $true) {
  #TODO: Add 'mark' color.
  #TODO: Add 'non marked' color'
  #TODO: Move Write-MarkedPatternInline into its own module

  if ($null -eq $Raw) {
    # RAW (meaning, simple match, not regex match) defaults to FALSE
    $Raw = $false;
  }

  if ($Raw) {
    $pattern = [regex]::Escape($pattern);
  }

  $regexOptions = 'None';
  if ($null -eq $CaseSensitive) {
    # Default is CASE INSENSITIVE... ignore case.
    $CaseSensitive = $false;
  }

  if (-not $CaseSensitive) {
    $regexOptions = 'IgnoreCase';
  }

  [regex]::Matches($line, $pattern, $RegexOptions) |
    ForEach-Object -Begin {
      $upTo = 0;
    } -Process {
      #write-host $_.Index -f green -n;
      write-filler $line.Substring($upTo, ($_.Index - $upTo)) "" "...";
      #write-host $line.Substring($upTo, ($_.Index - $upTo)) -f darkgray -n;
      Write-Host $_.Value -f white -n; # -b green;
      #$aResult = $_;
      $upTo = $_.Index + $_.Value.Length;
    } -End {
      #write-host $line.SubString(0 + $aResult.Index +$aResult.Value.Length, $line.length - $aResult.Index - $aResult.Value.Length) -f gray;
      write-filler $line.Substring($upTo) "" "...";
      #write-host $line.SubString($upTo) -f darkgray -n;
    }
}

function Get-ActualFileName {
  Param (
    [parameter(Mandatory = $true)]
    [string]
    $DirOrFile
  )

  if (-not ( (Test-Path $DirOrFile -PathType Leaf) -or (Test-Path $DirOrFile -PathType Container) ) ) {
    # File or directory not found
    return $DirOrFile
  }
  $DirOrFile = $DirOrFile.TrimEnd("\")
  $TruePath = "";
  foreach ($PathPart in $DirOrFile.Split("\")) {
    if ($TruePath -eq "") {
      $TruePath = $PathPart.ToUpper() + "\";
      continue;
    }
    $TruePath = [System.IO.Directory]::GetFileSystemEntries($TruePath, $PathPart)[0];
  }
  return $TruePath;
}


function Write-CaseDifference ($string1, $string2) {
  $i = 0;
  $string1.ToCharArray() | ForEach-Object {
    if ($_ -ne $string2[$i]) {
      Write-Host  $string2[$i] -n -f white -b red;
      #Write-Host  $_ -n -f red;
    }
    elseif ($_ -ceq $string2[$i]) {
      Write-Host  $_ -n -f darkgray;
    }
    else {
      Write-Host  $string2[$i] -n -f black -b darkred;
      #Write-Host  $_ -n -f darkred;
    }

    $i++;
  }

  if ($string2.length -gt $string1.length) {
    $String2.substring($string1.length).ToCharArray() | ForEach-Object {
      Write-Host  $_ -n -f black -b darkgreen;
    }
  }

  Write-Host "";
}


# jump to a folder
# can enter exact name of mark, or prefix.
# if ok is on the system, then it will be called after the jump. Any other command provided will be passed on to ok.
function jump {

  param (
    [parameter(mandatory = $false, position = 0)][string]$name,
    [parameter(mandatory = $false)][switch]$suppressOk,
    [parameter(
      mandatory = $false,
      position = 1,
      ValueFromRemainingArguments = $true
    )][string]$arg
  )

  $exactName = $name;

  if ($null -eq $name -or $name -eq "") {
    Write-Host "No mark specified. " -ForegroundColor "yellow" -n #warning only!
    Write-Host "For help try: " -n
    Write-Host "'markjump_help'" -ForegroundColor "white" -n

    marks;
    # also display help? No.
    return;
  }

  if ($name -match "\*" -or $name -match "\?") {
    # name contains an asterisk or a question mark... they are searching.
    $searching = $true;
  }

  $target = $marks[$name];

  if ($null -eq $target) {
    ## jump without having identified an exact target... e.g. just "j", "j tod" (starting fragment of 'todo'), or "j s*" (searching) or "j sa?"
    foreach ($h in $marks.GetEnumerator() | Sort-Object -Property Name) {
      if ($searching) {
        if ($h.Name -like $name) {
          $foundCandidate = $true;
          $exactName = $h.Name;
          Write-Host "j " -f yellow -n
          Write-MarkedPatternInline ($name.Replace("*", "")) ($h.Name);
          Write-Host ("`t# " + $h.Value) -f darkgreen;
        }
      }
      else {
        if ($h.Name.StartsWith($name, "CurrentCultureIgnoreCase")) {
          $foundCandidate = $true;
          $exactName = $h.Name;
          Write-Host "No such mark! " -ForegroundColor "yellow" -n #warning only!
          Write-Host "Assume you meant: " -n
          Write-Host "'jump $($h.Name)'" -ForegroundColor "white" -n
          Write-Host ", " -n
          Write-Host "jumping now..." -ForegroundColor "green" #success!

          if ((Test-Path $h.Value)) {
            if ($h.Value -cne (Get-ActualFileName $h.Value)) {
              Write-Host "Incorrect case $($h.Value)";
              Write-CaseDifference $h.Value (Get-ActualFileName $h.Value);
              $h.Value = (Get-ActualFileName $h.Value)
            }

            # clear the current gitbranch so that re-detection can occur
            $env:gitbranch = $null;

            # Here is an actual jump (in case of inexact name provided)
            Store-Jump ($h.Name);
            Push-Location $h.Value;
            $Host.UI.RawUI.WindowTitle = ($h.Name.ToUpper() + ("✔")); # $exactName.ToUpper();
            if ($suppressOk -eq $false) {
              TryOk $arg;
            }

            return;
          }
          else {
            # "That folder no longer exists. Perhaps you should 'unmark $($h.Name)'?"
            Write-Host "That folder no longer exists. " -ForegroundColor "red" -n
            Write-Host "Perhaps you should: " -n
            Write-Host "'unmark $($h.Name)'" -ForegroundColor "white"  -n
            Write-Host "?"
            # we don't do this automatically, in case, for example it's on a networked drive that is only temporarily unavaiable.

            return;
          }
        }
      }
    }
    # "no such target! perhaps you meant 'mark $name'";
    if (!$foundCandidate) {
      Write-Host "No such mark! " -ForegroundColor "red" -NoNewline
    }
    if (!$searching) {
      Write-Host "Perhaps you meant: " -NoNewline
      Write-Host "'mark $name'" -ForegroundColor "white" -NoNewline
      Write-Host "?" -NoNewline
    }
    Write-Host "";

    return;
  }
  if ((Test-Path $target)) {

    if ($target -cne (Get-ActualFileName $target)) {
      Write-Host "Incorrect case $target";
      Write-CaseDifference $target (Get-ActualFileName $target);
      $target = (Get-ActualFileName $target)
    }

    # clear the current gitbranch so that re-detection can occur
    $env:gitbranch = $null;

    # Here is an actual JUMP! (in case of exact name)
    Store-Jump ($name);
    Push-Location $target;

    $Host.UI.RawUI.WindowTitle = $exactName.ToUpper() + ("✔");

    if ($suppressOk -eq $false) {
      TryOk $arg;
    }
  }
  else {
    # "That folder no longer exists. Perhaps you should 'unmark $name'"
    Write-Host "Folder no longer exists. " -ForegroundColor "red" -n
    Write-Host "perhaps you should: " -n
    Write-Host "'unmark $name'" -ForegroundColor "white"
  }
}

# mark the current folder...
function mark([string]$name) {
  if ($name -eq "") {
    Write-Host "Specify a name for the mark, e.g." -ForegroundColor "red" -n
    # i use this tortured expression to probably get the current folder name... or something... even when in "Function:", root of "C:\", "HKCU:" etc.
    Write-Host "'mark $(((Get-Item .) | Select-Object -First 1).Name -replace " ", "-" -replace "[\\]", '')'" -ForegroundColor   "white"
    marks;
    return;
  }

  $target = $marks[$name];
  if ($null -ne $target) {
    #'mark already exists. need to unmark first. or maybe you want to jump?'
    Write-Host "Mark already exists. " -ForegroundColor "red" -n
    Write-Host "Need to unmark first. Or maybe you want to " -n
    Write-Host "'jump $name'" -ForegroundColor "white"
    return;
  }

  Get-Location | ForEach-Object { $marks[$name] = $_.Path }
  save-marks;
}

# unmark the current folder
function unmark([string]$name) {
  if ($name -eq "") {
    marks;
    # also display help.
    return;
  }

  $target = $marks[$name];
  if ($null -eq $target) {
    Write-Host "No such mark! " -ForegroundColor   "red"

    foreach ($h in $marks.GetEnumerator() | Sort-Object -Property Name) {
      if ($h.Name.StartsWith($name, "CurrentCultureIgnoreCase")) {
        Write-Host "marks are case sensitive, did you mean " -n
        Write-Host "'unmark $($h.Name)'" -ForegroundColor   "white"
        return;
      }
    }

    Write-Host "(marks are case sensitive. use 'marks' to see all.)"
    return;
  }
  $marks.Remove($name);
  save-marks;
}

# list the marks... but if the value is on a network drive, remove the big ugly prefix "Microsoft.PowerShell.Core\FileSystem::"
function marks() {
  $marks.GetEnumerator() |
    Sort-Object Name |
    Format-Table -Property Name, @{Expression = {
        $_.Value -replace "^Microsoft.PowerShell.Core\\FileSystem::", ""
      }; Label                                = "Value"
    }
}

# 3 Local functions... get-marks, save-marks, and ConvertTo-Hash. These should not be accessed from outside


# LOAD THE MARKS: initialize the $marks variable from the marks.json file (or create the file if necessary)
function Get-marks() {
  if (Get-Command "ConvertTo-Json" -ErrorAction SilentlyContinue) {
    if ((Test-Path $env:localappdata"\marks.json") -eq $false) {
      $script:marks = @{ };
      save-marks;
    }
    $script:marks = ((Get-Content $env:localappdata"\marks.json") -join "`n" | ConvertFrom-Json)
    $script:marks = ConvertTo-Hash $script:marks
  }
  else {

    if ((Test-Path $env:localappdata"\marks.clixml") -eq $false) {
      $script:marks = @{ };
      save-marks;
    }
    $script:marks = (Import-Clixml $env:localappdata"\marks.clixml")
  }
  if ($null -eq $script:marks) {
    $script:marks = @{ };
  }
}

# save-marks: these are persisted to the marks.json file
function Local:save-marks() {
  if (Get-Command "ConvertTo-Json" -ErrorAction SilentlyContinue) {
    ConvertTo-Json $marks > $env:localappdata"\marks.json"
  }
  else {
    #"can't save it there..."
    $marks | Export-Clixml $env:localappdata"\marks.clixml"
  }
}

function Local:ConvertTo-NewHash {
  [CmdletBinding(DefaultParameterSetName = 'DirectParameter')]
  param (
    [Parameter(ParameterSetName = 'DirectParameter', ValueFromPipeline = $false, Position = 0)]
    [PSObject]$PSO,

    [Parameter(ParameterSetName = 'LiteralPSO', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('Obj')]
    [PSObject[]]$LiteralPSO
  )
  Begin {
  }
  Process {
    $nuHash = @{ };
    if ($PSCmdlet.ParameterSetName -eq 'LiteralPSO') {
      #wh "Processing pipeline input: $LiteralPSO";
      ForEach ($myPso in $LiteralPSO) {
        $names = $myPso | Get-Member -MemberType properties | Select-Object -ExpandProperty name
        if ($null -ne $names) {
          $names | ForEach-Object { 
            $nuHash.Add($_, $myPso.$_);
          }
        }
      }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'DirectParameter' -and $PSO) {
      $names = $PSO | Get-Member -MemberType properties | Select-Object -ExpandProperty name
      if ($null -ne $names) {
        $names | ForEach-Object { $nuHash.Add($_, $PSO.$_) }
      }
    }
    $nuHash;
  } # process
  End {
  } #end
}

# ConvertTo-Hash is used by Get-marks to convert the custom psObject into a hash table.
function Local:ConvertTo-Hash($i) {
  $hash = @{ };

  $names = $i | Get-Member -MemberType properties | Select-Object -ExpandProperty name
  if ($null -ne $names) {
    $names | ForEach-Object { $hash.Add($_, $i.$_) }
  }
  $hash;
}

## markjump_help    -- this output
function markjump_help() {
  $x = (& { $myInvocation.ScriptName })
  Get-Content $x | Where-Object {
    $_ -like "## *" -or $_ -eq "##"
  } |
    ForEach-Object {
      $_.TrimStart("#");
    }
    | ForEach-Object { show-code $_ ; wh ""; }

  if (Get-Command "ConvertTo-Json" -ErrorAction SilentlyContinue) {
    $markFile = ($env:localappdata + "\marks.json")
  }
  else {
    $markFile = ($env:localappdata + "\marks.clixml")
  }
  Write-Host "`n   Your mark file is:         " -n -f darkgray;
  Write-Host $markFile -f white;
  Write-Host "   Your markjump log file is: " -n -f darkgray;
  Write-Host (Join-Path $env:localappdata "mark-log.csv") -f white;
}

function TryOk ($argies) {
  if (Get-Command "ok" -ErrorAction SilentlyContinue) { ok $argies }
}


Get-marks;
#$marks
##
## # Recommended aliases:
##   m -> mark
##   j -> jump
##   um -> unmark
Set-Alias m mark
Set-Alias um unmark
Set-Alias j jump
Set-Alias j+ mark

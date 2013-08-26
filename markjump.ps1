#
# (Leon Bambrick's Powershell implementation of) Mark & Jump!
# inspired by this: http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
#
# MIT License.
# dot this file (for example add this to your $profile: ". .\markjump.ps1")

$marks = $null;
# four shell functions jump, mark, unmark, and marks:
function jump($name) {
  # jump to a folder
  $target = $marks[$name];
  if ($target -ne $null -and (test-path $target)) { set-location $target;}
}

function mark([string]$name) {
   # mark the current folder...
  if ($name -ne "") {
    get-location | % { $marks[$name] = $_.Path }
  }
  save-marks;
}

function unmark([string]$name) {
  # unmarks the current folder
  $marks.Remove($name);
  save-marks;
}

function marks() {
  # list all marks
  Load-marks;
  $marks.GetEnumerator() | % { [string]$_.name + " -> " + [string]$_.value }
}

# 3 Local functions... save-marks, Load-marks and ConvertTo-Hash

# save-marks: these are persisted the the marks.json file
function Local:save-marks() {
  ConvertTo-Json $marks > $env:localappdata"\marks.json"
}
# initial the $marks variable from the marks.json file (or create the file if necessary)
function Local:Load-marks() {
 if ((test-path $env:localappdata"\marks.json") -eq $false) { 
    $script:marks = @{};
    save-marks;
  }
  $script:marks = ((Get-Content $env:localappdata"\marks.json") -join "`n" | ConvertFrom-Json)
  $script:marks = ConvertTo-Hash $script:marks
  if ($script:marks -eq $null) {
    $script:marks = @{};
  }
}

# ConvertTo-Hash is used by Load-marks to convert the custom psObject into a hash table.
function Local:ConvertTo-Hash($i) {
    $hash = @{};

    $names = $i | Get-Member -MemberType properties | Select-Object -ExpandProperty name 
    if ($names -ne $null) {
        $names | ForEach-Object { $hash.Add($_,$i.$_) }
    } 
    $hash;
}

Local:Load-marks;

set-alias m mark
set-alias um unmark
set-alias j jump
function Trace-Message {
    <#
        .Synopsis
            Wrap Verbose, Debug, or Warning output with command profiling trace showing script line and time elapsed
        .Description

            Creates a stopwatch that tracks the time elapsed while a script runs, and adds caller position and time to the output
        .Example
            foreach($i in 1..20) { sleep -m 50; Trace-Message "Progress $i" }

            Demonstrates the simplest use of Trace-Message to add a duration timestamp to the message.
        .Example
            function Test-Trace {
                [CmdletBinding()]param()
                foreach($i in 1..20) {
                    $i
                    Trace-Message {
                        sleep -m 50; # just to be sure you can tell this is slow
                        $ps = (Get-Process | sort PM -Desc | select -first 2)
                        "Memory hog {1} using {0:N2}GB more than next process" -f (($ps[0].WS -$ps[1].WS) / 1GB), $ps[0].Name
                    } @PSBoundParameters
                }
            }

            Demonstrates how using a scriptblock can avoid calculation of complicated output when -Verbose is not set.  In this example, "Test-Trace" by itself will output 1-20 in under 20 miliseconds, but with verbose output, it can take over 1.25 seconds
    #>
    [CmdletBinding(DefaultParameterSetName="VerboseOutput")]
    param(
        # The message to write, or a scriptblock, which, when evaluated, will output a message to write
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="VerboseOutput",Position=0)]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="WarningOutput",Position=0)]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="DebugOutput",Position=0)]
        [PSObject]$Message,

        # When set, output to the warning stream instead of verbose
        [Parameter(Mandatory=$true,ParameterSetName="WarningOutput")]
        [Alias("AsWarning")]
        [switch]$WarningOutput,

        # When set, output to the debug stream instead of verbose
        [Parameter(Mandatory=$true,ParameterSetName="DebugOutput")]
        [Alias("AsDebug")]
        [switch]$DebugOutput,

        # Reset the timer to time the next block from zero
        [switch]$ResetTimer,

        # Clear out the timer completely after this output
        # When you explicitly pass a Stopwatch, you can pass this flag (only once) to stop and remove it
        [switch]$KillTimer,

        # A custom string overrides the automatic formatting which changes depending on how long the duration is
        [string]$ElapsedFormat,

        # If set, show the time since last Trace-Message
        [switch]$ShowStepTime,

        # Supports passing in an existing Stopwatch (running or not)
        [Diagnostics.Stopwatch]$Stopwatch
    )
    begin {
        if($Stopwatch) {
            ${Script:Trace Message Timer} = $Stopwatch
            ${Script:Trace Message Timer}.Start()
        }
        if(-not ${Trace Message Timer}) {
            ${global:Trace Message Timer} = New-Object System.Diagnostics.Stopwatch
            ${global:Trace Message Timer}.Start()

            # When no timer is provided...
            # Assume the timer is for "run" and
            # Clean up automatically at the next prompt
            $PreTraceTimerPrompt = $function:prompt

            $function:prompt = {
                if(${global:Trace Message Timer}) {
                    ${global:Trace Message Timer}.Stop()
                    Remove-Variable "Trace Message Timer" -Scope global -ErrorAction SilentlyContinue
                }
                & $PreTraceTimerPrompt
                ${function:global:prompt} = $PreTraceTimerPrompt
            }.GetNewClosure()
        }

        $Script:LastElapsed = $Script:Elapsed
        $Script:Elapsed = ${Trace Message Timer}.Elapsed.Duration()

        if($ResetTimer -or -not ${Trace Message Timer}.IsRunning)
        {
            ${Trace Message Timer}.Restart()
        }

        # Note this requires a host with RawUi
        $w = $Host.UI.RawUi.BufferSize.Width
    }

    process {
        if(($WarningOutput -and $WarningPreference -eq "SilentlyContinue") -or
           ($DebugOutput -and $DebugPreference -eq "SilentlyContinue") -or
           ($PSCmdlet.ParameterSetName -eq "VerboseOutput" -and $VerbosePreference -eq "SilentlyContinue")) { return }

        [string]$Message = if($Message -is [scriptblock]) {
                             ($Message.InvokeReturnAsIs(@()) | Out-String -Stream) -join "`n"
                           } else { "$Message" }

        $Message = $Message.Trim()

        $Location = if($MyInvocation.ScriptName) {
                        $Name = Split-Path $MyInvocation.ScriptName -Leaf
                        "${Name}:" + "$($MyInvocation.ScriptLineNumber)".PadRight(4)
                    } else { "" }

        $Tail = $(if($ElapsedFormat) {
                      "{0:$ElapsedFormat}" -f $Elapsed
                  }
                  elseif($Elapsed.TotalHours -ge 1.0) {
                      "{0:h\:mm\:ss\.ffff}" -f $Elapsed
                  }
                  elseif($Elapsed.TotaMinutes -ge 1.0) {
                      "{0:mm\m\ ss\.ffff\s}" -f $Elapsed
                  }
                  else {
                      "{0:ss\.ffff\s}" -f $Elapsed
                  }).PadLeft(12)

        $Tail = $Location + $Tail

        # "WARNING:  ".Length = 10
        $Length = ($Message.Length + 10 + $Tail.Length)
        # Twenty-five is a minimum 15 character message...
        $PaddedLength = if($Length -gt $w -and $w -gt (25 + $Tail.Length)) {
                            [string[]]$words = -split $message
                            $short = 10 # "VERBOSE:  ".Length
                            $count = 0  # Word count so far
                            $lines = 0
                            do {
                                do {
                                    $short += 1 + $words[$count++].Length
                                } while (($words.Count -gt $count) -and ($short + $words[$count].Length) -lt $w)
                                $Lines++
                                if(($Message.Length + $Tail.Length) -gt ($w * $lines)) {
                                    $short = 0
                                }
                            } while($short -eq 0)
                            $Message.Length + ($w - $short) - $Tail.Length
                        } else {
                            $w - 10 - $Tail.Length
                        }

        $Message = "$Message ".PadRight($PaddedLength, "$([char]8331)") + $Tail

        if($WarningOutput) {
            Write-Warning $Message
        } elseif($DebugOutput) {
            Write-Debug $Message
        } else {
            Write-Verbose $Message
        }
    }

    end {
        if($KillTimer -and ${Trace Message Timer}) {
            ${Trace Message Timer}.Stop()
            Remove-Variable "Trace Message Timer" -Scope Script -ErrorAction Ignore
            Remove-Variable "Trace Message Timer" -Scope Global -ErrorAction Ignore
        }
    }
}
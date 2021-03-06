[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position=1)]
    [string]$FilePath,
    [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
    [string]$HashType = "MD5",
    [ValidateSet("Console","XML")]
    [string]$OutputTo = "Console",
    [string]$OutputFile = ".\hash_output.xml",
    [switch]$NoRecursion
)

switch ( $HashType.ToUpper() )
{
    "MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
    "SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
    "SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
    "SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
    "SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
    "RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
    default     { Write-Error -Message "Invalid hash type selected." -Category InvalidArgument }
}

if ( Test-Path $FilePath )
{
    if ( $NoRecursion -or ( Test-Path $FilePath -PathType Leaf ) )
    {
        $FileList = Get-ChildItem $FilePath
    }
    else
    {
        $FileList = Get-ChildItem $FilePath -Recurse
    }

    $HashList = @{}

    foreach( $File in $FileList )
    {
        if ( $File.PSIsContainer -eq $false )
        {
            $FileName = Resolve-Path $File.FullName
            $fileData = New-Object IO.StreamReader $FileName
            $HashBytes = $hash.ComputeHash($fileData.BaseStream)
            $fileData.Close()
            $PaddedHex = ""

            foreach( $Byte in $HashBytes )
            {
                $ByteInHex = [String]::Format("{0:X}", $Byte)
                $PaddedHex += $ByteInHex.PadLeft(2,"0")
            }

            $HashList.Add("$FileName","$PaddedHex")
        }
    }

    if ( $OutputTo.ToUpper() -eq "XML" )
    {
        $HashList | Export-Clixml -Path $OutputFile
    }
    else
    {
        $HashList
    }
}
else
{
    Write-Error -Message "Invalid input file or path specified." -Category InvalidArgument
}

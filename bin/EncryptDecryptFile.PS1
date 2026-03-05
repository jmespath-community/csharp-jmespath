[CmdletBinding()]
param(
  [switch]$Encrypt
)

BEGIN {

  #################
  # Powershell Allows The Loading of .NET Assemblies
  # Load the Security assembly to use with this script
  #################
  [Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null

  Function Get-Crypto(){
    param(
      [string]$Passphrase,
      [string]$salt,
      [string]$init
    )
      # Create a COM Object for RijndaelManaged Cryptography
    $r = New-Object System.Security.Cryptography.RijndaelManaged
    # Convert the Passphrase to UTF8 Bytes
    $pass_ = [Text.Encoding]::UTF8.GetBytes($Passphrase)
    # Convert the Salt to UTF Bytes
    $salt = [Text.Encoding]::UTF8.GetBytes($salt)

    # Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits
    
    $r.Key = (
      New-Object Security.Cryptography.PasswordDeriveBytes `
      -Arg @($pass_, $salt_, "SHA1", 5)
      ).GetBytes(32) #256/8

    # Create the Intersecting Vector Cryptology Hash with the init
    $r.IV = (
      New-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init)
    )[0..15]

    Write-Output $r
  }

  #################
  # This function is to Encrypt A String.
  # $string is the string to encrypt, $passphrase is a second security "password" that has to be passed to decrypt.
  # $salt is used during the generation of the crypto password to prevent password guessing.
  # $init is used to compute the crypto hash -- a checksum of the encryption
  #################
  Function Encrypt-File {
    param(
      [string] $path,
      [string] $Passphrase,
      [string] $outputPath,
      [string] $salt="SaltCrypto",
      [string] $init="IV_Password"
    )

    $r = Get-Crypto -Passphrase $Passphrase -Salt $salt -Init $init
    $c = $r.CreateEncryptor()

    # Creates a MemoryStream to do the encryption in
    # Creates the new Cryptology Stream --> Outputs to $MS or Memory Stream

    $ms = New-Object IO.MemoryStream
    $cs = New-Object Security.Cryptography.CryptoStream -Arg @($ms, $c, "Write")
    $fs = [IO.File]::OpenRead($path)

    $fs.CopyTo($cs);

    $fs.Close();
    $cs.Close()
    $ms.Close()

    # Clears the IV and HASH from memory to prevent memory read attacks
    $r.Clear()

    # Takes the MemoryStream and puts it to an array
    [byte[]]$result = $ms.ToArray()

    $os = [IO.File]::OpenWrite($outputPath);
    $os.Write($result,0,$result.Length);
    $os.Close();
  }

  Function Decrypt-File {
    param(
      [string] $path,
      [string] $Passphrase,
      [string] $OutputPath,
      [string] $salt="SaltCrypto",
      [string] $init="IV_Password"
    )

    $r = Get-Crypto -Passphrase $Passphrase -Salt $salt -Init $init

    # Create a new Decryptor
    $d = $r.CreateDecryptor()

    # Create a New memory stream with the encrypted value.
    # Read the new memory stream and read it in the cryptology stream

    $fs = [IO.File]::OpenRead($path)
    $cs = New-Object Security.Cryptography.CryptoStream -Arg @($fs, $d, "Read")
    $os = [IO.File]::Open($outputPath, [IO.FileMode]::Truncate, [IO.FileAccess]::Write)

    $cs.CopyTo($os);

    $os.Close();
    $cs.Close()
    $fs.Close()

    # Clears the RijndaelManaged Cryptology IV and Key
    $r.Clear()
  }
}

PROCESS {

  $SRC_DIR = (Resolve-Path -Path (
    Join-Path -Path $PSScriptRoot -ChildPath "..")).Path
  
  $STRONG_NAME_PLAINTEXT_KEY_PATH="$($SRC_DIR)/src/jmespath.net.snk"
  $STRONG_NAME_ENCRYPTED_KEY_PATH="$($SRC_DIR)/src/jmespath.net.snk.crypted"
  
  if ($Encrypt.IsPresent) {
    Encrypt-File `
      -path $STRONG_NAME_PLAINTEXT_KEY_PATH `
      -Passphrase $env:SNK_PASSPHRASE `
      -salt $env:SNK_SALT `
      -init $env:SNK_INIT `
      -outputPath $STRONG_NAME_ENCRYPTED_KEY_PATH
  }
  
  else {
    Decrypt-File `
      -path $STRONG_NAME_ENCRYPTED_KEY_PATH `
      -Passphrase $env:SNK_PASSPHRASE `
      -salt $env:SNK_SALT `
      -init $env:SNK_INIT `
      -outputPath $STRONG_NAME_PLAINTEXT_KEY_PATH
  }
}

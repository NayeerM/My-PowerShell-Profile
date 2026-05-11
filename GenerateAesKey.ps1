$keyLength = 32

# Create a byte array to hold the random key
$randomKey = New-Object byte[] $keyLength

# Generate a cryptographically secure random key
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($randomKey)

# Convert the byte array to a Base64 string for easy storage
$jwtSecretKey = [Convert]::ToBase64String($randomKey)

# Output the generated secret key
$jwtSecretKey

#!/bin/bash
# Create a self-signed code signing certificate and import it into the
# login keychain. Saves the cert name to .signing-identity so build scripts
# pick it up automatically.
set -euo pipefail

cd "$(dirname "$0")/.."

CERT_NAME="${1:-ShotX Signing}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Bail out early if already present (and listed as a code signing identity)
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$CERT_NAME"; then
    echo "→ Cert '$CERT_NAME' already exists as a code signing identity"
else
    echo "→ Generating cert + key with openssl"
    openssl req -x509 -newkey rsa:2048 \
        -keyout "$TMP/key.pem" \
        -out "$TMP/cert.pem" \
        -days 3650 -nodes \
        -subj "/CN=$CERT_NAME" \
        -addext "basicConstraints=critical,CA:FALSE" \
        -addext "keyUsage=critical,digitalSignature" \
        -addext "extendedKeyUsage=codeSigning" \
        2>/dev/null

    echo "→ Bundling as PKCS12 (legacy format for macOS compatibility)"
    P12_PASS="shotx"
    LEGACY_FLAG=""
    if openssl pkcs12 -help 2>&1 | grep -q -- '-legacy'; then
        LEGACY_FLAG="-legacy"
    fi
    openssl pkcs12 -export $LEGACY_FLAG \
        -out "$TMP/cert.p12" \
        -inkey "$TMP/key.pem" \
        -in "$TMP/cert.pem" \
        -name "$CERT_NAME" \
        -password "pass:$P12_PASS"

    echo "→ Importing to login keychain"
    security import "$TMP/cert.p12" \
        -k "$KEYCHAIN" \
        -P "$P12_PASS" \
        -T /usr/bin/codesign \
        -T /usr/bin/security

    echo "→ Marking cert as trusted for code signing (may prompt for password)"
    security add-trusted-cert -d -r trustRoot -p codeSign \
        -k "$KEYCHAIN" "$TMP/cert.pem" 2>/dev/null || true
fi

echo "→ Saving identity name to .signing-identity"
echo "$CERT_NAME" > .signing-identity

echo
echo "✓ Cert '$CERT_NAME' is ready."
echo
echo "  • Build scripts will sign with it automatically."
echo "  • The cert is self-signed; macOS will show a Gatekeeper warning the"
echo "    first time you install a build (right-click → Open). After that,"
echo "    Screen Recording permission persists across updates."
echo
echo "Note: macOS may prompt you to allow codesign to access the private"
echo "key the first time it signs. Click 'Always Allow'."

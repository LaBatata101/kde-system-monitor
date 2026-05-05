#!/usr/bin/env bash
set -e

PLASMOID_NAME="com.labatata.sysmonitor"
VERSION=$(grep '"Version"' package/metadata.json | cut -d '"' -f 4)
FILENAME="${PLASMOID_NAME}-v${VERSION}.plasmoid"

echo "📦 Packaging $PLASMOID_NAME version $VERSION..."

# A .plasmoid file is just a ZIP archive containing the package files
# We exclude the git directory, install scripts, and screenshots
zip -r "$FILENAME" \
    metadata.json \
    package/contents \
    LICENSE \
    README.md \
    -x "*.git*" \
    -x "install.sh" \
    -x "package.sh" \
    -x ".qml*"


echo "✅ Created package: $FILENAME"

#!/bin/sh
#
# Добавляет в Info.plist собранного приложения URL-схему входа через Google
# (реверс CLIENT_ID). Без неё GoogleSignIn SDK падает с NSException.
#
# Скрипт нужен потому, что проект собирает Info.plist автоматически
# (GENERATE_INFOPLIST_FILE = YES), а CFBundleURLTypes нельзя задать через
# INFOPLIST_KEY_*. Client ID читается из GoogleService-Info.plist, поэтому при
# замене этого файла (например, после включения провайдера Google в Firebase)
# править проект не нужно.

set -e

GOOGLE_PLIST="${SRCROOT}/Beacon/GoogleService-Info.plist"
BUILT_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ ! -f "${GOOGLE_PLIST}" ] || [ ! -f "${BUILT_PLIST}" ]; then
    exit 0
fi

CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :CLIENT_ID" "${GOOGLE_PLIST}" 2>/dev/null || echo "")

if [ -z "${CLIENT_ID}" ]; then
    echo "warning: В GoogleService-Info.plist нет CLIENT_ID, вход через Google работать не будет. Включите провайдер Google в Firebase Console и замените файл."
    exit 0
fi

REVERSED_CLIENT_ID=$(printf '%s' "${CLIENT_ID}" | awk -F. '{ for (i = NF; i > 0; i--) printf "%s%s", $i, (i > 1 ? "." : ORS) }')

/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "${BUILT_PLIST}" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "${BUILT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "${BUILT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "${BUILT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "${BUILT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string ${REVERSED_CLIENT_ID}" "${BUILT_PLIST}"

echo "note: Добавлена URL-схема Google Sign-In: ${REVERSED_CLIENT_ID}"

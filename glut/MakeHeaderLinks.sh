#!/bin/sh

# This shell-script happens only when installing and causes the 
# gle and glsmap links in the Headers dir to be created.

if [ a"${TARGET_BUILD_DIR}" = a"" ] ; then
    TARGET_BUILD_DIR="${SYMROOT}"
fi

hdrLinks="gle glsmap"
hdrDir="${TARGET_BUILD_DIR}/${PRODUCT_NAME}.${WRAPPER_EXTENSION}/Versions/${FRAMEWORK_VERSION}/Headers"

echo SYMROOT=${SYMROOT}
echo TEMP_FILES_DIR=${TEMP_FILES_DIR}
echo TARGET_BUILD_DIR=${TARGET_BUILD_DIR}
echo Headers=${hdrDir}

if [ z"${ACTION}" = z"install" ] ; then
    echo -n "Installing GLUT header links "
    for h in $hdrLinks ; do
        echo -n "$h "
        (cd "${hdrDir}" ; /bin/ln -sf . $h)
    done
    echo " done."
fi


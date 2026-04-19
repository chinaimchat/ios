#!/bin/sh
# DISABLED: Do not copy ${TOOLCHAIN}/usr/lib/swift-5.0/.../libswiftCore.dylib into the app.
# That binary is only for iOS < 12.2; on iOS 12.2+ it aborts with:
#   "This copy of libswiftCore.dylib requires an OS version prior to 12.2.0."
# Fix: raise IPHONEOS_DEPLOYMENT_TARGET (e.g. 15.0) so Xcode uses OS Swift Concurrency, not back-deploy shims.
exit 0

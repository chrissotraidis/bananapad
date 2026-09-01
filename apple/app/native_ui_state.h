#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Nonzero while UIKit owns interaction or the app is inactive.
int BananaPad_IsNativeUIInputSuppressed(void);

#ifdef __cplusplus
}
#endif

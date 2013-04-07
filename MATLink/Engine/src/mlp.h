/* mlp.h
 *
 * Automatically choose the correct MLPutInteger* function
 * based on the type of data passed
 *
 */


#include <mathlink.h>

inline int mlpPutIntegerList(MLINK link, short *a, int n) {
    return MLPutInteger16List(link, a, n);
}

inline int mlpPutIntegerList(MLINK link, unsigned short *a, int n) {
    return MLPutInteger16List(link, (short *) a, n);
}

inline int mlpPutIntegerList(MLINK link, int *a, int n) {
    return MLPutInteger32List(link, a, n);
}

inline int mlpPutIntegerList(MLINK link, unsigned int *a, int n) {
    return MLPutInteger32List(link, (int *) a, n);
}

inline int mlpPutIntegerList(MLINK link, mlint64 *a, int n) {
    return MLPutInteger64List(link, a, n);
}

inline int mlpPutIntegerList(MLINK link, unsigned long *a, int n) {
    return MLPutInteger64List(link, (mlint64 *) a, n);
}

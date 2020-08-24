package systemstatus

/*
#include <sys/statvfs.h>
#include <sys/types.h>

double getDiskUsage(char *path) {
	struct statvfs result;
	if (statvfs(path, &result) == 0) {
		return 1.0 - (double)result.f_bfree / (double)result.f_blocks;
	} else {
		return -1.0;
	}
}
*/
import "C"

import (
	"errors"
)

func GetDiskUsage(directory string) (float64, error) {
	directory_c := C.CString(directory)
	if result := C.getDiskUsage(directory_c); result < 0 {
		return 0, errors.New("Error while retrieving disk usage")
	} else {
		return float64(result), nil
	}
}

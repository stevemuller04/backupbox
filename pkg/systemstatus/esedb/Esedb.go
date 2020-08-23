package esedb

import (
	"os"
	"io"
	"time"
	"errors"
	"encoding/hex"
	"www.velocidex.com/golang/go-ese/parser"
	"github.com/Velocidex/ordereddict"
	"encoding/binary"
	"bytes"
)

func GetLastBackupTimeFromFile(path string) (time.Time, error) {
	if f, err := os.Open(path); err != nil {
		return time.Time{}, err
	} else {
		defer f.Close()
		return GetLastBackupTimeFromReader(f)
	}
}

func GetLastBackupTimeFromReader(r io.ReaderAt) (time.Time, error) {
	var lastBackupTime time.Time

	if ctx, err := parser.NewESEContext(r); err != nil {
		return lastBackupTime, err
	} else if catalog, err := parser.ReadCatalog(ctx); err != nil {
		return lastBackupTime, err
	} else if catalog.DumpTable("global", func(row *ordereddict.Dict) error {
		if key, ok := row.GetString("key"); !ok {
		} else if value, ok := row.GetString("value"); !ok {
		} else if time, err := hexToTime(value); err != nil {
		} else if key == "L\u0000a\u0000s\u0000t\u0000B\u0000a\u0000c\u0000k\u0000u\u0000p\u0000T\u0000i\u0000m\u0000e\u0000\u0000\u0000" {
			lastBackupTime = time
		}
		return nil
	}); err != nil {
		return lastBackupTime, err
	}
	if lastBackupTime.IsZero() {
		return lastBackupTime, errors.New("Unable to find last backup time")
	} else {
		return lastBackupTime, nil
	}
}

func hexToTime(hexString string) (time.Time, error) {
	var wintime int64
	if bin, err := hex.DecodeString(hexString); err != nil {
		return time.Time{}, err
	} else if err := binary.Read(bytes.NewReader(bin), binary.LittleEndian, &wintime); err != nil {
		return time.Time{}, err
	} else {
		// NB: 134774 = number of days between 1601-01-01 (windows filetime) and 1970-01-01 (unix epoch)
		return time.Unix(wintime / 10000000 - 134774 * 86400, wintime % 10000000), nil
	}
}

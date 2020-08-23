package main

import (
	"fmt"
	"time"
	"errors"
	"math"
	"os"
	"os/signal"
	"path/filepath"
	syscall "golang.org/x/sys/unix"
	"bbx/pkg/peripheral"
	"bbx/pkg/systemstatus"
	"bbx/pkg/systemstatus/esedb"
)

func main() {
	peripheral.Init()
	s, _ := peripheral.NewLcdScreen("")
	l, _ := peripheral.NewStatusLed(18)

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		l.Destroy()
		s.Destroy()
		os.Exit(0)
	}()

	for {
		if lastBackup, err := getLastBackupTime("/mnt/usb/live/"); err != nil {
			s.DrawText("No backup!", 0, 0)
			red(l)
		} else {
			s.DrawText("Last backup:", 0, 0)
			s.DrawText(lastBackup.Format("02.01.2006"), 0, 15)

			if lastBackup.Before(time.Now().Add(time.Hour * -36)) {
				red(l)
			} else {
				green(l)
			}
		}

		if du, err := systemstatus.GetDiskUsage("/mnt/usb"); err != nil {
			s.DrawText("Disk: --%", 0, 40)
		} else {
			s.DrawText(fmt.Sprintf("Disk: %d%%", int32(math.Round(du * 100))), 0, 40)
		}

		s.Render()
		l.Render()

		time.Sleep(time.Second * 30)
	}
}

func red(led *peripheral.StatusLed) {
	led.SetColor(100, 0, 0)
}

func green(led *peripheral.StatusLed) {
	led.SetColor(0, 100, 0)
}

func getLastBackupTime(directory string) (time.Time, error) {
	var max time.Time
	if files, err := filepath.Glob(directory + "/*/*/Configuration/Catalog1.edb"); err != nil {
		return max, nil
	} else {
		for _, file := range files {
			if t, err := esedb.GetLastBackupTimeFromFile(file); err == nil && t.After(max) {
				max = t
			}
		}
	}
	if max.IsZero() {
		return max, errors.New("No back-up found")
	} else {
		return max, nil
	}
}


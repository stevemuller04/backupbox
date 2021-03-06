package main


import (
	"fmt"
	"os"
	"os/exec"
	"math"
	"time"
	"path/filepath"
	"github.com/gin-gonic/gin"
	syscall "golang.org/x/sys/unix"
	"bbx/pkg/systemstatus"
	"bbx/pkg/backup"
	"bbx/pkg/systemstatus/esedb"
)

const (
	InternalDiskPath = "/"
	ExternalDiskPath = "/mnt/bbx-disk"
	BackupStoragePath = ExternalDiskPath + "/live"
	SnapshotStoragePath = ExternalDiskPath + "/backup"
	ExternalDiskDevice = "/dev/sda"
	ExternalDiskDevicePartition = ExternalDiskDevice + "1"
)

func main() {
	r := gin.Default()
	r.LoadHTMLGlob("./templates/*")
	r.Static("/css", "./css")
	r.Static("/js", "./js")
	r.GET("/", func(c *gin.Context) {
		c.HTML(200, "index.html", gin.H{
			"uptime": templateGetUptime(),
			"usage_internal": templateGetDiskUsage(InternalDiskPath),
			"usage_external": templateGetDiskUsage(ExternalDiskPath),
			"backups": templateGetBackups(BackupStoragePath),
			"snapshots": templateGetSnapshots(SnapshotStoragePath),
		})
	})
	r.POST("/reboot", handleCmd(cmdReboot))
	r.POST("/shutdown", handleCmd(cmdShutdown))
	r.POST("/clean", handleCmd(cmdClean))
	r.POST("/reset", handleCmd(cmdReset))
	r.Run(":80")
}

func templateGetUptime() string {
	var result syscall.Sysinfo_t
	if err := syscall.Sysinfo(&result); err != nil {
		return "—"
	} else {
		d := time.Duration(int64(result.Uptime) * int64(time.Second))
		return time.Now().Add(-d).Format("2 January 2006, 15:04")
	}
}

func templateGetDiskUsage(directory string) string {
	if usage, err := systemstatus.GetDiskUsage(directory); err != nil {
		return "—%"
	} else {
		return fmt.Sprintf("%d%%", int(math.Round(usage * 100)))
	}
}

func templateGetBackups(directory string) []*gin.H {
	r := make([]*gin.H, 0)
	dirs, _ := filepath.Glob(directory + "/*/*")
	for _, dir := range dirs {
		date, _ := esedb.GetLastBackupTimeFromFile(dir + "/Configuration/Catalog1.edb")
		r = append(r, &gin.H {
			"user": filepath.Base(filepath.Dir(dir)),
			"computer": filepath.Base(dir),
			"date": date.Format("02 January 2006, 15:04"),
		})
	}
	return r
}

func templateGetSnapshots(directory string) []*gin.H {
	return []*gin.H {
		&gin.H {
			"label": "Daily",
			"list": templateGetSnapshotsForCategory(directory, "daily"),
		},
		&gin.H {
			"label": "Weekly",
			"list": templateGetSnapshotsForCategory(directory, "weekly"),
		},
		&gin.H {
			"label": "Monthly",
			"list": templateGetSnapshotsForCategory(directory, "monthly"),
		},
		&gin.H {
			"label": "Yearly",
			"list": templateGetSnapshotsForCategory(directory, "yearly"),
		},
	}
}

func templateGetSnapshotsForCategory(directory, category string) []*gin.H {
	r := make([]*gin.H, 0)
	dirs, _ := filepath.Glob(directory + "/" + category + "/*")
	for _, dir := range dirs {
		r = append(r, &gin.H {
			"date": filepath.Base(dir),
		})
	}
	return r
}

func handleCmd(cmd func() error) func(c *gin.Context) {
	return func(c *gin.Context) {
		if err := cmd(); err != nil {
			c.JSON(500, gin.H { "error": err.Error() })
		} else {
			c.JSON(200, gin.H { "error": nil })
		}
	}
}

func cmdReboot() error {
	go func() {
		time.Sleep(time.Second)
		exec.Command("/bin/systemctl", "reboot").Run()
	}()
	return nil
}

func cmdShutdown() error {
	go func() {
		time.Sleep(time.Second)
		exec.Command("/bin/systemctl", "poweroff").Run()
	}()
	return nil
}

func cmdClean() error {
	dirs, _ := filepath.Glob(SnapshotStoragePath + "/*/*")
	for _, dir := range dirs {
		if err := os.RemoveAll(dir); err != nil {
			return err
		}
	}
	return nil
}

func cmdReset() error {
	disk := backup.NewDisk(ExternalDiskDevice, ExternalDiskDevicePartition, ExternalDiskPath)
	if err := disk.Format(); err != nil {
		return err
	} else if err := disk.Structure(); err != nil {
		return err
	} else {
		return nil
	}
}


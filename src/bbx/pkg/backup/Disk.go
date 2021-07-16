package backup

import (
	"log"
	"os"
	"time"
	"os/user"
	"os/exec"
	"strconv"
	syscall "golang.org/x/sys/unix"
/*
	diskfs "github.com/diskfs/go-diskfs"
	"github.com/diskfs/go-diskfs/partition/gpt"
*/
)

type Disk struct {
	diskDevice string // disk, e.g. "/dev/sda"
	partDevice string // partition, e.g. "/dev/sda1"
	mount string
}

func NewDisk(diskDevice, partDevice, mount string) *Disk {
	return &Disk { diskDevice, partDevice, mount }
}

func (this *Disk) Format() error {
	// First unmount
	log.Printf("Unmount %s", this.mount)
	if err := syscall.Unmount(this.mount, 0); err != nil {
		// Disk might not be mounted; silently fail
		//return err
		log.Printf("Unmounting %s failed (maybe not mounted?)", this.mount)
	} else {
		log.Printf("Unmounted %s", this.mount)
	}

/*
	// Open disk for manipulation
	log.Printf("Open disk %s for reading", this.diskDevice)
	if disk, err := diskfs.Open(this.diskDevice); err != nil {
		return err
	} else {
		// Define main partition
		partition := gpt.Partition {
			Start: 2048,
			End: uint64(disk.Size / disk.LogicalBlocksize - 2049),
			Type: gpt.LinuxFilesystem,
			Name: "bbx",
			GUID: "",
			Attributes: 0,
		}

		// Define partition taböe
		table := gpt.Table {
			LogicalSectorSize: int(disk.LogicalBlocksize),
			PhysicalSectorSize: int(disk.PhysicalBlocksize),
			GUID: "",
			ProtectiveMBR: true,
			Partitions: []*gpt.Partition { &partition },
		}

		// Write partition table
		log.Printf("Writing partition table to %s", this.diskDevice)
		if err := disk.Partition(&table); err != nil {
			return err
		} else if err := disk.ReReadPartitionTable(); err != nil {
			return err
		}
	}
	log.Printf("Wrote partition table to %s", this.diskDevice)
*/

	log.Printf("Writing partition table to %s", this.diskDevice)
	if err := exec.Command("parted", "-s", "-a", "optimal", "--", this.diskDevice, "mklabel", "gpt", "mkpart", "primary", "1MiB", "-2048s").Run(); err != nil {
		return err
	}

	// Sleep some time to let the kernel recognize the new disk
	time.Sleep(time.Second)

	// Write file system and re-mount partition
	log.Printf("Create file system on %s", this.partDevice)
	if err := exec.Command("mkfs.ext4", this.partDevice).Run(); err != nil {
		return err
	}

	// Sleep some time to let the kernel recognize the new partition
	time.Sleep(time.Second)


	// Remount partition
	log.Printf("Remount %s", this.partDevice)
	if err := syscall.Mount(this.partDevice, this.mount, "ext4", 0, ""); err != nil {
		return err
	}

	log.Printf("Done")
	return nil
}

func (this *Disk) Structure() error {
	if err := os.MkdirAll(this.mount + "/live", 02770); err != nil {
		return err
	} else if err := os.MkdirAll(this.mount + "/backup", 02770); err != nil {
		return err
	} else if err := os.Chmod(this.mount + "/live", 02770); err != nil { // in case directory exists already
		return err
	} else if err := os.Chmod(this.mount + "/backup", 02770); err != nil { // in case directory exists already
		return err
	} else if rootUser, err := user.Lookup("root"); err != nil {
		return err
	} else if rootGroup, err := user.LookupGroup("root"); err != nil {
		return err
	} else if backupGroup, err := user.LookupGroup("backupusers"); err != nil {
		return err
	} else if rootUid, err := strconv.Atoi(rootUser.Uid); err != nil {
		return err
	} else if rootGid, err := strconv.Atoi(rootGroup.Gid); err != nil {
		return err
	} else if backupGid, err := strconv.Atoi(backupGroup.Gid); err != nil {
		return err
	} else if err := os.Chown(this.mount + "/live", rootUid, backupGid); err != nil {
		return err
	} else if err := os.Chown(this.mount + "/backup", rootUid, rootGid); err != nil {
		return err
	} else {
		return nil
	}
}

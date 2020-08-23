package peripheral

import (
	"periph.io/x/periph/conn/i2c"
	"periph.io/x/periph/conn/i2c/i2creg"
	"periph.io/x/periph/devices/ssd1306"
	"periph.io/x/periph/devices/ssd1306/image1bit"
	"image"
	"golang.org/x/image/font"
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
)

type LcdScreen struct {
	bus i2c.BusCloser
	dev *ssd1306.Dev
	img *image1bit.VerticalLSB
}

func NewLcdScreen(busName string) (*LcdScreen, error) {
	opts := ssd1306.Opts {
		W: 128,
		H: 64,
		Rotated: true,
		Sequential: false,
		SwapTopBottom: false,
	}
	if bus, err := i2creg.Open(busName); err != nil {
		return nil, err
	} else if dev, err := ssd1306.NewI2C(bus, &opts); err != nil {
		return nil, err
	} else {
		s := LcdScreen { bus, dev, nil }
		s.reset()
		return &s, nil
	}
}

func (this *LcdScreen) reset() {
	this.img = image1bit.NewVerticalLSB(this.dev.Bounds())
}

func (this *LcdScreen) Render() error {
	return this.dev.Draw(this.dev.Bounds(), this.img, image.Point{})
}

func (this *LcdScreen) DrawText(text string, x, y int) error {
	f := basicfont.Face7x13
	drawer := font.Drawer {
		Dst: this.img,
		Src: &image.Uniform { image1bit.On },
		Face: f,
//		Dot: fixed.P(0, this.img.Bounds().Dy() - 1 - f.Descent),
		Dot: fixed.P(x, y + f.Metrics().Ascent.Round()),
	}
	drawer.DrawString(text)
	return nil
}

func (this *LcdScreen) Destroy() {
	this.reset()
	this.Render()
	this.bus.Close()
}

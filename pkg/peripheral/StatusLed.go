package peripheral

import (
	ws281x "github.com/rpi-ws281x/rpi-ws281x-go"
)

type StatusLed struct {
	dev *ws281x.WS2811
}

func NewStatusLed(pin int) (*StatusLed, error) {
	opt := ws281x.DefaultOptions
	opt.Channels[0].Brightness = 255
	opt.Channels[0].LedCount = 1

	if dev, err := ws281x.MakeWS2811(&opt); err != nil {
		return nil, err
	} else if err := dev.Init(); err != nil {
		return nil, err
	} else {
		return &StatusLed { dev }, nil
	}
}

func (this *StatusLed) SetColor(r, g, b uint8) error {
	this.dev.Leds(0)[0] = uint32(r) << 16 | uint32(g) << 8 | uint32(b)
	return nil
}

func (this *StatusLed) Render() error {
	return this.dev.Render()
}

func (this *StatusLed) Destroy() {
	this.SetColor(0, 0, 0)
	this.Render()
	this.dev.Fini()
}

# caplaythrough-swift

Swift version of the CAPlayThrough example provided by Apple. (https://developer.apple.com/library/mac/samplecode/CAPlayThrough/Introduction/Intro.html)

This fork modifies the app to instead be a menu bar application, intended to replace SoundFlowerBed (which stops working after a few hours on my machine). It will remember the devices you selected and start play-through when it launches if the input and output device are both found. This makes it possible to use Soundflower as your system output device and forward it to your real sound card, thereby giving you a working volume control (which is lacking on many audio recording cards such as mine).

The icon is made by [Noor Hakim](https://www.iconfinder.com/icons/3938493/adjust_audio_equalizer_media_video_icon).

## Description

Here is the description provided in the example by Apple.

The CAPlayThrough example project provides a Cocoa based sample application for obtaining all possible input and output devices on the system, setting the default device for input and/or output, and playing through audio from the input device to the output. The application uses two instances of the AUHAL audio unit (one for input, one for output) and a varispeed unit. the varispeed does two things:

(1) if there is a difference between the sample rates of the input and output device, the varispeed AU does a resample (this is a setting that is made and is constant through the lifetime of the I/O operation, presuming the devices involved don't change) 

(2) As the devices involved may NOT be synchronized, a further adjustment is made over time, by varying the rate of playback between the two devices. This rate adjustment is made by looking at the rate scalar in the time stamps of the two devices. The rate scalar describes the measured difference between the idealized sample rate of a given device (say 44.1KHz) and the measured sample rate of the device as it is running - which will also vary. This adjustment is made by tweaking the rate parameter of the varispeed.

The app also uses a ring buffer to store the captured audio data from input and access it as needed by the output unit.

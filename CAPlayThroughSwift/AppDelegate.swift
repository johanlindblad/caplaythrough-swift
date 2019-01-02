//
//  AppDelegate.swift
//  CAPlayThroughSwift
//
//  Created by Jasmin Lapalme on 15-12-29.
//  Copyright © 2016 jPense. All rights reserved.
//

import Cocoa
import CoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var inputDeviceController: NSArrayController!
	@IBOutlet weak var outputDeviceController: NSArrayController!
	@IBOutlet weak var stopStartButton: NSButton!
	@IBOutlet weak var progress: NSProgressIndicator!
	@IBOutlet weak var fftView: FFTView!;

	var inputDeviceList: AudioDeviceList;
	var outputDeviceList: AudioDeviceList;
	var inputDevice: AudioDeviceID = 0;
	var outputDevice: AudioDeviceID = 0;
	dynamic var selectedInputDevice: Device!;
	dynamic var selectedOutputDevice: Device!;
	var playThroughHost: CAPlayThroughHost!;
    let statusItem = NSStatusBar.system().statusItem(withLength:NSSquareStatusItemLength);
    var id_for = [String : AudioDeviceID]()
    var defaults = UserDefaults.standard

	override init() {
		self.inputDeviceList = AudioDeviceList(areInputs: true);
		self.outputDeviceList = AudioDeviceList(areInputs: false);
	}
	
	override func awakeFromNib() {
		var propsize = UInt32(MemoryLayout<AudioDeviceID>.size);
		
		var theAddress = AudioObjectPropertyAddress(
			mSelector: kAudioHardwarePropertyDefaultInputDevice,
			mScope: kAudioObjectPropertyScopeGlobal,
			mElement: kAudioObjectPropertyElementMaster
		);
		
		checkErr(AudioObjectGetPropertyData(
			AudioObjectID(kAudioObjectSystemObject),
			&theAddress,
			0,
			nil,
			&propsize,
			&inputDevice)
		);
		
		propsize = UInt32(MemoryLayout<AudioDeviceID>.size);
		theAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
		checkErr(AudioObjectGetPropertyData(
			AudioObjectID(kAudioObjectSystemObject),
			&theAddress,
			0,
			nil,
			&propsize,
			&outputDevice)
		);
		
		self.inputDeviceController.content = self.inputDeviceList.devices;
		self.outputDeviceController.content = self.outputDeviceList.devices;
        
        self.selectedInputDevice = self.inputDeviceList.devices.filter({ return $0.id == inputDevice }).first
        self.selectedOutputDevice = self.outputDeviceList.devices.filter({ return $0.id == outputDevice }).first
		
        let storedInput = UInt32(defaults.integer(forKey: "input_device")) as AudioDeviceID
        let storedOutput = UInt32(defaults.integer(forKey: "output_device")) as AudioDeviceID
        
        if storedInput > 0 {
            let matching = self.inputDeviceList.devices.filter({ return $0.id == inputDevice })
            if matching.count > 0 {
                inputDevice = storedInput
                selectedInputDevice = matching.first
            }
        }
        
        if storedOutput > 0 {
            let matching = self.outputDeviceList.devices.filter({ return $0.id == outputDevice })
            if matching.count > 0 {
                outputDevice = storedOutput
                selectedOutputDevice = matching.first
            }
        }
        
		playThroughHost = CAPlayThroughHost(input: inputDevice,output: outputDevice);
        
        let selectedBoth = inputDevice > 0 && outputDevice > 0;
        if selectedBoth {
            start();
        }
        
		self.fftView.playThroughHost = playThroughHost;
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("MenuIcon"))
        }
        
        refreshMenu()
	}

    func refreshMenu() {
        let menu = NSMenu()
        
        statusItem.menu = menu
        
        let selectedBoth = inputDevice > 0 && outputDevice > 0;
    
        if playThroughHost.isRunning() {
            let startPlaying = NSMenuItem(title: "Start loopback", action: nil, keyEquivalent: "")
            let stopPlaying = NSMenuItem(title: "Stop loopback", action: #selector(AppDelegate.stopClicked(_:)), keyEquivalent: "")
            menu.addItem(startPlaying)
            menu.addItem(stopPlaying)
        } else if selectedBoth {
            let startPlaying = NSMenuItem(title: "Start loopback", action: #selector(AppDelegate.startClicked(_:)), keyEquivalent: "")
            let stopPlaying = NSMenuItem(title: "Stop loopback", action: nil, keyEquivalent: "")
            menu.addItem(startPlaying)
            menu.addItem(stopPlaying)
        } else {
            let startPlaying = NSMenuItem(title: "Start loopback", action: nil, keyEquivalent: "")
            let stopPlaying = NSMenuItem(title: "Stop loopback", action: nil, keyEquivalent: "")
            menu.addItem(startPlaying)
            menu.addItem(stopPlaying)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        
        let inputHeader = NSMenuItem(title: "Input Device:", action: nil, keyEquivalent: "");
        inputHeader.isEnabled = false;
        menu.addItem(inputHeader)
        
        for device in self.inputDeviceList.devices {
            let name = device.name
            let id: AudioDeviceID = device.id
            id_for[name] = id
            
            let item = NSMenuItem(title: name, action: #selector(AppDelegate.selectInputDevice(_:)), keyEquivalent: "")
            menu.addItem(item)
            
            if id == inputDevice {
                item.state = NSControlStateValueOn;
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let outputHeader = NSMenuItem(title: "Output Device:", action: nil, keyEquivalent: "");
        outputHeader.isEnabled = false;
        menu.addItem(outputHeader)
        
        for device in self.outputDeviceList.devices {
            let name = device.name
            let id: AudioDeviceID = device.id
            id_for[name] = id
            
            let item = NSMenuItem(title: name, action: #selector(AppDelegate.selectOutputDevice(_:)), keyEquivalent: "")
            menu.addItem(item)
            
            if id == outputDevice {
                item.state = NSControlStateValueOn;
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
    func start() {
		if playThroughHost.isRunning() {
			return;
		}
		stopStartButton.title = "Stop";
		playThroughHost.start();
		progress.isHidden = false;
		progress.startAnimation(self);
	}
    
    func startClicked(_ sender: NSMenuItem) {
        start();
        refreshMenu();
    }
	
    func stopClicked(_ sender: NSMenuItem) {
        stop();
        refreshMenu();
    }
    
    func stop() {
		if !playThroughHost.isRunning() {
			return;
		}
		stopStartButton.title = "Start";
		playThroughHost.stop();
		progress.isHidden = true;
		progress.stopAnimation(self);
	}
	
	func resetPlayThrough() {
		if playThroughHost.playThroughExists() {
			playThroughHost.deletePlayThrough();
		}
		playThroughHost.createPlayThrough(inputDevice, outputDevice);
	}
	
	@IBAction func startStop(_ sender: NSButton) {
		if !playThroughHost.playThroughExists() {
			self.playThroughHost.createPlayThrough(inputDevice, outputDevice);
		}
		
		if !playThroughHost.isRunning() {
			start();
		} else {
			stop();
		}
	}
	
	@IBAction func inputDeviceSelected(_ sender: NSPopUpButton) {
		if (selectedInputDevice.id == inputDevice) {
			return;
		}
		
		stop();
		inputDevice = selectedInputDevice.id;
		resetPlayThrough();
	}
    
    func selectInputDevice(_ sender: NSMenuItem) {
        let id = id_for[sender.title]!;
        inputDevice = id;
        defaults.set(id, forKey: "input_device")

        if (selectedInputDevice.id == inputDevice) {
            return;
        }
        
        stop();
        resetPlayThrough();
        self.selectedInputDevice = self.inputDeviceList.devices.filter({ return $0.id == inputDevice }).first
        refreshMenu()
    }

    func selectOutputDevice(_ sender: NSMenuItem) {
        let id = id_for[sender.title]!;
        outputDevice = id;
        defaults.set(id, forKey: "output_device")
        
        if (selectedOutputDevice.id == outputDevice) {
            return;
        }
        
        stop();
        resetPlayThrough();
        self.selectedOutputDevice = self.outputDeviceList.devices.filter({ return $0.id == outputDevice }).first
        refreshMenu()
    }
	
	@IBAction func outputDeviceSelected(_ sender: NSPopUpButton) {
		if (selectedOutputDevice.id == outputDevice) {
			return;
		}
		
		stop();
		outputDevice = selectedOutputDevice.id;
		resetPlayThrough();
	}
}


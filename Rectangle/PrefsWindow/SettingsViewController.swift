//
//  SettingsViewController.swift
//  Rectangle
//
//  Created by Ryan Hanson on 8/24/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa
import ServiceManagement
import Sparkle

class SettingsViewController: NSViewController {
    
    static let allowAnyShortcutNotificationName = Notification.Name("allowAnyShortcutToggle")
    static let windowSnappingNotificationName = Notification.Name("windowSnappingToggle")
    static let changeDefaultsNotificationName = Notification.Name("changeDefaults")
    
    @IBOutlet weak var launchOnLoginCheckbox: NSButton!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var windowSnappingCheckbox: NSButton!
    @IBOutlet weak var hideMenuBarIconCheckbox: NSButton!
    @IBOutlet weak var subsequentExecutionCheckbox: NSButton!
    @IBOutlet weak var allowAnyShortcutCheckbox: NSButton!
    @IBOutlet weak var checkForUpdatesAutomaticallyCheckbox: NSButton!
    @IBOutlet weak var checkForUpdatesButton: NSButton!
    @IBOutlet weak var unsnapRestoreButton: NSButton!
    @IBOutlet weak var gapSlider: NSSlider!
    @IBOutlet weak var gapLabel: NSTextField!
    
    @IBAction func toggleLaunchOnLogin(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        let smLoginSuccess = SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, newSetting)
        if !smLoginSuccess {
            Logger.log("Unable to set launch at login preference. Attempting one more time.")
            SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, newSetting)
        }
        Defaults.launchOnLogin.enabled = newSetting
    }
    
    @IBAction func toggleWindowSnapping(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.windowSnapping.enabled = newSetting
        NotificationCenter.default.post(name: SettingsViewController.windowSnappingNotificationName, object: newSetting)
    }
    
    @IBAction func toggleHideMenuBarIcon(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.hideMenuBarIcon.enabled = newSetting
        RectangleStatusItem.instance.refreshVisibility()
    }
    
    @IBAction func toggleSubsequentExecutionBehavior(_ sender: NSButton) {
        Defaults.subsequentExecutionMode.value = sender.state == .on
            ? .acrossMonitor
            : .resize
    }
    
    @IBAction func gapSliderChanged(_ sender: NSSlider) {
        gapLabel.stringValue = "\(sender.intValue) px"
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp || event.type == .keyDown {
                if Float(sender.intValue) != Defaults.gapSize.value {
                    Defaults.gapSize.value = Float(sender.intValue)
                }
            }
        }
    }
    
    @IBAction func toggleUnsnapRestore(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.unsnapRestore.enabled = newSetting
    }
    
    @IBAction func toggleAllowAnyShortcut(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.allowAnyShortcut.enabled = newSetting
        NotificationCenter.default.post(name: SettingsViewController.allowAnyShortcutNotificationName, object: newSetting)
    }
    
    @IBAction func checkForUpdates(_ sender: Any) {
        SUUpdater.shared()?.checkForUpdates(sender)
    }
    
    @IBAction func restoreDefaults(_ sender: Any) {
        WindowAction.active.forEach { UserDefaults.standard.removeObject(forKey: $0.name) }
        let currentDefaults = Defaults.alternateDefaultShortcuts.enabled ? "Rectangle" : "Spectacle"
        let response = AlertUtil.twoButtonAlert(question: "Default Shortcuts", text: "You are currently using \(currentDefaults) defaults.\n\nSelect your defaults. ", confirmText: "Rectangle", cancelText: "Spectacle")
        let rectangleDefaults = response == .alertFirstButtonReturn
        if rectangleDefaults != Defaults.alternateDefaultShortcuts.enabled {
            Defaults.alternateDefaultShortcuts.enabled = rectangleDefaults
            NotificationCenter.default.post(name: Self.changeDefaultsNotificationName, object: nil)
        }
    }
    
    override func awakeFromNib() {
        if Defaults.launchOnLogin.enabled {
            launchOnLoginCheckbox.state = .on
        }
        
        if Defaults.hideMenuBarIcon.enabled {
            hideMenuBarIconCheckbox.state = .on
        }
        
        if Defaults.subsequentExecutionMode.value == .acrossMonitor {
            subsequentExecutionCheckbox.state = .on
        }
        
        if Defaults.allowAnyShortcut.enabled {
            allowAnyShortcutCheckbox.state = .on
        }
        
        if Defaults.windowSnapping.enabled == false {
            windowSnappingCheckbox.state = .off
        }
        
        if let updater = SUUpdater.shared() {
            checkForUpdatesAutomaticallyCheckbox.bind(.value, to: updater, withKeyPath: "automaticallyChecksForUpdates", options: nil)
        }
        
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String

        versionLabel.stringValue = "v" + appVersionString + " (" + buildString + ")"
        
        gapSlider.intValue = Int32(Defaults.gapSize.value)
        gapLabel.stringValue = "\(gapSlider.intValue) px"
        gapSlider.isContinuous = true
        
        if Defaults.unsnapRestore.userDisabled {
            unsnapRestoreButton.state = .off
        }
        
        checkForUpdatesButton.title = NSLocalizedString("HIK-3r-i7E.title", tableName: "Main", value: "Check for Updates…", comment: "")
    }

}

extension SettingsViewController {
    static func freshController() -> SettingsViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = "SettingsViewController"
        guard let viewController = storyboard.instantiateController(withIdentifier: identifier) as? SettingsViewController else {
            fatalError("Unable to find ViewController - Check Main.storyboard")
        }
        return viewController
    }
}

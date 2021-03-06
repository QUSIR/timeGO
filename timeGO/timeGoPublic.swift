//
//  public.swift
//  timeGO
//
//  Created by 5km on 2019/1/7.
//  Copyright © 2019 5km. All rights reserved.
//
import Cocoa

protocol StatusItemUpdateDelegate {
    func timerDidStart()
    func timerDidStop()
    func timerUpdate(percent: Double)
}

struct UserDataKeys {
    static let time = "timeDataKey"
    static let voice = "voiceNotificationEnable"
    static let again = "againKey"
    static let languages = "AppleLanguages"
    static let currentLanguage = "AppleCurrentLanguage"
    static let checkUpdate = "checkUpdate"
}

var timeArray = [[String: String]]()
var arrayChanged = false
var currentLanguage = "system"
var tagAppRelaunch = false

func getAppInfo() -> String {
    let infoDic = Bundle.main.infoDictionary
    let versionStr = infoDic?["CFBundleShortVersionString"] as! String
    return NSLocalizedString("app-name", comment: "") + " v" + versionStr
}

func getTimeArray() -> [Dictionary<String, String>] {
    var timeArray: [Dictionary<String, String>] = []
    if UserDefaults.standard.array(forKey: UserDataKeys.time) == nil {
        timeArray.append(["time": "25", "tip": NSLocalizedString("timer-default-tip-1", comment: "")])
        timeArray.append(["time": "5", "tip": NSLocalizedString("timer-default-tip-2", comment: "")])
        UserDefaults.standard.set(timeArray, forKey: UserDataKeys.time)
    } else {
        if UserDefaults.standard.array(forKey: UserDataKeys.time) is [Int] {
            let timeOldArray = UserDefaults.standard.array(forKey: UserDataKeys.time) as! [Int]
            UserDefaults.standard.removeObject(forKey: UserDataKeys.time)
            for time in timeOldArray {
                timeArray.append(["time": "\(time)", "tip": ""])
            }
            UserDefaults.standard.set(timeArray, forKey: UserDataKeys.time)
        } else {
            timeArray = UserDefaults.standard.array(forKey: UserDataKeys.time) as! [Dictionary<String, String>]
            
        }
    }
    return timeArray
}

func tipInfo(withTitle: String, withMessage: String) {
    let alert = NSAlert()
    alert.messageText = withTitle
    alert.informativeText = withMessage
    alert.addButton(withTitle: NSLocalizedString("tip-ok-button-title", comment: ""))
    alert.window.titlebarAppearsTransparent = true
    alert.runModal()
}

func tipInfo(withTitle title: String, withMessage message: String, oKButtonTitle: String, cancelButtonTitle: String, okHandler:(()-> Void)) {
    let alert = NSAlert()
    alert.alertStyle = NSAlert.Style.informational
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: oKButtonTitle)
    alert.addButton(withTitle: cancelButtonTitle)
    alert.window.titlebarAppearsTransparent = true
    if alert.runModal() == .alertFirstButtonReturn {
        okHandler()
    }
}

// 语音提醒
func getNotificationVoice(lang: String) -> String {
    let voiceDict = [
        "en": "Alex",
        "zh-Hans": "Ting-Ting",
        "zh-Hant": "Mei-Jia",
        "ja": "Kyoko",
        "ko": "Yuna"
    ]
    return voiceDict[currentLanguage]!
}

// NSTextField 支持快捷键
extension NSTextField {
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        switch event.charactersIgnoringModifiers {
        case "a":
            return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: self.window?.firstResponder, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: self.window?.firstResponder, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: self.window?.firstResponder, from: self)
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: self.window?.firstResponder, from: self)
        case "z":
            self.window?.firstResponder?.undoManager?.undo()
            return true
        case "Z":
            self.window?.firstResponder?.undoManager?.redo()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

// 扩展字符串的截取字符串方法
extension String {
    func prefix(upTo end: Int) -> String {
        if abs(end) > count {
            return self
        }
        return String(prefix(upTo: index(endIndex, offsetBy: end)))
    }
}

/**
 *  当调用onLanguage后替换掉mainBundle为当前语言的bundle
 */

class BundleEx: Bundle {
    
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = Bundle.getLanguageBundel() {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
    }
}

extension Bundle {
    
    private static var onLanguageDispatchOnce: ()->Void = {
        //替换Bundle.main为自定义的BundleEx
        object_setClass(Bundle.main, BundleEx.self)
    }
    
    func onLanguage(){
        Bundle.onLanguageDispatchOnce()
    }
    
    class func getLanguageBundel() -> Bundle? {
        let path = main.path(forResource: currentLanguage, ofType: "lproj")
        //        print("path = \(languageBundlePath)")
        guard path != nil else {
            return nil
        }
        let bundle = Bundle(path: path!)
        guard bundle != nil else {
            return nil
        }
        return bundle!
        
    }
}

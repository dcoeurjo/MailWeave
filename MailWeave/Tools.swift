//
//  Tools.swift
//  MailWeave
//
//  Created by Bertrand Kerautret on 04/09/2026.
//
import AppKit
import Carbon
func checkMailAutomationPermission(completion: @escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        let target = NSAppleEventDescriptor(
            bundleIdentifier: "com.apple.mail"
        )
        let status = AEDeterminePermissionToAutomateTarget(
            target.aeDesc,
            typeWildCard,
            typeWildCard,
            true
        )
        DispatchQueue.main.async {
            completion(status == noErr)
        }
    }
}




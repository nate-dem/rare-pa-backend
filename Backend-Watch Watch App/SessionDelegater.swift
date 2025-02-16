//
//  SessionDelegater.swift
//  Watch Backend
//
//  Created by nate demchak on 2/6/25.
//

import WatchConnectivity

class SessionDelegater: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated successfully")
    }
}

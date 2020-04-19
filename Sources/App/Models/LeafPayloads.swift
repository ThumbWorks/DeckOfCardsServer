//
//  LeafPayloads.swift
//  App
//
//  Created by Roderic Campbell on 4/15/20.
//

import Foundation
public struct LoggedInData: Encodable {
    let user: User
    let triggers: [Trigger]
    let newTrigger: Trigger?
    
    init(user: User, triggers: [Trigger], newTrigger: Trigger) {
        self.user = user
        self.triggers = triggers
        self.newTrigger = newTrigger
    }
    init(user: User, triggers: [Trigger]) {
        self.user = user
        self.triggers = triggers
        self.newTrigger = nil
    }
}

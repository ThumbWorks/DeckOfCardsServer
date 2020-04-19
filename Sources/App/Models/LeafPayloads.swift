//
//  LeafPayloads.swift
//  App
//
//  Created by Roderic Campbell on 4/15/20.
//

import Foundation
public struct LoggedInData: Encodable {
    let triggers: [Trigger]
    let newTrigger: Trigger?

    init(triggers: [Trigger], newTrigger: Trigger) {
        self.triggers = triggers
        self.newTrigger = newTrigger
    }
    init(triggers: [Trigger]) {
           self.triggers = triggers
           self.newTrigger = nil
       }
}

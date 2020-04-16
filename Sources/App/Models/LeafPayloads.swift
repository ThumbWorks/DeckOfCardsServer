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
    let teams: [String]

    init(triggers: [Trigger], newTrigger: Trigger, teams: [String]) {
        self.triggers = triggers
        self.newTrigger = newTrigger
        self.teams = teams
    }
    init(triggers: [Trigger], teams: [String]) {
           self.triggers = triggers
           self.newTrigger = nil
           self.teams = teams
       }
}

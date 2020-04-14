//
//  UserTriggerPivot.swift
//  App
//
//  Created by Roderic Campbell on 4/13/20.
//

import Foundation
import FluentPostgreSQL
import Fluent
import Vapor


final class UserTriggerPivot: PostgreSQLModel, Pivot {

    var id: Int?

    typealias Left = User
    typealias Right = Trigger

    static var leftIDKey: LeftIDKey = \.userID
    static var rightIDKey: RightIDKey = \.triggerID

    var userID: Int
    var triggerID: Int
}

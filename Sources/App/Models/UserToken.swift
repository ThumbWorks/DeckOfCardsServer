//
//  UserToken.swift
//  App
//
//  Created by Roderic Campbell on 4/10/20.
//

import FluentPostgreSQL
import Authentication

struct UserToken: PostgreSQLModel {
    var id: Int?
    var string: String
    var userID: User.ID

    var user: Parent<UserToken, User> {
        return parent(\.userID)
    }
}
extension UserToken: Token {
    /// See `Token`.
    typealias UserType = User

    /// See `Token`.
    static var tokenKey: WritableKeyPath<UserToken, String> {
        return \.string
    }

    /// See `Token`.
    static var userIDKey: WritableKeyPath<UserToken, User.ID> {
        return \.userID
    }
}

/// Allows `User` to be used as a dynamic migration.
extension UserToken: Migration { }

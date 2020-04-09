//
//  User.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Authentication
import FluentSQLite
import Vapor


/// A single entry of a User list.
final class User: SQLiteModel, Codable {
    /// The unique identifier for this `User`.
    var id: Int?

    var name: String
    var email: String
    var githubAccesToken: String?

    var tokens: Children<User, UserToken> {
           return children(\.userID)
       }

    /// Creates a new `User`.
    init(id: Int?, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

struct UserToken: SQLiteModel {
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

extension User: TokenAuthenticatable {
    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration { }

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

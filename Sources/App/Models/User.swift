//
//  User.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import FluentSQLite
import Vapor

/// A single entry of a User list.
final class User: SQLiteModel, Codable {
    /// The unique identifier for this `User`.
    var id: Int?

    var name: String
    var email: String
    var githubAccesToken: String?

    /// Creates a new `User`.
    init(id: Int?, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration { }

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

//
//  Trigger.swift
//  App
//
//  Created by Roderic Campbell on 4/13/20.
//

import Authentication
import FluentPostgreSQL
import Vapor


final class Trigger: PostgreSQLModel, Codable {
    var id: Int?
    let gitRepo: String
    let swaggerRepo: String

    init(gitRepo: String, swaggerRepo: String) {
        self.gitRepo = gitRepo
        self.swaggerRepo = swaggerRepo
    }

    init(payload: SubmitPayload) {
        self.gitRepo = "\(payload.githubTeam)/\(payload.swaggerSpecName)"
        self.swaggerRepo = payload.swaggerSpecName
    }
}

/// Allows `Trigger` to be used as a dynamic migration.
extension Trigger: Migration { }

/// Allows `Trigger` to be encoded to and decoded from HTTP messages.
extension Trigger: Content { }

/// Allows `Trigger` to be used as a dynamic parameter in route definitions.
extension Trigger: Parameter { }

/// Allows us to use sessions for web authentication
extension Trigger: SessionAuthenticatable { }

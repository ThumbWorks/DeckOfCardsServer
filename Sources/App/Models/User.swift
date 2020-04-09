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

    var name, location, blog, company, type, email, githubAccessToken, login, nodeID, gravatarID, gistsURLString, starredURLString, eventsURLString, followingURLString: String
    var avatarURL, receivedEventsURL, reposURL, url, htmlURL, subscriptionsURL, organizationsURL, followersURL: URL
    var siteAdmin, twoFactorAuthentication: Bool
    var bio: String?
    var hireable: String?
    var publicRepos, following, followers, publicGists, privateGists: Int
    var createdAt, updatedAt: Date
    var totalPrivateRepos, ownedPrivateRepos, diskUsage, collaborators: Int
    var plan: GithubPlan
    var tokens: Children<User, UserToken> {
           return children(\.userID)
       }

    init(userResponse: UserResponse, accessToken: String) {
        self.id = userResponse.id
        self.name = userResponse.name
        self.email = userResponse.email
        self.githubAccessToken = accessToken
        self.login = userResponse.login
        self.nodeID = userResponse.nodeID
        self.avatarURL = userResponse.avatarURL
        self.gravatarID = userResponse.gravatarID
        self.followersURL = userResponse.followersURL
        self.url = userResponse.url
        self.htmlURL = userResponse.htmlURL
        self.location = userResponse.location
        self.blog = userResponse.blog
        self.company = userResponse.company
        self.type = userResponse.type
        self.starredURLString = userResponse.starredURLString
        self.gistsURLString = userResponse.gistsURLString
        self.eventsURLString = userResponse.eventsURLString
        self.receivedEventsURL = userResponse.receivedEventsURL
        self.reposURL = userResponse.reposURL
        self.followingURLString = userResponse.followingURLString
        self.subscriptionsURL = userResponse.subscriptionsURL
        self.organizationsURL = userResponse.organizationsURL
        self.siteAdmin = userResponse.siteAdmin
        self.bio = userResponse.bio
        self.hireable = userResponse.hireable
        self.publicRepos = userResponse.publicRepos
        self.following = userResponse.following
        self.followers = userResponse.followers
        self.publicGists = userResponse.publicGists
        self.privateGists = userResponse.privateGists
        self.createdAt = userResponse.createdAt
        self.updatedAt = userResponse.updatedAt
        self.totalPrivateRepos = userResponse.totalPrivateRepos
        self.ownedPrivateRepos = userResponse.ownedPrivateRepos
        self.diskUsage = userResponse.diskUsage
        self.collaborators = userResponse.collaborators
        self.twoFactorAuthentication = userResponse.twoFactorAuthentication
        self.plan = userResponse.plan
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

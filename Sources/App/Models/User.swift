//
//  User.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Authentication
import FluentPostgreSQL
import Vapor


/// A single entry of a User list.
final class User: PostgreSQLModel, Codable {
    /// The unique identifier for this `User`.
    var githubAccessToken: String
    var id: Int?
    var name, location, blog, company, type, email, login, nodeID, gravatarID, gistsURLString, starredURLString, eventsURLString, followingURLString: String
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

    func updateUser(with userResponse: UserResponse, accessToken: String) {
        self.githubAccessToken = accessToken
        self.name = userResponse.name
        self.email = userResponse.email
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

    init(userResponse: UserResponse, accessToken: String) {
        self.githubAccessToken = accessToken
        self.name = userResponse.name
        self.email = userResponse.email
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

/// Allows us to use sessions for web authentication
extension User: SessionAuthenticatable { }

extension User {
    func fetchRepos(_ req: Request) throws -> Future<[RepoResponse]> {
           let user = try req.requireAuthenticated(User.self)
           let repoURL = user.reposURL
           let client = try req.client()
           // Create the request to fetch the user from github
           let responseFuture = client.get(repoURL) { serverRequest in
               if let token = try req.session()[.githubToken] {
                   serverRequest.http = buildGetRepoRequest(with: repoURL.absoluteString, accessToken: token)
               }
        }
        return responseFuture.flatMap { try $0.content.decode([RepoResponse].self).map { response  in
            return response
            }
        }
    }

    private func buildGetRepoRequest(with path: String, accessToken: String) -> HTTPRequest {
             var request =  HTTPRequest(method: .GET, url: path)
             request.headers.add(name: .authorization, value: "token \(accessToken)")

             request.headers.add(name: HTTPHeaderName.accept, value: "application/json")
             return request
         }
}

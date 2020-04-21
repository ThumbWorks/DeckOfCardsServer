//
//  GithubOAuthController.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Vapor
import FluentPostgreSQL
import Authentication

struct GithubCallbackRequest: Content {
    var code: String
}

struct GithubPlan: Content {
    let name: String
    let space: Int
    let collaborators: Int
    let privateRepos: Int
    enum CodingKeys: String, CodingKey {
        case name, space, collaborators
        case privateRepos = "private_repos"
    }
}

struct UserResponse: Content {
    let login, nodeID, gravatarID, followingURLString, gistsURLString,
    starredURLString, eventsURLString, type, name, company, blog, location, email: String

    let publicRepos, followers, following, publicGists, totalPrivateRepos,
    ownedPrivateRepos, collaborators, diskUsage, privateGists, id: Int

    let avatarURL, url, htmlURL, followersURL, reposURL,
    subscriptionsURL, organizationsURL, receivedEventsURL: URL

    let siteAdmin, twoFactorAuthentication: Bool

    let bio, hireable: String?

    let createdAt, updatedAt: Date

    let plan: GithubPlan

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case avatarURL = "avatar_url"
        case gravatarID = "gravatar_id"
        case htmlURL = "html_url"
        case followersURL = "followers_url"
        case followingURLString = "following_url"
        case gistsURLString = "gists_url"
        case starredURLString = "starred_url"
        case subscriptionsURL = "subscriptions_url"
        case organizationsURL = "organizations_url"
        case reposURL = "repos_url"
        case eventsURLString = "events_url"
        case receivedEventsURL = "received_events_url"
        case siteAdmin = "site_admin"
        case publicRepos = "public_repos"
        case publicGists = "public_gists"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case privateGists = "private_gists"
        case totalPrivateRepos = "total_private_repos"
        case ownedPrivateRepos = "owned_private_repos"
        case diskUsage = "disk_usage"
        case twoFactorAuthentication = "two_factor_authentication"
        case name, company, blog, location, url, id, login, type, hireable, bio, email, followers, following, collaborators, plan
    }
}

struct GithubAuthTokenResponse: Content {
    var accessToken: String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

final class GithubOAuthController {
    let clientID: String
    let clientSecret: String

    lazy var ENV: [String:String] = ["GH_BASIC_CLIENT_ID" : clientID,
                                     "GH_BASIC_SECRET_ID" : clientSecret]

    init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
    }
    
    func logout(_ req: Request) throws -> Future<View> {
        try req.unauthenticate(User.self)
        return try loginCheck(req)
    }

    func login(_ req: Request) throws -> Future<View> {
        return try req.view().render(.users, ENV)
    }

    func loginCheck(_ req: Request) throws -> Future<View> {
        guard let user = try req.authenticated() as User? else {
            return try login(req)
        }
        return Trigger.query(on: req).all().flatMap { allTriggers -> EventLoopFuture<View> in
            let payload = LoggedInData(user: user, triggers: allTriggers)
            return try req.view().render(.loggedInPath, payload)
        }
    }

    func callback(_ req: Request) throws -> Future<Response> {
        let code = try req.query.decode(GithubCallbackRequest.self).code
        User.authenticate(sessionID: code.hashValue, on: req).catch { error in
            print(error)
        }
        return try send(code, on: req)
    }

    private func send(_ code: String, on req: Request) throws -> Future<Response> {
        let client = try req.client()
        return client.get("https://.....") { serverRequest in
            serverRequest.http = buildCodeForAccessTokenExchangeRequest(with: code)
        }.flatMap { response in
            return try response.content.decode(GithubAuthTokenResponse.self).flatMap { try self.getGithubUser(with: $0.accessToken, on: req) }
        }
    }

    private func buildCodeForAccessTokenExchangeRequest(with code: String) -> HTTPRequest {
        let urlToPost = "https://\(String.githubHost)\(String.postPath)?code=\(code)"
        var request =  HTTPRequest(method: .POST, url: urlToPost)
        request.headers.basicAuthorization = BasicAuthorization(username: clientID, password: clientSecret)
        request.headers.add(name: HTTPHeaderName.accept, value: "application/json")
        return request
    }

    private func getGithubUser(with accessToken: String, on req: Request) throws -> EventLoopFuture<Response> {
        let client = try req.client()

        // Create the request to fetch the user from github
        let responseFuture = client.get("https://.....") { serverRequest in
            serverRequest.http = buildGetUserRequest(with: accessToken)
        }

        // With the response do this
        return responseFuture.flatMap { response  in
            do {
                let decodedResponse = try response.content.decode(UserResponse.self)
                return decodedResponse.flatMap { self.queryUser(userResponse: $0, accessToken: accessToken, on: req) }
            }
        }
    }

    private func queryUser(userResponse: UserResponse, accessToken: String, on req: Request) -> EventLoopFuture<Response> {
        return User.query(on: req).filter(\.login == userResponse.login).first().flatMap { user in
            let savableUser: User
            if let user = user {
                // If yes, update
                savableUser = user
                savableUser.updateUser(with: userResponse, accessToken: accessToken)
            } else {
                // If no, create
                savableUser = User(userResponse: userResponse, accessToken: accessToken)
            }

            let session = try req.session()
            session[.githubToken] = accessToken
            print("the session is \(session)")
            // try req.authenticate(savableUser)
            try req.authenticateSession(savableUser)
            return savableUser.save(on: req).flatMap { try self.queryToken(user: $0, accessToken: accessToken, on: req) }
        }
    }

    private func buildGetUserRequest(with accessToken: String) -> HTTPRequest {
        let urlToPost = "https://api.\(String.githubHost)\(String.getUserPath)"
        var request =  HTTPRequest(method: .GET, url: urlToPost)
        request.headers.add(name: .authorization, value: "token \(accessToken)")
        request.headers.add(name: HTTPHeaderName.accept, value: "application/json")
        return request
    }

    private func queryToken(user: User, accessToken: String, on req: Request) throws -> EventLoopFuture<Response> {
        return try UserToken.query(on: req).filter(\.userID == user.requireID()).first().flatMap { userToken in
            var newToken = try UserToken(string: accessToken, userID: user.requireID())
            newToken.bearerToken = accessToken
            return newToken.save(on: req).map { token -> Response in
                return req.redirect(to: "/")
            }
        }
    }
}


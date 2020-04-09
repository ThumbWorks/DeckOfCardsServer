//
//  GithubOAuthController.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Vapor

private let githubHost = "github.com"
private let postPath = "/login/oauth/access_token"
private let getUserPath = "/user"

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
    let login: String
    let id: Int
    let nodeID: String
    let avatarURL: URL
    let gravatarID: String
    let url: URL
    let htmlURL: URL
    let followersURL: URL
    let followingURLString: String
    let gistsURLString: String
    let starredURLString: String
    let subscriptionsURL: URL
    let organizationsURL: URL
    let reposURL: URL
    let eventsURLString: String
    let receivedEventsURL: URL
    let type: String
    let siteAdmin: Bool
    let name: String
    let company: String
    let blog: String
    let location: String
    let email: String
    let bio: String?
    let hireable: String?
    let publicRepos: Int
    let publicGists: Int
    let followers: Int
    let following: Int
    let createdAt: Date
    let updatedAt: Date
    let privateGists: Int
    let totalPrivateRepos: Int
    let ownedPrivateRepos: Int
    let diskUsage: Int
    let collaborators: Int
    let twoFactorAuthentication: Bool
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
    
    func callback(_ req: Request) throws -> Future<View> {
        let code = try req.query.decode(GithubCallbackRequest.self).code

        // Do a post to github with the code
        do {
            try send(code, on: req)
        } catch {
            print("an error occured here, may need to respond by rendering a 500 or something")
        }

        return try req.view().render("Callback", ENV)
    }
    func login(_ req: Request) throws -> Future<View> {
        return try req.view().render("Users", ENV)
    }

    private func buildCodeForAccessTokenExchangeRequest(with code: String) -> HTTPRequest {
        let urlToPost = "https://\(githubHost)\(postPath)?code=\(code)"
        var request =  HTTPRequest(method: .POST, url: urlToPost)
        request.headers.basicAuthorization = BasicAuthorization(username: clientID, password: clientSecret)
        request.headers.add(name: HTTPHeaderName.accept, value: "application/json")
        return request
    }

    private func send(_ code: String, on req: Request) throws {
        let client = try req.client()
        let responseFuture = client.get("https://.....") { serverRequest in
            serverRequest.http = buildCodeForAccessTokenExchangeRequest(with: code)
        }
        responseFuture.catch { error in
            print("we got an error \(error)")
        }
        _ = responseFuture.map { response -> (Void) in
            let status =  try response.content.decode(GithubAuthTokenResponse.self).map(to: HTTPStatus.self) { tokenResponse in
                try req.session()["accessToken"] = tokenResponse.accessToken
                let user = User(id: 1, name: "Rod with an Access Token", email: "access token email")
                user.githubAccesToken = tokenResponse.accessToken
                let _ = user.save(on: req).map { user  in
                    try req.authenticate(user)
                    try self.getUser(on: req)
                }

                return .ok
            }
            print(status)
        }
    }

    private func buildGetUserRequest(with accessToken: String) -> HTTPRequest {
        let urlToPost = "https://api.\(githubHost)\(getUserPath)"
        var request =  HTTPRequest(method: .GET, url: urlToPost)
        request.headers.add(name: .authorization, value: "token \(accessToken)")
        request.headers.add(name: HTTPHeaderName.accept, value: "application/json")
        return request
    }

    private func getUser(on req: Request) throws {
        let client = try req.client()
        guard let accessToken = try req.session()["accessToken"] else { return }
        let responseFuture = client.get("https://.....") { serverRequest in
            serverRequest.http = buildGetUserRequest(with: accessToken)
        }
        responseFuture.catch { error in
            print("we got an error \(error)")
        }
        _ = responseFuture.map { response -> (Void) in
            do {
                let _ =  try response.content.decode(UserResponse.self).map(to: Void.self) { userResponse in
                    print(userResponse)
                }.catch({ (error) in
                    print("error parsing \(error)")
                })
            }
        }
    }

}

//
//  GithubOAuthController.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Vapor



private let githubHost = "https://github.com"
private let postPath = "/login/oauth/access_token"
private let getUserPath = "/login/oauth/access_token"

struct GithubCallbackRequest: Content {
    var code: String
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
        let urlToPost = "\(githubHost)\(postPath)?code=\(code)"
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
                try self.getUser(on: req)
                return .ok
            }
            print(status)
        }
    }

    private func buildGetUserRequest(with accessToken: String) -> HTTPRequest {
        let urlToPost = "\(githubHost)\(getUserPath)"
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
            if let data = response.http.body.data {
                // TODO I need to parse this with an actual response object
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                // Oh wait we should be able to use encodables for this
                if let object = json as? [String: String] {
                    print(object)
                }
            }
        }
    }

}

//
//  GithubOAuthController.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Vapor



private let githubHost = "https://github.com"
private let postPath = "/login/oauth/access_token"

struct GithubCallbackRequest: Content {
    var code: String
}

struct GithubAuthTokenResponse: Content {
    var authToken: String
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
            try send(code: code, to: req.client())
        } catch {
            print("an error occured here, may need to respond by rendering a 500 or something")
        }

        return try req.view().render("Callback", ENV)
    }
    func login(_ req: Request) throws -> Future<View> {
        return try req.view().render("Users", ENV)
    }

    private func buildHTTPRequest(with code: String) -> HTTPRequest {
        let urlToPost = "\(githubHost)\(postPath)?code=\(code)"
        var request =  HTTPRequest(method: .POST, url: urlToPost)
        request.headers.basicAuthorization = BasicAuthorization(username: clientID, password: clientSecret)
        return request
    }

    private func send(code: String, to client: Client) {
        let responseFuture = client.get("https://.....") { serverRequest in
            serverRequest.http = buildHTTPRequest(with: code)
            serverRequest.http.headers.add(name: HTTPHeaderName.accept, value: "application/json")
        }
        responseFuture.catch { error in
            print("we got an error \(error)")
        }
        _ = responseFuture.map { response -> (Void) in
            do {
                if let data = response.http.body.data {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let object = json as? [String: String] {
                        print("object \(object["access_token"])")
                    }
                }
            } catch {
                print(error)
            }
        }
    }

}

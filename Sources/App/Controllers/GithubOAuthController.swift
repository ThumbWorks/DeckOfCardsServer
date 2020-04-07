//
//  GithubOAuthController.swift
//  App
//
//  Created by Roderic Campbell on 4/6/20.
//

import Vapor

let ENV: [String:String] = ["GH_BASIC_CLIENT_ID" : CLIENT_ID,
                            "GH_BASIC_SECRET_ID" : CLIENT_SECRET]
private let CLIENT_ID = "yyy"
private let CLIENT_SECRET = "xxx"
private let githubHost = "api.github.com"
private let postPath = "/login/oauth/access_token"

struct GithubCallbackRequest: Content {
    var code: String
}

struct GithubAuthTokenResponse: Content {
    var authToken: String
}

private func buildHTTPClient(incomingRequest: Request) throws -> EventLoopFuture<HTTPClient> {
    let client = HTTPClient.connect(scheme: .https,
                                    hostname: githubHost,
                                    on: incomingRequest) { error in
        print("We got an error in the connection \(error)")
    }
    return client
}

private func buildHTTPRequest(with code: String) -> HTTPRequest {
    var request =  HTTPRequest(method: .POST, url: postPath)
    request.headers.basicAuthorization = BasicAuthorization(username: CLIENT_ID, password: CLIENT_SECRET)
    request.headers.add(name: "code", value: code)
    return request
}

private func postCode(with incomingRequest: Request, httpClientFuture: EventLoopFuture<HTTPClient>, outgoingRequest: HTTPRequest) {
    // Connect a new client to the supplied hostname.
    // Send the HTTP request, fetching a response
    let promise = incomingRequest.eventLoop.newPromise(Void.self)
    /// Dispatch some work to happen on a background thread
    
    DispatchQueue.global().async {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        do {
            let httpRes = try httpClientFuture.wait().send(outgoingRequest)

            httpRes.do { (response) in
                guard let data = response.body.data else {
                    print("no body in response")
//                    promise.fail(error: Error(string: "Errordata"))
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let object = json as? [String: String] {
                        print("object \(object)")
                    }
                } catch {
                    print(error)
                    promise.fail(error: error)
                }
            }.catch { (error) in
                print("error parsing the response \(error)")
                promise.fail(error: error)
            }
            promise.succeed()
        } catch {
            print("failed a do at some point \(error)")
            promise.fail(error: error)
        }
    }
}

final class GithubOAuthController {
    func callback(_ req: Request) throws -> Future<View> {
        let code = try req.query.decode(GithubCallbackRequest.self).code

        // Do a post to github with the code
        do {
            let client = try buildHTTPClient(incomingRequest: req)
            let outgoingRequest = buildHTTPRequest(with: code)
            postCode(with: req, httpClientFuture: client, outgoingRequest: outgoingRequest)
        } catch {
            print("an error occured here, may need to respond by rendering a 500 or something")
        }

        return try req.view().render("Callback", ENV)
    }
    func login(_ req: Request) throws -> Future<View> {
        return try req.view().render("Users", ENV)
    }
}

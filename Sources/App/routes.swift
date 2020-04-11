import Authentication
import Vapor
import Foundation
import Leaf

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    let fetchController = GeneratedCodeFetchController()
    router.post("webook", use: fetchController.webhook)

    // Example of configuring a controller
    let userController = UserController()


    guard let clientID = Environment.get("github_app_client_id"),
        let clientSecret = Environment.get("github_app_client_secret") else { fatalError() }
    let githubOAuthController = GithubOAuthController(clientID: clientID, clientSecret: clientSecret)

    router.get("login", use: githubOAuthController.login)

    let session = User.authSessionsMiddleware()
    router.grouped(session).get("oauth/redirect", use: githubOAuthController.callback)
    router.grouped(session).get("/", use: githubOAuthController.loginCheck)
    router.grouped(session).get("users", use: userController.index)
    router.grouped(session).post("users", use: userController.create)
    router.grouped(session).delete("users", User.parameter, use: userController.delete)

}


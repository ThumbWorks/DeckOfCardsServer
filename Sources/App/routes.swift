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
    router.get("users", use: userController.index)
    router.post("users", use: userController.create)
    router.delete("users", User.parameter, use: userController.delete)


    guard let clientID = Environment.get("github_app_client_id"),
        let clientSecret = Environment.get("github_app_client_secret") else { fatalError() }
    let githubOAuthController = GithubOAuthController(clientID: clientID, clientSecret: clientSecret)
    router.get("login", use: githubOAuthController.login)
    router.get("oauth/redirect", use: githubOAuthController.callback)

    // Use user model to create an authentication middleware
    let token = User.tokenAuthMiddleware()

    // Create a route closure wrapped by this middleware
    router.grouped(token).get("hello", use: userController.hello)
}


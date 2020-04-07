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

    let githubOAuthController = GithubOAuthController()
    router.get("login", use: githubOAuthController.login)
    router.get("callback", use: githubOAuthController.callback)
}


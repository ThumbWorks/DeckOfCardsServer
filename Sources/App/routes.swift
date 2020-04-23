import Authentication
import Vapor
import Foundation
import Leaf

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // The webhook that controlls the fetch logic
    let fetchController = GeneratedCodeFetchController()
    router.post("webhook", use: fetchController.webhook)

    let triggerController = TriggerController()
    let userController = UserController()


    guard let clientID = Environment.get("github_app_client_id"),
        let clientSecret = Environment.get("github_app_client_secret") else { fatalError() }
    let githubOAuthController = GithubOAuthController(clientID: clientID, clientSecret: clientSecret)

    router.get("login", use: githubOAuthController.login)

    let session = User.authSessionsMiddleware()

    // Triggers
    let authenticatedTriggerGroup = router.grouped(session).grouped("trigger")
    // create trigger
    authenticatedTriggerGroup.post("create", use: triggerController.index)

    // delete trigger
    authenticatedTriggerGroup.post("delete", use: triggerController.delete)

    // list triggers
    authenticatedTriggerGroup.get("showAllTriggers/", use: triggerController.showAllTriggers)


    router.grouped(session).get("/", use: githubOAuthController.loginCheck)

    // the login redirect
    router.grouped(session).get("oauth/redirect", use: githubOAuthController.callback)

    let authenticatedUserGroup = router.grouped(session).grouped("users")
    router.grouped(session).get("/logout", use: githubOAuthController.logout)
    authenticatedUserGroup.get("/", use: userController.users)
    authenticatedUserGroup.post("/", use: userController.create)
    authenticatedUserGroup.delete("/", User.parameter, use: userController.delete)
    authenticatedUserGroup.get("/repos", use: userController.repos)
    authenticatedUserGroup.get("/orgs", use: userController.orgs)
    authenticatedUserGroup.get("/triggers", use: userController.triggers)
}


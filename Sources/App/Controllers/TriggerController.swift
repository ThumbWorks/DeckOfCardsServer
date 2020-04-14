//
//  TriggerController.swift
//  App
//
//  Created by Roderic Campbell on 4/13/20.
//

import Vapor

struct SubmitPayload: Content {
    var githubTeam: String
    var swaggerOwner: String
    var swaggerSpecName: String
    var version: String

}
struct DeletePayload: Content {
    var triggerID: Int
}


final class TriggerController {

    private static func allTriggerView(on req: Request) throws -> EventLoopFuture<View> {
        return Trigger.query(on: req).all().flatMap { allTriggers -> EventLoopFuture<View> in
            let payload = ["triggers" : allTriggers]
            return try req.view().render("loggedIn", payload)
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<Response> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(DeletePayload.self).flatMap { payload in
            return Trigger.find(payload.triggerID, on: req).flatMap { trigger in
                if let trigger = trigger {
                    return trigger.delete(on: req).map { _ in
                        return req.redirect(to: "/")
                    }
                } else {
                    return req.future(Response.self).map { _ in
                        return req.redirect(to: "/")
                    }
                }
            }
        }
    }

    func showAllTriggers(_ req: Request) throws -> EventLoopFuture<[Trigger]> {
        return Trigger.query(on: req).all()
    }

    func index(_ req: Request) throws -> EventLoopFuture<View> {
        return try req.content.decode(SubmitPayload.self).flatMap({ submitPayload in
            let repo = "\(submitPayload.githubTeam)/\(submitPayload.swaggerSpecName)"
            let newTrigger = Trigger(gitRepo: repo, swaggerRepo: submitPayload.swaggerSpecName)
            return newTrigger.save(on: req).flatMap { trigger in
                guard let _ = trigger.id else {
                    return try req.view().render("createFailed")
                }
                return Trigger.query(on: req).all().flatMap { allTriggers -> EventLoopFuture<View> in
                    let payload = ["new": [trigger], "triggers" : allTriggers]
                    return try req.view().render("loggedIn", payload)
                }
            }
        })
    }
}


//
//  TriggerController.swift
//  App
//
//  Created by Roderic Campbell on 4/13/20.
//

import Vapor
import Fluent
struct SubmitPayload: Content {
    var githubTeam: String
    var swaggerSpecName: String
}
struct DeletePayload: Content {
    var triggerID: Int
}


final class TriggerController {

    private static func allTriggerView(on req: Request) throws -> EventLoopFuture<View> {
        let user = try req.requireAuthenticated(User.self)
        return Trigger.query(on: req).all().flatMap { allTriggers -> EventLoopFuture<View> in
            let payload = LoggedInData(user: user, triggers: allTriggers)
            return try req.view().render(.loggedInPath, payload)
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let _ = try req.requireAuthenticated(User.self)

        return try req.content.decode(Array<Int>.self).flatMap { payload in
            return Trigger.query(on: req).filter(\Trigger.id ~~ payload).delete().transform(to: .ok)
        }
    }

    func showAllTriggers(_ req: Request) throws -> EventLoopFuture<[Trigger]> {
        return Trigger.query(on: req).all()
    }

    func index(_ req: Request) throws -> EventLoopFuture<View> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(SubmitPayload.self).flatMap({ submitPayload in
            let newTrigger = Trigger(payload: submitPayload)
            return newTrigger.save(on: req).flatMap { trigger in
                guard let _ = trigger.id else {
                    return try req.view().render(.createFailed)
                }
                return Trigger.query(on: req).all().flatMap { allTriggers -> EventLoopFuture<View> in
                    let payload = LoggedInData(user: user, triggers: allTriggers, newTrigger: trigger)
                    return try req.view().render(.loggedInPath, payload)
                }
            }
        })
    }
}


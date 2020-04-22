import Vapor

struct RepoResponse: Content {
    struct Permissions: Content {
        let admin: Bool
        let push: Bool
        let pull: Bool
    }
    let id: Int
    let nodeID, name, fullName: String
    let isPrivate: Bool
    let permissions: Permissions
    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case fullName = "full_name"
        case isPrivate = "private"
        case id, name, permissions
    }
}


/// Controls basic CRUD operations on `user`s.
final class UserController {
    /// Returns a list of all `user`s.
    func users(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }

    /// Saves a decoded `user` to the database.
    func create(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { user in
            return user.save(on: req)
        }
    }

    /// Deletes a parameterized `user`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).flatMap { user in
            return user.delete(on: req)
        }.transform(to: .ok)
    }

    func hello(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        print( "Hello, \(user.name).")
        return req.future(HTTPStatus.ok)
    }

    func repos(_ req: Request) throws -> Future<[RepoResponse]> {
        let user = try req.requireAuthenticated(User.self)
        return try user.fetchRepos(req)
    }

    func triggers(_ req: Request) throws -> Future<[Trigger]> {
        return Trigger.query(on: req).all()
    }

}

import Vapor

/// Controls basic CRUD operations on `user`s.
final class UserController {
    /// Returns a list of all `user`s.
    func index(_ req: Request) throws -> Future<[User]> {
        _ = User.query(on: req).all().map { users in
            if users.isEmpty { print("empty user list") }
            users.forEach { user in
                print("This is a user \(user)")
            }
        }
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
}

import Vapor

/// Controls basic CRUD operations on `user`s.
final class UserController {
    /// Returns a list of all `user`s.
    func index(_ req: Request) throws -> Future<View> {
        let rod =  User(id: 1, name: "Rod", email: "roderic@thumbworks.io")
        let bob = User(id: 2, name: "Bob", email: "bob@thumbworks.io")
        return try req.view().render("AllUsers", ["allUsers" : [rod, bob]])
//        return User.query(on: req).all()
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
}

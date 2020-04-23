import Vapor


struct Organization: Content {
    let login: String
    let id: Int
    let nodeID: String
    let url, reposURL, eventsURL, hooksURL, issuesURL, membersURL, publicMembersURL, avatarURL: String

    enum CodingKeys: String, CodingKey {
        case reposURL = "repos_url"
        case eventsURL = "events_url"
        case hooksURL = "hooks_url"
        case issuesURL = "issues_url"
        case membersURL = "members_url"
        case publicMembersURL = "public_members_url"
        case avatarURL = "avatar_url"
        
        case nodeID = "node_id"
        case login, id, url
    }
}
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

    func repos(_ req: Request) throws -> Future<[String]> {
        let user = try req.requireAuthenticated(User.self)
        return try user.fetchRepos(req)
    }

    func orgs(_ req: Request) throws -> Future<[String]> {
           let user = try req.requireAuthenticated(User.self)
           return try user.fetchOrgs(req)
       }

    func triggers(_ req: Request) throws -> Future<[Trigger]> {
        return Trigger.query(on: req).all()
    }

}

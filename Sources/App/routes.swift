import Vapor
import Foundation
import Leaf

// TODO we need to get a proper path in the form of something like /tmp/generatedCode/githubUser/reponame/language
private let pathToGeneratedCode = "/tmp/generatedCode"
private let generatorServiceHost = "generator3.swagger.io"

struct OAuthResponse: Content {
    var status: Bool
    var localizedString: String
}

struct GenerationResponse: Content {
    var status: Bool
    var localizedString: String
}

struct WebhookRequest: Content {
    var path: String
    var action: String
}

extension WebhookRequest {
    func owner() -> String {
        // Seems dangerous to return an indexed value
        return path.components(separatedBy: "/")[2]
    }
    func repo() -> String {
        // Seems dangerous to return an indexed value
        return path.components(separatedBy: "/")[3]
    }

    func version() -> String {
        // Seems dangerous to return an indexed value
        return path.components(separatedBy: "/")[4]
    }
}

enum GenerationError: Error {
    case failedToCreateDirectory
    case failedToGenerateClientCode
    case failedToMoveGeneratedCode
    case failedToUnzip
    case failedToRemoveArtifacts(String)

    var localizedDescription: String {
        switch self {

        case .failedToCreateDirectory:
            return "Failed to create temp directory"
        case .failedToGenerateClientCode:
            return "Failed to build client"
        case .failedToMoveGeneratedCode:
            return "Failed to move client code"
        case .failedToRemoveArtifacts(let file):
            return "Failed to remove code gen build artifacts. \(file)"
        case .failedToUnzip:
            return "Failed to unzip the payload"
        }
    }
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.post { req -> GenerationResponse in
        let content = parseRequestJson(rawRequestContent: req.content)

        // Step 1: Make the tmp directory and fail silently
        try? makeCodeDirectory()
        let specURLString = "https://api.swaggerhub.com/apis/\(content.owner())/\(content.repo())/\(content.version())/swagger.json"
        let client = try buildHTTPClient(incomingRequest: req)
        let requestData = try buildJSONPayload(specURLString: specURLString)
        let outgoingRequest = buildHTTPRequest(with: requestData)
        fetchGeneratedClient(with: req, httpClientFuture: client, outgoingRequest: outgoingRequest)
        return GenerationResponse(status: true, localizedString: "Successfully built client!")
    }


    // Example of configuring a controller
    let userController = UserController()
    router.get("users", use: userController.index)
    router.post("users", use: userController.create)
    router.delete("users", User.parameter, use: userController.delete)

    let githubOAuthController = GithubOAuthController()
    router.get("login", use: githubOAuthController.login)
    router.get("callback", use: githubOAuthController.callback)
}

/**
  Parse the request content

 {
 "path": "/apis/username/api-name/1.1",
 "action": "after_api_version_saved",
 "definition": {
 "swagger": "2.0",
 "info": {
 "description": "This is a sample Petstore server ...",
 "version": "1.1",
 "title": "Swagger Petstore"
 },
 "host": "petstore.swagger.io",
 ...
 **/
private func parseRequestJson(rawRequestContent: ContentContainer<Request>) -> WebhookRequest {
    var content: WebhookRequest = WebhookRequest(path: "", action: "")
    _ = try? rawRequestContent.decode(WebhookRequest.self).map(to: HTTPStatus.self) { webhookRequest in
        content = webhookRequest
        return .ok
    }
    return content
}
private func unzipPayload() throws {
    guard shell("unzip", "-o", "\(pathToGeneratedCode)/client.zip", "-d", "\(pathToGeneratedCode)/client/") == 0 else {
        throw GenerationError.failedToUnzip
    }
}
/// mv /tmp/generatedCode/SwaggerClient/Classes/Swaggers/* /tmp/generatedCode/
private func cleanupGeneratedCode() throws {
    // This is all very swift-client specific instructions
    guard shell("cp", "-r", "\(pathToGeneratedCode)/client/SwaggerClient/Classes/Swaggers/", "\(pathToGeneratedCode)/") == 0 else {
        throw GenerationError.failedToMoveGeneratedCode
    }
    guard shell("rm", "-r", "\(pathToGeneratedCode)/client/SwaggerClient/") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("Swagger Client directory")
    }
    guard shell("rm", "\(pathToGeneratedCode)/client/SwaggerClient.podspec") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("Pod spec file")
    }
    guard shell("rm", "\(pathToGeneratedCode)/client.zip") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("downloaded zip file")
    }
    guard shell("rm", "\(pathToGeneratedCode)/client/git_push.sh") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("git push shell script")
    }
    guard shell("rm", "\(pathToGeneratedCode)/client/Cartfile") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("Cart file")
    }

}

//swagger-codegen generate -i https://api.swaggerhub.com/apis/Thumbworks/DeckOfCards/1.0.0/swagger.json -l swift5 -o /tmp/generatedCode/
private func generateClient(url: String, language: String) throws {
    guard shell("swagger-codegen", "generate", "-i", url, "-l", language, "-o", pathToGeneratedCode) == 0 else {
        throw GenerationError.failedToGenerateClientCode
    }
}

private func makeCodeDirectory() throws {
    guard shell("mkdir", pathToGeneratedCode) == 1  else {
        throw GenerationError.failedToCreateDirectory
    }
}

private func buildJSONPayload(specURLString: String) throws -> Data {
    let bodyDict = [
           "specURL": specURLString,
           "lang" : "swift5",
           "type" : "CLIENT",
           "codegenVersion" : "V3"
       ]
    return try JSONSerialization.data(withJSONObject: bodyDict, options: .prettyPrinted)
}

private func buildHTTPRequest(with requestData: Data) -> HTTPRequest {
    var httpReq = HTTPRequest(method: .POST, url: "/api/generate")
    httpReq.contentType = MediaType.json
    httpReq.body = HTTPBody(data: requestData)
    return httpReq
}

private func buildHTTPClient(incomingRequest: Request) throws -> EventLoopFuture<HTTPClient> {
    return HTTPClient.connect(scheme: .https, hostname: generatorServiceHost, port: nil, connectTimeout: .minutes(1), on: incomingRequest) { error in
        print("We got an error in the connection \(error)")
    }
}

private func fetchGeneratedClient(with incomingRequest: Request, httpClientFuture: EventLoopFuture<HTTPClient>, outgoingRequest: HTTPRequest) {
    // Connect a new client to the supplied hostname.
    // Send the HTTP request, fetching a response
    let promise = incomingRequest.eventLoop.newPromise(Void.self)
    /// Dispatch some work to happen on a background thread
    DispatchQueue.global().async {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        do {
            let httpRes = try httpClientFuture.wait().send(outgoingRequest)
            httpRes.do { (response) in

                do {
                    // TODO we need to put this in a network request specific tmp folder
                    try response.body.data?.write(to: URL(fileURLWithPath: "\(pathToGeneratedCode)/client.zip"))
                    try unzipPayload()
                    // TODO Add the github integration here
                    try cleanupGeneratedCode()
                } catch GenerationError.failedToRemoveArtifacts(let string) {
                    _ = say(someWord: "Error cleaning up artifacts \(string)")
                    promise.fail(error: GenerationError.failedToRemoveArtifacts(string))
                }
                catch {
                    print("error writing file \(error)")
                    promise.fail(error: error)
                    return
                }
            }.catch { (error) in
                print("error parsing the response \(error)")
                promise.fail(error: error)
            }
        } catch {
            print("error with request \(error)")
            promise.fail(error: error)
        }
        /// When the "blocking work" has completed,
        /// complete the promise and its associated future.
        promise.succeed()
    }
}
/**
 Speak status of either an error or success state during local development
 */
private func say(someWord: String) -> Bool {
    return shell("say", someWord) == 1
}

private func shell(_ args: String...) -> Int32 {
    let task = Process()
    // print(task.currentDirectoryPath)
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    if let error = task.standardError {
        print(error)
    }
    task.waitUntilExit()
    return task.terminationStatus
}

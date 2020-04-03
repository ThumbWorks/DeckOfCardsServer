import Vapor
import Foundation

private let pathToGeneratedCode = "/tmp/generatedCode"

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
        }
    }
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.post { req -> GenerationResponse in

        let language = "swift5"

        let content = parseRequestJson(rawRequestContent: req.content)

        // Step 1: Make the tmp directory and fail silently

        try? makeCodeDirectory()
        do {
            try generateClient(owner: content.owner(), repo: content.repo(), version: content.version(), language: language)
            try cleanupGeneratedCode()
        } catch {
            _ = say(someWord: error.localizedDescription)
            return GenerationResponse(status: false, localizedString: error.localizedDescription)
        }
        _ = say(someWord: "Successfully built client!")

        return GenerationResponse(status: true, localizedString: "Successfully built client!")
    }


    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
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
/// mv /tmp/generatedCode/SwaggerClient/Classes/Swaggers/* /tmp/generatedCode/
private func cleanupGeneratedCode() throws {
    guard shell("cp", "-r", "\(pathToGeneratedCode)/SwaggerClient/Classes/Swaggers/", "\(pathToGeneratedCode)/") == 0 else {
        throw GenerationError.failedToMoveGeneratedCode
    }
    guard shell("rm", "-r", "\(pathToGeneratedCode)/SwaggerClient/") == 0 else {
//        guard shell("rm", "-r", "\(pathToGeneratedCode)/SwaggerClient/", "SwaggerClient.podspec", "git_push.sh", "Cartfile") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("Swagger Client directory")
    }
    guard shell("rm", "\(pathToGeneratedCode)/SwaggerClient.podspec") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("Pod spec file")
    }
    guard shell("rm", "\(pathToGeneratedCode)/git_push.sh") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("git push shell script")
    }

    guard shell("rm", "\(pathToGeneratedCode)/Cartfile") == 0 else {
        throw GenerationError.failedToRemoveArtifacts("Cart file")
    }

}

//swagger-codegen generate -i https://api.swaggerhub.com/apis/Thumbworks/DeckOfCards/1.0.0/swagger.json -l swift5 -o /tmp/generatedCode/
private func generateClient(owner: String, repo: String, version: String, language: String) throws {
    let url = "https://api.swaggerhub.com/apis/\(owner)/\(repo)/\(version)/swagger.json"
    guard shell("swagger-codegen", "generate", "-i", url, "-l", language, "-o", pathToGeneratedCode) == 0 else {
        throw GenerationError.failedToGenerateClientCode
    }
}

private func makeCodeDirectory() throws {
    guard shell("mkdir", pathToGeneratedCode) == 1  else {
        throw GenerationError.failedToCreateDirectory
    }
}

private func say(someWord: String) -> Bool {
    return shell("say", someWord) == 1
}

func shell(_ args: String...) -> Int32 {
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

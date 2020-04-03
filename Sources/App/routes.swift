import Vapor
import Foundation

private let pathToGeneratedCode = "/tmp/generatedCode"

enum GenerationError: Error {
    case failedToCreateDirectory
    case failedToGenerateClientCode
    case failedToMoveGeneratedCode
    case failedToRemoveArtifacts(String)
}
/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req -> String in
        do {
            try makeCodeDirectory()
        } catch {
            print("failed to create the directory, not a big deal")
        }
        let owner = "Thumbworks"
        let repo = "DeckOfCards"
        let version = "1.0.0"
        let language = "swift5"
        do {
            try generateClient(owner: owner, repo: repo, version: version, language: language)
            try cleanupGeneratedCode()
        } catch GenerationError.failedToGenerateClientCode {
            _ = say(someWord: "Failed to build client")
            return "Failed to build client"
        } catch GenerationError.failedToMoveGeneratedCode {
            _ = say(someWord: "Failed to move client code")
            return "Failed to move client code"
        } catch GenerationError.failedToRemoveArtifacts(let file) {
            _ = say(someWord: "Failed to remove code gen build artifacts. \(file)")
            return  "Failed to remove code gen build artifacts. \(file)"
        } catch {
            _ = say(someWord: "Unexpected Error")
            throw error
        }
        _ = say(someWord: "Successfully built client!")

        return "Successfully built client!"
    }


    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
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

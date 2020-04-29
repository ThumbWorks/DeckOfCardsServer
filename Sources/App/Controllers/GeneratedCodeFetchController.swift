//
//  GeneratedCodeFetchController.swift
//  App
//
//  Created by Roderic Campbell on 4/7/20.
//

import Vapor

struct GenerationResponse: Content {
    var localizedString: String
}

enum GenerationError: Error {
    case failedToGenerateURL
    case failedToCreateDirectory
    case failedToGenerateClientCode
    case failedToMoveGeneratedCode
    case failedToUnzip
    case failedToRemoveArtifacts(String)
    case failedToClone
    case failedToGitAdd
    case failedToGitCommit
    case failedToGitPush

    var localizedDescription: String {
        switch self {
        case .failedToClone:
            return "Failed to clone"
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
        case .failedToGenerateURL:
            return "Failed to generate URL from payload"
        case .failedToGitAdd:
            return "Failed to perform git add"
        case .failedToGitCommit:
            return "Failed to perform git commit"
        case .failedToGitPush:
            return "Failed to perform git push origin master"
        }
    }
}

struct WebhookRequest: Content {
    var path: String
    var action: String
}

extension WebhookRequest {
    func owner() throws -> String {
        return path.components(separatedBy: "/")[2]
    }
    func repo() throws -> String {
        // Seems dangerous to return an indexed value
        return path.components(separatedBy: "/")[3]
    }

    func version() throws -> String {
        // Seems dangerous to return an indexed value
        return path.components(separatedBy: "/")[4]
    }
}

final class GeneratedCodeFetchController {
    
    private func shell(_ args: String...) throws -> Int32 {
        print(args)
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        try task.run()
        if let error = task.standardError {
            print(error)
        }
        task.waitUntilExit()
        return task.terminationStatus
    }
    private func unzipPayload() throws {
        guard try shell("unzip", "-o", "\(String.pathToGeneratedCode)/client.zip", "-d", "\(String.pathToGeneratedCode)/client/") == 0 else {
            throw GenerationError.failedToUnzip
        }
    }
    /// mv /tmp/generatedCode/SwaggerClient/Classes/Swaggers/* /tmp/generatedCode/
    private func rearrangeSwaggerOutputToSwiftPackageFormat() throws {
        // This is all very swift-client specific instructions
        guard try shell(.copyCommand, .recursive, "\(String.pathToGeneratedCode)/client/SwaggerClient/Classes/Swaggers/", "\(String.pathToGeneratedCode)/Sources/DeckOfCards") == 0 else {
            throw GenerationError.failedToMoveGeneratedCode
        }
        guard try shell(.removeCommand, .recursive, "\(String.pathToGeneratedCode)/client/SwaggerClient/") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("Swagger Client directory")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client/SwaggerClient.podspec") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("Pod spec file")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client.zip") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("downloaded zip file")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client/git_push.sh") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("git push shell script")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client/Cartfile") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("Cart file")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client/.gitignore") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("gitignore")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client/.swagger-codegen-ignore") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("swagger-codegen-ignore")
        }
        guard try shell(.removeCommand, "\(String.pathToGeneratedCode)/client/.swagger-codegen/Version") == 0 else {
            throw GenerationError.failedToRemoveArtifacts(".swagger-codegen/Version")
        }
        guard try shell(.removeDirCommand, "\(String.pathToGeneratedCode)/client/.swagger-codegen/") == 0 else {
            throw GenerationError.failedToRemoveArtifacts(".swagger-codegen directory")
        }
        guard try shell(.removeDirCommand, "\(String.pathToGeneratedCode)/client/") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("Client dir")
        }
    }

    /// remove all artifacts from the generation and swift pacakge formatting.
    private func removeSwiftPackageFormattedCode() throws {
        // This is all very swift-client specific instructions

        guard try shell(.removeCommand, "-rf", "\(String.pathToGeneratedCode)") == 0 else {
            throw GenerationError.failedToRemoveArtifacts("Generated Code Dir")
        }
    }

    private func cloneRepo(repoURL: URL) throws {
        // TODO need to parameterize this
        guard try shell("git", "clone", repoURL.absoluteString, .pathToGeneratedCode) == 0 else {
            throw GenerationError.failedToClone
        }
    }

    private func fetchGeneratedClient(client: Client, requestData: Data) -> EventLoopFuture<Response>  {
        return client.post("https://\(String.generatorServiceHost)/api/generate") { serverRequest in
            serverRequest.http.contentType = MediaType.json
            serverRequest.http.body = HTTPBody(data: requestData)
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

    private func removeCodeDirectory() throws {
        guard try shell("rmdir", String.pathToGeneratedCode) == 0 else {
            throw GenerationError.failedToRemoveArtifacts("Stale Directory")
        }
    }

    private func makeCodeDirectory() throws {
        guard try shell("mkdir", String.pathToGeneratedCode) == 0  else {
            throw GenerationError.failedToCreateDirectory
        }
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

     Try this for testing: $ curl -i --request POST -H "Content-Type: application/json" localhost:8080/webhook -d '{"path":"/apis/Thumbworks/DeckOfCards/1.0.0","action":"after_api_version_saved"}'

     **/
    private func parseRequestJson(rawRequestContent: ContentContainer<Request>) throws -> EventLoopFuture<WebhookRequest> {
        return try rawRequestContent.decode(WebhookRequest.self)
    }

    func gitAddChanges() throws {
        guard try shell("git", "-C", String.pathToGeneratedCode, "add", ".") == 0 else {
            throw GenerationError.failedToGitAdd
        }
    }

    func gitCommitChanges() throws {
        guard try shell("git", "-C", String.pathToGeneratedCode, "commit", "-m", "Updated api") == 0 else {
            throw GenerationError.failedToGitCommit
        }
    }

    func gitPushChanges() throws {
        guard try shell("git", "-C", String.pathToGeneratedCode, "push",  "origin", "master") == 0 else {
            throw GenerationError.failedToGitPush
        }
    }

    func webhook(_ req: Request) throws -> EventLoopFuture<GenerationResponse> {
        return try req.content.decode(WebhookRequest.self).flatMap({ request -> EventLoopFuture<GenerationResponse> in
            print("request \(request)")
            // Step 1: Make the tmp directory and fail silently
            try? self.removeSwiftPackageFormattedCode()
            let username = "rodericj"
            let token = "checkDatabase"
            guard let url = URL(string: "https://\(username):\(token)@github.com/ThumbWorks/DeckOfCards.git") else {
                throw GenerationError.failedToGenerateURL
            }
            try self.cloneRepo(repoURL: url)

            let repo = try request.repo()
            let owner = try request.owner()
            let version = try request.version()
            let specURLString = "https://api.swaggerhub.com/apis/\(owner)/\(repo)/\(version)/swagger.json"
            let client = try req.client()
            let requestData = try self.buildJSONPayload(specURLString: specURLString)
            return self.fetchGeneratedClient(client: client, requestData: requestData)
                .map { response -> GenerationResponse in
                    try response.http.body.data?.write(to: URL(fileURLWithPath: "\(String.pathToGeneratedCode)/client.zip"))
                    try self.unzipPayload()
                    try self.rearrangeSwaggerOutputToSwiftPackageFormat()
                    try self.gitAddChanges()
                    try self.gitCommitChanges()
                    try self.gitPushChanges()
                    // TODO Add the github integration from the database here
                    // 1. Look up the user's configuration
                    return GenerationResponse(localizedString: "Successfully built client!")
            }
        })
    }
}

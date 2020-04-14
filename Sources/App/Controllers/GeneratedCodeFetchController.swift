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

// TODO we need to get a proper path in the form of something like /tmp/generatedCode/githubUser/reponame/language
private let pathToGeneratedCode = "/tmp/generatedCode"
private let generatorServiceHost = "generator3.swagger.io"


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

    private func fetchGeneratedClient(client: Client, requestData: Data) -> EventLoopFuture<GenerationResponse>  {
        let outgoingRequest = buildHTTPRequest(with: requestData)
        return client.post("https://\(generatorServiceHost)/api/generate") { serverRequest in
            serverRequest.http = outgoingRequest
        }.map { response -> GenerationResponse in
            try response.http.body.data?.write(to: URL(fileURLWithPath: "\(pathToGeneratedCode)/client.zip"))
            try self.unzipPayload()
            try self.cleanupGeneratedCode()
            // TODO Add the github integration here
            // 1. Look up the user's configuration
            return GenerationResponse(localizedString: "Successfully built client!")
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
    
    private func makeCodeDirectory() throws {
        guard shell("mkdir", pathToGeneratedCode) == 1  else {
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

    private func buildHTTPRequest(with requestData: Data) -> HTTPRequest {
        var httpReq = HTTPRequest(method: .POST, url: "https://\(generatorServiceHost)/api/generate")
        httpReq.contentType = MediaType.json
        httpReq.body = HTTPBody(data: requestData)
        return httpReq
    }

    func webhook(_ req: Request) throws -> EventLoopFuture<GenerationResponse> {
        return try req.content.decode(WebhookRequest.self).flatMap({ request -> EventLoopFuture<GenerationResponse> in
            // Step 1: Make the tmp directory and fail silently
            try? self.makeCodeDirectory()
            let repo = try request.repo()
            let owner = try request.owner()
            let version = try request.version()
            let specURLString = "https://api.swaggerhub.com/apis/\(owner)/\(repo)/\(version)/swagger.json"
            let client = try req.client()
            let requestData = try self.buildJSONPayload(specURLString: specURLString)
            return self.fetchGeneratedClient(client: client, requestData: requestData)
        })
    }
}

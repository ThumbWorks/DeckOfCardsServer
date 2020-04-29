//
//  Strings.swift
//  App
//
//  Created by Roderic Campbell on 4/15/20.
//

import Foundation
import Routing

extension String {
    // local key value lookup
    static let githubToken = "githubToken"

    // paths
    static let githubHost = "github.com"
    static let postPath = "/login/oauth/access_token"
    static let getUserPath = "/user"

    // code generation strings
    static let pathToGeneratedCode = "/tmp/generatedCode"
    static let pathToClonedCode = "/tmp/generatedCodeClone"
    static let generatorServiceHost = "generator3.swagger.io"

    static let removeDirCommand = "rmdir"
    static let removeCommand = "rm"
    static let copyCommand = "cp"
    static let recursive = "-r"


    // leaf payload keys
    static let triggersKey = "triggers"
    static let newKey = "new"

    // Leaf names
    static let loggedInPath = "LoggedIn"
    static let users = "Users"
    static let createFailed = "createFailed"

    // route names
}


<p align="center">
    <img src="https://user-images.githubusercontent.com/1342803/36623515-7293b4ec-18d3-11e8-85ab-4e2f8fb38fbd.png" width="320" alt="API Template">
    <br>
    <br>
    <a href="http://docs.vapor.codes/3.0/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor">
        <img src="https://img.shields.io/discord/431917998102675485.svg" alt="Team Chat">
    </a>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://circleci.com/gh/vapor/api-template">
        <img src="https://circleci.com/gh/vapor/api-template.svg?style=shield" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1">
    </a>
</p>


### What is this?

This is a service which attempts to do the following: 

1. Make a directory in /tmp
2. Generate a webservice client using a remote yaml file defining a [Deck of Cards webservice](https://deckofcardsapi.com)
3. Push the webservice client to a repo 
4. Expose the client via [Swift Package Manager](https://swift.org/package-manager/)

### Current status

1. The generation process works locally
2. When deployed to Heroku, there is no installed binary `swagger-codegen` so the system falls apart.

### TODO:
Figure out how to install the codegen, or fire up a [docker instance](https://github.com/swagger-api/swagger-codegen#docker)

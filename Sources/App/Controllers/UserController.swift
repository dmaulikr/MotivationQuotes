//
//  UserController.swift
//  MotivationQuotes
//
//  Created by Alif on 12/06/2017.
//
//

import Vapor
import HTTP
import AuthProvider
import JWT

import Vapor
import HTTP
import AuthProvider
import JWT

final class UserController {
    let droplet: Droplet
    
    init(_ droplet: Droplet) {
        self.droplet = droplet
    }
    
    func register(request: Request) throws -> ResponseRepresentable {
        // Get our credentials
        guard let email = request.data["email"]?.string, let password = request.data["password"]?.string, let passwordConfirmation = request.data["password_confirmation"]?.string else {
            return try Response(status: .badRequest, json: JSON(node: ["error": "Missing email or password"]))
        }
        
        if password != passwordConfirmation {
            return try Response(status: .badRequest, json: JSON(node: ["error": "Passwords do not match"]))
        }
        
        // Try to register the user
        let hashedPassword = try User.passwordHasher.make(password)
        let user = try User.register(email: email, password: hashedPassword)
        try request.auth.authenticate(User.authenticate(Password(username: email, password: password)))
        try user.save()
        
        guard let userId = user.id?.int else {
            return try Response(status: .badRequest, json: JSON(node: ["error": "Could not generate authentication token. Your account was created so please reauthenticate and try again."]))
        }
        
        return try JSON(node: [
            "access_token": try droplet.createJwtToken(String(userId)),
            "user": user
            ])
    }
    
    func login(request: Request) throws -> ResponseRepresentable {
        guard let email = request.data["email"]?.string, let password = request.data["password"]?.string else {
            return try Response(status: .badRequest, json: JSON(node: ["error": "Missing email or password"]))
        }
        let credentials = Password(username: email, password: password)
        let user = try User.authenticate(credentials)
        request.auth.authenticate(user)
        
        guard let userId = user.id?.int else {
            return try Response(status: .badRequest, json: JSON(node: ["error": "Could not find your account. Please try authenticating again."]))
        }
        
        return try JSON(node: [
            "access_token": try droplet.createJwtToken(String(userId)),
            "user": user
            ])
    }
    
    func logout(request: Request) throws -> ResponseRepresentable {
        // Clear the session
        try request.auth.unauthenticate()
        return try JSON(node: ["success": true])
    }
    
    func me(request: Request) throws -> ResponseRepresentable {
        return try request.user()
    }
    
}

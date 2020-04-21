//
//  SMTPManager.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor
import SwiftSMTP

struct SMTPManager {
    static var shared = SMTPManager()
    private init() {}
    
    func sendVerificationMail(_ req: Request, user: User) throws {
        let smtp = SMTP(hostname: "smtp.gmail.com", email: "example@gmail.com", password: "password")
        let from = Mail.User(name: "ChatApp", email: "example@gmail.com")
        let to = Mail.User(name: user.name, email: user.email)
        let content = mailContent(user: user)
        let htmlAttachment = Attachment(htmlContent: content)
        let mail = Mail(from: from, to: [to], subject: "Verification", attachments: [htmlAttachment])
        
        smtp.send(mail)
    }
    
    private func mailContent(user: User) -> String {
        guard let token = user.token else { return "" }
        return """
        <p>Verification link - <a href="http://localhost:8080/verify-email?token=\(token)">
        Click here</a> to verify your Email.</p>
        """
    }
}

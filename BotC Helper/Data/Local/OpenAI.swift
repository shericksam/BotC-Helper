//
//  OpenAI.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation
let openAIKey = "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" // TU API KEY AQUÍ

struct OpenAIMessage: Encodable {
    let role: String    // "user" o "assistant" o "system"
    let content: String
}

struct OpenAIRequest: Encodable {
    let model: String                  // "gpt-3.5-turbo"
    let messages: [OpenAIMessage]
    let max_tokens: Int
}

struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        let message: MessageContent
    }
    struct MessageContent: Decodable {
        let role: String
        let content: String
    }
    let choices: [Choice]
}

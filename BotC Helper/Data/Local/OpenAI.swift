//
//  OpenAI.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation

func getOpenAIKey() -> String {
    if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path),
       let apiKey = dict["OPENAI_API_KEY"] as? String {
        return apiKey
    }
    return ""
}

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

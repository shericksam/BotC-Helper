//
//  GPTAssistantView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI

struct GPTAssistantView: View {
    let board: BoardState

    @State private var chatHistory: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var sending = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(chatHistory) { msg in
                        HStack {
                            if msg.isUser {
                                Spacer()
                                if msg.text.count > 70 {
                                    ExpandableText(text: msg.text, lineLimit: 2)
                                        .frame(maxWidth: 320)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                } else {
                                    Text(msg.text)
                                        .font(.body.monospaced())
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                        .frame(maxWidth: 320)
                                }
                            } else {
                                Text(try! AttributedString(markdown: msg.text))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(Color.green.opacity(0.12))
                                    .cornerRadius(6)
                                    .frame(maxWidth: 320, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                        .id(msg.id)
                    }
                }
            }
            .padding(.horizontal)
            .onChange(of: chatHistory.count) { _ in
                // Haz scroll al fondo cuando aparecen nuevos mensajes
                if let lastId = chatHistory.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
            HStack {
                TextField("Pregúntale a ChatGPT...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button("Enviar") {
                    Task { await sendToGPT() }
                }
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || sending)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Actualizar info") {
                    Task { await sendGameContextToGPT() }
                }
            }
        }
        .onAppear {
            if chatHistory.isEmpty {
                chatHistory = loadChatHistory(for: board)
                // Si tampoco hay, puedes enviar el prompt inicial como antes
                if chatHistory.isEmpty {
                    Task { await sendGameContextToGPT() }
                }
            }
        }
        .onChange(of: chatHistory) { _, newValue in
            saveChatHistory(newValue, for: board)
        }
        .navigationTitle("Asistente AI")
    }

    func chatKey() -> String {
        // Usa un ID único por juego, si lo tienes
        "gptchat-\(board.suggestedName)"
    }
    func saveChatHistory(_ chat: [ChatMessage], for board: BoardState) {
        guard let data = try? JSONEncoder().encode(chat) else { return }
        UserDefaults.standard.set(data, forKey: chatKey())
    }

    func loadChatHistory(for board: BoardState) -> [ChatMessage] {
        guard let data = UserDefaults.standard.data(forKey: chatKey()),
              let history = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return history
    }

    // Enviar el resumen inicial de juego al modelo
    func sendGameContextToGPT() async {
        sending = true
        let resumen = makeInitialPrompt(board: board)
        chatHistory.append(.init(isUser: true, text: resumen))
        let gptReply = await sendToOpenAI(history: chatHistory, userPrompt: resumen) // tu función real
        chatHistory.append(.init(isUser: false, text: gptReply))
        sending = false
    }

    // Genera el prompt inicial/resumen del estado de juego
    func makeInitialPrompt(board: BoardState) -> String {
        let editionName = board.edition?.meta.name ?? "Desconocido"
        let players = board.players.map { p in
            let name = p.name.isEmpty ? "Jugador \(p.seatNumber)" : p.name
            let claim = board.edition?.characters.first(where: { $0.id == p.claimRoleId })?.name ?? ""
            let status = (board.days[board.currentDay][p.seatNumber-1].dead ? "muerto" : "vivo")

            let notas = p.personalNotes.count > 0 ? "Notas de \(name) por día: \(p.personalNotes.sorted(by: { $0.key < $1.key }).map {"Día \($0.key + 1): \($0.value)" }.joined(separator: "\n"))" : "No tiene notas"

            return "\(name) (\(status))" + (claim.isEmpty ? "" : " - CLAIM: \(claim)") + " \n notas: \(notas)"
        }
        let myPlayer = board.players.first(where: { $0.isMe })
        let myselfClaim = board.edition?.characters.first(where: { $0.id == myPlayer?.claimRoleId })?.name ?? ""
        let demonRoles = board.edition?.characters.filter { $0.team == .demon }.map(\.name) ?? []
        let minionRoles = board.edition?.characters.filter { $0.team == .minion }.map(\.name) ?? []
        let townsfolkRoles = board.edition?.characters.filter { $0.team == .townsfolk }.map(\.name) ?? []
        let outsiderRoles = board.edition?.characters.filter { $0.team == .outsider }.map(\.name) ?? []
        let travellerRoles = board.edition?.characters.filter { $0.team == .traveller }.map(\.name) ?? []

        let prompt = """
        Estado actual de la partida de Blood on the Clocktower, edición '\(editionName)', día \(board.currentDay + 1):
        
        Jugadores (\(players.count)):
        \(players.joined(separator: "\n"))
        
        Yo soy: \(myPlayer?.name ?? "") (\(myPlayer?.seatNumber ?? 0)). 
        Mi CLAIM: \(myselfClaim.isEmpty ? "Sin claim aún" : myselfClaim)
        
        Roles en juego: 
        Ciudadanos: \(townsfolkRoles.joined(separator: ", "))
        Forasteros: \(outsiderRoles.joined(separator: ", "))
        Esbirros: \(minionRoles.joined(separator: ", "))
        Demonio: \(demonRoles.joined(separator: ", "))
        Viajeros: \(travellerRoles.joined(separator: ", "))
        
        Notas personales propias: 
        \(myPlayer?.personalNotes.sorted(by: { $0.key < $1.key }).map {"Día \($0.key + 1): \($0.value)" }.joined(separator: "\n") ?? "Sin notas")
        
        
        Con esta información, dame tus tips o estrategias para mi equipo y mi rol en base a lo que observes.
        """
        return prompt
    }

    func sendToOpenAI(history: [ChatMessage], userPrompt: String) async -> String {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: endpoint) else { return "Error: URL no válida" }
        // 1. Prepara el historial como 'messages'
        // Puedes incluir mensajes anteriores si quieres que el modelo tenga contexto.
        var messages: [OpenAIMessage] = [OpenAIMessage(role: "system", content: "Eres un experto en Blood on the Clocktower. Da estrategias claras y consejos útiles. Explica tus razones. Responde en español.")]

        // Si quieres enviar historial previo:
        // Solo toma los últimos 6 mensajes (alternando user/assistant)
        let recentHistory = history.suffix(6)
        for msg in recentHistory {
            messages.append(OpenAIMessage(role: msg.isUser ? "user" : "assistant", content: msg.text))
        }
        // El último userPrompt es igual al último mensaje user del chat, pero inclúyelo si lo necesitas explícito.

        // 2. Crea la petición
        let request = OpenAIRequest(model: "gpt-3.5-turbo", messages: messages, max_tokens: 500)
        guard let jsonData = try? JSONEncoder().encode(request) else {
            return "Error preparando petición OpenAI"
        }

        // 3. Prepara el URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData

        // 4. Envía la petición
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Respuesta OpenAI:\n\(jsonString)")
            }

            let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            if let respuesta = decoded.choices.first?.message.content {
                return respuesta.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return "No se recibió respuesta de ChatGPT"
        } catch {
            print("OpenAI ERROR:", error)
            return "Error al conectar con OpenAI: \(error.localizedDescription)"
        }
    }

    func sendToGPT() async {
        sending = true
        let prompt = gptPrompt(for: board, userMessage: userInput)
        chatHistory.append(.init(isUser: true, text: userInput))
        let gptReply = await sendToOpenAI(history: chatHistory, userPrompt: prompt)
        chatHistory.append(.init(isUser: false, text: gptReply))
        sending = false
        userInput = ""
    }

    func gptPrompt(for board: BoardState, userMessage: String) -> String {
        // Contexto para el modelo. ¡Personaliza todo lo que quieras!
        let myPlayer = board.players.first(where: { $0.isMe })
        let myNotes: [String] = myPlayer?.personalNotes.values.compactMap { $0 }.filter { !$0.isEmpty } ?? []
        let claims: [String] = board.players.compactMap {
            guard let rid = $0.claimRoleId else { return nil }
            let claimName = board.edition?.characters.first(where: { $0.id == rid })?.name ?? $0.claimManual
            return "\($0.name) (\($0.seatNumber)): \(claimName)"
        }

        let team = detectTeam(me: myPlayer, edition: board.edition)
        let base = """
        Soy un jugador en Blood on the Clocktower, jugando la edición \(board.edition?.meta.name ?? "Desconocido") con \(board.players.count) jugadores.
        Mi asiento: \(myPlayer?.seatNumber ?? -1).
        Día actual: \(board.currentDay + 1).
        Los roles en juego son: \(board.edition?.characters.map(\.name).joined(separator: ", ") ?? "-").
        Mis notas:
        \(myNotes.joined(separator: "\n"))
        Claims de otros jugadores:
        \(claims.joined(separator: "\n"))
        Yo soy: \(myPlayer?.name ?? "-"). Equipo: \(team).
        """
        return base + "\nPregunta del usuario: \(userMessage)"
    }

    func systemPrompt(for board: BoardState) -> String {
        // ¡Personalízalo! Aquí le dices el espíritu del advice.
        let myPlayer = board.players.first(where: { $0.isMe })
        let team = detectTeam(me: myPlayer, edition: board.edition)
        switch team {
        case "demon", "minion":
            return "Ayúdame a inventar buenos bluffeos o despistar a los aldeanos para ganar si soy el demonio o minion."
        default:
            return "Ayúdame a identificar a los minions y demonio, y sugerir mejores estrategias ciudadanas para mi mesa."
        }
    }

    /** Detecta a qué tipo de jugador eres para el prompt */
    func detectTeam(me: Player?, edition: EditionData?) -> String {
        guard let id = me?.claimRoleId, let role = edition?.characters.first(where: { $0.id == id }) else { return "unknown" }
        return role.team?.rawValue ?? "unknown"
    }
}

#Preview {
    GPTAssistantView(board: .Mock.example)
}

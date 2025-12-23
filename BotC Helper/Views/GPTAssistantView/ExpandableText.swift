//
//  ExpandableText.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI
import MarkdownUI

struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(text)
                .lineLimit(expanded ? nil : lineLimit)
                .animation(.easeInOut(duration: 0.2), value: expanded)
            if text.count > 70 {
                Button(expanded ? MSG("see_less") : MSG("see_more")) {
                    expanded.toggle()
                }
                .font(.caption)
            }
        }
    }
}

#Preview {
    ExpandableText(text: "Como Empath, puedes hacer preguntas estratégicas a varios jugadores para obtener más información y avanzar en la partida. Aquí hay algunas sugerencias de preguntas que podrías hacer y a quién podrías dirigirlas:\n\n1. **A Pedro (Fortune Teller)**: Pregunta a Pedro si hay alguna información adicional que pueda compartir sobre sus visiones nocturnas y por qué está tan seguro de que el demonio está entre los jugadores 1 y 2.\n\n2. **A Jorge (Virgin)**: Pregunta a Jorge si ha sentido alguna vibra negativa de algún jugador en particular o si ha notado alguna discordancia en las interacciones del grupo.\n\n3. **A Jose (Washerwoman)**: Pregunta a Jose si ha visto algo sospechoso en sus investigaciones nocturnas que pueda ayudar a esclarecer la verdadera identidad de los jugadores.\n\n4. **A Jugador 1 y Jugador 2**: Pregunta a estos jugadores sobre su opinión acerca de la afirmación de Pedro y cómo se sienten al respecto. También puedes indagar sobre sus propias sospechas y teorías respecto a quién podría ser el demonio.\n\n5. **A Erick (Empath)**: Pregunta a otros jugadores si pueden corroborar tus visiones nocturnas y si notaron algo inusual en relación a tus claims como Empath.\n\nRecuerda que hacer las preguntas de manera estratégica y analizar detenidamente las respuestas te ayudará a obtener información valiosa para identificar al demonio y a sus esbirros. ¡Buena suerte en la partida!", lineLimit: 4)
}


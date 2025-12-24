//
//  AboutAppView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 24/12/25.
//

import SwiftUI

struct AboutAppView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Label(MSG("about_title"), systemImage: "wand.and.stars")
                        .font(.title).padding(.top, 12)

                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .scaledToFit()
                        VStack(alignment: .leading) {
                            Text(MSG("about_feature_games"))
                            Text(MSG("about_feature_games_es"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .scaledToFit()
                        VStack(alignment: .leading) {
                            Text(MSG("about_feature_notes"))
                            Text(MSG("about_feature_notes_es"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .scaledToFit()
                        VStack(alignment: .leading) {
                            Text(MSG("about_feature_ai"))
                            Text(MSG("about_feature_ai_es"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    Spacer()

                    VStack(spacing: 10) {
                        Text(MSG("about_support_headline"))
                            .font(.headline)
                        Button {
                            if let url = URL(string: "https://paypal.me/shericksam") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "cup.and.saucer.fill").foregroundColor(.brown)
                                Text(MSG("about_support_button"))
                                    .underline()
                            }
                            .padding(8)
                            .background(Color.yellow.opacity(0.22))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(MSG("about_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#Preview {
    AboutAppView()
}

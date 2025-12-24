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
                VStack(spacing: 24) {
                    Label {
                        Text(MSG("about_title"))
                            .bold()
                    } icon: {
                        ZStack {
                            Circle().fill(Color.accentColor.opacity(0.22))
                                .frame(width: 55, height: 55)
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.accentColor).font(.system(size: 28, weight: .medium))
                        }
                    }
                    .font(.system(size: 26, weight: .bold))
                    .padding(.top, 20)

                    GroupBox {
                        VStack(alignment: .leading, spacing: 24) {
                            aboutItem(
                                icon: "person.3.sequence.fill",
                                color: .indigo,
                                title: MSG("about_feature_games"),
                                subtitle: MSG("about_feature_games_es")
                            )
                            aboutItem(
                                icon: "list.bullet.rectangle",
                                color: .blue,
                                title: MSG("about_feature_notes"),
                                subtitle: MSG("about_feature_notes_es")
                            )
                            aboutItem(
                                icon: "arrow.left.arrow.right.circle",
                                color: .green,
                                title: MSG("about_feature_drag_swap")
                            )
                            aboutItem(
                                icon: "doc.text.magnifyingglass",
                                color: .purple,
                                title: MSG("about_feature_tap_edition")
                            )
                            aboutItem(
                                icon: "bolt.circle.fill",
                                color: .yellow,
                                title: MSG("about_feature_ai"),
                                subtitle: MSG("about_feature_ai_es")
                            )
                        }
                        .padding(.vertical, 12)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.systemBackground).opacity(0.93))
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                    )

                    GroupBox {
                        VStack(spacing: 14) {
                            Text(MSG("about_support_headline"))
                                .font(.headline)
                            Button {
                                if let url = URL(string: "https://paypal.me/shericksam") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .foregroundColor(.brown)
                                    Text(MSG("about_support_button"))
                                        .underline()
                                }
                                .font(.body.weight(.bold))
                                .padding(9)
                                .background(Color.yellow.opacity(0.15))
                                .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemBackground).opacity(0.91))
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 4)
                    )

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle(MSG("about_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    func aboutItem(icon: String, color: Color, title: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    AboutAppView()
}

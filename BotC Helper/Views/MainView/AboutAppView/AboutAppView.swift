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
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.92))
                                    .frame(width: 128, height: 128)
                                Image("main-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .shadow(radius: 6)
                            }
                            .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)

                            Text(MSG("about_title"))
                                .font(.system(size: 22, weight: .bold))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Features
                        featureGroup(title: MSG("about_section_gameplay"), items: [
                            (icon: "person.3.sequence.fill", color: Color.indigo,
                             title: MSG("about_feature_games"), sub: MSG("about_feature_games_es")),
                            (icon: "arrow.left.arrow.right.circle.fill", color: Color(red: 0.55, green: 0.2, blue: 0.1),
                             title: MSG("about_feature_freeform_drag"), sub: MSG("about_feature_freeform_drag_es")),
                            (icon: "tag.fill", color: Color.orange,
                             title: MSG("about_feature_reminders"), sub: MSG("about_feature_reminders_es")),
                        ])

                        featureGroup(title: MSG("about_section_tracking"), items: [
                            (icon: "list.bullet.rectangle.portrait.fill", color: Color.blue,
                             title: MSG("about_feature_notes"), sub: MSG("about_feature_notes_es")),
                            (icon: "figure.archery.circle.fill", color: Color.red,
                             title: MSG("about_feature_death_types"), sub: MSG("about_feature_death_types_es")),
                            (icon: "exclamationmark.triangle.fill", color: Color.yellow,
                             title: MSG("about_feature_jinxes"), sub: MSG("about_feature_jinxes_es")),
                        ])

                        featureGroup(title: MSG("about_section_scripts"), items: [
                            (icon: "doc.text.magnifyingglass", color: Color.purple,
                             title: MSG("about_feature_tap_edition"), sub: nil),
                            (icon: "arrow.down.doc.fill", color: Color.green,
                             title: MSG("about_feature_custom_script"), sub: MSG("about_feature_custom_script_es")),
                            (icon: "person.2.fill", color: Color(red: 0.35, green: 0.1, blue: 0.5),
                             title: MSG("about_feature_friends"), sub: MSG("about_feature_friends_es")),
                        ])

                        // Support
                        GroupBox {
                            VStack(spacing: 12) {
                                Text(MSG("about_support_headline"))
                                    .font(.subheadline.weight(.semibold))
                                    .multilineTextAlignment(.center)
                                Button {
                                    if let url = URL(string: "https://paypal.me/shericksam") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cup.and.saucer.fill").foregroundColor(.brown)
                                        Text(MSG("about_support_button")).underline()
                                    }
                                    .font(.body.weight(.bold))
                                    .padding(10)
                                    .background(Color.yellow.opacity(0.15))
                                    .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }

                        // Disclaimer
                        Text(MSG("app_disclaimer"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(MSG("about_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func featureGroup(title: String, items: [(icon: String, color: Color, title: String, sub: String?)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
                .padding(.bottom, 6)

            GroupBox {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        aboutItem(icon: item.icon, color: item.color, title: item.title, subtitle: item.sub)
                        if item.title != items.last?.title {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private func aboutItem(icon: String, color: Color, title: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .resizable().scaledToFit()
                    .foregroundColor(color)
                    .frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    AboutAppView()
}

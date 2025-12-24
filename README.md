# Blood on the Clocktower Helper

**Blood on the Clocktower Helper** is the ultimate app to simplify and enhance your Blood on the Clocktower (BotC) games.

- Create and manage new games visually, save seats and roles for each player.
- Track nominations, votes, deaths, and notes day by day.
- Multilingual support and roles/reminders fully localized to your device’s language (including per-role custom fields).
- Edition and Jinx analyzer, with automatic detection of special role combos.
- Review your game history, resume any session, and enjoy a modern, intuitive interface.

**Coming soon:**
- Integrated **AI tips (ChatGPT)**: get real-time bluff suggestions and deduction advice based on your role.
- Auto suggestions for the storyteller and players.
- And much more!

**Want to support this app?**  
[Buy me a coffee on PayPal](https://paypal.me/tuusuario)

---

# 🛠️ Technical & Structure

- **SwiftUI** + **SwiftData** as core technologies.
- Multi-language (localization in English and Spanish) using `.strings` keys and/or dictionaries in models.
- Support for both **official** and **custom editions**/scripts (add, edit, delete).
- **Role model** stores `name`, `ability`, `reminders`, etc. as `[String: String]` or `[String: [String]]` for true multi-language runtime.
- Storage of **Jinxes** as entities; each edition auto-detects applicable Jinxes at save-time.
- Dynamic, persistent tracking of:
    - Player seats and assignments
    - Day and night cycle; all PlayerStatus (votes, deaths, notes, claims) per player per day.
    - Drag & drop for rearranging players visually.
    - Manual or AI-assisted role claims.
- Integration-ready with [OpenAI ChatGPT API](https://platform.openai.com/) for analysis and gameplay suggestions.

---

# ⚙️ Main Dependencies

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) (`@MainActor`, `@Bindable`, navigation, etc)
- [SwiftData](https://developer.apple.com/documentation/swiftdata/) (`@Model`, relationships, queries, and persistent store)
- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) (for rich AI responses, optional)
- [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/bs4/doc/) (for HTML role extraction during setup)
- [Googletrans](https://py-googletrans.readthedocs.io/en/latest/) / [DeepL](https://www.deepl.com/) API (for role text translation scripts)
- [OpenAI API](https://platform.openai.com/docs/api-reference) (for GPT-based tips, planned/future)

---

# 💡 **How Localization Works in this Project**

- All user-facing text in the UI is passed through a `MSG()` helper and resolved via `.strings` (for UI),  
  or by runtime lookup using the correct key (for role name/ability stored as `[String: String]`).
- Default language is English (`"en"`), with fallback to any non-empty if missing.
- Roles, abilities, reminders and more adapt to the user's device language in real-time.

---

# 🌍 **Contact & Contributions**

For support, reporting bugs, or to contribute, please open an issue or email the developer.

---

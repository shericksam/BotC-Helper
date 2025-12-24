import json
import re
from pathlib import Path
from bs4 import BeautifulSoup
try:
    from deep_translator import GoogleTranslator
    translator_available = True
except Exception:
    GoogleTranslator = None
    translator_available = False

BASE = Path(__file__).resolve().parents[1]
roles_json_path = BASE / 'BotC Helper' / 'Resources' / 'all-roles-v1.json'
roles_html_path = BASE / 'BotC Helper' / 'Resources' / 'roles.html'
output_path = BASE / 'BotC Helper' / 'Resources' / 'roles-combined.json'

with open(roles_json_path, 'r', encoding='utf-8') as f:
    es_roles = json.load(f)

html = roles_html_path.read_text(encoding='utf-8')
soup = BeautifulSoup(html, 'html.parser')
if translator_available and GoogleTranslator is not None:
    class _Deep:
        def translate(self, text, src='es', dest='en'):
            try:
                # deep-translator expects language codes like 'es' and 'en'
                translated = GoogleTranslator(source=src, target=dest).translate(text)
                return type('T', (), {'text': translated})()
            except Exception:
                return type('T', (), {'text': text})()
    trans = _Deep()
else:
    class _Dummy:
        def translate(self, text, src='es', dest='en'):
            return type('T', (), {'text': text})()
    trans = _Dummy()

combined = []

for r in es_roles:
    rid = r.get('id')
    es_name = r.get('name', '')
    team = r.get('team', '')
    es_ability = r.get('ability', '')
    es_reminders = r.get('reminders', []) or []
    es_first = r.get('firstNightReminder', '') or ''
    es_other = r.get('otherNightReminder', '') or ''

    # Find the div with id in roles.html
    div = soup.find(id=rid)
    en_name = ''
    en_ability = ''
    if div:
        # get character-name if present
        name_h4 = div.find('h4', class_='character-name')
        if name_h4:
            a = name_h4.find('a')
            if a and a.text.strip():
                en_name = a.text.strip()
            else:
                en_name = name_h4.text.strip()
        # get character-summary
        summary = div.find('div', class_='character-summary')
        if summary:
            # normalize whitespace
            en_ability = re.sub(r'\s+', ' ', summary.get_text()).strip()

    # If en_name missing, translate from Spanish name
    if not en_name and es_name:
        try:
            en_name = trans.translate(es_name, src='es', dest='en').text
        except Exception:
            en_name = ''

    # If en_ability missing, translate from Spanish ability
    if not en_ability and es_ability:
        try:
            en_ability = trans.translate(es_ability, src='es', dest='en').text
        except Exception:
            en_ability = ''

    # Translate reminders and other texts
    en_reminders = []
    for rem in es_reminders:
        if rem:
            try:
                txt = trans.translate(rem, src='es', dest='en').text
            except Exception:
                txt = rem
            en_reminders.append(txt)

    def tr_or_empty(s):
        if not s:
            return ''
        try:
            return trans.translate(s, src='es', dest='en').text
        except Exception:
            return s

    en_first = tr_or_empty(es_first)
    en_other = tr_or_empty(es_other)

    combined.append({
        'id': rid,
        'name': {'es': es_name, 'en': en_name},
        'team': team,
        'ability': {'es': es_ability, 'en': en_ability},
        'reminders': {'es': es_reminders, 'en': en_reminders},
        'firstNightReminder': {'es': es_first, 'en': en_first},
        'otherNightReminder': {'es': es_other, 'en': en_other}
    })

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(combined, f, ensure_ascii=False, indent=2)

print(f'Wrote {len(combined)} roles to {output_path}')

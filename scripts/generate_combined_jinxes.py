import json
import re
from pathlib import Path
from bs4 import BeautifulSoup
from deep_translator import GoogleTranslator

BASE = Path(__file__).resolve().parents[1]
jinxes_json_path = BASE / 'BotC Helper' / 'Resources' / 'jinxes.json'
fables_html_path = BASE / 'BotC Helper' / 'Resources' / 'fables.html'
output_path = BASE / 'BotC Helper' / 'Resources' / 'jinxes-combined.json'

with open(jinxes_json_path, 'r', encoding='utf-8') as f:
    es_jinxes = json.load(f)

html = fables_html_path.read_text(encoding='utf-8')
soup = BeautifulSoup(html, 'html.parser')
translator = GoogleTranslator(source='es', target='en')

combined = []
missing_html = []

for j in es_jinxes:
    jid = j.get('id')
    roles = j.get('roles', [])
    es_text = j.get('description', '')

    # Find div with id in fables.html
    div = soup.find(id=jid)
    en_text = ''
    if div:
        summary = div.find(class_='jinx-text')
        if summary:
            en_text = re.sub(r'\s+', ' ', summary.get_text()).strip()

    # If no en_text found, translate the Spanish description
    if not en_text and es_text:
        try:
            en_text = translator.translate(es_text)
        except Exception:
            en_text = es_text

    if not div:
        missing_html.append(jid)

    combined.append({
        'id': jid,
        'roles': roles,
        'text': {'es': es_text, 'en': en_text}
    })

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(combined, f, ensure_ascii=False, indent=2)

print(f'Wrote {len(combined)} jinxes to {output_path}')
if missing_html:
    print('Missing HTML entries for:', ', '.join(missing_html))

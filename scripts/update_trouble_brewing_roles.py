import json
from pathlib import Path
from deep_translator import GoogleTranslator

BASE = Path(__file__).resolve().parents[1]
roles_combined_path = BASE / 'BotC Helper' / 'Resources' / 'roles-combined.json'
trouble_path = BASE / 'BotC Helper' / 'Resources' / 'trouble_brewing.json'
output_path = BASE / 'BotC Helper' / 'Resources' / 'trouble_brewing.updated.json'

with open(roles_combined_path, 'r', encoding='utf-8') as f:
    roles_combined = json.load(f)

roles_map = {r['id']: r for r in roles_combined}
translator = GoogleTranslator(source='es', target='en')

with open(trouble_path, 'r', encoding='utf-8') as f:
    tb = json.load(f)

out = []
missing = []
for entry in tb:
    eid = entry.get('id')
    # keep meta as-is
    if eid and eid.endswith('_meta'):
        out.append(entry)
        continue
    if not eid:
        out.append(entry)
        continue

    if eid in roles_map:
        base = roles_map[eid].copy()
        # Preserve scenario-specific fields
        for key in ['image', 'setup', 'special', 'remindersGlobal']:
            if key in entry:
                base[key] = entry[key]
        # If scenario provides reminders (list in Spanish), prefer them
        if 'reminders' in entry and isinstance(entry['reminders'], list):
            es_rem = entry['reminders']
            # translate to en if roles_map doesn't have en form for reminders
            en_rem = roles_map[eid].get('reminders', {}).get('en', [])
            if not en_rem:
                try:
                    en_rem = [translator.translate(r) for r in es_rem]
                except Exception:
                    en_rem = es_rem
            base['reminders'] = {'es': es_rem, 'en': en_rem}
        # Merge firstNightReminder and otherNightReminder from scenario if present
        for rn in ['firstNightReminder', 'otherNightReminder']:
            if rn in entry and entry[rn]:
                es_val = entry[rn]
                en_val = roles_map[eid].get(rn, {}).get('en', '')
                if not en_val:
                    try:
                        en_val = translator.translate(es_val)
                    except Exception:
                        en_val = es_val
                base[rn] = {'es': es_val, 'en': en_val}
            else:
                # ensure keys exist and are objects
                if rn in base and isinstance(base[rn], str):
                    # convert to object using present string as es and leave en empty
                    base[rn] = {'es': base[rn], 'en': ''}
                elif rn not in base:
                    base[rn] = {'es': '', 'en': ''}
        # Ensure ability is object
        if isinstance(base.get('ability', ''), str):
            txt = base['ability']
            base['ability'] = {'es': txt, 'en': roles_map[eid].get('ability', {}).get('en', '')}
        out.append(base)
    else:
        missing.append(eid)
        out.append(entry)

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

print(f'Wrote {len(out)} entries to {output_path}')
if missing:
    print('Missing roles not found in roles-combined:', missing)

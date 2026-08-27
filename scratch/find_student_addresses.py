import re, json

path = r'c:\Users\Usuário\Desktop\FICAI_4.0_PRONTO_FLUXO_CT\FICAI_4.0_PRONTO_FLUXO_CT\index.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find all occurrences of residencia or endereco in JS demo data
addresses = set()
for match in re.finditer(r'(residencia|endereco|rua|logradouro)[\"\']?\s*:\s*[\"\']([^\"\']+)[\"\']', content, re.IGNORECASE):
    val = match.group(2).strip()
    if len(val) > 5 and ('rua' in val.lower() or 'r.' in val.lower() or 'av' in val.lower() or 'estrada' in val.lower() or 'itaguaí' in val.lower()):
        addresses.add(val)

print(f"Total de {len(addresses)} endereços de alunos/fichas encontrados no código:")
for a in sorted(addresses):
    print(" -", a)

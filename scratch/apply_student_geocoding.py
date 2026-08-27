import json, re

path = r'c:\Users\Usuário\Desktop\FICAI_4.0_PRONTO_FLUXO_CT\FICAI_4.0_PRONTO_FLUXO_CT\index.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Streets dictionary to inject into index.html
streets_map = {
    "josé rodrigues": {"lat": -22.8710021, "lng": -43.7956648, "label": "Rua José Rodrigues da Silva, Vila Margarida"},
    "jose rodrigues": {"lat": -22.8710021, "lng": -43.7956648, "label": "Rua José Rodrigues da Silva, Vila Margarida"},
    "antonio fernando": {"lat": -22.8698, "lng": -43.7942, "label": "Rua Antonio Fernando dos Santos"},
    "joão da silva carvalho": {"lat": -22.8722, "lng": -43.7948, "label": "Rua João da Silva Carvalho"},
    "joao da silva carvalho": {"lat": -22.8722, "lng": -43.7948, "label": "Rua João da Silva Carvalho"},
    "bocaiúva": {"lat": -22.8655, "lng": -43.7782, "label": "Rua General Bocaiúva"},
    "bocaiuva": {"lat": -22.8655, "lng": -43.7782, "label": "Rua General Bocaiúva"},
    "amália louzada": {"lat": -22.8584, "lng": -43.7758, "label": "Rua Amália Louzada"},
    "amalia louzada": {"lat": -22.8584, "lng": -43.7758, "label": "Rua Amália Louzada"},
    "joão ramalho": {"lat": -22.8620, "lng": -43.7790, "label": "Rua João Ramalho"},
    "joao ramalho": {"lat": -22.8620, "lng": -43.7790, "label": "Rua João Ramalho"},
    "prefeito dudu": {"lat": -22.8610, "lng": -43.7710, "label": "Rua Prefeito Dudu"},
    "tocantins": {"lat": -22.8535216, "lng": -43.7678924, "label": "Rua Tocantins"},
    "manoel soares": {"lat": -22.8658521, "lng": -43.7883110, "label": "Rua Manoel Soares da Costa"},
    "reta de piranema": {"lat": -22.8550, "lng": -43.7650, "label": "Estrada Reta de Piranema"},
    "mazomba": {"lat": -22.8350, "lng": -43.7550, "label": "Estrada do Mazomba"},
    "guilherme serrano": {"lat": -22.8710, "lng": -43.7850, "label": "Rua Guilherme Serrano"},
    "ivete lino": {"lat": -22.8660, "lng": -43.7770, "label": "Rua Ivete Lino Ribeiro"},
    "josé bonifácio": {"lat": -22.8650, "lng": -43.7760, "label": "Rua José Bonifácio"},
    "jose bonifacio": {"lat": -22.8650, "lng": -43.7760, "label": "Rua José Bonifácio"},
    "júlio verne": {"lat": -22.8700, "lng": -43.7940, "label": "Rua Júlio Verne"},
    "julio verne": {"lat": -22.8700, "lng": -43.7940, "label": "Rua Júlio Verne"},
    "lucia tieme": {"lat": -22.8650, "lng": -43.7650, "label": "Rua Lucia Tieme Hara"},
    "machado de assis": {"lat": -22.8600, "lng": -43.7680, "label": "Rua Machado de Assis"},
    "pedro pacheco": {"lat": -22.8750, "lng": -43.7920, "label": "Rua Pedro Pacheco"},
    "mario covas": {"lat": -22.8760, "lng": -43.7950, "label": "Av. Gov. Mario Covas"},
    "mário covas": {"lat": -22.8760, "lng": -43.7950, "label": "Av. Gov. Mario Covas"}
}

js_streets = json.dumps(streets_map, ensure_ascii=False, indent=2)

# Check if EXACT_STREET_COORDINATES exists or inject it
if "const EXACT_STREET_COORDINATES =" not in content:
    content = content.replace("    let infoMapInstance = null;", f"    const EXACT_STREET_COORDINATES = {js_streets};\n\n    let infoMapInstance = null;")
    print("[OK] Injetado EXACT_STREET_COORDINATES no index.html!")
else:
    content = re.sub(r'const EXACT_STREET_COORDINATES = \{.*?\};', f'const EXACT_STREET_COORDINATES = {js_streets};', content, flags=re.DOTALL)
    print("[OK] Atualizado EXACT_STREET_COORDINATES no index.html!")

# Update geocodeAddress function to check EXACT_STREET_COORDINATES before random hash offset
old_geocode_regex = r'function geocodeAddress\(text, fallbackBase = \{ lng: -43\.7770, lat: -22\.8660 \} \) \{.*?\n    \}'

new_geocode_code = """function geocodeAddress(text, fallbackBase = { lng: -43.7770, lat: -22.8660 }) {
      if (!text) return { ...fallbackBase };
      const lower = text.toLowerCase();

      // 1. Verificação no mapa de coordenadas exatas de escolas
      if (typeof EXACT_SCHOOL_COORDINATES !== 'undefined') {
        for (const [sName, sCoords] of Object.entries(EXACT_SCHOOL_COORDINATES)) {
          if (sameText(lower, sName.toLowerCase()) || lower.includes(sName.toLowerCase())) {
            return { lng: sCoords.lng, lat: sCoords.lat };
          }
        }
      }

      // 2. Verificação no mapa de coordenadas exatas de ruas dos alunos
      if (typeof EXACT_STREET_COORDINATES !== 'undefined') {
        for (const [stKey, stData] of Object.entries(EXACT_STREET_COORDINATES)) {
          if (lower.includes(stKey)) {
            return { lng: stData.lng, lat: stData.lat };
          }
        }
      }

      // 3. Casos específicos de alta precisão
      if (lower.includes('josé rodrigues') || lower.includes('jose rodrigues')) {
        return { lng: -43.7956648, lat: -22.8710021 };
      }
      if (lower.includes('497') || lower.includes('tupinamba') || lower.includes('tupinambá')) {
        return { lng: -43.788311, lat: -22.8658521 };
      }

      // 4. Busca em regiões e bairros cadastrados
      for (const [key, coords] of Object.entries(REGION_GEO_LOCATIONS)) {
        if (lower.includes(key)) {
          return { lng: coords.lng, lat: coords.lat };
        }
      }

      // 5. Offset determinístico sutil (máx 150m) apenas se a rua for completamente desconhecida
      let hash = 0;
      for (let i = 0; i < text.length; i++) hash = ((hash << 5) - hash) + text.charCodeAt(i);
      const offsetLng = (((Math.abs(hash) % 20) + 1) / 10000) * (hash % 2 === 0 ? 1 : -1);
      const offsetLat = (((Math.abs(hash >> 2) % 20) + 1) / 10000) * (hash % 3 === 0 ? 1 : -1);
      return { lng: fallbackBase.lng + offsetLng, lat: fallbackBase.lat + offsetLat };
    }"""

# Replace geocodeAddress in content
pos_geo = content.find('function geocodeAddress(')
if pos_geo != -1:
    pos_end_geo = content.find('function getMapCoordinatesForFicai(', pos_geo)
    if pos_end_geo != -1:
        content = content[:pos_geo] + new_geocode_code + "\n\n    " + content[pos_end_geo:]
        print("[OK] geocodeAddress substituído com suporte a ruas exatas de alunos!")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("[OK] index.html atualizado e salvo com sucesso!")

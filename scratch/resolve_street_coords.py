import urllib.request, urllib.parse, json, time, re

addresses = [
    "R. José Rodrigues da Silva, Vila Margarida, Itaguaí",
    "Rua Antonio Fernando dos Santos, Itaguaí",
    "Rua João da Silva Carvalho, Itaguaí",
    "Rua General Bocaiúva, Centro, Itaguaí",
    "Rua Amália Louzada, Fazenda Caxias, Itaguaí",
    "Rua João Ramalho, São Salvador, Itaguaí",
    "Rua Prefeito Dudu, Monte Serrat, Itaguaí",
    "Rua Tocantins, Estrela do Céu, Itaguaí",
    "Rua Manoel Soares da Costa, Engenho, Itaguaí",
    "Rua Pastor Manuel Avelino de Souza, Fazenda Caxias, Itaguaí",
    "Estrada Reta de Piranema, Parque de Santana, Itaguaí",
    "Estrada do Mazomba, Itaguaí",
    "Rua Ary Parreira, Itaguaí",
    "Rua Elvira Ciuffo Cicarino, Vila Margarida, Itaguaí",
    "Rua Guilherme Serrano, Vila Geny, Itaguaí",
    "Rua Ivete Lino Ribeiro, Centro, Itaguaí",
    "Rua José Bonifácio, Centro, Itaguaí",
    "Rua João Rosa Gonzales, Engenho, Itaguaí",
    "Rua Júlio Verne, Vila Margarida, Itaguaí",
    "Rua Kaisser Abraão, Monte Serrat, Itaguaí",
    "Rua Lucia Tieme Hara, Santana, Itaguaí",
    "Rua Machado de Assis, Vila Ibirapitanga, Itaguaí",
    "Rua Odilon Penolon Fialho, Vila Geny, Itaguaí",
    "Rua Pedro Pacheco, Brisamar, Itaguaí",
    "Rua Professor Chico, Santana, Itaguaí",
    "Av. Gov. Mario Covas, Brisamar, Itaguaí",
    "Av. Guilherme Serrano, Vila Geny, Itaguaí",
    "Av. Tabajara, Ibirapitanga, Itaguaí"
]

print(f"Resolvendo {len(addresses)} ruas em Itaguaí via Nominatim...")

resolved_streets = {}

# Explicit known exact coordinates:
resolved_streets["josé rodrigues"] = {"lat": -22.8710021, "lng": -43.7956648, "label": "Rua José Rodrigues da Silva, Vila Margarida"}
resolved_streets["jose rodrigues"] = {"lat": -22.8710021, "lng": -43.7956648, "label": "Rua José Rodrigues da Silva, Vila Margarida"}

for addr in addresses:
    clean_street = addr.split(',')[0].strip()
    key_name = clean_street.lower().replace('rua ', '').replace('r. ', '').replace('av. ', '').replace('estrada ', '').replace('estr. ', '').strip()
    if key_name in resolved_streets:
        continue

    url = f"https://nominatim.openstreetmap.org/search?q={urllib.parse.quote(addr + ', Rio de Janeiro, Brasil')}&format=json&limit=1"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'FICAI-StreetGeocoder/1.0'})
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            if data and len(data) > 0:
                lat = float(data[0]['lat'])
                lng = float(data[0]['lon'])
                resolved_streets[key_name] = {"lat": round(lat, 6), "lng": round(lng, 6), "label": clean_street}
                print(f"[OK] {clean_street} -> lat={lat:.6f}, lng={lng:.6f}")
            else:
                print(f"[SKIP] Não encontrou: {clean_street}")
    except Exception as e:
        print(f"[ERRO] {clean_street}: {e}")
    time.sleep(0.4)

out_file = r'c:\Users\Usuário\Desktop\FICAI_4.0_PRONTO_FLUXO_CT\FICAI_4.0_PRONTO_FLUXO_CT\scratch\street_coords.json'
with open(out_file, 'w', encoding='utf-8') as out:
    json.dump(resolved_streets, out, ensure_ascii=False, indent=2)

print(f"\nSalvo {len(resolved_streets)} ruas no arquivo scratch/street_coords.json!")

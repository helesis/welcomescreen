# Voyage Sorgun — Hotel TV Welcome Screen

## Proje genel bakış

1920×1080 otel TV karşılama ekranı. Kiosk Chrome ile çalışır. Veriler PocketBase üzerinden yönetilir; admin panelinden yapılan değişiklikler TV tarafında realtime ile güncellenir.

---

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `index.html` | TV ekranı (GitHub Pages vb.) |
| `version.json` | Deploy sonrası ekranların yenilenmesi için sürüm (`v` değişince otomatik reload) |
| `voyage_admin.html` | İçerik yönetim paneli |
| `scripts/pb_app_config_tv_fields.sh` | PocketBase `app_config` içine TV harita/program alanlarını terminalden ekler (`curl`, `jq` gerekir) |

### PocketBase: TV alanlarını script ile eklemek

```bash
export PB_URL="https://senin-pb-adresin.com"   # isteğe bağlı; yoksa README’deki varsayılan
./scripts/pb_app_config_tv_fields.sh
```

Admin e-posta/şifre sorulur. Alanlar zaten varsa script çıkar, tekrar eklemez.

### GitHub Pages — TV otomatik güncelleme

`index.html` yaklaşık **90 saniyede bir** `version.json` dosyasını çeker. **`v` alanını** her deploy’da artır (örn. `"2"`, `"2025-03-19"`); açık olan TV tarayıcıları yeni sürümü görünce **sayfayı yeniler**. Sadece `index.html` değiştiyse bile `version.json`’u güncelle.

---

## Mimari

```
PocketBase (kendi kurduğunuz sunucu)
├── app_config      → 14 günlük döngü başlangıç tarihi (tek kayıt)
├── venues          → harita birimleri (tanımlayıcı + ad + koordinat)
├── activities      → cycle_day (0–13), mekan eşlemesi
├── announcements   → duyuru metni, gösterim süresi (sn), zaman pencereleri, aktif/pasif
└── restaurants     → haftalık saatler, mekan / koordinat
        │
        ├── voyage_welcome_screen.html  (okur, Realtime)
        └── voyage_admin.html           (yazar)
```

HTML dosyalarındaki PocketBase adresi, kendi örneğinizin URL’si ile değiştirilmelidir.

---

## PocketBase şeması

### `app_config` (tek kayıt önerilir)

| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| `cycle_anchor` | text | ✓ | Gün 0 tarihi `YYYY-MM-DD` (İstanbul). Bu tarihten itibaren 0→13 döngü. |
| `map_schedule_map_sec` | number | | Harita görünüm süresi (sn), varsayılan 30 |
| `map_schedule_schedule_sec` | number | | 4 bölmeli program görünümü süresi (sn), varsayılan 30 |
| `schedule_daytime_activity_ids` | json | | `activities` kayıt id’leri — gündüz kutusu |
| `schedule_kids_activity_ids` | json | | Çocuk aktiviteleri kutusu |
| `schedule_resto_use_all` | bool | | `true`: bugün açık tüm restoranlar; `false`: yalnızca `schedule_resto_ids` |
| `schedule_resto_ids` | json | | Seçili restoran id’leri (`schedule_resto_use_all` false iken) |
| `schedule_evening_kids_show` | text | | Bu akşam — çocuk gösterisi |
| `schedule_evening_main_show` | text | | Akşam gösterisi |
| `schedule_evening_after_show` | text | | After show |

TV’de harita ile program görünümü **dönüşümlü** gösterilir; içerik **Admin → TV Harita / Program** sekmesinden yönetilir.

### `venues`

| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| Benzersiz metin alanı (slug) | text | ✓ | Küçük harf, alt çizgi; aktivite/restoran kayıtlarındaki mekan alanı bununla eşleşir |
| `name` | text | ✓ | Görünen ad |
| `lat` / `lng` | number | ✓ | Harita koordinatları |

### `activities`

| Alan | Tip | Not |
|------|-----|-----|
| `hour`, `minute` | number | Başlangıç saati (**`min` değil, `minute`** — PocketBase uyumu) |
| `name`, `venue`, `icon` | text | Ad, mekan metni, emoji |
| `cycle_day` | number | 0–13; boş = her gün |
| Mekan eşlemesi | text | Doluysa koordinat `venues` tablosundan |

### `announcements`

| Alan | Tip | Not |
|------|-----|-----|
| `text` | text | Duyuru metni |
| `duration_sec` | number | TV’de bu duyurunun kaç saniye gösterileceği (3–600); yoksa 10 sn |
| `windows` | json | Zaman pencereleri; boş = her zaman. Örn. gün listesi + açılış/kapanış saati (İstanbul) |
| `active` | bool | Kapalıysa TV’de gösterilmez |

TV’de duyurular **kayan yazı değil**: sırayla tam ekran şeridinde gösterilir, süre dolunca sonrakine geçer.

### `restaurants`

| Alan | Tip | Not |
|------|-----|-----|
| `name`, `icon`, `cuisine` | text | |
| `weekly` | json | Haftanın günleri → açılış/kapanış veya kapalı |
| `opens` / `closes` | text | `weekly` yoksa yedek |
| Mekan / `lat` / `lng` | | Harita için |

**14 günlük döngü:** `cycle_anchor` = indeks 0. Bugünün İstanbul tarihi ile fark, mod 14 = o günün programı.

**Haftalık restoran:** Pazartesi = 0, Pazar = 6.

### Erişim kuralları (özet)

- TV için: ilgili koleksiyonlarda herkese açık okuma (list/view).
- Yazma: yalnızca giriş yapmış yönetici veya kuralınızda tanımlı yetkili kullanıcı.

---

## `voyage_welcome_screen.html`

- 1920×1080, viewport’a göre ölçekleme
- Saat/tarih, günün saatine göre selamlama
- Hava ve deniz: Open-Meteo (ücretsiz, harici hesap gerekmez)
- Harita: **MapLibre GL** + CARTO Voyager (raster); eğim (pitch) ile 3D hissi; zoom/pan kilitli
- Haritada **aktif aktivite** ve **açık restoran**: yatay kart — solda **emoji ikon**, sağda okunaklı başlık ve saat bilgisi (fotoğraf kullanılmaz)
- Aktivite şeridi, duyuru ticker’ı

**Notlar:** Sayfa `file://` ile açılabilir; Realtime için mümkünse aynı ağda HTTPS üzerinden servis etmek daha öngörülebilirdir. Koordinat önceliği: PocketBase `venues` + kayıttaki mekan eşlemesi; yoksa HTML içindeki yedek eşleme.

---

## `voyage_admin.html`

- PocketBase yönetici hesabı ile giriş (kendi PB panel adresinizden oluşturduğunuz kullanıcı)
- Oturum tarayıcıda saklanır
- Sekmeler: aktiviteler, duyurular, restoranlar, konumlar (venues), 14 günlük döngü ayarı

---

## Harici servisler

| Servis | Kullanım |
|--------|----------|
| Open-Meteo | Hava |
| Open-Meteo Marine | Dalga |
| CARTO (Voyager) | Harita karosu |
| MapLibre GL | Harita (WebGL, pitch) |
| PocketBase | Veri + Realtime |

Bu listedeki hava/harita servisleri için ayrı bir API anahtarı tanımlamanız gerekmez.

---

## Dikkat / riskler (özet)

1. **Admin paneli** tam yetkili hesap kullanıyorsa, cihaz güvenliği ve tarayıcı erişimi önemlidir. İleride sadece içerik tablolarına yetkili sınırlı kullanıcı düşünülebilir.
2. **Public okuma** kurallarında URL bilen herkes liste verisini okuyabilir; hassas metin konmamalı.
3. **Tek dosya HTML** bakımı zorlaştırabilir; ileride CSS/JS ayrımı düşünülebilir.

---

## Yapılacaklar (örnek)

- Staff kullanıcı + koleksiyon kuralları
- TV sayfasını statik host üzerinden servis etme
- Çoklu TV testi

---

## Tasarım

- Renkler: koyu lacivert + altın aksan
- Fontlar: Cormorant Garamond + Montserrat

### PocketBase `minute` alanı

`min` adı bazı ortamlarda 0 değerini sorunlu gösterebildiği için alan adı `minute` kullanılır.

### Realtime

Koleksiyonlarda değişince TV tarafı veriyi yeniden çeker; koleksiyon adları kod ile birebir uyumlu olmalıdır.

---

## Sunucu (genel)

PocketBase binary, systemd ve ters vekil (nginx vb.) ile çalıştırılır; SSL ve domain yapılandırması ortamınıza göre yapılır. Detaylı yol ve alan adları bu repoda yer almaz; kurulum notlarınızı ayrı tutun.

# Voyage Sorgun — Hotel TV Welcome Screen

## Proje Genel Bakış

Voyage Sorgun (Manavgat/Side, Antalya) için 1920×1080 hotel TV welcome screen sistemi. Kiosk modunda Chrome ile çalışır. Ayrı bir admin paneli üzerinden PocketBase backend'e yazılan veriler TV ekranına realtime yansır.

---

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `voyage_welcome_screen.html` | TV ekranı — kiosk Chrome ile açılır |
| `voyage_admin.html` | Admin paneli — herhangi bir cihazda browser ile açılır |

---

## Mimari

```
PocketBase (hotel-data.voyagestars.com)
├── app_config      → 14 günlük döngü başlangıç tarihi (tek kayıt)
├── venues          → mekan anahtarı + koordinat (harita birimleri)
├── activities      → cycle_day (0–13), venue_key
├── announcements
└── restaurants     → weekly (haftalık saatler JSON), venue_key isteğe bağlı
        │
        ├── voyage_welcome_screen.html  (okur, Realtime)
        └── voyage_admin.html           (yazar)
```

---

## Backend — PocketBase

- **URL:** `https://hotel-data.voyagestars.com`
- **Admin panel:** `https://hotel-data.voyagestars.com/_/`
- **Sunucu:** Narhost VDS (Ubuntu), systemd servisi olarak çalışır
- **Nginx:** subdomain proxy, Cloudflare üzerinden SSL (Let's Encrypt)
- **Pause yok** — free tier değil, kendi sunucu

### Tablolar

#### `app_config` (tek kayıt önerilir)
| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| `cycle_anchor` | text | ✓ | **Gün 0** tarihi, `YYYY-MM-DD` (İstanbul takvimi). Bu tarihten itibaren her gün sırayla 0→13 döngü tekrarlanır. |

#### `venues`
| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| `key` | text | ✓ | Benzersiz slug, örn. `beach_court` (küçük harf, alt çizgi) |
| `name` | text | ✓ | Görünen ad (dropdown’da) |
| `lat` | number | ✓ | |
| `lng` | number | ✓ | |

#### `activities`
| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| `hour` | number | ✓ | 0–23 |
| `minute` | number | — | 0–59 · **`min` değil, `minute`** |
| `name` | text | ✓ | Aktivite adı |
| `venue` | text | — | Mekan adı (TV’de metin) |
| `venue_key` | text | — | `venues.key` ile eşleşirse harita koordinatı buradan |
| `cycle_day` | number | — | **0–13** = 14 günlük şemada hangi gün; boş = her gün gösterilir (eski kayıtlar) |
| `icon` | text | — | Emoji |

#### `announcements`
| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| `text` | text | ✓ | Kayan yazı metni |
| `windows` | json | — | Zaman pencereleri; boş = her zaman göster. Örn: `[{"d":[0,1,2],"o":"09:00","c":"12:00"}]` — `d` Pzt=0…Paz=6, `o`/`c` saat (İstanbul) |
| `active` | bool | — | `false` = TV ticker’da gösterilmez; yok / `true` = aktif |

#### `restaurants`
| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| `name` | text | ✓ | |
| `icon` | text | — | Emoji |
| `cuisine` | text | — | Mutfak türü |
| `weekly` | json | — | Haftalık saatler: anahtar `0`–`6` (Pzt–Paz), değer `{ "o":"19:00","c":"23:00" }` veya `null` (kapalı) |
| `opens` / `closes` | text | — | `weekly` yoksa veya geriye dönük uyumluluk |
| `venue_key` | text | — | Doluysa koordinat `venues` tablosundan alınabilir |
| `lat` | number | — | Enlem |
| `lng` | number | — | Boylam |
| `query` | text | — | Unsplash arama sorgusu |

**14 günlük döngü:** `cycle_anchor` günü = indeks 0. Bugünün İstanbul tarihi ile anchor arasındaki gün farkı mod 14 = bugünün `cycle_day` değeri. Aynı şema her 14 günde bir tekrarlanır.

**Haftalık restoran:** Pazartesi = `0`, Pazar = `6`.

### API Rules
- **List / View:** `app_config`, `venues`, `activities`, `announcements`, `restaurants` — TV için public okuma
- **Create / Update / Delete:** Admin token (`@request.auth.id != ""`)

### PocketBase’de yeni koleksiyon / alan (bir kerelik)

Admin ve TV’nin yeni özellikleri kullanması için:

1. **`app_config`** koleksiyonu: alan `cycle_anchor` (Text). **List/View** kuralı herkese açık. Bir kayıt oluşturup tarih girin veya admin **14 Gün** sekmesinden kaydedin.
2. **`venues`** koleksiyonu: `key` (Text, unique), `name` (Text), `lat`, `lng` (Number). Public list/view.
3. **`activities`**: `cycle_day` (Number, 0–13, isteğe bağlı), `venue_key` (Text, isteğe bağlı).
4. **`restaurants`**: `weekly` (JSON), isteğe bağlı `venue_key` (Text). Eski kayıtlar sadece `opens`/`closes` ile çalışmaya devam eder.

Realtime için TV tarafı `app_config` ve `venues` aboneliği yapıyor; koleksiyon adları birebir aynı olmalı.

**`announcements`:** `windows` (JSON) zaman penceresi; **`active`** (Bool, isteğe bağlı) — `false` ise TV’de gösterilmez. Eski kayıtlar `active` olmadan aktif kabul edilir.

---

## `voyage_welcome_screen.html`

### Özellikler
- 1920×1080, viewport'a otomatik scale
- Saat/tarih, Good Morning/Afternoon/Evening/Night (saate göre)
- **Hava durumu:** Open-Meteo API (ücretsiz, key yok) — Side/Manavgat koordinatları
- **Dalga:** Open-Meteo Marine API
- **Harita:** Leaflet.js + CARTO Voyager tiles (key yok, `file://` ile çalışır)
  - Zoom 18, tamamen kilitli (drag/scroll yok)
  - Merkez: `36.756893, 31.418769`
  - Aktif aktiviteler LIVE pin ile gösterilir
  - Açık restoranlar Unsplash fotoğrafıyla kart olarak gösterilir
- **Activity strip:** Önümüzdeki 5 saatteki aktiviteler
- **Ticker:** Announcements tablosundan çeker

### Kritik Notlar

1. **`file://` protokolü ile çalışır** — Mapbox denenip bırakıldı (WebGL + `file://` uyumsuzluğu). Leaflet + CARTO kullanılıyor.

2. **Koordinatlar** — Öncelik `venues` + `venue_key`; yoksa TV tarafında `VENUE_COORDS` yedek eşleme.

3. **Realtime bağlantısı** — PocketBase SSE Realtime ile admin değişiklik yapınca ekran anında güncellenir. `file://` üzerinde test edilmedi; sunucudan serve edilince güvenli çalışır.

4. **Restoranlar** — Varsa `weekly` JSON’a göre haftanın günü; yoksa `opens`/`closes`.

### Kiosk Başlatma (Windows)
```
chrome.exe --kiosk --disable-infobars --noerrdialogs file:///C:/path/to/voyage_welcome_screen.html
```

### API Koordinatları — Harita Merkezi
```
LAT: 36.756893
LNG: 31.418769
```

---

## `voyage_admin.html`

### Özellikler
- PocketBase admin email + şifre ile login
- Token localStorage'da tutulur, sayfa kapatılıp açılsa giriş gerekmez
- 3 sekme: Aktiviteler · Duyurular · Restoranlar
- Kayıt ekle / sil → anında TV'ye yansır (Realtime)
- Herhangi bir cihazda (`file://` veya web) açılabilir

### Login
PocketBase admin panelinde oluşturulan email/şifre kullanılır:
`https://hotel-data.voyagestars.com/_/`

---

## Harici Servisler & API Keyler

| Servis | Amaç | Key / Durum |
|--------|------|-------------|
| Open-Meteo | Hava durumu | Ücretsiz, key yok |
| Open-Meteo Marine | Dalga verisi | Ücretsiz, key yok |
| CARTO Tiles | Harita | Ücretsiz, key yok |
| Leaflet.js 1.9.4 | Harita kütüphanesi | CDN, ücretsiz |
| Unsplash | Restoran fotoğrafları | Key: `A70R36hURzGFRRppSSxDlabMdXa7yyrIuSkUf6OhiQw` |
| PocketBase | Backend DB | `hotel-data.voyagestars.com` |

> ⚠️ **Unsplash key kaynak kodda açık.** Unsplash dashboard'dan domain kısıtlaması ekle.

---

## Dikkat ve riskler

Aşağıdaki maddeler bilinçli teknik borç / güvenlik notlarıdır. İleride düzeltilecek (bkz. yapılacaklar).

### 1. Unsplash API anahtarı kaynak kodda

- **Risk:** Anahtar repoda ve HTML içinde düz metin. Sızıntıda kotanız veya kötüye kullanım riski.
- **Azaltma (geçici):** Unsplash uygulamasında domain / referrer kısıtlaması.
- **Hedef çözüm:** Anahtarı ortam değişkeni veya sunucu tarafı proxy ile tutmak; veya restoran görsellerini PocketBase file field ile yüklemek (Unsplash’e bağımlılığı kaldırmak).

### 2. Admin paneli = PocketBase admin hesabı

- **Risk:** `voyage_admin.html` PocketBase **superuser** (admin) email/şifre ile giriş yapıyor; token `localStorage`’da. Bu hesap tüm koleksiyonlar, ayarlar ve diğer adminlere erişebilir. XSS veya cihaz çalınırsa etki alanı çok geniş.
- **Hedef çözüm:** Sadece `activities` / `announcements` / `restaurants` için yetkili, sınırlı bir **staff** kullanıcısı; collection rules ile sadece bu tablolarda create/update/delete. Admin paneli bu kullanıcı ile API auth (admin API yerine).

### 3. Tek dosyada yoğun kod (bakım riski)

- **Risk:** `voyage_welcome_screen.html` çok satırlı (CSS + JS tek dosyada). Özellik ekleme ve hata ayıklama zorlaşır, birleştirme çakışması riski artar.
- **Hedef çözüm:** Stil ve script’i ayrı `.css` / `.js` dosyalarına bölmek veya küçük bir static build (isteğe bağlı).

### 4. `file://` ve Realtime / ağ

- **Risk:** TV’de sayfa `file://` ile açılıyorsa tarayıcı ve ortama göre CORS, çerez, SSE/WebSocket davranışı farklı olabilir; Realtime bu ortamda tam test edilmemiş olabilir.
- **Hedef çözüm:** Welcome ekranını aynı ağda nginx veya statik host üzerinden `https://` veya en azından `http://` ile servis etmek; davranışı öngörülebilir kılmak.

### 5. Public list/view kuralları

- **Not:** Aktivite, duyuru ve restoran kayıtları liste/görüntüleme için public. Bu otel içi bilgi için genelde kabul edilebilir; ancak hassas içerik konulmamalı. URL bilen herkes okuyabilir.

---

## Eksik / Yapılacaklar

- [ ] **Dikkat ve riskler** bölümündeki maddeler (Unsplash key, staff kullanıcı, dosya bölme, TV için static serve, public veri farkındalığı)
- [ ] `VENUE_COORDS` objesi PocketBase'e taşınacak (aktivite koordinatları admin'den düzenlenebilsin)
- [ ] Restoran tablosuna `lat/lng` koordinatları girilmeli (şu an yaklaşık)
- [ ] Admin paneline aktivite sıralama / düzenleme (şu an sadece ekle/sil)
- [ ] Restoran fotoğraflarını Unsplash yerine manuel upload (PocketBase file field)
- [ ] Birden fazla TV ekranı için test

---

## Geliştirme Notları

### Tasarım Sistemi
- **Renkler:** `--navy: #080d1c`, `--gold: #c9a84c`, `--gold2: #e8c97a`
- **Fontlar:** Cormorant Garamond (serif/başlık) + Montserrat (sans/metin)
- **Format:** 1920×1080, dark navy + altın aksan

### PocketBase'de `minute` Alanı
Tablo oluşturulurken `min` adı PocketBase'de `0` değerini "boş" sayıyordu. Bu yüzden alan adı `minute` olarak değiştirildi. Kodda her yerde `a.minute || 0` şeklinde kullanılıyor.

### Mapbox Denendi, Bırakıldı
Mapbox GL JS `file://` protokolü üzerinde "Script error" veriyor (WebGL + CORS kısıtlaması). Leaflet + CARTO tercih edildi, her ortamda çalışır.

### PocketBase Realtime
```javascript
// SSE bağlantısı kurar, activities/announcements/restaurants değişince
// fetchFromPB() çağrılır, ekran yenilenir
connectRealtime();
```

---

## Sunucu Bilgileri

- **VDS:** Narhost (Ubuntu 24)
- **PocketBase binary:** `/opt/pocketbase/pocketbase`
- **Systemd:** `sudo systemctl status pocketbase`
- **Nginx config:** `/etc/nginx/sites-available/pocketbase`
- **SSL:** Let's Encrypt (Certbot)
- **Domain:** `hotel-data.voyagestars.com` → Cloudflare A kaydı (proxy OFF)

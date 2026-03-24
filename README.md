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
| `scripts/pb_app_config_tv_fields.sh` | `app_config` TV süre alanları + (eski) json alanları |
| `scripts/pb_activities_schedule_slot.sh` | `activities.schedule_slot` text alanı ekler |
| `scripts/pb_activities_start_end.sh` | `activities.start`, `activities.end` (text, örn. "09:00") |
| `scripts/migrate_activities_to_start_end.sh` | Mevcut hour/minute → start/end dönüşümü |

### PocketBase: script ile alan eklemek

```bash
export PB_URL="https://senin-pb-adresin.com"   # isteğe bağlı
./scripts/pb_activities_schedule_slot.sh   # önce bunu (aktivite TV programı)
./scripts/pb_activities_start_end.sh       # aktivite start/end (metin HH:MM) — TV + admin bunu kullanır
./scripts/pb_app_config_tv_fields.sh       # app_config süreleri (json alanları isteğe bağlı)
# Eski kayıtlar (hour/minute) için: migrate_activities_to_start_end.sh, pb_activities_end_fields.sh, migrate_activities_end_plus60.sh
```

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
| `map_schedule_map_sec` | number | | Harita süresi (sn); boş → 30. Dönüşümde **0** = o slotta harita yok |
| `map_schedule_schedule_sec` | number | | Program süresi (sn); boş → 30. **0** = o slotta program yok |
| `tv_map_enabled` | bool | | **false** = harita tamamen kapalı. Alan yoksa: `map_schedule_map_sec` &gt; 0 ise açık kabul edilir |
| `tv_schedule_enabled` | bool | | **false** = program tamamen kapalı. Alan yoksa: süre &gt; 0 ise açık |

İkisi de kapalıysa veya ikisi de açıkken her iki süre **0** ise TV’de harita/program alanı boş mesaj gösterilir. Yönetim: **TV** sekmesindeki aç/kapa kutuları bu alanları yazar; PocketBase’de alan yoksa `./scripts/pb_app_config_tv_fields.sh` ile ekleyin.

Program kutuları **Aktiviteler** → `schedule_slot` (gündüz / çocuk / akşam) ile dolar; restoran kutusu bugün açık olanların tamamıdır.

### `venues`

| Alan | Tip | Zorunlu | Not |
|------|-----|---------|-----|
| Benzersiz metin alanı (slug) | text | ✓ | Küçük harf, alt çizgi; aktivite/restoran kayıtlarındaki mekan alanı bununla eşleşir |
| `name` | text | ✓ | Görünen ad |
| `lat` / `lng` | number | ✓ | Harita koordinatları |

### `activities`

| Alan | Tip | Not |
|------|-----|-----|
| `start`, `end` | text | Saatler `HH:MM` (örn. `09:00`, `23:30`). Bitiş başlangıçtan küçük olabilir (ertesi güne sarkan program). `end` boş bırakılırsa admin/TV tarafında başlangıç + 60 dk varsayılır. |
| `name`, `venue`, `icon` | text | Ad, mekan, ikon |
| `cycle_day` | number | 0–13; boş = her gün |
| `schedule_slot` | text | TV program: `daytime` (gündüz), `kids` (çocuk), `evening` (akşam) |
| `venue_key` | text | Doluysa harita koordinatı `venues` tablosundan |

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
- Program drum picker’ları: Daytime, Kids, Restaurants, Evening
- Aktivite şeridi, duyuru ticker’ı

**Notlar:** Sayfa `file://` ile açılabilir; Realtime için mümkünse aynı ağda HTTPS üzerinden servis etmek daha öngörülebilirdir.

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

### Realtime

Koleksiyonlarda değişince TV tarafı veriyi yeniden çeker; koleksiyon adları kod ile birebir uyumlu olmalıdır.

---

## Sunucu (genel)

PocketBase binary, systemd ve ters vekil (nginx vb.) ile çalıştırılır; SSL ve domain yapılandırması ortamınıza göre yapılır. Detaylı yol ve alan adları bu repoda yer almaz; kurulum notlarınızı ayrı tutun.

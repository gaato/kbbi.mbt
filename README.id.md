# gaato/kbbi

Cari kata bahasa Indonesia di [KBBI Daring](https://kbbi.kemendikdasmen.go.id), edisi daring *Kamus Besar Bahasa Indonesia*, dari MoonBit atau dari shell. Setiap entri dikembalikan sebagai data bertipe, atau sebagai JSON dari perintahnya: lema beserta nomor homonimnya, lafal, kata dasar dan bentuk tidak baku, serta label, definisi, contoh, dan arti contoh untuk setiap makna. Tersedia juga *skill* agen untuk perintah ini.

Tidak resmi, dan tidak berafiliasi dengan KBBI maupun pengelolanya. Hasilnya dibaca dari halaman KBBI Daring.

[English](https://github.com/gaato/kbbi.mbt/blob/main/README.md) · [日本語](https://github.com/gaato/kbbi.mbt/blob/main/README.ja.md)

## Pemasangan

Perintahnya tidak perlu dipasang: `moonx` milik MoonBit mengunduh rilis terbaru lalu menjalankannya, seperti di bawah. Untuk pustakanya:

```sh
moon add gaato/kbbi
moon add gaato/mttp
```

## Coba dari shell

```sh
moonx gaato/kbbi/cmd/kbbi makan
moonx gaato/kbbi/cmd/kbbi rumah sakit
moonx gaato/kbbi/cmd/kbbi --help
```

Argumen digabung dengan spasi menjadi satu kueri, jadi baris kedua mencari frasa *rumah sakit*. Satu pencarian mencetak satu dokumen JSON yang sudah dirapikan.

| Kode keluar | Arti |
| --- | --- |
| 0 | Berhasil, termasuk kata yang tidak ada di KBBI (`found: false`) |
| 1 | Kegagalan jaringan, kode status, atau dekode |
| 2 | Argumen tidak valid |

Galat ditulis ke stderr sebagai `error: ...`. Permintaan dihentikan setelah 10 detik. Mohon hindari pencarian massal yang beruntun cepat.

Kebijakan moonrun opsional membatasi akses jaringan perintah ini hanya ke KBBI. Simpan ini sebagai `kbbi-policy.json`:

```json
{"net":{"connect":["kbbi.kemendikdasmen.go.id:443"]}}
```

```sh
moonx --experimental-policy kbbi-policy.json gaato/kbbi/cmd/kbbi gemas
```

## Memakai pustakanya

`lookup` menerima `Client` dari `gaato/mttp_core`, sehingga pustaka ini tidak mengimpor *runtime* asinkron dan dapat dibangun untuk wasm, native, dan js. Program yang dapat dijalankan menambahkan `gaato/mttp`, yang `@mttp.Client`-nya bertipe sama, lalu membuatnya dengan `@mttp.client()`, seperti yang dilakukan `run_lookup` di bawah. Pemanggil memiliki dan menutup klien itu, dan pengaturan batas waktu, percobaan ulang, serta batas ukuran isi milik klien berlaku untuk pencarian. Gunakan satu klien untuk beberapa kueri.

```mbt check
///|
/// Prints the headword and first definition of each entry for `word`.
async fn print_definitions(client : @mttp.Client, word : String) -> Unit {
  let result = @kbbi.lookup(client, word)
  if !result.found {
    println("\{word}: not in KBBI")
  }
  for entry in result.entries {
    println("\{entry.headword}: \{entry.senses[0].gloss}")
  }
}

///|
/// Builds a client, looks `word` up and closes the client, on mttp's event
/// loop; an executable's `fn main` can call it.
fn run_lookup(word : String) -> Unit {
  @mttp.run(async fn() {
    let client = @mttp.client(timeout_ms=10_000)
    defer client.close()
    print_definitions(client, word)
  })
}

///|
test "the usage example compiles" {
  ignore(print_definitions)
  ignore(run_lookup)
}
```

Kata yang tidak ada di KBBI bukan galat: hasilnya memiliki `found: false` dan tanpa entri. `to_json()` mengubah hasil menjadi JSON yang sama dengan yang dicetak perintahnya.

### Mengurai halaman yang disimpan

`parse` membaca halaman entri tanpa I/O apa pun, dan `entry_url` memberikan halaman yang perlu disimpan. Gunakan untuk pengujian, atau untuk membaca ulang entri tanpa permintaan lagi:

```mbt check
///|
test "parse a saved page" {
  let html =
    #|<h2>ma.kan<sup>1</sup></h2>
    #|<ol><li><font color="red"><i><span title="Verba: kata kerja">v</span></i></font>
    #|mengisap:<font color="grey"><i>-- candu</i></font></li></ol>
  let url = @kbbi.entry_url("makan")
  let result = @kbbi.parse(html, query="makan", url~)
  inspect(url, content="https://kbbi.kemendikdasmen.go.id/entri/makan")
  inspect(result.entries[0].headword, content="makan")
  inspect(result.entries[0].senses[0].gloss, content="mengisap")
}
```

### Galat

`lookup` memunculkan `KbbiError`:

- `EmptyQuery`: kueri kosong setelah spasi di tepinya dibuang. Tidak ada yang dikirim.
- `Http`: pengiriman atau pembacaan gagal. Membawa `TransportError`.
- `Status`: KBBI menjawab dengan kode status selain 2xx.
- `Decode`: halamannya bukan UTF-8 yang valid.

Galat yang dimunculkan oleh kebijakan klien itu sendiri diteruskan apa adanya.

## Paket

| Paket | Isinya | Target |
|---|---|---|
| `gaato/kbbi` | Pustakanya: `lookup`, `parse`, `entry_url`, dan tipe-tipe hasil | wasm, native, js |
| `gaato/kbbi/cmd/kbbi` | Perintah `kbbi` dan *skill* agennya | wasm, native |

[*Skill* agen](https://github.com/gaato/kbbi.mbt/blob/main/cmd/kbbi/SKILL.md) menjelaskan cara menjalankan pencarian dan membaca JSON-nya.

## Tautan

- [Catatan perubahan](https://github.com/gaato/kbbi.mbt/blob/main/CHANGELOG.md)
- [Repositori](https://github.com/gaato/kbbi.mbt)

## Lisensi

Apache-2.0

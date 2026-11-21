# gaato/kbbi

*Kamus Besar Bahasa Indonesia* のオンライン版 [KBBI Daring](https://kbbi.kemendikdasmen.go.id) で、インドネシア語の単語を MoonBit やシェルから引けます。項目は型付きのデータとして、コマンドからは JSON として返ります。中身は、同音異義語の番号つきの見出し語、発音、語根、非標準の綴り、そして語義ごとのラベル・定義・用例・用例の意味です。コマンド用のエージェントのスキルも付いています。

非公式で、KBBI やその運営元とは関係ありません。結果は KBBI Daring のページから読み取っています。

[English](https://github.com/gaato/kbbi.mbt/blob/main/README.md) · [Bahasa Indonesia](https://github.com/gaato/kbbi.mbt/blob/main/README.id.md)

## インストール

コマンドはインストール不要です。下のように、MoonBit の `moonx` が最新のリリースを取ってきて動かします。ライブラリを使うには:

```sh
moon add gaato/kbbi
moon add gaato/mttp
```

## シェルから試す

```sh
moonx gaato/kbbi/cmd/kbbi makan
moonx gaato/kbbi/cmd/kbbi rumah sakit
moonx gaato/kbbi/cmd/kbbi --help
```

引数はスペースでつないで一つの検索語になるので、2 行目は *rumah sakit* という句を引きます。一回の検索で、整形した JSON の文書を一つ表示します。

| 終了コード | 意味 |
| --- | --- |
| 0 | 成功。KBBI にない単語(`found: false`)も含む |
| 1 | ネットワーク・状態コード・デコードの失敗 |
| 2 | 引数の誤り |

エラーは標準エラーに `error: ...` として出ます。リクエストは 10 秒で打ち切ります。短い間隔での大量の検索は控えてください。

任意の moonrun のポリシーで、コマンドのネットワークへのアクセスを KBBI だけに絞れます。次を `kbbi-policy.json` として保存します:

```json
{"net":{"connect":["kbbi.kemendikdasmen.go.id:443"]}}
```

```sh
moonx --experimental-policy kbbi-policy.json gaato/kbbi/cmd/kbbi gemas
```

## ライブラリを使う

`lookup` は `gaato/mttp_core` の `Client` を取るので、ライブラリは非同期の実行環境を import せず、wasm・native・js でビルドできます。実行ファイルは `gaato/mttp` を足し、同じ型の `@mttp.Client` を、下の `run_lookup` のように `@mttp.client()` で作ります。クライアントは呼び出し側が持って閉じ、その時間制限・再試行・本文の上限の設定が検索にも効きます。いくつも引くときは一つのクライアントを使い回してください。

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

KBBI にない単語はエラーではありません。結果は `found: false` で、項目は空です。`to_json()` は、結果をコマンドが表示するのと同じ JSON にします。

### 保存したページを解析する

`parse` は I/O なしで項目のページを読み、`entry_url` は保存すべきページを返します。テストや、もう一度リクエストせずに項目を読み直すときに使えます:

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

### エラー

`lookup` は `KbbiError` を送出します:

- `EmptyQuery`: 前後の空白を除くと検索語が空。何も送らない。
- `Http`: 送信か読み込みに失敗した。`TransportError` を持つ。
- `Status`: KBBI が 2xx 以外の状態コードで答えた。
- `Decode`: ページが正しい UTF-8 ではない。

クライアント自身の方針が送出するエラーは、そのまま通します。

## パッケージ

| パッケージ | 中身 | ターゲット |
|---|---|---|
| `gaato/kbbi` | ライブラリ: `lookup`・`parse`・`entry_url` と結果の型 | wasm, native, js |
| `gaato/kbbi/cmd/kbbi` | `kbbi` コマンドとエージェントのスキル | wasm, native |

[エージェントのスキル](https://github.com/gaato/kbbi.mbt/blob/main/cmd/kbbi/SKILL.md)には、検索の動かし方と JSON の読み方が書いてあります。

## リンク

- [変更履歴](https://github.com/gaato/kbbi.mbt/blob/main/CHANGELOG.md)
- [リポジトリ](https://github.com/gaato/kbbi.mbt)

## ライセンス

Apache-2.0 です。

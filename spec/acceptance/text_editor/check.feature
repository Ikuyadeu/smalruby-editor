# encoding: utf-8
# language: ja
@javascript
機能: Check - プログラムのエラーチェック
  シナリオ: チェックボタンを押してプログラムの正しいかチェックできる
    前提 "エディタ" 画面を表示する
    かつ テキストエディタに "puts 'Hello, World!'" を入力済みである

    もし "チェックボタン" をクリックする
    かつ JavaScriptによるリクエストが終わるまで待つ

    ならば "メッセージ" に "チェックしました" を含むこと
    かつ "メッセージ" に "ただし、プログラムを動かすとエラーが見つかるかもしれません。" を含むこと

    もし テキストエディタに "puts Hello, World!'" を入力済みである
    かつ "チェックボタン" をクリックする
    かつ JavaScriptによるリクエストが終わるまで待つ

    ならば "メッセージ" に "エラー" を含むこと
    かつ "メッセージ" に "1行、19文字: syntax error, unexpected tSTRING_BEG, expecting keyword_do or '{' or '('" を含むこと
    かつ "メッセージ" に "1行: unterminated string meets end of file" を含むこと
    かつ "メッセージ" に "チェックしました" を含まないこと

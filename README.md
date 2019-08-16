# Japanese text transliteration

## Overview

This is a sample iOS app for converting Japanese text with kanji to hiragana, katakana, or Latin alphabet.

![Sample app in action](/action_movie.gif)


## Functionality

There are 3 options for converting text. 

#### 1. [Goo Hiragana Translation API](https://labs.goo.ne.jp/api/jp/hiragana-translation/)

A JSON API to convert Japanese text with kanji to either hiragana or katakana.

#### 2. [Yahoo! Japan Furigana API](https://developer.yahoo.co.jp/webapi/jlp/furigana/v1/furigana.html)

An XML API to put ruby (furigana) over Japanese text with kanji. 
In this app it is used to convert text to either hiragana or Latin alphabet.

#### 3. Core Foundation

[`CFStringTokenizer`](https://developer.apple.com/documentation/corefoundation/cfstringtokenizer-rf8) can be used to generate Latin transcription of Japanese text on device without using network.
From that, a `String` [transformation](https://developer.apple.com/documentation/foundation/nsstring/1407787-applyingtransform) can be applied to get hiragana or katakana transliterations.


## Configuration

To use network APIs you must first register a developer account with [Goo](https://labs.goo.ne.jp/jp/apiregister/) and [Yahoo! Japan](https://developer.yahoo.co.jp) (both are in Japanese only) and obtain App IDs for each.

Then fill them in `furigana-converter/secrets.xcconfig`.
Don't use quotation marks, e.g.:
```
GOO_APP_ID = 12345abcd
YAHOO_APP_ID = 12345abcd
```

## Next steps

This sample app can be improved in several ways.

1. Implement tests.

2. Introduce 3rd party frameworks to reduce complexity.

Stuff like `Moya` or/and `Alamofire` for network abstraction, `RxSwift` for better state handling.

3. Add new functionality.

- Copying the result to clipboard.
- Take full advantage of Yahoo API and surface different options to user, or show results as actual furigana.
- Put UI into table view and implement showing and managing history of requests.

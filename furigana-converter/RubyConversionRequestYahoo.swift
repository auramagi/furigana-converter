//
//  RubyConversionRequestYahoo.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

struct RubyConversionRequestYahoo: RubyConversionRequest {
    let text: String
    let output: RubyConversionOutput
    
    var task: URLSessionDataTask?
    
    static var availableOutputs: [RubyConversionOutput] { return [.hiragana, .romaji] }
    
    init(text: String, output: RubyConversionOutput) {
        self.text = text
        self.output = output
    }
    
    mutating func convert(completion: @escaping (Result<String, RubyConversionError>) -> Void) {
        guard let appID = RubyConversionRequestYahoo.appID, !appID.isEmpty else {
            completion(.failure(.providerNotAvaliable))
            return
        }
        var comps = URLComponents(url: RubyConversionRequestYahoo.endpoint, resolvingAgainstBaseURL: false)
        comps?.queryItems = [
            "appid": appID,
            "sentence": text
            ].map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = comps?.url else {
            completion(.failure(.providerError))
            return
        }
        
        let request = URLRequest(url: url)
        
        task = URLSession.shared.dataTask(with: request) { [output = self.output] (data, response, error) in
            guard let data = data else {
                    completion(.failure(.providerError))
                    return
            }
            
            var result = ""
            XMLObjectParser(data: data).document
                .descendants(withTagName: "Word")
                .forEach {
                    let ruby: String?
                    switch output {
                    case .hiragana: ruby = $0.firstChild(withTagName: "Furigana")?.text
                    case .romaji: ruby = $0.firstChild(withTagName: "Roman")?.text
                    case .katakana: ruby = nil
                    }
                    result += ruby ?? $0.firstChild(withTagName: "Surface")?.text ?? ""
            }
            completion(.success(result))
        }
        
        task?.resume()
    }
    
    mutating func cancel() {
        task?.cancel()
        task = nil
    }
    
    private static let endpoint = URL(string: "https://jlp.yahooapis.jp/FuriganaService/V1/furigana")!
    private static var appID: String? {
        return Bundle.main.object(forInfoDictionaryKey: "YAHOO_APP_ID") as? String
    }
}

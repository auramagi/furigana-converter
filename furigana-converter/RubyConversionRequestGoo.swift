//
//  RubyProviderGoo.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

struct RubyConversionRequestGoo: RubyConversionRequest {
    let text: String
    let output: RubyConversionOutput
    
    var task: URLSessionDataTask?
    
    init(text: String, output: RubyConversionOutput) {
        self.text = text
        self.output = output
    }
    
    mutating func convert(completion: @escaping (Result<String, RubyConversionError>) -> Void) {
        guard let appID = RubyConversionRequestGoo.appID, !appID.isEmpty else {
            completion(.failure(.providerNotAvaliable))
            return
        }
        let requestContent = Request(app_id: appID,
                              sentence: text,
                              output_type: .fromOutput(output))
        guard let json = try? JSONEncoder().encode(requestContent) else {
            completion(.failure(.providerError))
            return
        }
        var request =  URLRequest(url: RubyConversionRequestGoo.endpoint)
        request.httpMethod = "POST"
        request.httpBody = json
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let jsonResponse = try? JSONDecoder().decode(Response.self, from: data)
                else {
                completion(.failure(.providerError))
                return
            }
            completion(.success(jsonResponse.converted))
        }
        
        task?.resume()
    }
    
    mutating func cancel() {
        task?.cancel()
        task = nil
    }
    
    private static let endpoint = URL(string: "https://labs.goo.ne.jp/api/hiragana")!
    private static var appID: String? {
        return Bundle.main.object(forInfoDictionaryKey: "GOO_APP_ID") as? String
    }
}

extension RubyConversionRequestGoo {
    private enum OutputType: String, Codable {
        case hiragana = "hiragana"
        case katakana = "katakana"
        
        static func fromOutput(_ output: RubyConversionOutput) -> OutputType {
            switch output {
            case .hiragana: return .hiragana
            case .katakana: return .katakana
            }
        }
    }
    
    private struct Request: Encodable {
        let app_id: String
        let sentence: String
        let output_type: OutputType
    }
    
    private struct Response: Decodable {
        let request_id: String
        let output_type: OutputType
        let converted: String
    }
}

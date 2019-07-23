//
//  RubyProviderGoo.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

class RubyConversionRequestGoo: RubyConversionRequest {
    var task: URLSessionDataTask?
    
    required init(text: String, completion: @escaping (String?) -> Void) {
        let requestContent = Request(app_id: RubyConversionRequestGoo.appID,
                              sentence: text,
                              output_type: .hiragana)
        let json = try! JSONEncoder().encode(requestContent)
        var request =  URLRequest(url: RubyConversionRequestGoo.endpoint)
        request.httpMethod = "POST"
        request.httpBody = json
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let jsonResponse = try? JSONDecoder().decode(Response.self, from: data)
                else { return }
            completion(jsonResponse.converted)
        }
        
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    private static let endpoint = URL(string: "https://labs.goo.ne.jp/api/hiragana")!
    private static var appID: String {
        return Bundle.main.object(forInfoDictionaryKey: "GOO_APP_ID") as! String
    }
}

extension RubyConversionRequestGoo {
    private enum OutputType: String, Codable {
        case hiragana = "hiragana"
        case katakana = "katakana"
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

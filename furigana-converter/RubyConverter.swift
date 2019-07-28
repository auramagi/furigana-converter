//
//  RubyConverter.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

protocol RubyConverterDelegate: class {
    func converterWillStart()
    func converterDidConvertText(_ originalText: String, ruby: String, output: RubyConversionOutput)
    func converterDidFail(error: RubyConversionError?)
    func converterDidEnd()
}

enum RubyConversionError: Error {
    /// API Keyが見つからない他
    case providerNotAvaliable
    /// ネットワークエラーやAPIリクエストエラー他
    case providerError
    /// セレクトした出力は非対応
    case outputNotAvailable
}

protocol RubyConversionRequest {
    static var availableOutputs: [RubyConversionOutput] { get }
    
    init(text: String, output: RubyConversionOutput)
    
    mutating func convert(completion: @escaping (Result<String, RubyConversionError>) -> Void)
    mutating func cancel()
}

enum RubyConversionOutput {
    case hiragana
    case katakana
    case romaji
}

enum RubyConversionProvider {
    case goo
    case yahoo
    case coreFoundation
}

class RubyConverter {
    weak var delegate: RubyConverterDelegate?
    
    var throttleTimeout: TimeInterval = 1
    
    private var throttleTimer: Timer?
    private var request: RubyConversionRequest?
    private var requestOptions: (String, RubyConversionOutput, RubyConversionProvider)?
    
    static func availableOutputs(provider: RubyConversionProvider) -> [RubyConversionOutput] {
        switch provider {
        case .goo: return RubyConversionRequestGoo.availableOutputs
        case .yahoo: return RubyConversionRequestYahoo.availableOutputs
        case .coreFoundation: return RubyConversionRequestCoreFoundation.availableOutputs
        }
    }
    
    func convert(_ text: String, to output: RubyConversionOutput, using provider: RubyConversionProvider) {
        requestOptions = (text, output, provider)
        if throttleTimer == nil {
            throttleTimer = .scheduledTimer(withTimeInterval: throttleTimeout, repeats: false, block: { [weak self] _ in
                self?.throttleTimer = nil
                self?.makeRequest()
            })
        }
        delegate?.converterWillStart()
    }
    
    func cancel() {
        throttleTimer?.invalidate()
        throttleTimer = nil
        request?.cancel()
        request = nil
        delegate?.converterDidEnd()
    }
    
    private func makeRequest() {
        request?.cancel()
        guard let (text, output, provider) = requestOptions else { return }
        guard RubyConverter.availableOutputs(provider: provider).contains(output) else {
            self.delegate?.converterDidFail(error: .outputNotAvailable)
            self.delegate?.converterDidEnd()
            return
        }
        switch provider {
        case .goo: request = RubyConversionRequestGoo(text: text, output: output)
        case .yahoo: request = RubyConversionRequestYahoo(text: text, output: output)
        case .coreFoundation: request = RubyConversionRequestCoreFoundation(text: text, output: output)
        }
        request?.convert { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.delegate?.converterDidFail(error: error)
                case .success(let ruby):
                    self?.delegate?.converterDidConvertText(text, ruby: ruby, output: output)
                }
                self?.delegate?.converterDidEnd()
            }
        }
    }
}

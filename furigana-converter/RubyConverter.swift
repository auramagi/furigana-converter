//
//  RubyConverter.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

protocol RubyConverterDelegate: class {
    func converterWillStart(_ converter: RubyConverter)
    func converterDidConvertText(_ converter: RubyConverter, originalText: String, ruby: String, output: RubyConversionOutput)
    func converterDidFail(_ converter: RubyConverter, error: RubyConversionError?)
    func converterDidEnd(_ converter: RubyConverter)
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
    
    static func availableOutputs(provider: RubyConversionProvider) -> [RubyConversionOutput] {
        switch provider {
        case .goo: return RubyConversionRequestGoo.availableOutputs
        case .yahoo: return RubyConversionRequestYahoo.availableOutputs
        case .coreFoundation: return RubyConversionRequestCoreFoundation.availableOutputs
        }
    }
    
    func convert(_ text: String, to output: RubyConversionOutput, using provider: RubyConversionProvider) {
        let timeout = throttleTimer?.fireDate.timeIntervalSinceNow ?? throttleTimeout
        throttleTimer?.invalidate()
        delegate?.converterWillStart(self)
        throttleTimer = .scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
            self?.throttleTimer = nil
            self?.makeRequest(text, to: output, using: provider)
        })
    }
    
    func cancel() {
        throttleTimer?.invalidate()
        throttleTimer = nil
        request?.cancel()
        request = nil
        delegate?.converterDidEnd(self)
    }
    
    private func makeRequest(_ text: String, to output: RubyConversionOutput, using provider: RubyConversionProvider) {
        request?.cancel()
        guard RubyConverter.availableOutputs(provider: provider).contains(output) else {
            self.delegate?.converterDidFail(self, error: .outputNotAvailable)
            self.delegate?.converterDidEnd(self)
            return
        }
        switch provider {
        case .goo: request = RubyConversionRequestGoo(text: text, output: output)
        case .yahoo: request = RubyConversionRequestYahoo(text: text, output: output)
        case .coreFoundation: request = RubyConversionRequestCoreFoundation(text: text, output: output)
        }
        request?.convert { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.delegate?.converterDidFail(self, error: error)
                case .success(let ruby):
                    self.delegate?.converterDidConvertText(self, originalText: text, ruby: ruby, output: output)
                }
                self.delegate?.converterDidEnd(self)
            }
        }
    }
    
    deinit {
        delegate?.converterDidEnd(self)
    }
}

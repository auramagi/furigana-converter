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
    func converterDidEnd()
}

protocol RubyConversionRequest {
    init(text: String, output: RubyConversionOutput)
    mutating func convert(completion: @escaping (String?) -> Void)
    mutating func cancel()
}

enum RubyConversionOutput {
    case hiragana
    case katakana
}

enum RubyConversionProvider {
    case goo
}

class RubyConverter {
    weak var delegate: RubyConverterDelegate?
    
    var throttleTimeout: TimeInterval = 1
    
    private var throttleTimer: Timer?
    private var request: RubyConversionRequest?
    private var requestOptions: (String, RubyConversionOutput)?
    
    func convert(_ text: String, to output: RubyConversionOutput, using provider: RubyConversionProvider) {
        requestOptions = (text, output)
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
    }
    
    private func makeRequest() {
        request?.cancel()
        guard let (text, output) = requestOptions else { return }
        request = RubyConversionRequestGoo(text: text, output: output)
        request?.convert { [weak self] ruby in
            guard let ruby = ruby else { return }
            DispatchQueue.main.async {
                self?.delegate?.converterDidConvertText(text, ruby: ruby, output: output)
                self?.delegate?.converterDidEnd()
            }
        }
    }
}

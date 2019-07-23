//
//  RubyConverter.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

protocol RubyConverterDelegate: class {
    func converterDidConvertText(_ originalText: String, ruby: String)
}

protocol RubyConversionRequest {
    init(text: String, completion: @escaping (String?) -> Void)
    func cancel()
}

class RubyConverter {
    weak var delegate: RubyConverterDelegate?
    
    var throttleTimeout: TimeInterval = 1
    
    private var throttleTimer: Timer?
    private var request: RubyConversionRequest?
    private var requestText: String?
    
    func convert(_ text: String) {
        requestText = text
        if throttleTimer == nil {
            throttleTimer = .scheduledTimer(withTimeInterval: throttleTimeout, repeats: false, block: { [weak self] _ in
                self?.throttleTimer = nil
                self?.makeRequest()
            })
        }
    }
    
    func cancel() {
        throttleTimer?.invalidate()
        throttleTimer = nil
        request?.cancel()
        request = nil
    }
    
    private func makeRequest() {
        request?.cancel()
        guard let text = requestText else { return }
        request = RubyConversionRequestGoo(text: text, completion: { [weak self] ruby in
            guard let ruby = ruby else { return }
            DispatchQueue.main.async {
                self?.delegate?.converterDidConvertText(text, ruby: ruby)
            }
        })
    }
}

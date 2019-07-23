//
//  RubyConversionRequestCoreFoundation.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

struct RubyConversionRequestCoreFoundation: RubyConversionRequest {
    let text: String
    let output: RubyConversionOutput
    
    var isCancelled = false
    
    static var availableOutputs: [RubyConversionOutput] { return [.hiragana, .katakana, .romaji] }
    
    init(text: String, output: RubyConversionOutput) {
        self.text = text
        self.output = output
    }
    
    func convert(completion: @escaping (Result<String, RubyConversionError>) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let ruby = self.text.converting(to: self.output)
            if !self.isCancelled { completion(.success(ruby)) }
        }
    }
    
    mutating func cancel() {
        isCancelled = true
    }
}

/// Absence of a string tokenizer token.
fileprivate let kCFStringTokenizerTokenNone = CFStringTokenizerTokenType(rawValue: 0)

private extension String {
    func converting(to output: RubyConversionOutput) -> String {
        var result = ""
        let text = self as NSString
        let fullRange: CFRange = CFRangeMake(0, text.length)
        
        let tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, self as CFString, fullRange,  kCFStringTokenizerUnitWord, Locale(identifier: "ja") as CFLocale)
        
        // Scan through the string tokens, appending to result Latin transcription and ranges that can't be transcribed.
        var lastPosition: CFIndex = 0
        while CFStringTokenizerAdvanceToNextToken(tokenizer) != kCFStringTokenizerTokenNone {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if range.location > lastPosition {
                let missingRange = CFRange(location: lastPosition, length: range.location - lastPosition)
                result.append(self, range: missingRange)
            }
            lastPosition = range.max
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
                switch output {
                case .hiragana:
                    result += latin.applyingTransform(.latinToHiragana, reverse: false) ?? ""
                case .katakana:
                    result += latin.applyingTransform(.latinToKatakana, reverse: false) ?? ""
                case .romaji:
                    result += latin
                }
            }
        }
        if fullRange.max > lastPosition {
            let missingRange = CFRange(location: lastPosition, length: fullRange.max - lastPosition)
            result.append(self, range: missingRange)
        }
        
        return result
    }
    
    private mutating func append(_ string: String, range: CFRange) {
        guard let substring = CFStringCreateWithSubstring(kCFAllocatorDefault, string as CFString, range) else { return }
        append(substring as String)
    }
}

fileprivate extension CFRange {
    var max: CFIndex { return location + length }
}

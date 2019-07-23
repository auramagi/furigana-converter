//
//  ViewController.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var textInput: UITextField!
    @IBOutlet var rubyOutput: UILabel!
    
    @IBOutlet var providerSelectionButton: UIButton!
    @IBOutlet var outputSelectionButton: UIButton!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView?
    
    private let rubyConverter = RubyConverter()
    
    var conversionProvider = RubyConversionProvider.goo
    var conversionOutput = RubyConversionOutput.hiragana

    override func viewDidLoad() {
        super.viewDidLoad()
        
        rubyConverter.delegate = self
        updateButtonText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textInput.becomeFirstResponder()
    }
    
    private func updateButtonText() {
        providerSelectionButton.setTitle(conversionProvider.text, for: .normal)
        outputSelectionButton.setTitle(conversionOutput.text, for: .normal)
    }
    
    @IBAction func selectRubyProvider(_ sender: UIButton) {
        let options = [RubyConversionProvider.goo, .yahoo, .coreFoundation].map {
            AlertSelectorOption(value: $0, text: $0.text)
        }
        let alert = AlertSelector(title: nil, message: nil, options: options)
        alert.present(in: self, sender: sender) { [weak self] value in
            self?.conversionProvider = value
            let availableOutputs = RubyConverter.availableOutputs(provider: value)
            if let selectedOutput = self?.conversionOutput, !availableOutputs.contains(selectedOutput) {
                self?.conversionOutput = availableOutputs.first!
            }
            self?.convertCurrentText()
            self?.updateButtonText()
        }
    }
    
    @IBAction func selectRubyOutput(_ sender: UIButton) {
        let options = RubyConverter.availableOutputs(provider: conversionProvider).map {
            AlertSelectorOption(value: $0, text: $0.text)
        }
        let alert = AlertSelector(title: nil, message: nil, options: options)
        alert.present(in: self, sender: sender) { [weak self] value in
            self?.conversionOutput = value
            self?.convertCurrentText()
            self?.updateButtonText()
        }
    }
    
    @IBAction func textDidChange(_ textInput: UITextField) {
        convertCurrentText()
    }
    
    private func convertCurrentText() {
        guard let text = textInput.text, !text.isEmpty else {
            rubyConverter.cancel()
            rubyOutput.text = ""
            return
        }
        rubyConverter.convert(textInput.text ?? "", to: conversionOutput, using: conversionProvider)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: RubyConverterDelegate {
    func converterDidConvertText(_ originalText: String, ruby: String, output: RubyConversionOutput) {
        rubyOutput.text = ruby
    }
    
    func converterDidFail(error: RubyConversionError?) {
        let errorText: String
        switch error {
        case .some(.providerNotAvaliable): errorText = "変換オプションの\(conversionProvider.text)が設定されていないため、現在は使えません。"
        case .some(.outputNotAvailable): errorText = "変換オプションの\(conversionProvider.text)は\(conversionOutput.text)変換に非対応です。"
        default: errorText = "変換中、エラーが発生しました。"
        }
        rubyOutput.text = errorText
    }
    
    func converterWillStart() {
        activityIndicator?.isHidden = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func converterDidEnd() {
        activityIndicator?.isHidden = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension RubyConversionProvider {
    var text: String {
        switch self {
        case .goo: return "Goo"
        case .yahoo: return "Yahoo"
        case .coreFoundation: return "iOS"
        }
    }
}

extension RubyConversionOutput {
    var text: String {
        switch self {
        case .hiragana: return "ひらがな"
        case .katakana: return "カタカナ"
        case .romaji: return "ローマ字"
        }
    }
}

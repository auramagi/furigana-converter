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
        textInput.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        
        updateButtonText()
    }
    
    private func updateButtonText() {
        providerSelectionButton.setTitle(conversionProvider.text, for: .normal)
        outputSelectionButton.setTitle(conversionOutput.text, for: .normal)
    }
    
    @IBAction func selectRubyProvider(_ sender: UIButton) {
        let options = [RubyConversionProvider.goo].map {
            AlertSelectorOption(value: $0, text: $0.text)
        }
        let alert = AlertSelector(title: nil, message: nil, options: options)
        alert.present(in: self, sender: sender) { [weak self] value in
            self?.conversionProvider = value
            self?.convertCurrentText()
        }
    }
    
    @IBAction func selectRubyOutput(_ sender: UIButton) {
        let options = [RubyConversionOutput.hiragana, .katakana].map {
            AlertSelectorOption(value: $0, text: $0.text)
        }
        let alert = AlertSelector(title: nil, message: nil, options: options)
        alert.present(in: self, sender: sender) { [weak self] value in
            self?.conversionOutput = value
            self?.convertCurrentText()
        }
    }
    
    @objc func textDidChange(_ textInput: UITextField) {
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

extension ViewController: RubyConverterDelegate {
    func converterDidConvertText(_ originalText: String, ruby: String, output: RubyConversionOutput) {
        rubyOutput.text = ruby
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
        }
    }
}

extension RubyConversionOutput {
    var text: String {
        switch self {
        case .hiragana: return "ひらがな"
        case .katakana: return "カタカナ"
        }
    }
}
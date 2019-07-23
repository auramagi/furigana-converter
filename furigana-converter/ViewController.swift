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
    
    private let rubyConverter = RubyConverter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        rubyConverter.delegate = self
        textInput.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textDidChange(_ textInput: UITextField) {
        guard let text = textInput.text, !text.isEmpty else {
            rubyConverter.cancel()
            rubyOutput.text = ""
            return
        }
        rubyConverter.convert(textInput.text ?? "")
    }
}

extension ViewController: RubyConverterDelegate {
    func converterDidConvertText(_ originalText: String, ruby: String) {
        rubyOutput.text = ruby
    }
}

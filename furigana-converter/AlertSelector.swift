//
//  AlertSelector.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import UIKit

struct AlertSelectorOption<T> {
    let value: T
    let text: String
}

struct AlertSelector<T> {
    let title: String?
    let message: String?
    let options: [AlertSelectorOption<T>]
    
    func present(in viewController: UIViewController, sender: UIView, completion: @escaping (T) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        options.forEach { option in
            let action = UIAlertAction(title: option.text, style: .default, handler: { _ in
                completion(option.value)
            })
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        
        viewController.present(alert, animated: true, completion: nil)
    }
}

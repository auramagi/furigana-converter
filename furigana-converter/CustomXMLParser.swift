//
//  CustomXMLParser.swift
//  furigana-converter
//
//  Created by Mikhail Apurin on 23/07/2019.
//  Copyright © 2019 Mikhail Apurin. All rights reserved.
//

import Foundation

class XMLObject {
    let tagName: String
    var attributes: [String: String] = [:]
    var children: [Any] = []
    init(tagName: String) {
        self.tagName = tagName
    }
}

class XMLObjectParser: NSObject, XMLParserDelegate {
    let xml: XMLParser
    init(data: Data) {
        xml = XMLParser(data: data)
        super.init()
        xml.delegate = self
        xml.parse()
    }
    
    let document = XMLObject(tagName: "document")
    
    private var contextItems: [XMLObject] = []
    private var parent: XMLObject { return contextItems.count > 1 ? contextItems[-2] : document }
    private var currentItem: XMLObject { return contextItems.last ?? document }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let child = XMLObject(tagName: elementName)
        currentItem.children.append(child)
        contextItems.append(child)
        
        currentItem.attributes.merge(attributeDict, uniquingKeysWith: { _, new in return new })
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentItem.children.append(string)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        contextItems.removeLast()
    }

}

extension XMLObject {
    var text: String {
        let components: [String] = children.compactMap { child in
            if let child = child as? String { return child }
            if let child = child as? XMLObject { return child.text }
            return nil
        }
        return components.joined()
    }
    
    var xmlObjectChildren: [XMLObject] {
        return children.compactMap { $0 as? XMLObject }
    }
    
    func firstChild(withTagName tagName: String) -> XMLObject? {
        return xmlObjectChildren.first { $0.tagName == tagName }
    }
    
    func descendants(withTagName tagName: String) -> [XMLObject] {
        var result: [XMLObject] = []
        xmlObjectChildren.forEach {
            if $0.tagName == tagName { result.append($0) }
            result.append(contentsOf: $0.descendants(withTagName: tagName))
        }
        return result
    }
}

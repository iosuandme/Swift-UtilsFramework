//
//  XMLParser.swift
//  SQLiteSwift
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////
//
//  let document = XMLParser.parseXML("<boards><board><id>1</id><name>bbb1</name></board><board><id>2</id><name>bbb2</name></board></boards>")
//
//  if let doc = document?.root {
//      for note in doc.childNotes {
//          for attr in note.childNotes {
//              println("\(attr.key)=\(attr.value)")
//          }
//      }
//  }
//
/////////////////////////////////////////////////////////////////////////////

import Cocoa

class XMLParser {

    class func parseXML(string:String) -> XMLParser.Document? {
        let str:NSString = string
        return parseXML(str.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    class func parseXML(data:NSData) -> XMLParser.Document? {
        let parser = NSXMLParser(data: data)
        let delegate = Parser()
        parser.delegate = delegate
        if parser.parse() {
            return delegate.document
        }
        return nil
    }
}

extension XMLParser {
    class Note {
        
        var attributes:[NSObject : AnyObject]!
        var value:String?
        var cdata:NSData?
        var childNotes:[Note]=[]
        
        weak var parent:Note?
        let key:String
        init(_ key:String, _ parent:Note?) {
            self.key = key
            self.parent = parent
            if let note = parent {
                note.childNotes.append(self)
            }
        }
        
        init(_ key:String) {
            self.key = key
            self.parent = nil
        }

    }
    
    class Document : Note {
        var root:Note! {
            if self.childNotes.count > 0{
                return childNotes[0]
            }
            return nil
        }
    }
    
    class Parser : NSObject, NSXMLParserDelegate {
        override init() {
            current = document
        }
        let document:Document = Document("")
        var current:Note
        
        //开始解析
        func parserDidStartDocument(parser: NSXMLParser!) {
            //current = document
        }
        
        //开始解析节点
        func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
            let note = Note(elementName, current)
            note.attributes = attributeDict;
            current = note
        }
        
        //获取节点间内容
        func parser(parser: NSXMLParser!, foundCharacters string: String!) {
            current.value = string
        }
        
        //获取节点间CDATA
        func parser(parser: NSXMLParser!, foundCDATA CDATABlock: NSData!) {
            current.cdata = CDATABlock
        }
        
        //解析节点完成
        func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
            current = current.parent!
        }
        
        //解析完成
        func parserDidEndDocument(parser: NSXMLParser!) {
            
        }
    }
}
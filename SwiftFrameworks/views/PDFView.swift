//
//  PDFView.swift
//  ExamReader
//
//  Created by C Lau on 15/4/24.
//  Copyright (c) 2015年 C Lau. All rights reserved.
//

import UIKit

class PDFView: UIView {
    
    var pdf:CGPDFDocumentRef?
    var page:CGPDFPageRef?
    
    var totalPages:Int = 0
    
    var currentPage:Int = 0
    
    var scaleWidth:CGFloat = 1
    var scaleHeight:CGFloat = 1
    
    
    init(frame:CGRect,fileName:String) {
        super.init(frame: frame)
        let dataPathFromApp = "\(localFilePath)\(fileName)"
        pdf = createPDFFromExistFile(dataPathFromApp)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    var scale:CGFloat = 0
    func createPDFFromExistFile(aFilePath:String)->CGPDFDocumentRef? {
        var path:CFStringRef?
        var url:CFURLRef?
        var document:CGPDFDocumentRef?
    
        path = CFStringCreateWithCString(nil, aFilePath, CFStringBuiltInEncodings.UTF8.rawValue)
        
        
        url = CFURLCreateWithFileSystemPath(nil, path, CFURLPathStyle.CFURLPOSIXPathStyle, Boolean(0))
        
        
        
        document = CGPDFDocumentCreateWithURL(url!)
        
        
        totalPages = CGPDFDocumentGetNumberOfPages(document)
        
        currentPage = 1
        
        if (totalPages == 0) {
            return nil
        }
        
        
        let pdfPageRef = CGPDFDocumentGetPage(document, currentPage)
        
        let width = CGPDFPageGetBoxRect(pdfPageRef, kCGPDFMediaBox).size.width
        let height = CGPDFPageGetBoxRect(pdfPageRef, kCGPDFMediaBox).size.height
        
        println("width:\(width).....height:\(height)")
        
        scaleWidth = UIScreen.mainScreen().bounds.width / width
        scaleHeight = UIScreen.mainScreen().bounds.height / height
        
        scale = min(scaleWidth,scaleHeight)
        return document
    
    }
    
    

    
    
    override func drawRect(rect: CGRect) {
        let context:CGContextRef = UIGraphicsGetCurrentContext()
        page = CGPDFDocumentGetPage(pdf, currentPage)
        CGContextTranslateCTM(context, 0.0, UIScreen.mainScreen().bounds.height)
        CGContextScaleCTM(context, scale, -scale)

        
        
        CGContextDrawPDFPage(context, page)
        
    }
    
    
    func reloadView() {
        setNeedsDisplay()
    }
    
    func goUpPage() {
        
        if currentPage >= totalPages { return }
        ++currentPage
        reloadView()

        
    }
    
    func goDownPage() {
        
        if currentPage < 2 {  return  }
        
        --currentPage
        reloadView()

    }
    
    
    
}

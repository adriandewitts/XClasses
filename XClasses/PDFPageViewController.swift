//
//  DetailViewController.swift
//  Beachcomber
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class PDFPageViewController: XUIViewController//, PDFPageViewDelegate
{
    var pdfDocument: PDFDocument? = nil
    var pageNumber = 0

    override func viewDidLoad()
    {
        super.viewDidLoad()

        //let pdfView = self.view as! PDFPageView
        //pdfView.pageViewDelegate = self

        if let page = viewModel as? Text
        {
            pageNumber = page.number()
            pdfDocument = page.pdfDocument()
            let scrollView = self.view as! UIScrollView
            //pdfView.setPDFDocument(document: pdfDocument!, pageNumber: pageNumber)
            //let image = pdfDocument?.pdfPageImage(at: pageNumber)
            //let uiImageView = UIImageView(image: image)
            let pdfSubView = PDFPageSubview(pdfDocument: pdfDocument!, pageNumber: pageNumber, rect: self.view.frame)
            scrollView.addSubview(pdfSubView)
            //scrollView.sendSubview(toBack: pdfSubView)
            scrollView.contentSize = self.view.frame.size
            scrollView.setNeedsDisplay()
        }
    }

    func handleSingleTap(_ pdfPageView: PDFPageView)
    {
        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
    }

//    override func viewWillLayoutSubviews()
//    {
//        super.viewWillLayoutSubviews()
//        let pdfView = self.view as! PDFPageView
//        pdfView.layoutSubviews()
//    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

}


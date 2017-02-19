//
//  DetailViewController.swift
//  Beachcomber
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class PDFPageViewController: UIScrollImageViewController//, PDFPageViewDelegate
{
//    var pdfDocument: PDFDocument? = nil
//    var index = 0

    override func viewDidLoad()
    {


        //pdfView.pageViewDelegate = self

        if let page = viewModel as? PDFPageDelegate
        {
            self.image = page.pdfDocument().pdfPageImage(at: page.index())



//            let imageView = UIImageView(image: image)
//
//            imageView.frame = scrollView.frame
//
//            scrollView.addSubview(imageView)

//            let pdfSubView = PDFPageSubview(pdfDocument: pdfDocument!, pageNumber: index, rect: self.view.frame)
//            scrollView.addSubview(pdfSubView)
//
//            scrollView.sendSubview(toBack: pdfSubView)
//            scrollView.contentSize = self.view.frame.size
//            scrollView.setNeedsDisplay()
        }

        super.viewDidLoad()
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


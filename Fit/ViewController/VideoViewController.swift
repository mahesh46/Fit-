//
//  VideoViewController.swift
//  Fit
//
//  Created by mahesh lad on 01/01/2024.
//  Copyright © 2024 mahesh lad. All rights reserved.
//

import UIKit
import WebKit

class VideoViewController: UIViewController {
    
    var scrollView: UIScrollView!
    var stackView: UIStackView!
    
    //  Your YouTube video IDs
    let videoIDs = ["3WUtJxLv-wI", "MCf2QDOsy0E", "szqnwJbfFNw", "RtO-EDVQpgI",
                    "GcZJhNi2yOM", "ULmxJSKZ-Zc", "mYUayOteLWk", "kVnyY17VS9Y",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = . dark
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        for videoID in videoIDs {
            let webView = WKWebView()
            let videoURL = URL(string: "https://www.youtube.com/embed/\(videoID)")
            let request = URLRequest(url: videoURL!)
            webView.load(request)
            
            stackView.addArrangedSubview(webView)
            
            webView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        }
    }
}

//
//  ViewController.swift
//  videos-composer
//
//  Created by Romain ROCHE on 01/09/2017.
//  Copyright © 2017 Romain ROCHE. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet private var firstButton: UIButton?;
    @IBOutlet private var secondButtin: UIButton?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction
    private func captureFirstVideo() {
        print("capturing first video");
    }
    
    @IBAction
    private func getSecondVideo() {
        print("getting second video");
    }

}


//
//  ViewController.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/20.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var beaconsButton: UIButton!
    
    @IBOutlet weak var mapsButton: UIButton!
    
    @IBOutlet weak var paintingsButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        beaconsButton.backgroundColor = .systemGray5
        mapsButton.backgroundColor = .systemGray5
        paintingsButton.backgroundColor = .systemGray5
        
        
    }
    
    //Called when the view finishes laying out all its subviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Change the corner radius
        beaconsButton.layer.cornerRadius = beaconsButton.frame.height/7
        mapsButton.layer.cornerRadius = mapsButton.frame.height/7
        paintingsButton.layer.cornerRadius = paintingsButton.frame.height/7
        
        //Change the appearance of buttons
        setUpButton(button: beaconsButton)
        setUpButton(button: mapsButton)
        setUpButton(button: paintingsButton)
    }
    
    func setUpButton(button: UIButton){
        
        
        //To apply Shadow
        button.layer.shadowOpacity = 0.40
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowColor = UIColor.gray.cgColor
        
        
    }
    


}

